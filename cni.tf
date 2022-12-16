# Configure CNI custom network
resource "null_resource" "cni_patch" {
  triggers = {
    cluster_name  = local.cluster_name
    cluster_sg    = module.eks.cluster_primary_security_group_id
    intra_subnets = join(",", module.vpc.intra_subnets)
    content       = file("${path.module}/scripts/network.sh")
  }
  provisioner "local-exec" {
    environment = {
      CLUSTER_NAME = self.triggers.cluster_name
      CLUSTER_SG   = self.triggers.cluster_sg
      SUBNETS      = self.triggers.intra_subnets
    }
    command     = "${path.cwd}/scripts/network.sh"
    interpreter = ["bash"]
  }
}