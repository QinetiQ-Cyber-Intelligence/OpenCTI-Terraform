############################
# -- Application LB for -- #
# --  external access   -- #
############################
resource "aws_lb" "application" {
  name = "${var.resource_prefix}-alb"
  #checkov:skip=CKV_AWS_150:It is not expected that delete protection is required.
  internal                         = false
  load_balancer_type               = "application"
  enable_cross_zone_load_balancing = true
  subnets                          = var.public_subnet_ids
  security_groups                  = [aws_security_group.this.id]
  access_logs {
    bucket  = var.logging_s3_bucket
    prefix  = var.public_opencti_access_logs_s3_prefix
    enabled = true
  }
  drop_invalid_header_fields = true
}

resource "aws_security_group" "this" {
  name        = "${var.resource_prefix}-alb-public-access"
  description = "OpenCTI Platform Access"
  vpc_id      = var.vpc_id
  ingress {
    description = "OpenCTI Platform Public Access"
    from_port   = (var.domain == "") ? 80 : 443
    to_port     = (var.domain == "") ? 80 : 443
    protocol    = "tcp"
    cidr_blocks = var.cidr_blocks_public_lb_ingress
  }
  egress {
    description = "Access to internet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_listener" "lb_listener_http" {
  count             = (var.domain == "") ? 1 : 0
  load_balancer_arn = aws_lb.application.arn
  port              = "80"
  protocol          = "HTTP"

  # OIDC is not supported for non-HTTPS

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

# Redirect HTTP to HTTPS
resource "aws_lb_listener" "lb_listener_redirect" {
  count             = (var.domain == "") ? 0 : 1
  load_balancer_arn = aws_lb.application.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "lb_listener_https" {
  count             = (var.domain == "") ? 0 : 1
  load_balancer_arn = aws_lb.application.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = aws_acm_certificate_validation.this[count.index].certificate_arn

  # Check if authorized, if authenticate_oidc.on_authenticated_request
  # is deny or authenticate and if the client id is set
  dynamic "default_action" {
    for_each = (var.oidc_information.client_id == "") ? [] : [var.oidc_information.client_id]
    content {
     type  = "authenticate-oidc"
     order = 49999
     authenticate_oidc {
       authorization_endpoint     = var.oidc_information.authorization_endpoint
       client_id                  = var.oidc_information.client_id
       client_secret              = var.oidc_information.client_secret
       issuer                     = var.oidc_information.issuer
       token_endpoint             = var.oidc_information.token_endpoint
       user_info_endpoint         = var.oidc_information.user_info_endpoint
       scope                      = var.oidc_information.scope
       session_timeout            = var.oidc_information.session_timeout
       on_unauthenticated_request = var.oidc_information.on_unauthenticated_request
     }
    }
  }

  default_action {
    type             = "forward"
    order            = 50000
    target_group_arn = aws_lb_target_group.this.arn
  }
}


# Generate rules depending on the amount of needed
# IP addresses to bypass OIDC;AWS only allows 5 per rule
locals {
  chunked_whitelisted_ips = {for idx, val in chunklist(var.cidr_blocks_bypass_auth, 5): idx => val}
}
resource "aws_lb_listener_rule" "lb_listener_https_rule" {
  # Create rules for the listener, 5 whitelisted IPs per rule
  # These are placed higher priority than the default rules
  for_each     = (var.domain == "" || var.oidc_information.client_id == "") ? {} : local.chunked_whitelisted_ips
  listener_arn = aws_lb_listener.lb_listener_https[0].arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  condition {
    source_ip {
      values = each.value
    }
  }
}

resource "aws_lb_target_group" "this" {
  name                          = "${var.resource_prefix}-alb-opencti-target"
  port                          = var.opencti_platform_port
  protocol                      = "HTTP"
  vpc_id                        = var.vpc_id
  target_type                   = "ip"
  deregistration_delay          = 1
  load_balancing_algorithm_type = "least_outstanding_requests"
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    protocol            = "HTTP"
    interval            = 10
    path                = "/"
  }
}


##########################
# -- SSL & R53 Config -- #
##########################
resource "aws_route53_zone" "public_subdomain_zone" {
  count   = (var.domain == "") ? 0 : 1
  name    = "${var.environment}.${var.domain}"
}

# # Create an A record from the subdomain to the Application Load Balancer
resource "aws_route53_record" "alb_record" {
  count   = (var.domain == "") ? 0 : 1
  zone_id = aws_route53_zone.public_subdomain_zone[count.index].zone_id
  name    = "${var.subdomain}.${aws_route53_zone.public_subdomain_zone[count.index].name}"
  type    = "A"
  alias {
    name                   = aws_lb.application.dns_name
    zone_id                = aws_lb.application.zone_id
    evaluate_target_health = false
  }
}

# # SSL certificate for ALB
resource "aws_acm_certificate" "alb_ssl" {
  count             = (var.domain == "") ? 0 : 1
  domain_name       = aws_route53_record.alb_record[count.index].fqdn
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

# # Verifying DNS ownership for the ACM certificate
resource "aws_route53_record" "cert_validation" {
  count           = (var.domain == "") ? 0 : 1
  allow_overwrite = true
  name            = tolist(aws_acm_certificate.alb_ssl[count.index].domain_validation_options)[0].resource_record_name
  records         = [tolist(aws_acm_certificate.alb_ssl[count.index].domain_validation_options)[0].resource_record_value]
  type            = tolist(aws_acm_certificate.alb_ssl[count.index].domain_validation_options)[0].resource_record_type
  zone_id         = aws_route53_zone.public_subdomain_zone[count.index].id
  ttl             = 60
}

# # Informing Terraform to await ACM Cert validation before progressing 
resource "aws_acm_certificate_validation" "this" {
  count                   = (var.domain == "") ? 0 : 1
  certificate_arn         = aws_acm_certificate.alb_ssl[count.index].arn
  validation_record_fqdns = [aws_route53_record.cert_validation[count.index].fqdn]
}

################################
# --    Internal NLB for    -- #
# -- Workers and Connectors -- #
################################

resource "aws_lb" "network" {
  #checkov:skip=CKV_AWS_91:Access Logging is not required on the private NLB.
  #checkov:skip=CKV_AWS_150:It is not expected that delete protection is required.
  name                             = "${var.resource_prefix}-nlb"
  internal                         = true
  load_balancer_type               = "network"
  enable_cross_zone_load_balancing = true
  subnet_mapping {
    subnet_id            = var.private_subnet_ids[0]
    private_ipv4_address = var.network_load_balancer_ips[0]
  }
  subnet_mapping {
    subnet_id            = var.private_subnet_ids[1]
    private_ipv4_address = var.network_load_balancer_ips[1]
  }

  subnet_mapping {
    subnet_id            = var.private_subnet_ids[2]
    private_ipv4_address = var.network_load_balancer_ips[2]
  }
}

##########################
# -- OpenCTI Platform -- #
# --     Internal     -- #
##########################

resource "aws_lb_listener" "opencti_platform" {
  load_balancer_arn = aws_lb.network.arn
  port              = var.opencti_platform_port
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.opencti_platform.arn
  }
}
resource "aws_lb_target_group" "opencti_platform" {
  name                   = "${var.resource_prefix}-nlb-opencti-target"
  port                   = var.opencti_platform_port
  protocol               = "TCP"
  target_type            = "ip"
  vpc_id                 = var.vpc_id
  deregistration_delay   = 2
  connection_termination = true
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    protocol            = "HTTP"
    interval            = 10
    path                = "/"
  }
}

######################
# -- RabbitMQ NLB -- #
# --    listener  -- #
######################

resource "aws_lb_listener" "rabbitmq_cluster" {
  load_balancer_arn = aws_lb.network.arn
  port              = var.rabbitmq_node_port
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.rabbitmq_cluster.arn
  }
}
resource "aws_lb_target_group" "rabbitmq_cluster" {
  name                   = "${var.resource_prefix}-nlb-rcluster-target"
  port                   = var.rabbitmq_node_port
  protocol               = "TCP"
  target_type            = "ip"
  vpc_id                 = var.vpc_id
  deregistration_delay   = 2
  connection_termination = true
  # We perform the Health Check on the RabbitMQ Management port as the NLB will
  # fail when performing a Health Check with HTTP against AMQP.
  health_check {
    enabled             = true
    port                = var.rabbitmq_management_port
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
  }
}

resource "aws_lb_listener" "rabbitmq_management" {
  load_balancer_arn = aws_lb.network.arn
  port              = var.rabbitmq_management_port
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.rabbitmq_management.arn
  }
}
resource "aws_lb_target_group" "rabbitmq_management" {
  name                   = "${var.resource_prefix}-nlb-rmanage-target"
  port                   = var.rabbitmq_management_port
  protocol               = "TCP"
  target_type            = "ip"
  vpc_id                 = var.vpc_id
  deregistration_delay   = 2
  connection_termination = true
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
  }
}
