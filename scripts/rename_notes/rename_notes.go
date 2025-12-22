package main

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io/fs"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"time"
)

type GenReq struct {
	Model       string   `json:"model"`
	System      string   `json:"system,omitempty"`
	Prompt      string   `json:"prompt"`
	Stream      bool     `json:"stream"`
	Temperature *float64 `json:"temperature,omitempty"`
}

type GenResp struct {
	Response string `json:"response"`
	Done     bool   `json:"done"`
}

type Suggest struct {
	Title string   `json:"title"`
	Slug  string   `json:"slug"`
	Tags  []string `json:"tags"`
}

var (
	// Match old timestamped folder notes: .../20210504185947/README.md
	reTSReadme = regexp.MustCompile(`(^|/)(\d{14})/README\.md$`)

	reFrontmatter = regexp.MustCompile(`(?s)\A---\s*\n(.*?)\n---\s*\n`)
	reFMTitle     = regexp.MustCompile(`(?m)^\s*title:\s*(.+?)\s*$`)
	reFMID        = regexp.MustCompile(`(?m)^\s*id:\s*(.+?)\s*$`)
	reFMTags      = regexp.MustCompile(`(?m)^\s*tags:\s*(.+?)\s*$`)
	reH1          = regexp.MustCompile(`(?m)^\#\s+(.+?)\s*$`)

	reSlugClean = regexp.MustCompile(`[^a-z0-9\-]+`)
	reMultiDash = regexp.MustCompile(`-+`)
	reIsTS      = regexp.MustCompile(`^\d{14}$`)

	// Match any README.md (used for reviews/*/README.md mode)
	reAnyReadme = regexp.MustCompile(`(?i)(^|/)README\.md$`)
)

func main() {
	var (
		root        = flag.String("root", "/home/rossim2i2/Repos/github.com/rossim2i2/zet", "zet repo root")
		model       = flag.String("model", "zettel", "Ollama model name")
		host        = flag.String("host", "http://127.0.0.1:11434", "Ollama host")
		maxSlug     = flag.Int("max-slug", 60, "max slug chars (excluding timestamp/ext)")
		maxFilename = flag.Int("max-file", 90, "max basename chars excluding .md (timestamp+hyphen+slug)")
		excerpt     = flag.Int("excerpt", 2500, "max content chars sent to Ollama")
		timeout     = flag.Duration("timeout", 30*time.Second, "per-request timeout")
		apply       = flag.Bool("apply", false, "apply changes (git mv + rewrite files)")
		onlyReadme  = flag.Bool("only-readme", false, "only process YYYY.../README.md notes (skip root *.md)")
		baseDir     = flag.String("base-dir", "", "optional subdirectory to process (e.g. reviews)")
		readmeAny   = flag.Bool("readme-any", false, "process any README.md under base-dir (e.g. reviews/*/README.md)")
	)
	flag.Parse()

	rootAbs, err := filepath.Abs(*root)
	must(err)

	workRoot := rootAbs
	if *baseDir != "" {
		workRoot = filepath.Join(rootAbs, *baseDir)
	}

	paths := collectNotes(workRoot, *onlyReadme, *readmeAny)
	sort.Strings(paths)

	client := &http.Client{}
	changed := 0

	for _, p := range paths {
		rawBytes, err := os.ReadFile(p)
		if err != nil {
			fmt.Fprintf(os.Stderr, "read %s: %v\n", p, err)
			continue
		}
		raw := string(rawBytes)

		ts := inferTimestamp(p, raw)
		if ts == "" {
			// No timestamp we can trust; skip safely.
			continue
		}

		existingTitle := extractTitle(raw)
		body := stripFrontmatter(raw)
		body = strings.TrimSpace(body)

		// Provide some body even if empty by using the title (helps ollama)
		if body == "" && existingTitle == "" {
			continue
		}

		// Limit what we send to Ollama
		sentBody := body
		if len(sentBody) > *excerpt {
			sentBody = sentBody[:*excerpt]
		}

		ctx, cancel := context.WithTimeout(context.Background(), *timeout)
		sug, err := suggestAll(ctx, client, *host, *model, existingTitle, sentBody, *maxSlug)
		// If this is a reviews/*/README.md note, force slug from the book folder name.
		if *baseDir == "0_reviews" && *readmeAny && reAnyReadme.MatchString(filepath.ToSlash(p)) {
			bookDir := filepath.Base(filepath.Dir(p)) // e.g. "The Obstacle Is the Way"
			sug.Slug = bookDir
			sug.Title = existingTitle // keep whatever title is already in the note
		}
		cancel()

		// Fallbacks if Ollama fails or returns incomplete
		if err != nil {
			fmt.Fprintf(os.Stderr, "ollama failed for %s: %v\n", p, err)
		}
		if strings.TrimSpace(sug.Title) == "" {
			sug.Title = existingTitle
		}
		if strings.TrimSpace(sug.Title) == "" {
			// last resort: derive from first H1 or filename
			if t := extractH1(body); t != "" {
				sug.Title = t
			} else {
				sug.Title = "Untitled"
			}
		}
		if strings.TrimSpace(sug.Slug) == "" {
			sug.Slug = slugify(sug.Title)
		}

		// Normalize slug and enforce lengths
		slug := normalizeSlug(sug.Slug)
		slug = truncate(slug, *maxSlug)
		if slug == "" {
			slug = "note"
		}

		// Enforce max full basename length: ts + "-" + slug
		base := fmt.Sprintf("%s-%s", ts, slug)
		if len(base) > *maxFilename {
			need := *maxFilename - (len(ts) + 1)
			if need < 8 {
				need = 8
			}
			slug = truncate(slug, need)
			if slug == "" {
				slug = "note"
			}
			base = fmt.Sprintf("%s-%s", ts, slug)
		}

		dst := filepath.Join(workRoot, base+".md")
		dst = dedupeDestination(workRoot, dst)

		// Update frontmatter (id/title/tags in hashtag format)
		out := upsertFrontmatter(raw, ts, sug.Title, sug.Tags)
		outBytes := []byte(out)

		relSrc := strings.TrimPrefix(p, rootAbs+string(filepath.Separator))
		relDst := strings.TrimPrefix(dst, rootAbs+string(filepath.Separator))
		fmt.Printf("%s  ->  %s\n", relSrc, relDst)

		if *apply {
			// Move/rename (git mv keeps history)
			must(gitMv(rootAbs, p, dst))
			must(os.WriteFile(dst, outBytes, 0o644))
			changed++
		}
	}

	if !*apply {
		fmt.Printf("\nDry run. Re-run with --apply to execute.\n")
	} else {
		fmt.Printf("\nUpdated %d note(s).\n", changed)
	}
}

func collectNotes(root string, onlyReadme bool, readmeAny bool) []string {
	var all []string
	_ = filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() {
			switch d.Name() {
			case ".zk", ".git":
				return filepath.SkipDir
			}
			return nil
		}
		if filepath.Ext(d.Name()) != ".md" {
			return nil
		}
		all = append(all, path)
		return nil
	})

	out := make([]string, 0, len(all))
	for _, p := range all {
		// Old: timestamped README.md
		if reTSReadme.MatchString(filepath.ToSlash(p)) {
			out = append(out, p)
			continue
		}
		// New mode: any README.md under workRoot (e.g. reviews/*/README.md)
		if readmeAny && reAnyReadme.MatchString(filepath.ToSlash(p)) {
			out = append(out, p)
			continue
		}

		// New: root md files
		if !onlyReadme && filepath.Dir(p) == root {
			out = append(out, p)
		}
	}
	return out
}

func inferTimestamp(path, text string) string {
	// 1) old folder name
	if m := reTSReadme.FindStringSubmatch(filepath.ToSlash(path)); len(m) == 3 {
		return m[2]
	}
	// 2) frontmatter id
	if m := reFrontmatter.FindStringSubmatch(text); len(m) == 2 {
		fm := m[1]
		if idm := reFMID.FindStringSubmatch(fm); len(idm) == 2 {
			id := strings.Trim(idm[1], ` "'`)
			if reIsTS.MatchString(id) {
				return id
			}
		}
	}
	// 3) filename prefix
	base := strings.TrimSuffix(filepath.Base(path), filepath.Ext(path))
	if len(base) >= 14 && reIsTS.MatchString(base[:14]) {
		return base[:14]
	}
	// 4) fallback: file mtime -> YYYYMMDDHHMMSS
	if st, err := os.Stat(path); err == nil {
		return st.ModTime().Format("20060102150405")
	}
	return ""
}

func extractTitle(text string) string {
	// frontmatter title
	if m := reFrontmatter.FindStringSubmatch(text); len(m) == 2 {
		fm := m[1]
		if t := reFMTitle.FindStringSubmatch(fm); len(t) == 2 {
			return strings.Trim(t[1], ` "'`)
		}
	}
	// first H1
	if h := reH1.FindStringSubmatch(text); len(h) == 2 {
		return strings.TrimSpace(h[1])
	}
	return ""
}

func extractH1(body string) string {
	if h := reH1.FindStringSubmatch(body); len(h) == 2 {
		return strings.TrimSpace(h[1])
	}
	return ""
}

func stripFrontmatter(text string) string {
	if m := reFrontmatter.FindStringSubmatchIndex(text); m != nil {
		return text[m[1]:]
	}
	return text
}

func dedupeDestination(root, dst string) string {
	// If dst exists, append -2, -3, ...
	if !fileExists(dst) {
		return dst
	}
	dir := filepath.Dir(dst)
	base := strings.TrimSuffix(filepath.Base(dst), filepath.Ext(dst))
	ext := filepath.Ext(dst)
	for i := 2; ; i++ {
		cand := filepath.Join(dir, fmt.Sprintf("%s-%d%s", base, i, ext))
		if !fileExists(cand) {
			return cand
		}
	}
}

func upsertFrontmatter(text, ts, title string, tags []string) string {
	// Parse existing frontmatter if present
	fm := ""
	body := text
	if m := reFrontmatter.FindStringSubmatch(text); len(m) == 2 {
		fm = m[1]
		body = stripFrontmatter(text)
	}

	kv := parseFrontmatterKV(fm)

	// Ensure id
	if _, ok := kv["id"]; !ok {
		kv["id"] = ts
	} else {
		// Normalize id if it looks like quoted timestamp
		id := strings.Trim(kv["id"], ` "'`)
		if reIsTS.MatchString(id) {
			kv["id"] = id
		}
	}

	// Ensure title
	if strings.TrimSpace(title) != "" {
		kv["title"] = quoteYAML(title)
	} else {
		// Keep existing title if present, else attempt from H1
		if _, ok := kv["title"]; !ok {
			h1 := extractH1(body)
			if h1 != "" {
				kv["title"] = quoteYAML(h1)
			}
		}
	}

	// Update tags if suggested tags are present
	if len(tags) > 0 {
		hashtags := make([]string, 0, len(tags))
		seen := map[string]bool{}

		for _, t := range tags {
			t = strings.TrimSpace(t)
			if t == "" {
				continue
			}
			// Accept either "#tag" or "tag"; normalize to "#kebab-case"
			if strings.HasPrefix(t, "#") {
				t = t[1:]
			}
			t = normalizeSlug(t)
			if t == "" {
				continue
			}
			tag := "#" + t
			if !seen[tag] {
				seen[tag] = true
				hashtags = append(hashtags, tag)
			}
		}

		if len(hashtags) > 0 {
			sort.Strings(hashtags)
			kv["tags"] = yamlInlineStringArray(hashtags) // quoted strings
		}
	} else {
		// If tags missing entirely, keep existing tags untouched
		if _, ok := kv["tags"]; !ok {
			// Keep as-is
		}
	}

	// If there was a tags line like tags: [] and we didn't set tags, keep it.
	// kv already preserves it if it existed.

	// Rebuild frontmatter in a stable order
	keysFirst := []string{"id", "title", "date", "tags", "type"}
	seenKey := map[string]bool{}
	outFM := []string{}
	for _, k := range keysFirst {
		if v, ok := kv[k]; ok {
			outFM = append(outFM, fmt.Sprintf("%s: %s", k, v))
			seenKey[k] = true
		}
	}
	// Append remaining keys
	extras := []string{}
	for k := range kv {
		if !seenKey[k] {
			extras = append(extras, k)
		}
	}
	sort.Strings(extras)
	for _, k := range extras {
		outFM = append(outFM, fmt.Sprintf("%s: %s", k, kv[k]))
	}

	body = strings.TrimLeft(body, "\n")
	return fmt.Sprintf("---\n%s\n---\n\n%s", strings.Join(outFM, "\n"), body)
}

func parseFrontmatterKV(fm string) map[string]string {
	kv := map[string]string{}
	lines := strings.Split(fm, "\n")
	for _, ln := range lines {
		ln = strings.TrimRight(ln, "\r")
		if strings.TrimSpace(ln) == "" {
			continue
		}
		parts := strings.SplitN(ln, ":", 2)
		if len(parts) != 2 {
			continue
		}
		k := strings.TrimSpace(parts[0])
		v := strings.TrimSpace(parts[1])
		kv[k] = v
	}
	return kv
}

func quoteYAML(s string) string {
	// Use JSON quoting (valid YAML string quoting as well)
	b, _ := json.Marshal(s)
	return string(b)
}

func yamlInlineStringArray(items []string) string {
	// YAML inline list with QUOTED items so "#tag" is not treated as comment.
	quoted := make([]string, 0, len(items))
	for _, it := range items {
		quoted = append(quoted, quoteYAML(it))
	}
	return fmt.Sprintf("[%s]", strings.Join(quoted, ", "))
}

func suggestAll(ctx context.Context, client *http.Client, host, model, existingTitle, body string, maxSlug int) (Suggest, error) {
	system := fmt.Sprintf(`You generate a note title, file slug, and tags for a Zettelkasten note.
Return ONLY valid JSON with keys "title", "slug", and "tags". No markdown, no commentary, no code fences.

Rules:
- Use the content as the primary signal; the existing title is secondary.
- title: short, specific, not generic.
- slug: lowercase ASCII, hyphen-separated, no punctuation except hyphen, no leading/trailing hyphen.
- slug should be <= %d characters if possible.
- tags: 3 to 7 items.
- tag format: MUST be hashtag strings like "#kebab-case".
- tags should be topical (concepts/entities), not meta like "#note" or "#zettelkasten".
If you cannot comply, return {"title":"","slug":"","tags":[]}.`, maxSlug)

	prompt := fmt.Sprintf(
		"Existing title (may be empty): %q\n\nNote content:\n%s\n\nReturn JSON now.",
		existingTitle, body,
	)

	temp := 0.2
	reqBody := GenReq{
		Model:       model,
		System:      system,
		Prompt:      prompt,
		Stream:      false,
		Temperature: &temp,
	}
	j, _ := json.Marshal(reqBody)

	req, err := http.NewRequestWithContext(ctx, "POST", strings.TrimRight(host, "/")+"/api/generate", bytes.NewReader(j))
	if err != nil {
		return Suggest{}, err
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := client.Do(req)
	if err != nil {
		return Suggest{}, err
	}
	defer resp.Body.Close()
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return Suggest{}, fmt.Errorf("ollama status %s", resp.Status)
	}

	var out GenResp
	if err := json.NewDecoder(resp.Body).Decode(&out); err != nil {
		return Suggest{}, err
	}

	s := strings.TrimSpace(out.Response)
	// Extract first JSON object if there is any leading/trailing junk
	start := strings.Index(s, "{")
	end := strings.LastIndex(s, "}")
	if start < 0 || end < 0 || end <= start {
		return Suggest{}, errors.New("no JSON object in response")
	}
	s = s[start : end+1]

	var sug Suggest
	if err := json.Unmarshal([]byte(s), &sug); err != nil {
		return Suggest{}, err
	}
	return sug, nil
}

func slugify(s string) string {
	s = strings.ToLower(strings.TrimSpace(s))
	var b strings.Builder
	for _, r := range s {
		switch {
		case r >= 'a' && r <= 'z':
			b.WriteRune(r)
		case r >= '0' && r <= '9':
			b.WriteRune(r)
		case r == ' ' || r == '_' || r == '-':
			b.WriteRune('-')
		}
	}
	return normalizeSlug(b.String())
}

func normalizeSlug(s string) string {
	s = strings.ToLower(strings.TrimSpace(s))
	s = reSlugClean.ReplaceAllString(s, "-")
	s = reMultiDash.ReplaceAllString(s, "-")
	s = strings.Trim(s, "-")
	return s
}

func truncate(s string, max int) string {
	if len(s) <= max {
		return s
	}
	s = s[:max]
	s = strings.TrimRight(s, "-")
	return s
}

func fileExists(p string) bool {
	_, err := os.Stat(p)
	return err == nil
}

func gitMv(repoRoot, src, dst string) error {
	cmd := exec.Command("git", "mv", src, dst)
	cmd.Dir = repoRoot
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

func must(err error) {
	if err != nil {
		panic(err)
	}
}
