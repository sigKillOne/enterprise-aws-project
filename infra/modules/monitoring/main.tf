# infra/modules/monitoring/main.tf

# ---------------------------------------------------------
# NOTIFICATIONS (SNS)
# ---------------------------------------------------------

# 1. Create the SNS Topic (The megaphone)
resource "aws_sns_topic" "cpu_alerts" {
  name = "enterprise-cpu-alerts"
}

# 2. Subscribe your email to the topic
resource "aws_sns_topic_subscription" "email_target" {
  topic_arn = aws_sns_topic.cpu_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ---------------------------------------------------------
# MONITORING (CloudWatch)
# ---------------------------------------------------------

# 3. Create the CloudWatch Metric Alarm
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "enterprise-high-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2" # Must be over the threshold for 2 consecutive periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60" # 60 seconds (1 minute checks)
  statistic           = "Average"
  threshold           = "70" # Trigger if CPU hits 70%
  alarm_description   = "Triggers if App Server CPU exceeds 70%"
  
  # When the alarm trips, send a message to the SNS megaphone
  alarm_actions       = [aws_sns_topic.cpu_alerts.arn]

  # Tells CloudWatch exactly which specific server to watch
  dimensions = {
    InstanceId = var.app_server_id
  }
}
