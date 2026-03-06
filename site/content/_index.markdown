---
title: Home
---

# Elan England's Website

<br >
    
This site has:
- My [resume](/resume/).
- [All articles](/all-posts/) about various technical topics.
-  Write-ups about some personal projects I've completed (see below).

<br>

## [Shellbin](/shellbin/)
<hr>

Shellbin is a microservice architecture project that I built to exercise my understanding of CI/CD for cloud-native applications.

It's named shellbin because it's a pastebin clone that you can access with your shell using Unix pipes and the `netcat` utility.

```fish
cat $FILE | nc sb.cat-z.xyz
```

Users can also create pastes using a web front-end written in Go that uses server-side rendering.

The CLI and the web front-end both talk with the same decoupled microservice which itself talks to the database. 
This relationship is expressed in the diagram below.

```mermaid
flowchart LR
    Browser[Browser / HTTP client]
    Netcat[Netcat / TCP client]

    subgraph K8s["Kubernetes"]
      WS[webserver<br/>Gin on :4747<br/>Service port 80]
      NC[nc-server<br/>TCP on :6262<br/>Service targetPort 6262]
      DB[db-service<br/>Gin on :7272<br/>Service port 80]
      MYSQL[(MySQL)]
    end
    class K8s k8slabel
    classDef k8slabel color:#ffffff 

    Browser -->|GET /, GET /paste/:path, POST /submit| WS
    Netcat -->|TCP paste content| NC

    WS -->|HTTP POST /processInput| DB
    WS -->|HTTP POST /servePaste| DB
    NC -->|HTTP POST /processInput| DB

    DB -->|SQL queries to pastes table| MYSQL
```

In total, there are 4 discrete container images involved in this project: A web server, a database service, a netcat-receiving-server, and the MySQL database container.

As mentioned, the main goal was to implement a full CI/CD developement pipeline for these microservices.

The CI/CD pipeline includes testing and building the microservice binary entrypoints, TODO

Read the [full Shellbin write-up here](/shellbin/) for more details.

<br>
    
## [Webterm](/webterm/)
---

Webterm is a system that allows users to access Unix machines from their web browser.

I wrote this project because I wanted to do something in Kubernetes that sounded really interesting and a bit intimidating. Basically, my goal was to write Go code to interact with the Kubernetes API to create, destroy, and scale pods based on user load, and assign each pod to a user.

This project was out of my comfort zone and the source code reflects that. Despite that, it actually works!
Building something to process actually data coming from Kubernetes instead of using a pre-built solution taught me a about how to Kubernetes API works.

It also allowed me to implement some very neat and famous concurrency patterns in golang.

Here's the main concurrent runner of the component that reads from the Kubernetes API to scale pods.

```go
	for {
		select {
		case paramToAppend := <-fil.paramStream:
			fil.params = append(fil.params, &paramToAppend)
			fmt.Printf("params: %v\n", fil.params)
		case indexToRemove := <-fil.remIndexChan:
			fmt.Printf("removing filterParam %v\n", fil.params[indexToRemove].desc) //t
			fmt.Println(fil.params)                                                 //t
			fil.params = remove(fil.params, indexToRemove)
			fmt.Println(fil.params) //t
		case event := <-fil.inChan:
			for _, fp := range fil.params {
				if fp.pass(event, fil.done) {
					fp.outChan <- event
				}
			}
		case <-fil.done:
			return
		default:
			if len(fil.params) == 0 {
				fmt.Println("len(fil.params) == 0. closing filter") //t
				close(fil.done)
				runningFilter = nil
			}
		}
	}
```

This concurrency pattern is called a "for select loop", which I read about in the very fun book [Concurrency in Go](https://katherine.cox-buday.com/concurrency-in-go/) by Katherine Cox-Buday.

The code is sort of a mess, but I think it's very funny that it's a mess that _actually works._

There's a lot involved in the project:
- Helm charts to deploy various components
- Website frontend that emulates a terminal.
- Containers to run the Unix machine that is served to clients.
- Synchronization between pseudo-terminal hosting containers and website frontend
- Kubernetes cluster to all components
- TODO


Read the [full Webterm write-up here](/shellbin/) for more details.

<br>
    
## [Kubernetes Cluster](/cluster/)
---

My local kubernetes cluster.

The cluster uses GitOps via FluxCD. This means that the cluster configuration and applications are controlled using a git repo, so you can [see the source code of the cluster here.](https://github.com/england2/cluster)


<img src="/images/cluster.png" alt="Kubernetes cluster test bench" style="width: 50%; display: block; margin: 0 auto;">

### Cluster Description
- Cluster is GitOps enabled using FluxCD
- Grafana metrics systems
- 24 cores and 48GB of ram over three _beastly_ dell 7060s (this would be considered high performance computing back in the 80s.)
