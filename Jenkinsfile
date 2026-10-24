pipeline {
    // Run on this Jenkins controller EC2, with Terraform on PATH and an AWS role.
    agent { label 'built-in' }

    options {
        skipDefaultCheckout(true)
        disableConcurrentBuilds()
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '20'))
        timeout(time: 90, unit: 'MINUTES')
    }

    parameters {
        choice(name: 'ACTION', choices: ['PLAN', 'APPLY'],
            description: 'PLAN previews changes. APPLY also requires approval of the saved plan on main.')
    }

    environment {
        TF_IN_AUTOMATION = 'true'
        TF_INPUT = 'false'
        TF_ROOT = 'environments/production'
        PLAN_HAS_CHANGES = 'false'
        // Jenkins user IDs or group names; configure this group before deployment.
        PRODUCTION_APPROVERS = 'terraform-production-approvers'
    }

    stages {
        stage('Checkout') {
            steps {
                deleteDir()
                checkout scm
                sh 'terraform version'
            }
        }

        stage('Format') {
            steps {
                sh 'terraform fmt -check -recursive -no-color'
            }
        }

        stage('Validate and test') {
            steps {
                dir(env.TF_ROOT) {
                    sh '''
                        set -eu
                        terraform init -backend=false -input=false -no-color
                        terraform validate -no-color
                        terraform test -no-color
                    '''
                }
            }
        }

        stage('Production plan') {
            // Remote state and production planning are only used on trusted main.
            when { branch 'main' }
            steps {
                dir(env.TF_ROOT) {
                    // Terraform automatically loads the committed terraform.tfvars.
                    sh '''
                        set -eu
                        terraform init -reconfigure -input=false -no-color
                    '''
                    script {
                        int status = sh(
                            label: 'Create production plan (0=no changes, 2=changes)',
                            returnStatus: true,
                            script: '''
                                terraform plan -input=false -no-color -lock-timeout=5m \
                                    -detailed-exitcode -out=production.tfplan
                            '''
                        )
                        if (status == 2) {
                            env.PLAN_HAS_CHANGES = 'true'
                        } else if (status != 0) {
                            error("Terraform plan failed with exit code ${status}.")
                        } else {
                            echo 'No infrastructure changes required.'
                        }
                    }
                }
            }
        }
        stage('Approve production apply') {
            when {
                allOf {
                    branch 'main'
                    expression { params.ACTION == 'APPLY' && env.PLAN_HAS_CHANGES == 'true' }
                }
            }
            steps {
                timeout(time: 20, unit: 'MINUTES') {
                    input message: "Review the production plan in build ${env.BUILD_NUMBER} before applying.",
                        ok: 'Apply saved plan',
                        submitter: env.PRODUCTION_APPROVERS,
                        submitterParameter: 'APPROVED_BY'
                }
            }
        }

        stage('Apply production') {
            when {
                allOf {
                    branch 'main'
                    expression { params.ACTION == 'APPLY' && env.PLAN_HAS_CHANGES == 'true' }
                }
            }
            steps {
                dir(env.TF_ROOT) {
                    // Uses this EC2 instance's AWS role through the AWS credential chain.
                    // Apply exactly the approved binary plan; never generate a new one here.
                    sh '''
                        set -eu
                        terraform apply -input=false -no-color -lock-timeout=5m production.tfplan
                    '''
                }
            }
        }
    }

    post {
        always {
            // Saved plans and .terraform backend metadata can contain sensitive data.
            // Do not archive or stash them, or retain them in a reused workspace.
            deleteDir()
        }
    }
}

