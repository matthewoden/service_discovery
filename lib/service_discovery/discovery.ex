defmodule ServiceDiscovery.Network do
  require Logger

  @moduledoc """
  Utilizes erlang's build in functionality around `.host.erlang` file. See details about host.erlang's expected format and the :net_adm module [here](http://erlang.org/doc/man/net_adm.html) (format at the bottom).

  How you construct your hostfile is up to you. This example simply expects you to have generated a list of hosts prior to starting the application.

  If you're on AWS - you can grab the DNS values from an instance with the following snippet.

  ```
  SERVER_CLASS=tag-for-similar-nodes-in-aws
  aws ec2 describe-instances \
  --query 'Reservations[].Instances[].NetworkInterfaces[].PrivateIpAddresses[].PrivateDnsName' \
  --output text \
  --filter Name=tag:Class,Values=${SERVER_CLASS} | sed '$!N;s/\t/\n/' | sed -e "s/\(.*\)/'\1'./" > $OTP_ROOT/.hosts.erlang
  ```
  (this snippet, and inspiration for the code below, taken from [here](https://johnhamelink.com/2016/03/03/elixir-and-ec2).)

  """


  @doc """
  Uses a hostfile to discover and connect to nearby instances. Outputs a list of connected nodes on success, and reports on failure. Implementation uses Node.connect over :net_adm.world, to allow connections to multiple nodes on the same machine.
  """


  @spec discover() :: list(atom)
  def discover do
    host_file = :net_adm.host_file()

    case host_file do
      hosts when is_list(hosts) ->
        Logger.info("Attempting to join cluster")

        :net_adm.host_file()
        |> Stream.filter(fn host -> host != node() end)
        |> Stream.map(&connect(&1))
        |> Enum.filter(&(&1))
        |> display_result

      {:error, reason} ->
        Logger.warn("Couldn't find .host.erlang file - not joining cluster. Details #{inspect reason}")
    end

  end


  defp connect(name) do
    case Node.connect(:"#{name}") do
      true -> name
      _ -> nil
    end
  end

  defp display_result([]) do
    Logger.info("#{node()} is the only node in this cluster.")
    []
  end

  defp display_result(nodes) do
    Logger.info("#{node()} has connected to node(s): #{Enum.join(nodes, ", ")}")
    nodes
  end

end
