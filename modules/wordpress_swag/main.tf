
resource "kubernetes_deployment" "wordpress" {
  metadata {
    name = "wordpress-${var.id}"
  }

  spec {
    selector {
      match_labels = {
        app = "wordpress-${var.id}"
      }
    }

    template {
      metadata {
        labels = {
          app = "wordpress-${var.id}"
        }
      }

      spec {
        container {
          name  = "wordpress-${var.id}"
          image = var.wp_container_image

          volume_mount {
            name       = "wp-content-${var.id}"
            mount_path = "/var/www/html"
          }

          volume_mount {
            name       = "wp-config-${var.id}"
            mount_path = "/var/www/html/wp-config.php"
            sub_path   = "wp-config.php"
          }

        }
        volume {
          name = "wp-content-${var.id}"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.wp-content-cl.metadata[0].name
          }
        }

        volume {
          name = "wp-config-${var.id}"
          config_map {
            name = kubernetes_config_map.wp-config.metadata[0].name
          }
        }

      }
    }
  }
}


resource "kubernetes_service" "wordpress" {
  metadata {
    name = "wordpress-${var.id}"
  }

  spec {
    selector = {
      app = kubernetes_deployment.wordpress.metadata[0].name
    }

    port {
      protocol    = "TCP"
      port        = 9000
      target_port = 9000
    }

  }
}


resource "kubernetes_persistent_volume_claim" "wp-content-cl" {
  metadata {
    name = "wp-content-${var.id}-cl"
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.wp_storage_size
      }
    }
    volume_name        = "wp-content-${var.id}"
    storage_class_name = "local-path"
  }
}


resource "kubernetes_persistent_volume" "wp-content" {
  metadata {
    name = "wp-content-${var.id}"
  }
  spec {
    capacity = {
      storage = var.wp_storage_size
    }
    access_modes = ["ReadWriteOnce"]
    persistent_volume_source {
      host_path {
        path = "/home/wps/data/wordpress-${var.id}"
      }
    }
    storage_class_name = "local-path"
  }
}


resource "kubernetes_config_map" "wp-config" {
  metadata {
    name = "wp-config-${var.id}"
  }

  data = {
    "wp-config.php" = <<EOF
<?php


if (!function_exists('getenv_docker')) {
	// https://github.com/docker-library/wordpress/issues/588 (WP-CLI will load this file 2x)
	function getenv_docker($env, $default) {
		if ($fileEnv = getenv($env . '_FILE')) {
			return rtrim(file_get_contents($fileEnv), "\r\n");
		}
		else if (($val = getenv($env)) !== false) {
			return $val;
		}
		else {
			return $default;
		}
	}
}


define( 'DB_NAME', '${var.wp_db_name}' );

define( 'DB_USER',  '${var.wp_db_user}' );

define( 'DB_PASSWORD', '${var.wp_db_pass}' );

define( 'DB_HOST', '${var.mysql_service_name}' );

define( 'DB_CHARSET', 'utf8' );

define( 'DB_COLLATE', getenv_docker('WORDPRESS_DB_COLLATE', '') );

define( 'AUTH_KEY',         getenv_docker('WORDPRESS_AUTH_KEY',         '') );
define( 'SECURE_AUTH_KEY',  getenv_docker('WORDPRESS_SECURE_AUTH_KEY',  '') );
define( 'LOGGED_IN_KEY',    getenv_docker('WORDPRESS_LOGGED_IN_KEY',    '') );
define( 'NONCE_KEY',        getenv_docker('WORDPRESS_NONCE_KEY',        '') );
define( 'AUTH_SALT',        getenv_docker('WORDPRESS_AUTH_SALT',        '') );
define( 'SECURE_AUTH_SALT', getenv_docker('WORDPRESS_SECURE_AUTH_SALT', '') );
define( 'LOGGED_IN_SALT',   getenv_docker('WORDPRESS_LOGGED_IN_SALT',   '') );
define( 'NONCE_SALT',       getenv_docker('WORDPRESS_NONCE_SALT',       '') );

$table_prefix = '${var.wp_db_prefix}';

define( 'WP_DEBUG', ${var.wp_debug} );

if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && strpos($_SERVER['HTTP_X_FORWARDED_PROTO'], 'https') !== false) {
	$_SERVER['HTTPS'] = 'on';
}

if ($configExtra = getenv_docker('WORDPRESS_CONFIG_EXTRA', '')) {
	eval($configExtra);
}

if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', __DIR__ . '/' );
}

require_once ABSPATH . 'wp-settings.php';

	EOF
  }

}


resource "kubernetes_deployment" "swag" {
  metadata {
    name = "swag-${var.id}"
  }

  spec {
    selector {
      match_labels = {
        app = "swag-${var.id}"
      }
    }

    template {
      metadata {
        labels = {
          app = "swag-${var.id}"
        }
      }

      spec {
        container {
          name = "swag-${var.id}"
          image = "docker.io/linuxserver/swag:latest"

          volume_mount {
            name       = "config-${var.id}"
            mount_path = "/config"
          }

          volume_mount {
            name       = "default-${var.id}"
            mount_path = "/config/nginx/site-confs/default.conf"
            sub_path   = "default.conf"
          }

          volume_mount {
            name       = "wp-content-${var.id}"
            mount_path = "/config/www/"
          }

          env {
            name  = "URL"
            value = var.domain 
          }

          env {
            name  = "SUBDOMAINS"
            value = "www"
          }

          env {
            name  = "VALIDATION"
            value = "http"
          }

          env {
            name  = "TZ"
            value = "America/Santiago"
          }

          env {
            name  = "PUID"
            value = "82"
          }

          env {
            name  = "PGID"
            value = "82"
          }

          env {
            name  = "STAGING"
            value = var.wp_debug 
          }
        }

        volume {
          name = "wp-content-${var.id}"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.wp-content-cl.metadata[0].name
          }
        }

        volume {
          name = "config-${var.id}"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.swag-cl.metadata[0].name
          }
        }

        volume {
          name = "default-${var.id}"
          config_map {
            name = kubernetes_config_map.default.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "swag" {
  metadata {
    name = "swag-${var.id}"
  }

  spec {
    selector = {
      app = kubernetes_deployment.swag.metadata[0].name
    }

    port {
      name        = "wp-${var.id}-80"
      protocol    = "TCP"
      port        = 80
      target_port = 80
    }

    port {
      name        = "wp-${var.id}-443"
      protocol    = "TCP"
      port        = 443
      target_port = 443
    }

    type             = "LoadBalancer"
    load_balancer_ip = var.lb_ip 
  }
}

resource "kubernetes_persistent_volume_claim" "swag-cl" {
  metadata {
    name = "swag-${var.id}-cl"
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.swag_storage_size 
      }
    }
    volume_name        = "swag-${var.id}"
    storage_class_name = "local-path"
  }
}


resource "kubernetes_persistent_volume" "swag" {
  metadata {
    name = "swag-${var.id}"
  }
  spec {
    capacity = {
      storage = var.swag_storage_size
    }
    access_modes = ["ReadWriteOnce"]
    persistent_volume_source {
      host_path {
        path = "/home/wps/data/swag-${var.id}"
      }
    }
    storage_class_name = "local-path"
  }
}


resource "kubernetes_config_map" "default" {
  metadata {
    name = "default-${var.id}"
  }

  data = {
    "default.conf" = <<EOF

# redirect all traffic to https
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    location / {
        return 301 https://$host$request_uri;
    }
}


# main server block
server {
    listen 443 ssl http2 default_server;
    listen [::]:443 ssl http2 default_server;

    server_name _;

    include /config/nginx/ssl.conf;

    root /config/www;
    index index.php;

    location /.well-known/acme-challenge {
        default_type "text/plain";
    }

    location / {
        try_files $uri $uri/ /index.php$is_args$args;
    }

    location ~ \.php$  {

        root /var/www/html;

        fastcgi_split_path_info ^(.+\.php)(.*)$;
        fastcgi_pass ${kubernetes_service.wordpress.metadata.0.name}:9000;
        fastcgi_index index.php;
        include /etc/nginx/fastcgi_params;
    }

    # SECURITY : Deny all attempts to access hidden files .abcde
    location ~ /\\. {
     deny all;
    }
}

	EOF
  }

}
