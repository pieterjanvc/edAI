


```r
name <- "edAI_llm_agent"
usethis::use_rmarkdown_template(
  template_name = name,
  template_dir = name,
  template_description = "Creating simple AI agents"
)

usethis::use_vignette(name)
```

devtools::build_vignettes()
