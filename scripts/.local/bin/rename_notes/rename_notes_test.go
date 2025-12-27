package main

import "testing"

func TestStripFrontmatter(t *testing.T) {
	in := `---
title: "Hello"
tags: ["#one"]
---

# Heading

Body text.
`
	out := stripFrontmatter(in)
	if out == in {
		t.Fatalf("expected frontmatter to be stripped, but output unchanged")
	}
	if len(out) == 0 || out[0] != '\n' && out[0] != '#' {
		t.Fatalf("unexpected stripped output: %q", out[:min(30, len(out))])
	}
	if got := extractTitle(in); got != "Hello" {
		t.Fatalf("extractTitle from frontmatter: got %q want %q", got, "Hello")
	}
}

func TestExtractTitleFallsBackToH1(t *testing.T) {
	in := `
# My H1 Title

Some content.
`
	got := extractTitle(in)
	if got != "My H1 Title" {
		t.Fatalf("extractTitle from H1: got %q want %q", got, "My H1 Title")
	}
}

func TestInferTimestampFromOldReadmePath(t *testing.T) {
	path := "/home/u/zet/20210504185947/README.md"
	text := `---
title: "Anything"
---`
	got := inferTimestamp(path, text)
	if got != "20210504185947" {
		t.Fatalf("inferTimestamp from folder: got %q want %q", got, "20210504185947")
	}
}

func TestInferTimestampFromFrontmatterID(t *testing.T) {
	path := "/home/u/zet/some-note.md"
	text := `---
id: 20240102123456
title: "T"
---

# T
`
	got := inferTimestamp(path, text)
	if got != "20240102123456" {
		t.Fatalf("inferTimestamp from frontmatter id: got %q want %q", got, "20240102123456")
	}
}

func TestNormalizeSlug(t *testing.T) {
	in := "  Hello, World!!!  "
	got := normalizeSlug(in)
	want := "hello-world"
	if got != want {
		t.Fatalf("normalizeSlug: got %q want %q", got, want)
	}
}

func TestUpsertFrontmatterAddsIDTitleAndQuotedHashtagTags(t *testing.T) {
	in := `# Heading

Body.
`
	out := upsertFrontmatter(in, "20210504185947", "My Title", []string{"#Wayland", "tmux", "#wl-clipboard"})
	// Should contain id
	if !contains(out, "id: 20210504185947") {
		t.Fatalf("expected id in frontmatter, got:\n%s", out)
	}
	// Title is quoted
	if !contains(out, `title: "My Title"`) {
		t.Fatalf("expected quoted title, got:\n%s", out)
	}
	// Tags are quoted strings because of '#'
	if !contains(out, `tags: ["#tmux", "#waybar", "#wl-clipboard"]`) &&
		!contains(out, `tags: ["#tmux", "#wayland", "#wl-clipboard"]`) {
		// We sort tags, normalize to kebab-case, and prefix '#'
		// So expected tags include "#wayland" (from Wayland) and others.
		t.Fatalf("expected quoted hashtag tags list, got:\n%s", out)
	}
}

func TestTagsNormalizationAndSorting(t *testing.T) {
	in := `---
title: "T"
tags: []
---

# T
`
	out := upsertFrontmatter(in, "20210504185947", "T", []string{"#Zettelkasten", "zetTelKasten", "  tmux  ", "#tmux"})
	// Should dedupe and normalize
	// "zetTelKasten" -> "#zettelkasten"
	// "tmux" and "#tmux" -> "#tmux"
	if !contains(out, `tags: ["#tmux", "#zettelkasten"]`) {
		t.Fatalf("expected normalized/deduped/sorted tags, got:\n%s", out)
	}
}

// helpers

func contains(s, sub string) bool {
	return len(sub) == 0 || (len(s) >= len(sub) && indexOf(s, sub) >= 0)
}

func indexOf(s, sub string) int {
	// simple implementation to avoid importing strings in tests if you prefer
	// (feel free to replace with strings.Contains)
	for i := 0; i+len(sub) <= len(s); i++ {
		if s[i:i+len(sub)] == sub {
			return i
		}
	}
	return -1
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
