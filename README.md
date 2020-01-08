# Firebreak 2020-01: EKS Fargate spike

## Basic setup

The idea was to perform a rudimentary analysis on Fargate's capabilities to see
if and how we might use it with the GSP. So, we started simply enough:

* a VPC in Ireland (eu-west-1)
* 3 public subnets
* 3 private subnets
* an EKS cluster
* a managed node group
* two fargate profiles

## Terraform

In the terraform directory the cluster can be brought up by:

```
$ AWS_DEFAULT_REGION=eu-west-1 gds aws gsp-sandbox-admin -- terraform apply
```

## Findings

TL;DR: I don't think it will be much use to us in GSP. At least for now.

Mostly suspicions were confirmed. In some cases confusion given the difference
in observed behaviour from the documentation.

* persistent workloads are not supported in Fargate (this is documented). I
  hoped EKS would be smart enough to fall back to the managed node group if
  Fargate refused to schedule it; alas the pod remains in a "pending" state.
* The documentation states that only ALBs are supported. However I successfully
  got an HTTP 404 from envoy (with matching logs in the istio-ingressgateway
  pod) running in Fargate from an EKS-provisioned NLB (and an EKS-provision
  classic ELB).
* Fargate pods can't run CNI containers / daemonset pods. Fargate pods also are
  not allowed elevated permissions. So any pod requiring the istio sidecar can't
  be run in Fargate.
* There doesn't appear to be a logging solution yet, so the fargate pod logs
  don't end up in CloudWatch; they're lost once the pod exits.
* The daemonset control plane gets quite confused by fargate. It treats fargate
  instances as nodes and creates pods for each one, which all get stuck in
  "pending". The workaround / fix is to add node affinity entries to the pod
  templates so they target nodes that are not fargate ones.

## Istio installation

```
$ gds aws gsp-sandbox-admin -- istioctl manifest apply -f istio-control-plane.yaml
```
