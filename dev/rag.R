# ── 1. Embed the query the same way the store does ────────────────────────────
info <- keyring::key_get("edAI_creds") |> jsonlite::fromJSON()

query <- "Who is snow white?"

query_vec <- embed_azure_openai(
  query,
  endpoint = "https://azure-ai.hms.edu",
  model = "text-embedding-3-large",
  api_key = info$key
)
# query_vec is a matrix: 1 row × 3072 cols (one dimension per float)

# ── 2. Read all stored embeddings directly from DuckDB ────────────────────────
con <- DBI::dbConnect(
  duckdb::duckdb(),
  rag_store,
  read_only = TRUE,
  array = "matrix"
)
chunks_df <- DBI::dbGetQuery(con, "SELECT text, embedding FROM chunks")
DBI::dbDisconnect(con)

# embedding column comes back as a list of numeric vectors
# ── 3. Compute cosine similarity in R ─────────────────────────────────────────
cosine_sim <- function(a, b) sum(a * b) / (sqrt(sum(a^2)) * sqrt(sum(b^2)))

chunks_df$similarity <- apply(
  chunks_df$embedding,
  1,
  \(chunk_vec) cosine_sim(query_vec[1, ], chunk_vec)
)
chunks_df$distance <- 1 - chunks_df$similarity # cosine distance

result <- chunks_df[
  order(-chunks_df$similarity),
  c("text", "similarity", "distance")
]
head(result)

library(ggplot2)

all_vecs <- rbind(chunks_df$embedding)
all_vecs_with_query <- rbind(query_vec[1, ], all_vecs)

pca <- prcomp(all_vecs_with_query, rank. = 2)$x |> as.data.frame()
pca$label <- c("QUERY", rep("chunk", nrow(chunks_df)))
pca$similarity <- c(NA, chunks_df$similarity)

ggplot(pca, aes(PC1, PC2, colour = similarity, label = label)) +
  geom_point() +
  geom_point(data = pca[1, ], colour = "red", size = 4) +
  scale_colour_viridis_c(na.value = "red")


test_store <- edAI_rag_store("dev/test.duckdb")

data <- edAI_wiki_page("https://en.wikipedia.org/wiki/Alagille_syndrome")

edAI_rag_insert("dev/test.duckdb", data, origin = "alagille")

test <- ragnar_retrieve(
  test_store,
  "What are butterfly vertebra"
)

test$text[1] |> cat()
