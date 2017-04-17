# ServiceDiscovery

Scripts and experiments around dynamic/decentralized Service Discovery, and self-healing clusters.

## Contents:

**Modules**
* Tracker - Light wrapper around phoenix pubsub. 
* Network - Uses hostfile to automatically connects to node on the local machine, local subnet, or any resolved name

Tracker - Using Phoenix.PubSub, services are tracked and announced upon connection. Service tracking is fully decentralized, so no one node's health dictates the health of the cluster. Load balancing is handled by calling services, rather than a single load balancer.

Discovery - Run on startup (or after netsplit), allows the current module to rediscover the cluster.

_TODO: add quick script to Network module to handle renaming of current node in case of update to dynamically assigned address._

**Scripts: LAN Disovery**
* ipfinder - A quick and dirty example of dynamic hostfile generation for a local subnet. Assumes the user can't rely on a hostname alias, or setting static ip addresses.


## Background
Chris McCord gave two talks in 2016, each mentioning how Presence (Phoenix.PubSub) also solved service discovery. I didn't know how Presence worked at the time, so I implemented the examples he mentioned. From there I just started jotting down experiments in network management.


## Usage

The usage example below is for "distributed" use on a single machine. Multiple-machine example to come.


* 'ServiceDiscovery.Network` finds and connects to existing elixir/erlang servers on startup.
* `ServiceDiscovery.Tracker` registers the service to the cluster upon arrival, allowing it to immediately be used by other servers.


Examples usage project to come shortly. Docs available with `mix docs`.


## Giving it a spin

Assuming `~/.host.erlang` is on your machine with the following contents:

``` erlang
'node1@127.0.0.1'.
'node2@127.0.0.1'.
```

You should be able to run the following commands:

``` bash
# one terminal
>iex  --name node1@127.0.0.1 --cookie example  -S mix
```

``` bash
# a different terminal
>iex  --name node2@127.0.0.1 --cookie example  -S mix
```

...and see that node1 was the first to the cluster, and node2 discovered and joined node1

Then, on each iex instance, you can throw the following: 

``` erlang
iex> ServiceDiscovery.Tracker.track(self(), "test", %{})
```

At this point, you should start experimenting. Connect and disconnect nodes. Send tracker updates. Notice how the PubSub's CRDT model keeps announcements in sync, but not sudden disconnects. Those stick around, until the heartbeat.

Notice also that when a new node joins the cluster, it handles the cleanup of bad PIDs. This also shows how netsplits get handled - when services leave and arrive, even momentarily, they clean themselves up.

