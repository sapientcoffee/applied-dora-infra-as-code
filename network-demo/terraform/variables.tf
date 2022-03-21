variable "region" {
  type    = string
  default = "us-east1"
}

variable "instance_type" {
  type    = string
  default = "n1-standard-1"
}

variable "project" {
  type = string
  default = "coffee-with-iac"
}

variable "prefix" {
  type = string
  default = "rob"
}

variable "env" {
  type = string
  default = "coffee"
}