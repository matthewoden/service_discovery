# ServiceDiscovery

A very light wrapper around Phoenix.Pubsub, to create an eventually consistent service discovery application, and load balancing. 


## Background
I rewatched Chris McCord's 2016 Elixir talk about how creating Phoenix Presence also solved service discovery, but I didn't see any examples out there of how exactly that would work. So I wrote my own.

_(Turns out, there aren't examples because it's crazy-simple)_

In addition, I threw in a module that allows for a hosts file to be built as part of build (say, for an auto-scaling group in AWS), and automatically connect to any existing cluster. 

_(again, this is really just a wrapper around an existing feature.)_

## Usage

* 'ServiceDiscovery.Network` finds and connects to existing elixir/erlang servers on startup.
* `ServiceDiscovery.Tracker` registers the service to the cluster upon arrival, allowing it to immediately be used by other servers.


Examples usage project to come shortly. Docs available with `mix docs`.

**Note:** this project does assume you have a `.host.erlang` dotfile on your local machine.

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

and watch the magic happen. At this point, you can start start connecting and disconnecting, updating and tracking. Data will replicate over the nodes. Active updates like Tracker.join and Tracker.update register pretty much immediately, but netsplits and node disconnections take a few seconds to kick in. 
