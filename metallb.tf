
resource "null_resource" "kube_proxy_apply" {
  provisioner "local-exec" {
    command = <<EOF
kubectl get configmap kube-proxy -n kube-system -o yaml | \
sed -e "s/strictARP: false/strictARP: true/" | \
kubectl apply -f - -n kube-system
EOF
  }
}

resource "helm_release" "metallb" {
  name = "metallb"

  repository = "https://metallb.github.io/metallb"
  chart      = "metallb"
}


resource "kubernetes_manifest" "metallb-configmap" {
  manifest = {
    "apiVersion" = "metallb.io/v1beta1"
    "kind"       = "IPAddressPool"
    "metadata" = {
      "name"      = "wps-pool"
      "namespace" = "default"
    }
    "spec" = {
      "addresses" = ["x.x.x.x-y.y.y.y"]
    }
  }
}

