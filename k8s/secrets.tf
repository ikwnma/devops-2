############################
# Database Credentials Secret
############################

resource "kubernetes_secret" "db_credentials" {
  metadata {
    name      = "${var.project_name}-db-credentials"
    namespace = kubernetes_namespace.apps.metadata[0].name
  }

  type = "Opaque"

  data = {
    username = base64encode(var.db_username)
    password = base64encode(var.db_password)
  }

  depends_on = [kubernetes_namespace.apps]
}

############################
# ECR Image Pull Secret
############################

locals {
  ecr_auth = base64encode("AWS:${data.aws_ecr_authorization_token.token.authorization_token}")
}

data "aws_ecr_authorization_token" "token" {}

resource "kubernetes_secret" "ecr_credentials" {
  metadata {
    name      = "${var.project_name}-ecr-credentials"
    namespace = kubernetes_namespace.apps.metadata[0].name
  }

  type = "kubernetes.io/dockercfg"

  data = {
    ".dockercfg" = base64encode(jsonencode({
      "${var.ecr_registry_id}.dkr.ecr.${var.aws_region}.amazonaws.com" = {
        username = "AWS"
        password = data.aws_ecr_authorization_token.token.authorization_token
        email    = "aws@example.com"
        auth     = local.ecr_auth
      }
    }))
  }

  depends_on = [kubernetes_namespace.apps]
}
