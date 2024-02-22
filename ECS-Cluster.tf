resource "aws_ecs_cluster" "my_cluster" {
  name = "my-terraform-ecs-cluster"

}
resource "aws_ecr_repository" "my_repository" {
  name = "my-api-repository"
}