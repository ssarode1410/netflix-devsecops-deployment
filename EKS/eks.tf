module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.0.5"

  name               = "my-eks-cluster"
  kubernetes_version = "1.30"

  enable_cluster_creator_admin_permissions = true
  endpoint_public_access                   = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Optional: Specify control plane subnets if using separate ones
  # control_plane_subnet_ids = module.vpc.intra_subnets

  addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
    # eks-pod-identity-agent = {
    #   before_compute = true
    # }
  }

  eks_managed_node_groups = {
    prefix-enabled-nodes = {
      instance_types = ["t3.xlarge"]

      desired_size = 2
      min_size     = 1
      max_size     = 3

      ami_type = "AL2_x86_64"

      launch_template = {
        id      = aws_launch_template.prefix_delegation.id
        version = "$Latest"
      }
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

# Launch template enabling prefix delegation
resource "aws_launch_template" "prefix_delegation" {
  name_prefix   = "eks-prefix-enabled-"
  instance_type = "t3.medium"
  image_id      = data.aws_ami.eks_ami.id

  network_interfaces {
    associate_public_ip_address = true
    ipv4_prefix_count           = 1
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "eks-prefix-delegation-node"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Get latest EKS-compatible Amazon Linux 2 AMI
data "aws_ami" "eks_ami" {
  owners      = ["602401143452"] # Amazon
  most_recent = true

  filter {
    name   = "name"
    values = ["amazon-eks-node-1.29-v*"]
  }
}
