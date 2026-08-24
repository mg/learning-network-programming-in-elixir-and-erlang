defmodule Chat.MixProject do
  use Mix.Project

  def project do
    [
      app: :chat,
      version: "0.1.0",
      elixir: "~> 1.20",
      start_permanent: Mix.env() == :prod,
      build_path: "_build/#{application_variant()}",
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: application_mod()
    ]
  end

  defp application_mod do
    case application_variant() do
      "pool" -> {Chat.AcceptorPool.Application, []}
      "thousand_island" -> {Chat.ThousandIsland.Application, []}
      "default" -> {Chat.Application, []}
    end
  end

  defp application_variant do
    cond do
      System.get_env("POOL") -> "pool"
      System.get_env("THOUSAND_ISLAND") -> "thousand_island"
      true -> "default"
    end
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:thousand_island, "~> 1.3"}
    ]
  end
end
