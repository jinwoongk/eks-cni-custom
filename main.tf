module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.7.0"
  name                  = "terraform-demo-vpc"
  cidr                  = "10.0.0.0/16"
  secondary_cidr_blocks = ["100.64.0.0/16"]
  azs                   = ["${local.region}a", "${local.region}b", "${local.region}c"]
  private_subnets       = ["10.0.1.0/28", "10.0.2.0/28", "10.0.3.0/28"]
  intra_subnets         = [ "100.64.1.0/24", "100.64.2.0/24", "100.64.3.0/24"]
  public_subnets        = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_nat_gateway    = true
  single_nat_gateway    = true
  enable_dns_hostnames  = true
}
# private nat gateway
resource "aws_nat_gateway" "private_nat" {
  connectivity_type = "private"
  subnet_id         = module.vpc.private_subnets[0]
}
resource "aws_route" "intra_subnets_default_gateway" {
  route_table_id            = module.vpc.intra_route_table_ids[0]
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id            = aws_nat_gateway.private_nat.id
  depends_on                = [aws_nat_gateway.private_nat]
}

# Create EKS cluster 
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = local.cluster_name
  subnet_ids      = module.vpc.public_subnets
  vpc_id          = module.vpc.vpc_id

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  cluster_enabled_log_types              = var.enabled_cluster_log_types
  cloudwatch_log_group_retention_in_days = 7

}

resource "aws_eks_addon" "addons" {
  for_each          = { for addon in var.addons : addon.name => addon }
  cluster_name      = local.cluster_name
  addon_name        = each.value.name
  addon_version     = each.value.version
  resolve_conflicts = "OVERWRITE"

  depends_on = [
    aws_eks_node_group.default
  ]
}

# Create managed node group
resource "aws_eks_node_group" "default" {
  cluster_name  = local.cluster_name
  node_group_name = "${local.cluster_name}-node-group-default"
  node_role_arn   = aws_iam_role.eks_cluster_node_role.arn
  subnet_ids      = module.vpc.private_subnets
  instance_types  = [ "c5.large" ]
  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  depends_on = [
    null_resource.cni_patch,
  ]
}

