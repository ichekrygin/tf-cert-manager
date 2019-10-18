locals {
  kubeclt-cmd = "kubectl -s=https://${var.cluster-endpoint} --token=${var.cluster-auth-token} --insecure-skip-tls-verify"
}

resource kubernetes_namespace cert-manager {
  metadata {
    name = var.name
    labels = {
      "certmanager.k8s.io/disable-validation" = "true"
    }
  }
}

data local_file crds {
  filename = "${path.module}/crds.yaml"
}

resource null_resource cert-manager-crds {
  depends_on = [
    kubernetes_namespace.cert-manager
  ]

  triggers = {
    build_number = sha1(data.local_file.crds.content)
  }

  provisioner local-exec {
    command = "$KUBECTL -n ${kubernetes_namespace.cert-manager.metadata.0.name} apply -f ${data.local_file.crds.filename}"
    environment = {
      KUBECTL = local.kubeclt-cmd
    }
  }
}

data helm_repository cert-manager {
  name = var.chart-repo-name
  url = var.chart-repo-url
}

resource helm_release cert-manager {
  depends_on = [null_resource.cert-manager-crds]
  chart = var.chart-name
  name = var.name
  namespace = var.name
  version = var.chart-version
  wait = true
}

data template_file cluster-issuer {
  template = "${path.module}/cluster-issuer.yaml.tmpl"
  vars = {
    name = var.cluster-issuer-name
    email = var.cluster-issuer-email
  }
}

resource local_file cluster-issuer {
  filename = "${path.module}/cluster-issuer.yaml"
  content = data.template_file.cluster-issuer.rendered
}

resource null_resource cluster-issuer {
  provisioner local-exec {
    command = "$KUBECTL -n ${kubernetes_namespace.cert-manager.metadata.0.name} apply -f ${local_file.cluster-issuer.filename}"
    environment = {
      KUBECTL = local.kubeclt-cmd
    }
  }
}
