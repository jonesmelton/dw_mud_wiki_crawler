defmodule DwWikiScraper.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do

    children = [
      DwWikiScraper.SQlitePipeline.Repo
    ]

    opts = [strategy: :one_for_one, name: DwWikiScraper.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
