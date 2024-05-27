variable "public_key_path" {
  description = "Path to the public key used for SSH access"
}

variable "dockerhub_username" {
  description = "DockerHub username for pulling the Flask app image"
  type        = string
}

variable "aws_region" {
  description = "AWS region to deploy the resources"
  type        = string
}

variable "docker_hub_username" {
    description = "DockerHub username for pulling the Flask app image"
    type        = string
}

variable "DB_NAME" {
    description = "Database name"
    type        = string
}
variable "DB_USER" {
    description = "Database user"
    type        = string
}
variable "DB_PASSWORD" {
    description = "Database password"
    type        = string
}
variable "ROOT_DB_PASSWORD" {
    description = "Root database password"
    type        = string
}