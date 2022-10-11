terraform {
  required_providers {
    steampipecloud = {
      source = "turbot/steampipecloud"
    }
  }
}

resource "steampipecloud_workspace_mod" "hypothesis_dashboards" {
  organization = "acme" 
  workspace_handle = "jon"
  path = "github.com/judell/hypothesis-dashboards"
  constraint = "v0.1"
}
