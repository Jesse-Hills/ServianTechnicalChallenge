resource "aws_ecr_repository" "repo" {
  name = "servian-tech-app"
}

output "image_url" {
  value = aws_ecr_repository.repo.repository_url
}
