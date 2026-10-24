terraform {
  required_version = ">= 1.11.0, < 2.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 6.70.0"
    }
  }
  backend "s3" {
    # Create this bucket separately, then replace the placeholder before deployment.
    bucket       = "REPLACE-WITH-EXISTING-STATE-BUCKET"
    key          = "nginx/production/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}
