# ---------------------------------------------------------------------------
# Мережа під кластер.
#
# Свідоме спрощення: NAT Gateway не створюється, а вузли живуть у публічних
# підмережах. Причина суто економічна: NAT коштує близько $32 на місяць плюс
# трафік — майже половина ціни самого кластера.
#
# У продакшні роблять навпаки: вузли у приватних підмережах, вихід через NAT
# або приватні ендпоінти VPC. Наш варіант дешевший і простіший, але вузли
# доступні з інтернету на рівні мережі.
# ---------------------------------------------------------------------------

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "${var.prefix}-vpc"
  cidr = var.vpc_cidr

  azs             = local.azs
  public_subnets  = local.public_subnets
  private_subnets = local.private_subnets

  enable_nat_gateway   = false
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Вузли у публічних підмережах мають отримувати публічну адресу,
  # інакше вони не зможуть зареєструватись у кластері (немає NAT).
  map_public_ip_on_launch = true

  # Теги підмереж — НЕ косметика.
  # За ними AWS Load Balancer Controller знаходить, де створювати ELB.
  # Без правильного тега Service типу LoadBalancer зависне у Pending назавжди,
  # і в подіях не буде нічого зрозумілого.
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = local.common_tags
}
