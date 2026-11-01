# Assignment: Infrastructure is deployed, but the website fails

## Scenario

Deploy this repository in your own AWS lab account through Jenkins. One deliberate configuration fault prevents the intended webpage from loading through the ALB DNS name. Terraform should complete successfully when account setup, permissions and prerequisites are correct. Find and fix the fault using evidence.

## Requirements

- Use the existing public ALB and private EC2 architecture.
- Keep the security groups restricted as designed; do not add public IPs or SSH access to the application instances.
- Keep the existing health-check configuration and Auto Scaling behavior.
- Make the permanent fix in the repository and deploy it through an approved Jenkins APPLY.
- Do not treat a manual edit on one instance as a permanent fix.

## Investigation

1. Record the Jenkins result and the HTTP status and response received from the ALB URL.
2. Check the target group's health status and explain what that proves—and what it does not prove.
3. Use Systems Manager Session Manager to inspect an application instance. Compare the application response locally with the response through the ALB.
4. Inspect the web-server service, configuration, logs and deployed files. Identify evidence that explains the failure.
5. Propose the smallest configuration change that fixes the cause. Review its Terraform plan before applying it.
6. Wait for any instance refresh to finish. Verify the fix through the ALB and on the replacement instances.

## Acceptance criteria

- The ALB root URL returns HTTP 200 and the intended Nginx welcome page with instance details.
- `/healthz` continues to return HTTP 200.
- Targets remain healthy and application instances remain private.
- A newly launched replacement instance serves the corrected page without manual edits.
- Explain why successful Terraform deployment and healthy targets did not guarantee the homepage worked.


Submit your Git commit, relevant command output or screenshots, and a brief incident report. Use the README's teardown instructions to remove your lab resources when finished.
