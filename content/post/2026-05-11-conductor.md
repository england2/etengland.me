+++
title = "Agent Conductor Discussion (Working Copy)"
date = 2026-05-11
slug = "conductor"
hidden_from_all_posts = false
+++

<img src="/images/conductor-main.png" style="width: 100%; display: block; margin: 0 auto;">

<br>


## Source Code!



## Source Code!

https://github.com/england2/aws-demo/

## Overview

The Agent Conductor is responsible for scheduling and managing agents in reaction to tickets and AWS platform incidents.

The basic idea is that the conductor is the control process. It does not do the agent's work itself, and onstead watches for inputs, decides whether an agent should be started, prepares the agent's task files, and then starts a worker.

At a high level, here is how this project works:

- Tickets and CloudWatch alarms pushed to an SQS queue which the conductor polls for new work
- When the conductor gets new SQS messages, it passes the messages to the scheduler routine:
    - The scheduler places all tickets and incident alarms into an internal database
    - The scheduler relates new messages to old messages, determining if a job has already been spawned for the ticket or for incident messaging relating to an ongoing incident
    - The scheduler routine returns to main with a decision whether or not to spawn an agent
- The conductor interprets the decision and if necesarry spawns an agent
- The agent worker connects back to the conductor over gRPC
- The conductor sends the worker its task files
- The worker runs Codex, does the requested work, and submits its changes to github

The conductor currently handles two kinds of inputs:

- Tickets, which always spawn a job
- CloudWatch alarms, which may need to be grouped together so we do not spawn too many agents during one incident

# Database Scheduling System

The conductor is responsible for deciding when to spawn an agent, which I refer to as scheduling.

There are two types of scheduling that the conductor can perform, which are ticket scheduling and incident scheduling.

Here is how both work.

*Ticket scheduling:*
- The conductor receives a ticket from SQS, sourced from something like Jira.
- The scheduler stores the ticket in the database.
- If the ticket has not already been scheduled, the scheduler tells main to spawn one agent for it.
- If the ticket has been scheduled already, then no agent spawns.

Ticket scheduling is more simple than incident scheduling. Basically, the only point of the database here is to prevent repeating work.

<br>

Incident scheduling relates to CloudWatch alarms, such as high CPU alerts, error rates, cost anomalies, etc.
We're trying to spawn agents in reaction to AWS platform events, so there is slightly more logic involved here.

*Incident scheduling:*
- The conductor receives a CloudWatch alarm message from SQS.
- The scheduler stores the alarm in the database.
- The scheduler looks for other recent alarms that seem related.
- One alarm by itself does not spawn an agent.
- Multiple related alarms close together can become one incident.
- If that incident has not already been scheduled, the scheduler tells main to spawn one agent for it.

Incident scheduling is more careful because alarms can arrive in bursts. If 10 alarms are all part of the same problem, we probably do not want 10 agents working on it. We want one agent with enough context to understand the ongoing incident.

Right now, the relationship between alarms is really simple. Alarms from the same AWS account can be grouped together if they happen close enough in time. The current window is one hour.

## Acheiving Program Durability via Scheduling on a Database

The above describes simple scheduling logic that could easily be done in program memory without a database.

Of course, the issue with this is that program memory dies when the program dies.

The database is useful because it lets the conductor remember what has already been scheduled. If the conductor restarts, we can look at the database and avoid spawning duplicate agents for the same ticket or the same incident.

## Improved Program Testability With Database Scheduling
Deciding when to spawn an agent *and* with what context, permissions, repos, prompts, etc. to provide the agent with is an extremely important part of the program. Agent scheduling mistakes may include spawning too many agents or spawning agents that don't have the proper context/permissions to do their job. 

**It's important to get scheduling mistakes right, as badly scheduled agents will likely produce these kinds of penatlies:**
  - Wasting engineer hours on reviewing diffs that shouldn't exist in the first place (happens if we spawn too many agents; agents with weak context)
  - Wasting money on fargate instances (too many agents)
  - Delayed execution of legimate agent work (too many agents)
  - Agent PR merge issues and repeated work (repo-claiming subsystem doesn't work; multiple agents for alarms)

Therefore, we want to make sure we get agent scheudling right.

Basing scheduling decisions on a database means that we can load many scenarios into different test databases and see exactly what scheduling and spawn-context decisions the Conductor would make under many situations.

For example, what scheduling decisions will be made if 100 alarms goes off at once in a 40 minute period and if the system gets sent 10 tickets per second? Will the conductor allocate agents to the correct repositories, will it choose to solve tickets instead of reacting to the incident, will it encounter an obscure logic error and not schedule anything at all, will it spawn agents that are at risk of encountering merge issues?

To reiterate, these are all questions that can be answered when the correct test data is written, because the scheduler mostly looks at its internal database to schedule agents *and not* ephemeral, in-memory data-structures.

Notably, one could use old, existing system data to test scheduling in addition to test data generated by scripts.

**This being said, current scheduling logic is relatively simple, and if the scheduler didn't rely on a database it could absolutely still be tested**. But scheduling based on a database makes testing easier, which is important in case more complex scheduling behavior were needed. For example, a production scheduler may need to grow a subsystem to help agents target which multiple aws accounts they need to work on, or ensure certain agents have some aws permissions while others don't.


> ### Note: Incident Scheduling vs Ticket Scheduling in Early Versions
> The above penalties/potential complexity wouldn't apply if the conductor only solved tickets instead of also reacting to alarms.
>
> For this reason, I'm interested in getting a rock solid base program with well-tested subsystems (e.g git/platform permissions, mutli-AWS account complexity sorted-out, repo-claiming, etc.) *before* trying to implement potentially complex incident-based scheduling that may rely on OTel, CloudWatch, and other data to make decisions.
>
> In short, the v1 production Conductor would only respond to tickets. This would allow for time to iron-out the system's fundamentals while it still has predictable ticket-only scheduling and the stakes/penalties are generally lower.


# Deployment Process

It's inevitable that will we need to update the conductor software while it's deployed.

Of course, we can't kill the server process while it has active agents, so we implement a simple server-draining system.

The deployment pipeline must create two garuantees:
1. After the pipeline activations, the conductor must stop accepting new jobs.
2. The conductor does not shutdown until the agents it is managing are finished with their work.

Here's roughly how we accomplish this:

The conductor runs as a Docker container on an EC2 instance. When I want to deploy a new version, the new conductor image is pushed to ECR, and the EC2 instance pulls that image.

The slightly careful part is shutdown. The conductor may have active workers running when a deploy starts. I don't want to kill the conductor while workers are still connected to it, because the workers need the conductor for gRPC file transfer and status messages.

So the deploy process asks the old conductor to shut down safely:

- The deploy script writes a shutdown request file on the EC2 host.
- The conductor sees that file and stops polling SQS for new work.
- The conductor waits for active workers to finish.
- When there are no active workers left, the conductor writes a "ready for shutdown" file.
- The deploy script waits for that file before replacing the container.

After that, Docker starts the new conductor container.

SQS also plays a big role in this process. SQS Queues are inherently durable, meaning that we can safely just let it accumulate messages while the conductor is restarting. When the conductor starts up again, it just reads the SQS queue and gets back to work!

# Cleanly sharing protos and managing agents concurrently with gRPC

The conductor and workers need to talk to each other after a worker starts.

The worker needs to say things like:

- "I started."
- "Here is my worker id."
- "Please send me my task files."
- "I am uploading my final files."
- "I finished safely."

This is what gRPC is doing in the project.

The conductor runs a gRPC server. Each worker is a gRPC client. When the conductor spawns a worker, it gives the worker two important environment variables:

- the worker id
- the conductor gRPC address

The worker uses those values to connect back to the conductor. This is useful because the workers are temporary Fargate tasks. They come and go, but the conductor is the stable process they all call back into.

The proto file is the shared contract between the conductor and the worker. Instead of hand-writing JSON shapes in two places, both programs generate Go code from the same `.proto` file. That makes the messages a lot less ambiguous.

For example, the proto defines the messages for:

- worker identity
- worker handshake
- requesting work files
- uploading files
- shutdown
- codex errors

This is nice because the conductor and worker can be separate Go programs while still sharing one exact API definition.

The concurrency part is also important. Multiple workers may be running at the same time. Each worker can connect to the conductor and call the same gRPC methods.

The conductor uses the worker id to keep those messages separate. If worker A asks for files, it should get worker A's task files. If worker B uploads results, those results should be stored under worker B's run directory.

So the rough shape is:

- main spawns a worker and records its worker id
- the worker starts and handshakes with that same id
- the conductor checks that the worker id is known
- the worker requests files
- the conductor sends the files prepared for that worker
- later, the worker uploads results
- the conductor stores those results under that worker's directory
