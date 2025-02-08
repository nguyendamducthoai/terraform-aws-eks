module "eks_bottlerocket" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "${local.name}-bottlerocket"
  cluster_version = "1.31"

  # # EKS Addons
  # cluster_addons = {
  #   coredns                = {}
  #   eks-pod-identity-agent = {}
  #   kube-proxy             = {}
  #   vpc-cni                = {}
  # }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  control_plane_subnet_ids = module.vpc.public_subnets

  create_iam_role = true # Default is true
  attach_cluster_encryption_policy = false  # Default is true

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access = true


  create_cluster_security_group = true
  cluster_security_group_description = "EKS cluster security group"

  bootstrap_self_managed_addons = true

  authentication_mode = "API"
  enable_cluster_creator_admin_permissions = true

  dataplane_wait_duration = "40s"

  create_node_security_group = true
  node_security_group_enable_recommended_rules = true
  node_security_group_description = "EKS node group security group - used by nodes to communicate with the cluster API Server"

  eks_managed_node_groups = {
    example = {
      ami_type       = "BOTTLEROCKET_x86_64"
      instance_types = ["t3.medium"]

      min_size = 1
      max_size = 1
      # This value is ignored after the initial creation
      # https://github.com/bryantbiggs/eks-desired-size-hack
      desired_size = 1

      # This is not required - demonstrates how to pass additional configuration
      # Ref https://bottlerocket.dev/en/os/1.19.x/api/settings/
      bootstrap_extra_args = <<-EOT
        # The admin host container provides SSH access and runs with "superpowers".
        # It is disabled by default, but can be disabled explicitly.
        [settings.host-containers.admin]
        enabled = false

        # The control host container provides out-of-band access via SSM.
        # It is enabled by default, and can be disabled if you do not expect to use SSM.
        # This could leave you with no way to access the API and change settings on an existing node!
        [settings.host-containers.control]
        enabled = true

        # extra args added
        [settings.kernel]
        lockdown = "integrity"
      EOT
    }
  }

  tags = local.tags
}


module "eks_blueprints_addons" {
  source = "aws-ia/eks-blueprints-addons/aws"
  version = "1.19.0" #ensure to update this to the latest/desired version

  cluster_name      = module.eks_bottlerocket.cluster_name
  cluster_endpoint  = module.eks_bottlerocket.cluster_endpoint
  cluster_version   = module.eks_bottlerocket.cluster_version
  oidc_provider_arn = module.eks_bottlerocket.oidc_provider_arn

  # eks_addons = {
  #   coredns = {
  #     most_recent = true
  #   }
  #   vpc-cni = {
  #     most_recent = true
  #   }
  #   kube-proxy = {
  #     most_recent = true
  #   }
  # }

  enable_aws_load_balancer_controller    = true
  enable_cluster_proportional_autoscaler = false
  enable_karpenter                       = false
  enable_kube_prometheus_stack           = true
  enable_metrics_server                  = true
  enable_external_dns                    = false
  enable_cert_manager                    = false
  enable_argocd = true

  tags = {
    Environment = "dev"
  }
}