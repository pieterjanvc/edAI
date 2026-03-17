library(httr2)


base_url <- "https://archive-api.open-meteo.com/v1/"
endpoint <- "archive"

result <- request(base_url) |>
  req_url_path_append(endpoint) |>
  req_url_query(
    latitude = 42.33746763,
    longitude = -71.10549472,
    start_date = "2020-01-01",
    end_date = "2020-01-01",
    daily = "weather_code,temperature_2m_mean,precipitation_sum,daylight_duration,sunshine_duration",
    timezone = "America/New_York"
  ) |>
  req_perform() |>
  resp_body_json()

result$daily
