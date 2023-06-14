defmodule DwWikiScraper.SQlitePipeline do
  @moduledoc """
  Top level module for saving wiki pages to sqlite.

  Contains ecto repo config, migration, schema, and changeset for
  `page` items.

  Pages are unique by title, will update entries if title
  alread exists. Migration is run manually in `WikiScraper.init/0`
  without error handling.
  """

  defmodule Repo do
    use Ecto.Repo,
      otp_app: :DwWikiScraper,
      adapter: Ecto.Adapters.SQLite3

    @impl true
    def init(_context, config) do
      {:ok, Keyword.merge(config, database: "wiki_pages.sqlite")}
    end
  end

  defmodule Migrate do
    use Ecto.Migration

    def change do
      create_if_not_exists table("pages") do
        add(:title, :string)
        add(:text, :string)
        add(:wikitext, :string)
        add(:html, :string)

        timestamps()
      end

      create_if_not_exists(unique_index("pages", :title))
    end
  end

  defmodule Page do
    use Ecto.Schema

    schema "pages" do
      field(:title, :string)
      field(:text, :string)
      field(:wikitext, :string)
      field(:html, :string)

      timestamps()
    end

    @doc """
    This won't error if the page exists but it might not
    actually update it either. {: .info}

    I didn't verify and I'm not very experienced with ecto.
    """
    def upsert(attrs) do
      import Ecto.Changeset

        %Page{}
        |> cast(attrs, [:title, :text, :wikitext, :html])
        |> validate_required(:title)
        |> Repo.insert(
          on_conflict: [set: [text: attrs.text, wikitext: attrs.wikitext, html: attrs.html]],
          conflict_target: :title
        )
    end
  end

  @behaviour Crawly.Pipeline

  @impl Crawly.Pipeline
  def run(item, state, _opts \\ []) do
    DwWikiScraper.SQlitePipeline.Page.upsert(item)

    {item, state}
  end
end
