#!/usr/bin/env fish

if test (count $argv) -lt 1
    echo "Usage: ./new-post.fish \"Post Title\"" >&2
    exit 1
end

set -l title (string join " " -- $argv[1..-1])
set -l date_str (date +%F)

set -l safe_title (string replace -a '"' '\"' -- $title)
set -l slug (string lower -- $title | string replace -ra '[^a-z0-9]+' '-' | string replace -ra '^-+|-+$' '')
set -l post_file "content/post/$date_str-$slug.md"

set -l s "\
+++
title = \"$safe_title\"
date = $date_str
slug = \"$slug\"
+++
"
echo $s > $post_file

echo $post_file

