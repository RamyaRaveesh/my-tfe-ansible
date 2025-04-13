terraform {
  backend "s3" {
    bucket         = "ramya-terraform-state-eu-north-1"      # your S3 bucket name
    key            = "jenkins/terraform.tfstate"             # path inside the bucket
    region         = "eu-north-1"
    dynamodb_table = "terraform-locks"                        # lock table you just created
    encrypt        = true
  }
}
