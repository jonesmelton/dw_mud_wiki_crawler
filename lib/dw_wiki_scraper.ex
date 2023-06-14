defmodule WikiScraper do
  @moduledoc ~S"""
  # Extracts the text data from the wiki page via the `/w/api.php` endpoint.

  ## Extracted data
  ```
  title: plaintext page title eg "Yellow stone ring"
  html: raw html as presented to the browser
  wikitext: the "wikicode" wikimedia markup
  text: human-readable text extracted by `Floki.text/1`
  ```

  ## Links
  The api returns a collection of internal links to other wiki pages.
  Each link has a `ns` field but I don't fully understand its meaning.
  All `ns: 0` pages are "normal" article pages, and things like talk and
  category pages have other values.

  Ideally we'd only keep the full article pages and not categories etc.
  Initially I only followed `ns: 0` pages, but some articles are only
  referenced from category and list pages, so it missed a lot.

  There may not be a way to determine ahead of time which articles should
  be saved, and it will have to be parsed out and decided from the response.

  External links are not followed.
  talk
  """
  defp page_url(page) do
    query = %{
      page: page,
      action: "parse",
      format: "json",
      prop: "text|wikitext|links"
    }

    url = %URI{
      scheme: "https",
      host: "dwwiki.mooo.com",
      path: "/w/api.php",
      query: URI.encode_query(query)
    }

    URI.to_string(url)
  end

  defp extract(payload) do
    {:ok, %{parse: parse}} = Jason.decode(payload.body, keys: :atoms)

    %{
      links: linkdata,
      text: %{*: html},
      wikitext: %{*: wikitext},
      title: title
    } = parse

    data = %{
      title: title,
      pages: linkdata |> Enum.map(fn ld -> ld.* end),
      html: html,
      wikitext: wikitext
    }
    data
  end

  use Crawly.Spider

  @impl Crawly.Spider
  def base_url, do: "https://dwwiki.mooo.com/"

  @impl Crawly.Spider
  @doc """
  Callback for pre-crawling setup. Initializes repo and runs migrations.
  """
  def init do
    alias DwWikiScraper.SQlitePipeline.Repo
    Ecto.Migrator.run(Repo, [{0, DwWikiScraper.SQlitePipeline.Migrate}], :up, all: true)
    [start_urls: [page_url("Main Page")]]
  end

  @impl Crawly.Spider
  @doc """
  Handles a single response, returning the item to be saved,
  and the next links to be followed.
  """
  def parse_item(response) do
    results = extract(response)
    %{
      title: title,
      html: html,
      wikitext: wikitext
    } = results
    extracted_items = [%{
                          title: title,
                          html: html,
                          wikitext: wikitext,
                          text: Floki.text(html)
                       }]
    next_pages = Enum.map(results.pages, fn page -> page_url(page) end)

    next_requests = Crawly.Utils.requests_from_urls(next_pages)
    %Crawly.ParsedItem{items: extracted_items, requests: next_requests}
  end
end
