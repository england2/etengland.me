+++
title = "Saving links to webpages the Unix way"
date = 2026-03-14
slug = "filesystem-links"
+++

When I take notes on a technical article I make a directory with example code to experiment with.

In these situations it's useful to keep a link to the article in the same directory.

Here's a script that makes a special 'weblink' file.

```bash
# file: ~/bin/mkwl ("make web link")
#!/usr/bin/env fish
source /home/t/.config/fish/global.fish

set url $argv[1]
set filename \
    (string sub -s 3 -e 66 \
    (string replace 'http:' '' \
    (string replace 'https:' '' \
    (string replace --all '/' '_' $url)))).weblink

echo "$filename"
echo $url > $filename
```

To create a weblink we just do

```txt
$ mkwl https://medium.com/@siacavazzi/how-i-made-a-robust-web-scraper-d17060470bd8
```

And we get

```txt
$ ls
'medium.com_@siacavazzi_how-i-made-a-robust-web-scraper-d17060470.weblink'
```

And now we need a script to open it

```bash
# file: ~/bin/owl ("open web link")
#!/usr/bin/env fish
firefox (cat $argv[1] | head -n1) >/dev/null 2>&1 &
disown
```

Which we might call like so

```bash
owl medium.com_@siacavazzi_how-i-made-a-robust-web-scraper-d17060470.weblink
```


## Make it official

Here's how we can make weblinks recognized by `xdg` in Linux.

We need a desktop entry

```txt
# file: ~/.local/share/applications/weblink.desktop
[Desktop Entry]
Type=Application
Name=Open Web Link
Exec=/home/t/bin/owl %f
MimeType=application/x-weblink;
NoDisplay=true
Terminal=false
```

And a mime type

```txt
# file: ~/.local/share/mime/packages/weblink.xml
<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
  <mime-type type="application/x-weblink">
    <comment>Web link</comment>
    <glob pattern="*.weblink"/>
  </mime-type>
</mime-info>
```

Register it

```bash
update-mime-database ~/.local/share/mime
update-desktop-database ~/.local/share/applications
xdg-mime default weblink.desktop application/x-weblink
```

Check it

```bash
xdg-mime query filetype example.weblink
xdg-mime query default application/x-weblink
```

Then open a link

```bash
xdg-open example.weblink
```

<br>
