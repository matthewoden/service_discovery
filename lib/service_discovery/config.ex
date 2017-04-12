defmodule ServiceDiscovery.Config do

  def get_host_file_path do
    Application.get_env(:service_discovery, :hosts_file, '~/.hosts.erlang')
  end

end
