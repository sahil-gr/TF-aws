output "alb_bucket_id" {
  value = aws_s3_bucket.alb.id
  depends_on = [
    aws_s3_bucket_policy.alb,
    aws_s3_bucket_public_access_block.alb,
    aws_s3_bucket_server_side_encryption_configuration.alb
  ]
}
output "web_log_group_name" { value = aws_cloudwatch_log_group.web.name }
output "web_log_group_arn" { value = aws_cloudwatch_log_group.web.arn }
