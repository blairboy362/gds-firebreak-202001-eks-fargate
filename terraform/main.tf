provider "aws" {
}

module "vpc" {
  source = "btower-labz/btlabz-vpc-ha-3x/aws"

  vpc_name = "drb-test"

  vpc_cidr       = "172.20.0.0/16"
  public_a_cidr  = "172.20.0.0/20"
  public_b_cidr  = "172.20.16.0/20"
  public_c_cidr  = "172.20.32.0/20"
  private_a_cidr = "172.20.48.0/20"
  private_b_cidr = "172.20.64.0/20"
  private_c_cidr = "172.20.80.0/20"

  tags = map(
    "kubernetes.io/cluster/drb-test", "shared",
  )
}

resource "aws_eks_cluster" "drb_test" {
  name     = "drb-test"
  role_arn = aws_iam_role.drb_test.arn

  vpc_config {
    subnet_ids = [
      module.vpc.private_a,
      module.vpc.private_b,
      module.vpc.private_c,
      module.vpc.public_a,
      module.vpc.public_b,
      module.vpc.public_c,
    ]
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.drb_test_cluster_policy,
    aws_iam_role_policy_attachment.drb_test_service_policy,
  ]
}

resource "aws_eks_node_group" "drb_test" {
  cluster_name    = aws_eks_cluster.drb_test.name
  node_group_name = "drb_test"
  node_role_arn   = aws_iam_role.drb_test_node_instance.arn

  subnet_ids = [
    module.vpc.private_a,
    module.vpc.private_b,
    module.vpc.private_c,
  ]

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 2
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.drb_test_node_instance_worker_policy,
    aws_iam_role_policy_attachment.drb_test_node_instance_cni_policy,
    aws_iam_role_policy_attachment.drb_test_node_instance_ecr_policy,
  ]
}

resource "aws_eks_fargate_profile" "drb_test_drb_test" {
  cluster_name           = aws_eks_cluster.drb_test.name
  fargate_profile_name   = "drb-test-drb-test"
  pod_execution_role_arn = aws_iam_role.drb_test_eks_fargate_pod.arn
  subnet_ids             = [
    module.vpc.private_a,
    module.vpc.private_b,
    module.vpc.private_c,
  ]

  selector {
    namespace = "drb-test"
  }
}

resource "aws_eks_fargate_profile" "drb_test_istio_system" {
  cluster_name           = aws_eks_cluster.drb_test.name
  fargate_profile_name   = "drb-test-istio-system"
  pod_execution_role_arn = aws_iam_role.drb_test_eks_fargate_pod.arn
  subnet_ids             = [
    module.vpc.private_a,
    module.vpc.private_b,
    module.vpc.private_c,
  ]

  selector {
    namespace = "istio-system"
  }

  depends_on = [
    aws_eks_fargate_profile.drb_test_drb_test,
  ]
}
