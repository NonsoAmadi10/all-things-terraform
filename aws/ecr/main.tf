provider "aws" {
  region = "eu-west-1"
  shared_credentials_file = "${var.aws_credential}"
  profile = "default"
}

resource "aws_ecr_repository" "teraform_ecr" {
  name                 = "axios"
  image_tag_mutability = "IMMUTABLE"
  
  encryption_configuration {
    encryption_type = "KMS"
  }
  image_scanning_configuration {
    scan_on_push = true
  }
}

# Create a lifecycle policy to remove untagged images 
resource "aws_ecr_lifecycle_policy" "ecr_policy" {
  repository = aws_ecr_repository.teraform_ecr

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Expire images older than 14 days",
            "selection": {
                "tagStatus": "untagged",
                "countType": "sinceImagePushed",
                "countUnit": "days",
                "countNumber": 14
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}