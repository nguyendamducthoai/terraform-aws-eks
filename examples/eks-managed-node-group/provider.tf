# terraform {
#   required_providers {
#     helm = {
#       source = "hashicorp/helm"
#       version = "3.0.0-pre1"
#     }
#   }
# }

provider "aws" {
  region = local.region
}

provider "helm" {
  kubernetes {
    host                   = module.eks_bottlerocket.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_bottlerocket.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.eks_bottlerocket.cluster_name]
      command     = "aws"
    }
  }
}

# output name {
#   value       = module.eks_bottlerocket
# }

