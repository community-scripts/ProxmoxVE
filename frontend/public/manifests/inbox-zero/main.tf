# from manifests

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_deployment" "inbox_zero" {
  metadata {
    name = "inbox-zero"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "inbox-zero"
      }
    }

    template {
      metadata {
        labels = {
          app = "inbox-zero"
        }
      }

      spec {
        container {
          name  = "inbox-zero"
          image = "image:tag"

          port {
            container_port = 2368
          }
        }
      }
    }
  }
}
