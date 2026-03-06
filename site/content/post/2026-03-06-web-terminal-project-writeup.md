+++
title = "Web Terminal Project Writeup"
date = 2026-03-06
slug = "webterm"
+++

(TODO expound on bullet points)

## Intro
- 


## Retrospective



- use  [Kubebuilder](https://book.kubebuilder.io/)

- My soltution [instantiates a watch (click for source code)](https://todo-link-to-watch-in-source-code) on a Kubernetes API object
- However, the watch on the object returns a large stream of data that has to be filtered to find the revelant data
- If the data backing the watch changes while it's active, then .... (todo relearn how this works)
- We use a complex concurrency pattern to filter the data
- We use a complex concurrency pattern to filter the data



## How
