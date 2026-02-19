library(ellmer)
library(keyring)
library(httr2)

azure_init()


library(ellmer)
chat <- chat_azure_openai(
  model = "gpt-5-mini",
  system_prompt = "be academic in response"
)
# chat$register_tool(openai_tool_web_search())

# Define a regular function to use as a tool
get_current_time <- function(tz = "UTC") {
  format(Sys.time(), tz = tz, usetz = TRUE)
}

# Create the tool
get_current_time <- tool(
  get_current_time,
  name = "get_current_time",
  description = "Returns the current time.",
  #https://ellmer.tidyverse.org/articles/tool-calling.html#tool-inputs-and-outputs
  arguments = list(
    tz = type_string(
      "Time zone to display the current time in. Defaults to `\"UTC\"`.",
      required = FALSE
    )
  )
)

# Register the tool
chat$register_tool(get_current_time)

chat$chat("what is the month now")

token_usage()

chat$get_tokens()
