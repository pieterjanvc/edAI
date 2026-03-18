library(httr2)


base_url <- "https://api.orphadata.com"
endpoint <- "/rd-phenotypes/hpoids/HP:0004322,HP:0000407,HP:0000639,HP:0001644"

result <- request(base_url) |>
  req_url_path_append(endpoint) |>
  req_perform() |>
  resp_body_json()

result$data$results[[1]]$Disorder
