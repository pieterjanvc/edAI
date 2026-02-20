library(ellmer)

edAI_init()


chat <- chat_azure_openai(
  model = "gpt-5-mini",
  system_prompt = "Be terse"
)

test <- chat$chat("what is the month now")

# chat$register_tool(openai_tool_web_search())

# Define a regular function to use as a tool
lucky_numbers <- function(n = 3) {
  if (n < 1) {
    return("You must request at least 1 number")
  }
  set.seed(Sys.Date())
  sample(1:100, n)
}

# Create the tool
lucky_numbers <- tool(
  lucky_numbers,
  name = "lucky_numbers",
  description = "Returns a list of n lucky numbers (changes daily). Defaults to 3",
  #https://ellmer.tidyverse.org/articles/tool-calling.html#tool-inputs-and-outputs
  arguments = list(
    n = type_integer("The number of lucky numbers to return")
  )
)

# Register the tool
chat$register_tool(lucky_numbers)

chat$chat("Can I have 0 lucky numbers?")

chat$chat("2")

token_usage()
