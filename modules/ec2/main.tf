resource "aws_launch_template" "this" {
  name_prefix            = "${var.name}-"
  image_id               = var.ami_id
  instance_type          = var.instance_type
  update_default_version = true
  user_data = base64encode(templatefile("${path.module}/user_data.sh.tftpl", {
    region           = var.region
    log_group_name   = var.log_group_name
    page_html_base64 = filebase64("${path.module}/index.html")
  }))

  iam_instance_profile { name = var.instance_profile_name }
  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.security_group_id]
    delete_on_termination       = true
  }
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "disabled"
  }
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      encrypted             = true
      volume_type           = "gp3"
      volume_size           = 20
      delete_on_termination = true
    }
  }
  monitoring { enabled = true }
  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${var.name}-nginx" }
  }
  tag_specifications {
    resource_type = "volume"
    tags          = { Name = "${var.name}-nginx-root" }
  }
}

resource "aws_autoscaling_group" "this" {
  name_prefix               = "${var.name}-"
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = var.private_subnet_ids
  target_group_arns         = [var.target_group_arn]
  health_check_type         = "ELB"
  health_check_grace_period = 600
  default_instance_warmup   = 300
  wait_for_capacity_timeout = "15m"
  min_elb_capacity          = var.min_size
  enabled_metrics           = ["GroupDesiredCapacity", "GroupInServiceInstances", "GroupTotalInstances"]

  launch_template {
    id      = aws_launch_template.this.id
    version = tostring(aws_launch_template.this.latest_version)
  }
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 100
      max_healthy_percentage = 150
      instance_warmup        = 300
      auto_rollback          = true
    }
  }
  dynamic "tag" {
    for_each = merge(var.tags, { Name = "${var.name}-nginx" })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
  lifecycle {
    ignore_changes = [desired_capacity]
    precondition {
      condition     = var.min_size >= 2 && var.desired_capacity >= var.min_size && var.max_size >= var.desired_capacity
      error_message = "Require 2 <= min_size <= desired_capacity <= max_size."
    }
  }
}

resource "aws_autoscaling_policy" "cpu" {
  name                   = "${var.name}-cpu"
  autoscaling_group_name = aws_autoscaling_group.this.name
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification { predefined_metric_type = "ASGAverageCPUUtilization" }
    target_value = 60
  }
}
