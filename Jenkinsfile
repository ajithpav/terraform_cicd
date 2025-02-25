pipeline {
    agent any
    stages {
        stage('Setup Environment') {
            steps {
                sh 'python -m venv venv'
                sh '. venv/Scripts/activate && pip install --upgrade pip'
                sh '. venv/Scripts/activate && pip install -r requirements.txt'
            }
        }
        stage('Test') {
            steps {
                sh '. venv/Scripts/activate && pytest'
            }
        }
        stage('Deploy') {
            when {
                branch 'main'
            }
            steps {
                sh '. venv/Scripts/activate && python deploy.py'
            }
        }
    }
    post {
        always {
            echo "Pipeline completed"
        }
        success {
            echo "Pipeline succeeded"
        }
        failure {
            echo "Pipeline failed"
        }
    }
}
