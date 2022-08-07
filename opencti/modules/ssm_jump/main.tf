data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Fetch latest Amazon Linux 2 EC2 AMI Image
data "aws_ami_ids" "this" {
  owners = ["amazon"]
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  # https://docs.aws.amazon.com/systems-manager/latest/userguide/ami-preinstalled-agent.html
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2*"]
  }

}

#################################
# -- AWS EC2 Launch Template -- #
#################################
resource "aws_launch_template" "this" {
  name                   = "${var.resource_prefix}-jump-launch"
  image_id               = data.aws_ami_ids.this.ids[0]
  instance_type          = "t3.micro"
  update_default_version = true
  metadata_options {
    http_tokens = "required"
  }
  iam_instance_profile {
    arn = aws_iam_instance_profile.this.arn
  }
  vpc_security_group_ids = [
    aws_security_group.this.id
  ]
  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.resource_prefix}-ssm-jump-box"
    }
  }
  lifecycle {
    create_before_destroy = true
  }
}

###########################
# -- AutoScaling Group -- #
###########################
resource "aws_autoscaling_group" "this" {
  name = "${var.resource_prefix}-jump"
  #checkov:skip=CKV_AWS_153:Tags are defined within the Launch Template configuration.
  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }
  vpc_zone_identifier = var.private_subnet_ids

  min_size = 1
  max_size = 1
}
######################
# -- EC2 IAM Role -- #
######################
resource "aws_iam_instance_profile" "this" {
  name = "${var.resource_prefix}-jump-box-ec2-profile"
  role = aws_iam_role.this.name
}

resource "aws_iam_role" "this" {
  name                = "${var.resource_prefix}-jump-box-iam-role"
  assume_role_policy  = data.aws_iam_policy_document.this.json
  # IAM Policy cannot be restricted to specific account
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
}
data "aws_iam_policy_document" "this" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

##############################
# -- Jump Box Instance SG -- #
##############################
resource "aws_security_group" "this" {
  name        = "${var.resource_prefix}-jumpbox-sg"
  vpc_id      = var.vpc_id
  description = "SSM Jump Box"
  egress {
    description = "Access to internet"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  lifecycle {
    create_before_destroy = true
  }
}
