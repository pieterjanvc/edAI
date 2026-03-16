#' Fetch plain text content from a Wikipedia page
#'
#' @param url URL of the Wikipedia page to fetch
#'
#' @import httr2
#' @importFrom stringr str_extract
#' @importFrom jsonlite fromJSON
#'
#' @returns A character string containing the plain text extract of the page
#'
edAI_wiki_page <- function(url) {
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

#' Create or connect to a RAG store
#'
#' If a store already exists at `path`, connects to it. Otherwise creates a new
#' store configured to use Azure OpenAI embeddings.
#'
#' @param path File path to the DuckDB-backed RAG store
#' @param model Embedding model name (default: `"text-embedding-3-small"`)
#'
#' @importFrom keyring key_get
#' @importFrom jsonlite fromJSON
#'
#' @returns A `ragnar::RagnarStore` object
#' @export
#'
edAI_rag_store <- function(path, model = "text-embedding-3-small") {
  if (file.exists(path)) {
    return(ragnar_store_connect(path, read_only = F))
  }

  ragnar_store_create(
    path,
    embed = \(x) {
      info <- keyring::key_get("edAI_creds") |> jsonlite::fromJSON()
      embed_azure_openai(
        x,
        endpoint = "https://azure-ai.hms.edu",
        model = "text-embedding-3-small",
        api_key = info$key
      )
    }
  )
}

#' Insert content into a RAG store
#'
#' Chunks and embeds `new_data`, then upserts it into the store and rebuilds
#' the vector index. Accepts either a file path (read via
#' [ragnar::read_as_markdown()]) or a raw markdown string (requires `origin`).
#'
#' @param store A `ragnar::RagnarStore` object or file path to one
#' @param new_data File path to a document or a raw markdown string
#' @param origin Source label for the content. Required when `new_data` is a
#'   raw string; optional when it is a file path (defaults to the path)
#'
#' @returns The store, invisibly
#' @export
#'
edAI_rag_insert <- function(store, new_data, origin) {
  if (!inherits(store, "ragnar::RagnarStore")) {
    store <- ragnar_store_connect(store, read_only = FALSE)
  }

  if (file.exists(new_data)) {
    origin <- origin %||% new_data
    new_data <- read_as_markdown(new_data)
  } else {
    if (missing(origin)) {
      stop(
        "Must provide an `origin` when `new_data` is a raw string, not a file path."
      )
    }

    new_data <- MarkdownDocument(new_data, origin = origin)
  }

  chunks <- markdown_chunk(new_data)
  chunks$hash <- rlang::hash(new_data)
  ragnar_store_update(store, chunks)
  ragnar_store_build_index(store)

  invisible(store)
}
