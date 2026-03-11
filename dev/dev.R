library(ellmer)
library(ragnar)
library(jsonlite)
library(duckdb)


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


doc <- read_as_markdown(
  "https://writings.stephenwolfram.com/2023/02/what-is-chatgpt-doing-and-why-does-it-work/"
)

chunks <- markdown_chunk(doc)

ragnar_store_insert(store, chunks)

ragnar_store_build_index(store)

test <- ragnar_retrieve_vss(
  store,
  "What happens when we 'train' a neural network?"
)

test$text
