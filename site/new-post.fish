#!/usr/bin/env fish

if test (count $argv) -lt 1
    echo "Usage: ./new-post.fish \"Post Title\"" >&2
    exit 1
end

set -l title $argv[1]
set -l date_str (date +%F)

set -l safe_title (string replace -a '"' '\"' -- $title)
set -l slug (string lower -- $title | string replace -ra '[^a-z0-9]+' '-' | string replace -ra '^-+|-+$' '')

if test -z "$slug"
    set slug "untitled-post"
end

set -l post_file "content/post/$date_str-$slug.md"

printf "+++\n"
printf "title = \"%s\"\n" "$safe_title"
printf "date = %s\n" "$date_str"
printf "slug = \"%s\"\n" "$slug"
printf "+++\n\n"
printf "Post file: %s\n" "$post_file" >&2
