+++
title = "Print Firefox History from the command line"
date = 2026-03-07
slug = "firefox-history-cli"
+++

Firefox stores your browser history in a `.sqlite` file.

Therefore, it's pretty easy to script!

Here's a quick fish script that allows you to print your browsing history on the command line, similar to the builtin `history` command in most shells.

## ~/bin/ff-history

```fish
#!/usr/bin/env fish

# Replace `src` with your own firefox directory
set src $HOME/.mozilla/firefox/hogh53e4.default-release
set tmp $XDG_RUNTIME_DIR/places_copy.sqlite

# Default behavior is like most shell's `history` command; just print everything
set -l like_query '.'
set -l limit '-1'

# Optional arg to filter at the SQL query stage (conserve a `grep`)
set -q argv[1] && set -l like_query $argv[1]
# Optional arg to only return $limit matches from the query (conserve a `head -n <x>`)
set -q argv[2] && set -l limit $argv[2]

# Copy DB, as firefox will lock this file if it's running
cp $src/places.sqlite $tmp

# copy write-ahead-log if it exists
if test -f $src/places.sqlite-wal
    cp $src/places.sqlite-wal $tmp-wal
end

# Define and run our query
set query "
SELECT
    url
FROM moz_places
WHERE url LIKE '%$like_query%'
ORDER BY last_visit_date DESC
LIMIT $limit;
"
set query_res (printf "%s\n" $query | sqlite3 $tmp)

# Print
for line in $query_res
    echo $line
end

# Clean up
/bin/rm -f $tmp
if test -f $tmp-wal
    /bin/rm -f $tmp-wal
end
```
<br>


## Examples

print your 5 most recent github page vists
```bash
~ % ff-history 'github' 5
https://github.com/fsnotify/fsnotify/issues/9
https://github.com/fsnotify/fsnotify
https://github.com/golang/go/wiki/SliceTricks
https://github.com/arp242/arp242.net/issues/34
https://github.com/arp242/arp242.net/issues/37
https://github.com/arp242/arp242.net/issues/44
```

print your top-6 favorite sites

```bash
~ % ff-history | awk -F'/' '{print $3}' | sort | uniq -c | sort -nr | head -n6
     59 github.com
     36 www.google.com
     32 www.amazon.com
     31 www.youtube.com
     28 www.bilibili.com
     18 www.dcard.tw
```

## Addendum

You can also get more data out of it by using this query

```fish
set query "
SELECT
    url,
    title,
    datetime(last_visit_date/1000000, 'unixepoch') AS last_visit,
    visit_count
FROM moz_places
WHERE url LIKE '%$like_query%'
ORDER BY last_visit_date DESC
LIMIT $limit;
"
```

resulting in

```fish
~ % ff-history sean 5
https://www.seangoedecke.com/is-ai-wrong/|Is using AI wrong? A review of six popular anti-AI arguments||0
https://www.seangoedecke.com/party-tricks/|Crushing JIRA tickets is a party trick, not a path to impact||0
https://www.seangoedecke.com/ratchet-effects/|Ratchet effects determine engineer reputation at large companies||0
https://www.seangoedecke.com/getting-the-main-thing-right/#fnref-3|Getting the main thing right||0
https://www.seangoedecke.com/getting-the-main-thing-right/|Getting the main thing right||0
```
