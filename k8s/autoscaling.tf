############################
# Metrics Server (required for HPA)
############################

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"

  set {
    name  = "args[0]"
    value = "--kubelet-insecure-tls"
  }
}

############################
# Backend HPA (Horizontal Pod Autoscaler)
############################

resource "kubernetes_horizontal_pod_autoscaler_v2" "backend" {
  metadata {
    name      = "${var.project_name}-backend-hpa"
    namespace = kubernetes_namespace.apps.metadata[0].name
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.backend.metadata[0].name
    }

    min_replicas = var.backend_min_replicas
    max_replicas = var.backend_max_replicas

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = var.backend_cpu_target_percentage
        }
      }
    }

    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type                = "Utilization"
          average_utilization = var.backend_memory_target_percentage
        }
      }
    }

    behavior {
      scale_down {
        stabilization_window_seconds = 300
        policies {
          type                  = "Percent"
          value                 = 50
          period_seconds        = 60
        }
        select = "Max"
      }

      scale_up {
        stabilization_window_seconds = 0
        policies {
          type                  = "Percent"
          value                 = 100
          period_seconds        = 30
        }
        select = "Max"
      }
    }
  }

  depends_on = [
    kubernetes_deployment.backend,
    helm_release.metrics_server
  ]
}

############################
# Frontend HPA (Horizontal Pod Autoscaler)
############################

resource "kubernetes_horizontal_pod_autoscaler_v2" "frontend" {
  metadata {
    name      = "${var.project_name}-frontend-hpa"
    namespace = kubernetes_namespace.apps.metadata[0].name
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.frontend.metadata[0].name
    }

    min_replicas = var.frontend_min_replicas
    max_replicas = var.frontend_max_replicas

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = var.frontend_cpu_target_percentage
        }
      }
    }

    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type                = "Utilization"
          average_utilization = var.frontend_memory_target_percentage
        }
      }
    }

    behavior {
      scale_down {
        stabilization_window_seconds = 300
        policies {
          type                  = "Percent"
          value                 = 50
          period_seconds        = 60
        }
        select = "Max"
      }

      scale_up {
        stabilization_window_seconds = 0
        policies {
          type                  = "Percent"
          value                 = 100
          period_seconds        = 30
        }
        select = "Max"
      }
    }
  }

  depends_on = [
    kubernetes_deployment.frontend,
    helm_release.metrics_server
  ]
}
