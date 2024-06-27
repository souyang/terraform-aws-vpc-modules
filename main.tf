locals {
  tags = {
    ModificationDate = timestamp()
    # Client Infos
    Applictation = var.application
    Project      = var.project
    Environment  = local.environment[var.environment]
  }
  environment = {
    dev = "Development"
    prd = "Production"
    stage = "Staging"
  }
  # name_pattern = format("%s-%s-%s", var.project, var.environment, local.resource)
  vpc_name     = format("%s-%s-%s", var.project, var.environment, "vpc")
  ingress_name = format("%s-%s-%s", var.project, var.environment, "igw")
  route_public_name = format("%s-%s-%s", var.project, var.environment, "rt-public")
  route_private_name = format("%s-%s-%s", var.project, var.environment, "rt-private")
}

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true


  tags = merge({
    Name = local.vpc_name
  }, local.tags)
}


/**
 * Subnets - privates and public
 */

resource "aws_subnet" "private" {
  count = var.number_availability_zones

  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, var.subnet_size, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  vpc_id = aws_vpc.main.id


  tags = merge({
    Name = format("%s-%s-%s-%02d", var.project, var.environment,"subnet-private", count.index + 1)
  }, local.tags)
}

resource "aws_subnet" "public" {
  count = var.number_availability_zones

  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, var.subnet_size, count.index + var.number_availability_zones)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  vpc_id = aws_vpc.main.id


  tags = merge({
    Name = format("%s-%s-%s-%02d", var.project, var.environment,"subnet-public", count.index)
  }, local.tags)
}


/**
 * Internet Gateway
 */
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge({
    Name = local.ingress_name
  }, local.tags)
}


/**
 * Route Main
 */

resource "aws_default_route_table" "r" {
  default_route_table_id = aws_vpc.main.main_route_table_id

  tags = merge({
    Name = format("%s-route-main-%s", var.project, var.environment)
  }, local.tags)
}

resource "aws_route" "internet_access" {
  route_table_id = aws_vpc.main.main_route_table_id

  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge({
    Name = local.route_public_name
  }, local.tags)
}

resource "aws_route_table" "private" {
  count  = var.number_availability_zones
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.gw.*.id, count.index)
  }

  tags = merge({
    Name = local.route_private_name
  }, local.tags)

  depends_on =[
    aws_nat_gateway.gw
  ]
}

resource "aws_route_table_association" "public" {
  count          = var.number_availability_zones
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = element(aws_route_table.public.*.id, count.index)
}

resource "aws_route_table_association" "privates" {
  count          = var.number_availability_zones
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}

/**
 * NAT
 *
 */
resource "aws_eip" "nat" {
  count = var.number_availability_zones
  vpc   = true
}

resource "aws_nat_gateway" "gw" {
  count         = var.number_availability_zones
  allocation_id = element(aws_eip.nat.*.id, count.index)
  subnet_id     = element(aws_subnet.public.*.id, count.index)

  tags = merge({
    Name = format("%s-%s-%s-%02d",var.project,var.environment,"nat", count.index + 1)
  }, local.tags)
}
