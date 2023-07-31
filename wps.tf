
module "wp1" {
  id                 = "1"
  mysql_service_name = kubernetes_service.mysql-service.metadata.0.name
  source             = "./modules/wordpress_swag"
  wp_container_image = "docker.io/library/wordpress:php8.2-fpm-alpine"
  wp_db_name         = "dbname"
  wp_db_user         = "dbuser"
  wp_db_pass         = var.mysql_wp1_pass 
  wp_db_prefix       = "wp_"
  wp_debug           = "false"
  domain             = "your-domain.com"
  lb_ip              = "x.x.x.x"
}

