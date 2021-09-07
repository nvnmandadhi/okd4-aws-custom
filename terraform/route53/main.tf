data "aws_route53_zone" "public" {
  name = var.base_domain
}

resource "aws_route53_zone" "int" {
  name          = "${var.cluster_name}.${var.base_domain}"
  force_destroy = true

  vpc {
    vpc_id = var.vpc_id
  }

  tags = merge(
    {
      "Name" = "${var.infraID}-int"
    },
    {
      join("", ["kubernetes.io/cluster/", var.infraID]) = "owned"
    }
  )

  depends_on = [aws_route53_record.api_external_alias]
}

resource "aws_route53_record" "api_external_alias" {
  zone_id = data.aws_route53_zone.public.zone_id
  name    = "api.${var.cluster_name}.${var.base_domain}"
  type    = "A"

  alias {
    name                   = var.api_external_lb_dns_name
    zone_id                = var.api_external_lb_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "api_internal_alias" {
  zone_id = aws_route53_zone.int.zone_id
  name    = "api-int.${var.cluster_name}.${var.base_domain}"
  type    = "A"

  alias {
    name                   = var.api_internal_lb_dns_name
    zone_id                = var.api_internal_lb_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "api_external_internal_zone_alias" {
  zone_id = aws_route53_zone.int.zone_id
  name    = "api.${var.cluster_name}.${var.base_domain}"
  type    = "A"

  alias {
    name                   = var.api_internal_lb_dns_name
    zone_id                = var.api_internal_lb_zone_id
    evaluate_target_health = false
  }
}
