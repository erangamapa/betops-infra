terraform {
  backend "gcs" {
    bucket = "oddsmith-tfstate-placeholder"
    prefix = "betops-infra"
  }
}
