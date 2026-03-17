


```r
name <- "edAI_llm_rag"
usethis::use_rmarkdown_template(
  template_name = name,
  template_dir = name,
  template_description = "Using the httr2 library to fetch web data via an API"
)

usethis::use_vignette(name)
```

devtools::build_vignettes()

| Cosine Similarity | Cosine Distance | Meaning                        |
| ----------------- | --------------- | ------------------------------ |
| 1.0               | 0.0             | Identical vectors (best match) |
| 0.8               | 0.2             | Very similar                   |
| 0.5               | 0.5             | Moderately similar             |
| 0.0               | 1.0             | Unrelated                      |
