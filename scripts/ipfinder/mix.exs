defmodule Ipfinder.Mixfile do
  use Mix.Project

  def project do
    [app: :ipfinder,
     version: "0.1.0",
     elixir: "~> 1.4",
     deps: deps(),
     escript: escript()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  def escript do
    [ main_module: Ipfinder ]
  end

  defp deps do
    []
  end
end
