


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
