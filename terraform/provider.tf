provider "aws" {
  shared_credentials_file = "$HOME/.aws/credentials"
  profile                 = "default"
  region                  = "${var.region}"
  version                 = "~> 1.30"
}

provider "template" {
  version = "~> 1.0"
  alias   = "default"
}
