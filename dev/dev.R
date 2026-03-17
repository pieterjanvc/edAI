library(ellmer)
library(ragnar)
library(jsonlite)
library(duckdb)
library(httr2)
library(jsonlite)
library(stringr)

rag_store <- "dev/test_rag_store4.duckdb"

store <- ragnar_store_create(
  rag_store,
  embed = \(x) {
    info <- keyring::key_get("edAI_creds") |> jsonlite::fromJSON()
    embed_azure_openai(
      x,
      endpoint = "https://azure-ai.hms.edu",
      model = "text-embedding-3-large",
      api_key = info$key
    )
  }
)


get_wiki_page <- function(url) {
  # test <- request(url) |> req_method("HEAD") |> req_perform()

  resp <- request("https://en.wikipedia.org/w/api.php") |>
    req_url_query(
      action = "query",
      prop = "extracts",
      titles = str_extract(url, "[^/]+$"),
      format = "json",
      explaintext = TRUE
    ) |>
    req_perform()

  data <- resp |> resp_body_json()

  data$query$pages[[1]]$extract
}

url <- "https://en.wikipedia.org/wiki/Retinitis_pigmentosa"
wiki <- get_wiki_page(url)


doc <- read_as_markdown(wiki)

doc <- read_as_markdown(
  "https://en.wikipedia.org/w/index.php?title=Retinitis_pigmentosa&action=raw"
)
chunks <- markdown_chunk(wiki)

store <- ragnar_store_connect(rag_store, read_only = F)
ragnar_store_insert(store, chunks)

ragnar_store_build_index(store)

test <- ragnar_retrieve_vss(
  store,
  "How is retinitis pigmentosa inherited?"
)

test$text
