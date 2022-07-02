resource "aws_ecr_repository" "repo" {
  name = "servian-tech-app"
}

output "image_uri" {
  value = aws_ecr_repository.repo.repository_url
}
