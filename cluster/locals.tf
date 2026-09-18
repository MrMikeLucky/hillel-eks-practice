locals {
  name = "${var.prefix}-eks"

  # Три зони: контрольний рівень і так розподіляється по трьох,
  # тому й вузли розкладаємо так само.
  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  # Підмережі рахуються з діапазону VPC, а не пишуться руками.
  # 10.30.0.0/16 -> публічні 10.30.1..3.0/24, приватні 10.30.11..13.0/24
  public_subnets  = [for i in range(3) : cidrsubnet(var.vpc_cidr, 8, i + 1)]
  private_subnets = [for i in range(3) : cidrsubnet(var.vpc_cidr, 8, i + 11)]

  common_tags = {
    Project   = "hillel-eks-practice"
    ManagedBy = "terraform"
    Workspace = terraform.workspace
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}
