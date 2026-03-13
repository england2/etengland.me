+++
title = "Rewriting top in ocaml"
date = 2026-03-06
slug = "top-rewrite-ocaml"
+++

## Intro

- Linux's `top` is actually pretty complex, so we will only implement a few core features (sorry for the clickbait).
- This post goes over some Linux fundamentals, so if you're bored by that, then just feel free to skip past those parts!
- My goal for this project is to _only use the standard ocaml library in addition to `base`_. There are many great libraries for interacting with Linux, but using them would take away some of the fun.
- I'm new to ocaml! Feel free to [contact me](/mail://elan.thomas.england@gmail.com/) with any comments or corrections.


## What is `top`?

## Exploring the /proc/ folder and deciding our program structure

Unsurprisingly, a `top` program will probably want to look at the entire process list running on the system.

No, we don't have to invoke a bunch of nastly, low-level system calls to get the list. In fact, we already have it before the program is written!

Of course, I'm talking about the `/proc/` folder in Linux, which is short for "process".

Let's inspect the `/proc/` folder using df.

```fish
/proc % df .
Filesystem      Size  Used Avail Use% Mounted on
proc               0     0     0    - /proc
```

Because we wont be using libraries, it's important to understand what's happening here.
The file system of `/proc/` is just `proc`. What's actually happening here?


[This kernel.org article](/https://docs.kernel.org/filesystems/proc.html/) goes into a lot more detail about `/proc/`.

## Our first step of experimentation will be just print every
