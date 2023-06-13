defmodule WikiScraper do
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
      pages: linkdata |> Enum.filter(fn ld -> ld.ns == 0 end) |> Enum.map(fn ld -> ld.* end),
      html: html,
      wikitext: wikitext
    }
    data
  end

  use Crawly.Spider

  @impl Crawly.Spider
  def base_url(), do: "https://dwwiki.mooo.com/"

  @impl Crawly.Spider
  def init() do
    [start_urls: [page_url("Main Page")]]
  end

  @impl Crawly.Spider
  @doc """
     Extract items and requests to follow from the given response
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
    # Extract requests to follow from the response. Don't forget that you should
    # supply request objects here. Usually it's done via
    #
    # urls = document |> Floki.find(".pagination a") |> Floki.attribute("href")
    # Don't forget that you need absolute urls
    # requests = Crawly.Utils.requests_from_urls(urls)

    next_requests = Crawly.Utils.requests_from_urls(next_pages)
    %Crawly.ParsedItem{items: extracted_items, requests: next_requests}
  end
end
