provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {
    bucket = "tfstate-${var.env}-${var.aws_account_id}"
    key    = "vpc/terraform.tfstate"
    region = var.region
  }
}

############# 
# ECR Module 
############# 

module "ecr" {
  source                                    = "../../../tf-modules/aws/ecr" 
  count                                     = length(var.registry_list) 
  name                                      = var.registry_list[count.index] 
  tag_prefix_list                           = ["release"] 
  scan_on_push                              = true 
  image_tag_mutability                      = "IMMUTABLE" 

  # If invalid account such as "123456789012" is specified, then cause error with following message.
  # Invalid parameter at 'PolicyText' failed to satisfy constraint: 'Invalid repository policy provided'
  #
  # So, this example uses a valid account, that is the CloudTrail Service Account.
  # https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-supported-regions.html

  only_pull_accounts       = [data.aws_cloudtrail_service_account.main.id] 
  push_and_pull_accounts   = [data.aws_cloudtrail_service_account.main.id] 
  max_untagged_image_count = 5 
  max_tagged_image_count   = 50 
}

data "aws_cloudtrail_service_account" "main" {} 
