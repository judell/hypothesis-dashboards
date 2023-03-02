
mod "hypothesis" {
  title = "Hypothesis Insights"
}

locals {
host = "https://cloud.steampipe.io/org/acme/workspace/jon/dashboard"
//host = "http://localhost:9194"
}


variable "search_limit" {
  type = number
  default = 2500
}

