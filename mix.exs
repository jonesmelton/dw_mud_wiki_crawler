defmodule DwWikiScraper.MixProject do
  use Mix.Project

  def project do
    [
      app: :dw_wiki_scraper,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: [
        main: "WikiScraper",
        extras: ["readme.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {DwWikiScraper.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:crawly, "~> 0.15.0"},
      {:floki, "~> 0.34.3"},
      {:jason, "~> 1.4.0"},
      {:ecto_sql, "~> 3.10.1"},
      {:ecto_sqlite3, "~> 0.10.3"},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
    ]
  end
end
