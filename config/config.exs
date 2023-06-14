import Config

mud_char_name = "??"

config :crawly,
  closespider_timeout: 10,
  concurrent_requests_per_domain: 8,
  closespider_itemcount: :disabled,

  middlewares: [
    Crawly.Middlewares.DomainFilter,
    Crawly.Middlewares.UniqueRequest,
    {Crawly.Middlewares.UserAgent, user_agents: ["Crawly Bot / player: #{mud_char_name}"]}
  ],
  pipelines: [
    # An item is expected to have all fields defined in the fields list
    {Crawly.Pipelines.Validate, fields: [:title, :text, :html, :wikitext]},

    # Use the following field as an item uniq identifier (pipeline) drops
    # items with the same urls
    {Crawly.Pipelines.DuplicatesFilter, item_id: :title},
    DwWikiScraper.SQlitePipeline,
    Crawly.Pipelines.JSONEncoder,
    {Crawly.Pipelines.WriteToFile, extension: "jl", folder: "/tmp"}
  ]
