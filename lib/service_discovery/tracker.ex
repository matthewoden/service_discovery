defmodule ServiceDiscovery.Tracker do
  @behaviour Phoenix.Tracker


  @moduledoc """
  A very basic wrapper around Phoenix Tracker. Adds a little bit of sugar for
  naming nodes, handling pids and metadata, and basic load balancing.


  Honestly, you should probably just read up on Phoenix.PubSub for a better understanding of what's going on.
  """


  alias Phoenix.Tracker

  def start_link(opts) do
      opts = Keyword.merge([name: __MODULE__], opts)
      GenServer.start_link(Tracker, [__MODULE__, opts, opts], name: __MODULE__)
  end


  def init(opts) do
    server = Keyword.fetch!(opts, :pubsub_server)
    {:ok, %{pubsub_server: server, node_name: Phoenix.PubSub.node_name(server)}}
  end


  def handle_diff(diff, state) do

    for {topic, {joins, leaves}} <- diff do
      for {key, meta} <- joins do
        msg = {:join, key, meta}

        Phoenix.PubSub.direct_broadcast!(state.node_name, state.pubsub_server, topic, msg)
      end

      for {key, meta} <- leaves do
        msg = {:leave, key, meta}

        Phoenix.PubSub.direct_broadcast!(state.node_name, state.pubsub_server, topic, msg)
      end
    end

    {:ok, state}
  end

  @doc """
  Tracks a pid for a given service.

  * `pid` - The pid of the service being tracked
  * `service_name` - The service name to update for this tracker
  * `meta` - a map or a function that returns a map.

  """


  @spec track(pid :: pid, service_name :: String.t, meta :: Map.t) :: {:ok, ref :: binary} | {:error, reason :: term}
  def track(pid, service_name, meta) do
    topic = service_topic(service_name)
    id =  service_id(service_name)
    meta = Map.merge(meta, %{node: node(), pid: pid})

    Tracker.track(__MODULE__, pid, topic, id, meta)
  end

  @doc """
  Updates metadata about a given service.

  * `pid` - The pid of the service being tracked
  * `service_name` - The service name to update for this tracker
  * `meta` - a map or a function that returns a map.

  """


  @spec update(pid :: pid, service_name :: String.t, meta :: term) :: :ok
  def update(pid, service_name, meta) do
    topic = service_topic(service_name)
    id =  service_id(service_name)

    Tracker.update(__MODULE__, pid, topic, id, meta)
  end

  @doc """
  Stops tracking a given service for a pid.

  * `pid` - The pid of the service to untrack
  * `service_name` - The service name to untrack for this tracker

  """

  @spec untrack(pid :: pid) :: :ok
  def untrack(pid) do
    Tracker.untrack(__MODULE__, pid)
  end

  @spec untrack(pid :: pid, service_name:: String.t) :: :ok
  def untrack(pid, service_name) do
    topic = service_topic(service_name)
    id =  service_id(service_name)

    Tracker.untrack(__MODULE__, pid, topic, id)
  end

  @doc """
  Lists out metadata for a given service. By default returns a map with the pid, and node.

  * `service_name` - The service name to list
  """

  @spec list(service_name :: String.t) :: list(Map.t)
  def list(service_name) do
    topic = service_topic(service_name)

    Tracker.list(__MODULE__, topic)
  end

  @doc """
  Takes the server list, and plucks the metadata. Then runs `Enum.sort` on the results, with the provided function. You could sort based on

  * `service_name` - The service name to pick from.

  """

  @spec select(service_name :: String.t, select_fun :: term) :: pid | nil
  def select(service_name, select_fun) do
    service_name
    |> list()
    |> Stream.map(fn {_id, meta} -> meta end)
    |> Enum.sort(select_fun)
    |> Enum.at(0)
  end


  defp service_topic(service_name) do
    "service:#{service_name}"
  end

  defp service_id(service_name) do
    "service:#{service_name}:#{node()}"
  end


end
