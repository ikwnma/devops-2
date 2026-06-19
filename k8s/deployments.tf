############################
# Kubernetes Namespace
############################

resource "kubernetes_namespace" "apps" {
  metadata {
    name = "apps"
    labels = {
      name = "apps"
    }
  }
}

############################
# Backend Deployment
############################

resource "kubernetes_deployment" "backend" {
  metadata {
    name      = "${var.project_name}-backend"
    namespace = kubernetes_namespace.apps.metadata[0].name
    labels = {
      app = "backend"
    }
  }

  spec {
    replicas = var.backend_replicas

    selector {
      match_labels = {
        app = "backend"
      }
    }

    template {
      metadata {
        labels = {
          app = "backend"
        }
      }

      spec {
        image_pull_secrets {
          name = kubernetes_secret.ecr_credentials.metadata[0].name
        }

        container {
          name  = "backend"
          image = "${aws_ecr_repository.backend.repository_url}:latest"

          port {
            container_port = var.backend_port
          }

          env {
            name  = "SPRING_DATASOURCE_URL"
            value = var.db_url
          }

          env {
            name  = "SPRING_DATASOURCE_USERNAME"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db_credentials.metadata[0].name
                key  = "username"
              }
            }
          }

          env {
            name  = "SPRING_DATASOURCE_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db_credentials.metadata[0].name
                key  = "password"
              }
            }
          }

          resources {
            requests = {
              cpu    = var.backend_cpu_request
              memory = var.backend_memory_request
            }
            limits = {
              cpu    = var.backend_cpu_limit
              memory = var.backend_memory_limit
            }
          }

          liveness_probe {
            http_get {
              path   = "/actuator/health"
              port   = var.backend_port
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path   = "/actuator/health"
              port   = var.backend_port
            }
            initial_delay_seconds = 10
            period_seconds        = 5
          }
        }

        restart_policy = "Always"
      }
    }

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge       = 1
        max_unavailable = 0
      }
    }
  }

  depends_on = [kubernetes_namespace.apps, kubernetes_secret.ecr_credentials]
}

############################
# Frontend Deployment
############################

resource "kubernetes_deployment" "frontend" {
  metadata {
    name      = "${var.project_name}-frontend"
    namespace = kubernetes_namespace.apps.metadata[0].name
    labels = {
      app = "frontend"
    }
  }

  spec {
    replicas = var.frontend_replicas

    selector {
      match_labels = {
        app = "frontend"
      }
    }

    template {
      metadata {
        labels = {
          app = "frontend"
        }
      }

      spec {
        image_pull_secrets {
          name = kubernetes_secret.ecr_credentials.metadata[0].name
        }

        container {
          name  = "frontend"
          image = "${aws_ecr_repository.frontend.repository_url}:latest"

          port {
            container_port = var.frontend_port
          }

          env {
            name  = "VITE_API_URL"
            value = "http://${var.project_name}-backend:${var.backend_port}"
          }

          env {
            name  = "VITE_ENVIRONMENT"
            value = var.environment
          }

          resources {
            requests = {
              cpu    = var.frontend_cpu_request
              memory = var.frontend_memory_request
            }
            limits = {
              cpu    = var.frontend_cpu_limit
              memory = var.frontend_memory_limit
            }
          }

          liveness_probe {
            http_get {
              path   = "/"
              port   = var.frontend_port
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path   = "/"
              port   = var.frontend_port
            }
            initial_delay_seconds = 10
            period_seconds        = 5
          }
        }

        restart_policy = "Always"
      }
    }

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge       = 1
        max_unavailable = 0
      }
    }
  }

  depends_on = [kubernetes_namespace.apps, kubernetes_secret.ecr_credentials]
}
