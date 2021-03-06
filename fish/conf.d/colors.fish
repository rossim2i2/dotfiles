## set fish colors

if not set -q faho_colors_set
    echo Setting colors
    set -U faho_colors_set
    set -U fish_color_normal brcyan # normal
    set -U fish_color_command 005fd7
    set -U fish_color_param 00afff # cyan
    set -U fish_color_redirection FFF # normal
    set -U fish_color_comment 666 # THE NUMBER OF THE BEAST...
    set -U fish_color_error A00 --bold
    set -U fish_color_escape 0AA # cyan
    set -U fish_color_operator 0AA # cyan
    set -U fish_color_quote A50 # brown
    set -U fish_color_autosuggestion 7d7d7d
    set -U fish_color_valid_path --underline
    set -U fish_color_cwd 0A0 # green
    set -U fish_color_cwd_root A00 # red

    set -U fish_color_status --background=red white
    # Background color for matching quotes and parenthesis
    set -U fish_color_match 0AA # cyan

    # Background color for search matches
    set -U fish_color_search_match --background=533 # --background=purple

    # Background color for selections
    set -U fish_color_selection --background=B218B2 # --background=purple

    # Pager colors
    set -U fish_pager_color_prefix --underline 0AA # cyan
    set -U fish_pager_color_completion $fish_color_normal
    set -U fish_pager_color_description $fish_color_comment
    set -U fish_pager_color_progress $fish_color_match

    #
    # Directory history colors
    #

    set -U fish_color_history_current 0AA # cyan
end
