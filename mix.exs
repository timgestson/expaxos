Code.append_path "deps/relex/ebin"

defmodule Paxos.Mixfile do
  use Mix.Project

  if Code.ensure_loaded?(Relex.Release) do
    defmodule Release do
      use Relex.Release

      def name, do: "Paxos"
      def version, do: Mix.project[:version]
      def applications, do: [:paxos]
      def lib_dirs, do: ["deps"]
    end
  end

  def project do
    [ app: :paxos,
      version: "0.0.1",
      elixir: "~> 0.10.1",
      deps: deps ]
  end

  # Configuration for the OTP application
  def application do
    []
  end

  # Returns the list of dependencies in the format:
  # { :foobar, "0.1", git: "https://github.com/elixir-lang/foobar.git" }
  defp deps do
    [{:relex, github: "yrashk/relex"}]
  end
end
