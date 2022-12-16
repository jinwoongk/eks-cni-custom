#!/bin/bash

# # kubectl install 
# curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
# chmod +x kubectl
# mkdir -p ~/.local/bin
# mv ./kubectl ~/.local/bin/kubectl

# # kubectl auth
# aws --profile default configure set aws_access_key_id $AWS_ACCESS_KEY_ID
# aws --profile default configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
# aws --profile default configure set region "ap-northeast-2"
# export $(printf "AWS_ACCESS_KEY_ID=%s AWS_SECRET_ACCESS_KEY=%s AWS_SESSION_TOKEN=%s" \
# $(aws sts assume-role \
# --role-arn $ASSUME_ROLE \
# --role-session-name TempSession \
# --query "Credentials.[AccessKeyId,SecretAccessKey,SessionToken]" \
# --output text))
# aws sts get-caller-identity

KUBE_CONFIG="$(mktemp)"
aws eks update-kubeconfig --name "${CLUSTER_NAME}" --kubeconfig "${KUBE_CONFIG}"

## Apply VPC CNI manifests (origin: https://raw.githubusercontent.com/aws/amazon-vpc-cni-k8s/v1.11.2/config/master/aws-k8s-cni.yaml)
# Security group for pod env configurations ; ENABLE_POD_ENI=true
# https://github.com/aws/amazon-vpc-cni-k8s#disable_tcp_early_demux-v173 ; DISABLE_TCP_EARLY_DEMUX=true
# Custom networking ; AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG=true
# Custom networking ; ENI_CONFIG_LABEL_DEF=topology.kubernetes.io/zone
# Custom networking ; WARM_IP_TARGET=1
# Custom networking ; MINIMUM_IP_TARGET=30
# Custom networking ; WARM_PREFIX_TARGET=1
# Fewer API calls required to EC2 control plane ; ENABLE_PREFIX_DELEGATION=true
# Source NAT disabled ; AWS_VPC_K8S_CNI_EXTERNALSNAT=true

kubectl --kubeconfig "${KUBE_CONFIG}" apply -f ./scripts/aws-k8s-cni.yaml

# set up ENIConfig 
subnet_a=$(echo ${SUBNETS} |awk -F"," '{print $1}')
subnet_b=$(echo ${SUBNETS} |awk -F"," '{print $2}')
subnet_c=$(echo ${SUBNETS} |awk -F"," '{print $3}')

cat <<EOF | kubectl --kubeconfig "${KUBE_CONFIG}" apply -f -
apiVersion: crd.k8s.amazonaws.com/v1alpha1
kind: ENIConfig
metadata:
  name: "ap-northeast-2a"
spec:
  subnet: "${subnet_a}"
  securityGroups:
  - ${CLUSTER_SG}
EOF

cat <<EOF | kubectl --kubeconfig "${KUBE_CONFIG}" apply -f -
apiVersion: crd.k8s.amazonaws.com/v1alpha1
kind: ENIConfig
metadata:
  name: "ap-northeast-2b"
spec:
  subnet: "${subnet_b}"
  securityGroups:
  - ${CLUSTER_SG}
EOF

cat <<EOF | kubectl --kubeconfig "${KUBE_CONFIG}" apply -f -
apiVersion: crd.k8s.amazonaws.com/v1alpha1
kind: ENIConfig
metadata:
  name: "ap-northeast-2c"
spec:
  subnet: "${subnet_c}"
  securityGroups:
  - ${CLUSTER_SG}
EOF

# remobe creds
rm "${KUBE_CONFIG}"