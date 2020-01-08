data "aws_iam_policy_document" "assume_eks_control_plane" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
    ]
  }
}

resource "aws_iam_role" "drb_test" {
  name               = "drb-test-eks-cluster"
  assume_role_policy = data.aws_iam_policy_document.assume_eks_control_plane.json
}

resource "aws_iam_role_policy_attachment" "drb_test_cluster_policy" {
  role       = aws_iam_role.drb_test.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "drb_test_service_policy" {
  role       = aws_iam_role.drb_test.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

data "aws_iam_policy_document" "assume_eks_node_instance" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
    ]
  }
}

resource "aws_iam_role" "drb_test_node_instance" {
  name               = "drb-test-node-instance"
  assume_role_policy = data.aws_iam_policy_document.assume_eks_node_instance.json
}

resource "aws_iam_role_policy_attachment" "drb_test_node_instance_worker_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.drb_test_node_instance.name
}

resource "aws_iam_role_policy_attachment" "drb_test_node_instance_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.drb_test_node_instance.name
}

resource "aws_iam_role_policy_attachment" "drb_test_node_instance_ecr_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.drb_test_node_instance.name
}

data "aws_iam_policy_document" "assume_eks_fargate" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["eks-fargate-pods.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
    ]
  }
}

resource "aws_iam_role" "drb_test_eks_fargate_pod" {
  name = "drb-test-fargate-pod"
  assume_role_policy = data.aws_iam_policy_document.assume_eks_fargate.json
}

resource "aws_iam_role_policy_attachment" "drb_test_eks_fargate_pod_execution_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.drb_test_eks_fargate_pod.name
}
