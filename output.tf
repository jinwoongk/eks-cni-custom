# output "configure_kubectl" {
#   description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
#   value       = "aws eks --region ${local.region} update-kubeconfig --name ${module.eks.cluster_id}"
# }

# output "cluster_name" {
#   description = "Kubernetes Cluster Name"
#   value       = module.eks.cluster_id
# }

# output "eks_cluster_endpoint" {
#   description = "eks cluster endpoint"
#   value       = module.eks.cluster_endpoint
# }