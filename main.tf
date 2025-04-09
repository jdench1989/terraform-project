terraform {
  backend "s3" {
    bucket = "jackdench-terraform-state-bucket" # Not managed as a tf resource. Make changes manually
    key    = "tfstate"
    region = "eu-west-2"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "eu-west-2"
}
