variable "enabled_cluster_log_types" {
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  description = "A list of the desired control plane logging to enable. Possible values [`api`, `audit`, `authenticator`, `controllerManager`, `scheduler`]"
}

variable "addons" {
  type = list(object({
    name    = string
    version = string
  }))
  description = "EKS native Add-ons lists"
  default = [
    {
      name    = "kube-proxy"
      version = "v1.23.8-eksbuild.2"
    },
    # {
    #   name    = "vpc-cni"
    #   version = "v1.11.2-eksbuild.1"
    # },
    # {
    #   name    = "coredns"
    #   version = "v1.8.7-eksbuild.3"
    # }
  ]
}