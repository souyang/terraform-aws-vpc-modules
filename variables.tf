variable "project" {
  description = "Name to be used on all the resources as identifier"
  type        = string
}

variable "environment" {
  description = "The environment, and also used as a identifier"
  type        = string
  validation {
      condition = contains(["stage", "prod", "dev"], var.environment)
    error_message = "Define envrionment as one that follows: dev, stage or prd."
  }
}

variable "region" {
  description = "Region AWS where deploy occurs"
  type        = string
  default     = "us-east-1"
}

variable "application" {
  type = string
  description = "Name application"
}

########################################

variable "number_availability_zones"{
  type = number
  description = "Number of availability zones to be considered during each deploy"
  default = 2
}

variable "subnet_size"{
  type = number
  description = "Size of subnet"
  default = 4
}

variable "vpc_cidr" {
  type  = string
  description = "VPC size and range IP definition"
  default = "192.168.0.0/24"
}
