output "instance_profile_name" {
  value      = aws_iam_instance_profile.this.name
  depends_on = [aws_iam_role_policy_attachment.ssm, aws_iam_role_policy.logs]
}
