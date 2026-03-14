# -- CloudWatch Monitoring and Alarms --

# - Variables -

variable "services_health_map" {
  type = map(object({
    url  = string
    path = string
  }))
  description = <<-EOF
  Values for the services to monitor, 
  with the service url and health check 
  path
  EOF
  default = {
    frontend = {
      url  = "mwalika.com"
      path = "/"
    },
    agent = {
      url  = "agent.mwalika.com"
      path = "/api/system/health"
    }
  }
}

variable "alarm_emails" {
  type        = list(string)
  description = "Email address to receive CloudWatch alarm notifications"
  default     = ["alvinnjiiri@gmail.com"]
}

# - SNS Topic and Subscriptions -

resource "aws_sns_topic" "health_alerts" {
  provider = aws.us_east_1
  name     = "mwalika-service-health-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  provider = aws.us_east_1
  for_each = toset(var.alarm_emails)

  topic_arn = aws_sns_topic.health_alerts.arn
  protocol  = "email"
  endpoint  = each.value
}

# - Health Checks -

resource "aws_route53_health_check" "mwalika_health_checks" {
  for_each = var.services_health_map

  fqdn              = each.value.url
  type              = "HTTPS"
  resource_path     = each.value.path
  port              = 443
  request_interval  = 30
  failure_threshold = 3
  enable_sni        = true
}

# - CloudWatch Alarms -

resource "aws_cloudwatch_metric_alarm" "hc_alarm" {
	provider = aws.us_east_1
	for_each = var.services_health_map

	alarm_name          = "mwalika-health-check-failure-${each.key}"
	namespace           = "AWS/Route53"
	metric_name         = "HealthCheckStatus"
	statistic           = "Minimum"
	period              = 60
	evaluation_periods  = 3
	threshold           = 1
	comparison_operator = "LessThanThreshold"

	dimensions = {
		HealthCheckId = (
      aws_route53_health_check.mwalika_health_checks[each.key].id
    )
	}

	alarm_actions = [aws_sns_topic.health_alerts.arn]
}
