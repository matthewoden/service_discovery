defmodule ServiceDiscovery do
  @moduledoc """
  Documentation for ServiceDiscovery.
  """
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(Phoenix.PubSub.PG2, [ServiceDiscovery.PubSub, []]),
      worker(ServiceDiscovery.Tracker, [[name: ServiceDiscovery.Tracker,
                                         pubsub_server: ServiceDiscovery.PubSub]])
    ]

    opts = [strategy: :one_for_one, name: ServiceDiscovery.Supervisor]

    ServiceDiscovery.Network.discover()
    Supervisor.start_link(children, opts)
  end

end
