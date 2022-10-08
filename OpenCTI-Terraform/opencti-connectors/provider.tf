provider "aws" {
  region = "us-east-1" # Update to current region
  default_tags {
    tags = var.tags
  }
}