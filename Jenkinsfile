pipeline {
    agent any

    tools {
        nodejs 'NodeJS'
    }
    
    environment {
        // AWS credentials configured in Jenkins. Make sure to replace 'aws-deploy-credentials' with the actual ID of your credentials in Jenkins.git 
        AWS_CREDENTIALS = credentials('aws-deploy-credentials')
        AWS_REGION = 'us-west-2'
        
        // Update these with values from: terraform output
        S3_BUCKET = 'esther-devops-bucket-2026'  // Change to your bucket
        CLOUDFRONT_DISTRIBUTION_ID = 'E38JMDHCNCGA6Q' // Change to your distribution ID, triggering a cache invalidation after deployment
    }
    
    stages {
        stage('Clone repo') {
            steps {
                git branch: 'master', url:'https://github.com/essiewakukha/jenkins-walkthrough'
                echo "Code checked out from ${echo "Code checked out from ${env.BRANCH_NAME}"}"
            }
        }

        
        stage('Install Dependencies') {
            steps {
                sh 'npm install'
                echo "Dependencies installed"
            }
        }
        
        stage('Lint') {
            steps {
                sh 'npm run lint'
                echo "Code linting passed"
            }
        }
        
        stage('Test') {
            steps {
                sh 'npm test'
                echo "Unit tests passed"
            }
        }
        
        stage('Build') {
            steps {
                sh 'npm run build'
                echo "Production build created"
                sh 'ls -la dist/'
            }
        }
        
        stage('Deploy to S3') {
    steps {
        withCredentials([
            [$class: 'AmazonWebServicesCredentialsBinding',
             credentialsId: 'aws-deploy-credentials',
             accessKeyVariable: 'AWS_ACCESS_KEY_ID',
             secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']
        ]) {
            sh '''
                export AWS_DEFAULT_REGION=${AWS_REGION}
                echo "Deploying to S3..."
                aws s3 sync dist/ s3://${S3_BUCKET} 
                echo "Deployment complete"
            '''
        }
    }
}
        
        stage('Invalidate CloudFront Cache') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-deploy-credentials', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
                    sh '''
                        export AWS_DEFAULT_REGION=${AWS_REGION}
                        echo "Invalidating CloudFront cache..."
                        aws cloudfront create-invalidation \
                            --distribution-id ${CLOUDFRONT_DISTRIBUTION_ID} \
                            --paths "/*"
                        echo "CloudFront cache invalidated"
                    '''
                }
            }
        }
    }
    
    post {
        success {
            echo """
            ========================================
            DEPLOYMENT SUCCESSFUL!
            ========================================
            Site is live at:
            https://${CLOUDFRONT_DISTRIBUTION_ID}
            
            S3 Bucket: ${S3_BUCKET}
            CloudFront Distribution: ${CLOUDFRONT_DISTRIBUTION_ID}
            Build: ${BUILD_NUMBER}
            ========================================
            """
        }
        
        failure {
            echo "Deployment failed. Check logs above for details."
        }
        
        always {
            cleanWs()
        }
    }
}
