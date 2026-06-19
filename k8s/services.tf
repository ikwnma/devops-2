############################
# Backend Service
############################

resource "kubernetes_service" "backend" {
  metadata {
    name      = "${var.project_name}-backend"
    namespace = kubernetes_namespace.apps.metadata[0].name
    labels = {
      app = "backend"
    }
  }

  spec {
    selector = {
      app = "backend"
    }

    port {
      port        = var.backend_port
      target_port = var.backend_port
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }

  depends_on = [kubernetes_namespace.apps]
}

############################
# Frontend Service
############################

resource "kubernetes_service" "frontend" {
  metadata {
    name      = "${var.project_name}-frontend"
    namespace = kubernetes_namespace.apps.metadata[0].name
    labels = {
      app = "frontend"
    }
  }

  spec {
    selector = {
      app = "frontend"
    }

    port {
      port        = 80
      target_port = var.frontend_port
      protocol    = "TCP"
    }

    type = "LoadBalancer"
  }

  depends_on = [kubernetes_namespace.apps]
}

############################
# ALB Ingress Controller (Helm Chart)
############################

resource "helm_release" "alb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = var.eks_cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = true
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = var.alb_controller_role_arn
  }

  depends_on = [var.alb_controller_role_arn]
}

############################
# Ingress Resource (ALB)
############################

resource "kubernetes_ingress_v1" "frontend" {
  metadata {
    name      = "${var.project_name}-frontend-ingress"
    namespace = kubernetes_namespace.apps.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"                    = "alb"
      "alb.ingress.kubernetes.io/scheme"               = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"          = "ip"
      "alb.ingress.kubernetes.io/healthcheck-path"     = "/"
      "alb.ingress.kubernetes.io/healthcheck-interval" = "30"
      "alb.ingress.kubernetes.io/healthcheck-timeout"  = "5"
    }
  }

  spec {
    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.frontend.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }

        path {
          path      = "/api"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.backend.metadata[0].name
              port {
                number = var.backend_port
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_service.frontend,
    kubernetes_service.backend,
    helm_release.alb_controller
  ]
}
