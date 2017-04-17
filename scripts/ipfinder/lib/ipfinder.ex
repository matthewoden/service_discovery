defmodule Ipfinder do

  @moduledoc """
  Documentation for Ipfinder.
  """


  @doc """
  We use System.cmd to run a shell script that pings the network
  broadcast ip, and then calls the arp cache for hosts in our current subnet.
  """
  def main(args \\ []) do
    args |> parse_args |> process
  end

  @defaults [count: 1, broadcast: "192.168.1.255", help: false,
             out: "~/.hosts.erlang",
             ignore: ["192.168.1.0","192.168.1.255","239.255.255.250",
                      "224.0.0.251","255.255.255.255"] |> Enum.join(",")
            ]

  def parse_args(args) do
    switches = [count: :integer, broadcast: :string, help: :boolean,
                ignore: :string, nodes: :string, out: :string]

    {userOptions, nodes, _} =
      OptionParser.parse(args, switches: switches)

    options = Keyword.merge(@defaults, userOptions)

    try do
      %{ broadcast: options[:broadcast],
         count: options[:count],
         nodes: nodes,
         ignore: String.split(options[:ignore], ",", trim: true),
         output: options[:out],
         help: options[:help]
       }
    rescue
      _ -> %{help: true}
    end

  end

  def process(%{help: true}) do
    IO.puts display_help()
  end

  def process(options) do
    shell(options)
  end

  def shell(options) do
    System.cmd("ping", [options.broadcast, "-c #{options.count}"])

    case  System.cmd("arp", ["-an"]) do
      {_, exit} when exit > 0 ->
        IO.puts("Failed to get IP addressed on local network")

      {output, _exit} ->
        IO.puts "Creating hostfile for current subnet."

        output
        |> String.split("\n", trim: true)
        |> Stream.map(&parse_line(&1))
        |> Stream.reject(fn ip_address -> ip_address in options.ignore end)
        |> Stream.map(&create_line_entries(&1, options.nodes))
        |> Stream.into(File.stream!(options.output))
        |> Stream.run()

        IO.puts "Hostfile created."
    end
  end

  def display_help do
    """
    ipfinder:
    Creates a .hosts.erlang dotfile. Using a supplied broadcast ip address, it pings the current subnet, and builds the file from a space-delimited list of names.

    Example:
    $ ipfinder --count 2 --broadcast 192.168.1.255 --ignore 192.168.1.255,255.255.255.255 app queue

    The above would ping the broadcast ip of 192.169.1.255, filtering out the (supplied) broadcast and broadcast host results. If only one address is found, say, (192.168.0.1), then the command would output a file in the current user's home directory. The contents would be the following:

    'app@192.168.0.1'.
    'queue@192.168.0.1'.

    This file is could then be used with modules like :net_adm.world to connect to erlang and elixir apps that are using a resolved name (--name) set to app@192.168.0.1 or queue@192.168.0.1

    ------------------------------------------------

    --count     - the number of seconds to ping the network.
                  Defaults to #{@defaults[:count]}

    --broadcast - the broadcast ip of the current network.
                  Defaults to #{@defaults[:broadcast]}

    --out       - the output directory for the .host.erlang file.
                  Defaults to #{@defaults[:out]}

    --ignore    - comma delimited list of ip addresses to ignore on this subnet.

    --help      - displays this screen.

    """
  end


  #simple grab of paren contents, expecting format of
  # ? (255.255.255.255) at ff:ff:ff:ff:ff:ff on en0 ifscope [ethernet]
  # where the hostname "?" can be defined, or not.

  def parse_line(line) do
    do_parse_line(line, "", false)
  end

  #invalid line
  def do_parse_line(<<>>, _acc, _in_parens) do
    nil
  end

  #finish capture
  def do_parse_line(<< ")", _rest::binary >>, acc, _in_parens) do
    acc
  end

  #start capture
  def do_parse_line(<< "(", rest::binary>>, acc, false) do
    do_parse_line(rest, acc, true)
  end

  # skip until relevant
  def do_parse_line(<< _x::utf8, rest::binary>>, acc, false) do
    do_parse_line(rest, acc, false)
  end

  #capture
  def do_parse_line(<<c::utf8, rest::binary>>, acc, true) do
    acc = acc <> << c >>
    do_parse_line(rest, acc, true)
  end

  def create_line_entries(ip_address, node_names) do
    IO.puts("Creating entries for #{Enum.join(node_names, ", ")} at #{ip_address}")

    node_names
    |> Stream.map(fn (name) -> "'#{name}@#{ip_address}'. \n" end)
    |> Enum.join("")
  end

end
