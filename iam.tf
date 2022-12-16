# Create IAM role for EKS worker nodes
resource "aws_iam_role" "eks_cluster_node_role" {
  name = "eks-cluster-node-${local.cluster_name}"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
  inline_policy {
    name = "session_manager_policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "ssmmessages:CreateControlChannel",
            "ssmmessages:CreateDataChannel",
            "ssmmessages:OpenControlChannel",
            "ssmmessages:OpenDataChannel"
          ]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action = [
            "s3:GetEncryptionConfiguration"
          ]
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    })
  }
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_cluster_node_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_cluster_node_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_cluster_node_role.name
}

resource "aws_iam_role_policy_attachment" "SSMManagedInstancePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.eks_cluster_node_role.name
}
