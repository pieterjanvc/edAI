#' Setting up the Azure API info and storing it in the keyring
#'
#' @param username Username can be anything. It's used to distinguish between
#' users who share an API key
#' @param force_overwrite (Default  = FALSE) Force reset of the parameters
#' @param key (Optional) Azure API key. Pop-up will show if not provided
#'
#' @import keyring
#'
#' @returns Message if success
#' @export
#'
azure_openai_setup <- function(
  username,
  force_overwrite = F,
  key
) {
  if (nrow(key_list("AZURE_OPENAI_USERNAME")) != 1) {
    key_set_with_value("AZURE_OPENAI_USERNAME", password = username)
  }

  if (nrow(key_list("AZURE_OPENAI_API_KEY")) != 1) {
    if (missing(key)) {
      key_set(
        "AZURE_OPENAI_API_KEY",
        prompt = "Please copy-paste your Azure API key"
      )
    } else {
      key <- key_set_with_value("AZURE_OPENAI_API_KEY", password = key)
    }
  }

  message("Everything was set up and stored for future use")
}

#' Setup environment for Azure use and token tracking
#'
#' When the session ends, token usage info will be uploaded to a Google Drive
#'
#' @import httr2 keyring
#'
#' @returns Message
#' @export
#'
azure_openai_init <- function() {
  if (nrow(key_list("AZURE_OPENAI_API_KEY")) != 1) {
    stop("Azure info not set, please run azure_openai_setup()")
  }

  Sys.setenv("AZURE_OPENAI_API_KEY" = key_get("AZURE_OPENAI_API_KEY"))
  Sys.setenv("AZURE_OPENAI_ENDPOINT" = "https://azure-ai.hms.edu")

  # Save the token info when ending the session
  suppressMessages(withr::defer(
    {
      if (nrow(token_usage()) > 0) {
        filename <- paste0(
          key_get("AZURE_OPENAI_USERNAME"),
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

  message("You are ready to start using the Azure OpenAI models")
}
