defmodule SharedSettings.MixProject do
  use Mix.Project

  def project do
    [
      app: :shared_settings,
      version: "0.2.1",
      elixir: "~> 1.8",
      description: description(),
      package: package(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {SharedSettings.Application, []},
      extra_applications: [:logger, :redix, :crypto]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.22", only: :dev, runtime: false},
      {:redix, "~> 0.9", optional: true},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:mock, "~> 0.3.0", only: :test}
    ]
  end

  defp description() do
    "Manage and encrypt settings for your Elixir app with optional support for Ruby"
  end

  defp package() do
    [
      licenses: ["MIT"],
      links: %{repo: "https://github.com/kieraneglin/shared-settings-ex"}
    ]
  end
end
