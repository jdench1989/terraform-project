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

resource "aws_ecr_repository" "task_listing_app_repository" {
  name = "jackdench-task-app-repository"

}

resource "aws_iam_instance_profile" "task_listing_app_ec2_instance_profile" {
  name = "jackdench-task-listing-app-ec2-instance-profile"
  role = aws_iam_role.task_listing_app_ec2_role.name
}

resource "aws_iam_role" "task_listing_app_ec2_role" {
  name = "jackdench-task-listing-app-ec2-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_full_access" {
  role       = aws_iam_role.task_listing_app_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_role_policy_attachment" "eb_web_tier" {
  role       = aws_iam_role.task_listing_app_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_role_policy_attachment" "eb_multi_container_docker" {
  role       = aws_iam_role.task_listing_app_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
}

resource "aws_iam_role_policy_attachment" "eb_worker_tier" {
  role       = aws_iam_role.task_listing_app_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
}

resource "aws_iam_role_policy_attachment" "ecr_read_only" {
  role       = aws_iam_role.task_listing_app_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_elastic_beanstalk_application" "task_listing_app" {
  name        = "jackdench-task-listing-app"
  description = "Task listing app"
}

resource "aws_elastic_beanstalk_environment" "task_listing_app_environment" {
  name        = "jackdench-task-listing-app-environment"
  application = aws_elastic_beanstalk_application.task_listing_app.name

  # This page lists the supported platforms
  # we can use for this argument:
  # https://docs.aws.amazon.com/elasticbeanstalk/latest/platforms/platforms-supported.html#platforms-supported.docker
  solution_stack_name = "64bit Amazon Linux 2023 v4.0.1 running Docker"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.task_listing_app_ec2_instance_profile.name
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "EC2KeyName"
    value     = "jackdench"
  }
}

resource "aws_s3_bucket" "container_bucket" {
  bucket = "jackdench-task-listing-app-container-bucket"
  tags = {
    "name" = "jackdench-task-listing-app-container-bucket"
  }
}