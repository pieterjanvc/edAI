#' Interactive app to set Azure credentials
#'
#' @import shiny bslib
#'
#' @returns Starts a Shiny app that returns username and key
#'
cred_app <- function() {
  runApp(shinyApp(
    ui <- page_fluid(
      titlePanel("Azure OpenAI Credentials"),
      textInput("username", "Pick a username"),
      tags$i(
        "The username can be anything, but is used to track your token usage"
      ),
      hr(),
      textInput("key", "Provide an Azure API Key"),
      actionButton("submit", "Submit")
    ),

    server <- function(input, output, session) {
      observe({
        stopApp(list(username = input$username, key = input$key))
      }) |>
        bindEvent(input$submit)
    }
  ))
}

#' Validate Azure API key
#'
#' @param key API / Token to check
#' @param error_on_fail (Default = F) Generate error when failed authentication
#'
#' @import httr2
#' @importFrom dplyr case_when
#'
#' @returns List with checks
#'
cred_check <- function(key, error_on_fail = F) {
  status_code <- request(
    "https://azure-ai.hms.edu/openai/"
  ) |>
    req_headers(
      "Content-Type" = "application/json",
      "api-key" = key
    ) |>
    req_error(is_error = \(resp) FALSE) |>
    req_perform() |>
    resp_status()

  msg <- case_when(
    status_code == 401 ~ "The provided key is not valid (anymore)",
    status_code == 404 ~ "Successful authentication",
    TRUE ~ "There is an issue with the Azure server. Try again later"
  )

  if (error_on_fail & status_code != 404) {
    stop(msg)
  }

  return(invisible(list(
    success = status_code == 404,
    status_code = status_code,
    msg = msg
  )))
}

#' Setting up the Azure API info and storing it in the keyring
#'
#' @param force_overwrite (Default  = FALSE) Force reset of the parameters
#' @param username (Optional if interactive) Username can be anything.
#' It's used to distinguish between users who share an API key
#' @param key (Optional if interactive) Azure API key
#'
#' @import keyring
#' @importFrom jsonlite toJSON
#'
#' @returns Message
#' @export
#'
edAI_setup <- function(
  force_overwrite = F,
  username,
  key
) {
  if (!force_overwrite & nrow(key_list("edAI_creds")) == 1) {
    message(
      "Everything is set up already. You can remove this function from your code ",
      "or set `force_overwrite = T` if you need to update your key."
    )
    return(invisible())
  }

  if (interactive()) {
    info <- cred_app()
  } else {
    info <- list(username = usename, key = key)
  }

  cred_check(info$key, error_on_fail = T)

  key_set_with_value("edAI_creds", password = toJSON(info))

  message("Everything was set up and stored for future use")
}

#' Setup environment for Azure use and token tracking
#'
#' When the session ends, token usage info will be uploaded to a Google Drive
#'
#' @import httr2 keyring
#' @importFrom jsonlite fromJSON
#'
#' @returns Message
#' @export
#'
edAI_init <- function() {
  if (nrow(key_list("edAI_creds")) != 1) {
    stop("Credentials not found, please run edAI_setup()")
  }

  info <- key_get("edAI_creds") |> fromJSON()

  if (Sys.getenv("AZURE_OPENAI_API_KEY") == info$key) {
    message("Everything has been set up already")
    return(invisible())
  }

  check <- cred_check(info$key)

  if (!check$success) {
    stop(
      "You no longer have access to Azure with the credentials provided ",
      "when you installed the edAI package and should stop using the ",
      "edAI_setup() and edAI_init() functions, but can continue using other ",
      "functions and the `ellmer` library if you get new credentials. ",
      "Check the ellmer documentation for more info at ",
      " https://ellmer.tidyverse.org/reference/chat_azure_openai.html?q=api%20key#authentication"
    )
  }

  Sys.setenv("AZURE_OPENAI_API_KEY" = info$key)
  Sys.setenv("AZURE_OPENAI_ENDPOINT" = "https://azure-ai.hms.edu")

  # Save the token info when ending the session
  suppressMessages(withr::defer(
    {
      # Only run when there has been token usage
      if (nrow(token_usage()) > 0) {
        filename <- paste0(
          info$username,
          "_",
          as.integer(Sys.time()),
          ".csv"
        )
        write.csv(token_usage(), "token_usage.csv")
        # Upload the session token usage to a Google Drive
        request(
          "https://script.google.com/macros/s/AKfycbzrmI6esfRWYD20Kkz7N2EoyJUQZNpxgStTeKLWO7CURqo52XYsqaMAzrFCBVcOaAtYQQ/exec"
        ) |>
          req_method("POST") |>
          req_url_query(filename = filename, mimeType = "text/plain") |>
          req_body_file("token_usage.csv") |>
          req_error(is_error = \(resp) FALSE) |>
          req_perform()
      }
    },
    envir = parent.frame(),
    priority = "last"
  ))

  message("You are ready to start using LLMs!")
}
