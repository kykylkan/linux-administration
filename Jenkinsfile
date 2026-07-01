// Jenkinsfile — CI/CD пайплайн для Django-застосунку
//
// Кроки:
//   1. Checkout коду застосунку (цей репозиторій)
//   2. Збірка Docker-образу через Kaniko (без Docker daemon)
//   3. Push образу в Amazon ECR з тегом ${GIT_COMMIT_SHORT}-${BUILD_NUMBER}
//   4. Checkout GitOps-репозиторію з Helm chart
//   5. Оновлення image.tag у values.yaml Helm chart
//   6. Commit + push змін у main гілку GitOps-репозиторію
//   7. (далі Argo CD сам підхоплює зміни і синхронізує кластер)
//
// Пайплайн виконується на Kubernetes-агенті Jenkins (label "kaniko"),
// що піднімається подом із контейнерами jnlp + kaniko + git
// (конфігурація агента: modules/jenkins/values.yaml).

pipeline {
    agent {
        kubernetes {
            label 'kaniko'
        }
    }

    environment {
        ECR_REPO_URL   = "${ECR_REPO_URL}"           // передається з Helm values агента
        AWS_REGION     = "${AWS_REGION}"              // передається з Helm values агента
        GITOPS_REPO    = 'https://github.com/<your-account>/lesson-8-9-gitops.git'
        GITOPS_BRANCH  = 'main'
        CHART_PATH     = 'charts/django-app'
        IMAGE_TAG      = "${env.GIT_COMMIT?.take(7) ?: 'latest'}-${env.BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build & Push image (Kaniko)') {
            steps {
                container('kaniko') {
                    sh '''
                        /kaniko/executor \
                          --context `pwd` \
                          --dockerfile `pwd`/Dockerfile \
                          --destination ${ECR_REPO_URL}:${IMAGE_TAG} \
                          --destination ${ECR_REPO_URL}:latest \
                          --cache=true
                    '''
                }
            }
        }

        stage('Update GitOps repo (Helm values.yaml)') {
            steps {
                container('git') {
                    withCredentials([usernamePassword(
                        credentialsId: 'gitops-repo-credentials',
                        usernameVariable: 'GIT_USER',
                        passwordVariable: 'GIT_TOKEN'
                    )]) {
                        sh '''
                            rm -rf gitops
                            git clone https://${GIT_USER}:${GIT_TOKEN}@$(echo ${GITOPS_REPO} | sed 's#https://##') gitops
                            cd gitops
                            git checkout ${GITOPS_BRANCH}

                            # Оновлюємо image.tag у values.yaml Helm chart
                            sed -i "s|tag: .*|tag: \\"${IMAGE_TAG}\\"|" ${CHART_PATH}/values.yaml

                            git config user.email "jenkins-ci@example.com"
                            git config user.name "Jenkins CI"
                            git add ${CHART_PATH}/values.yaml
                            git commit -m "ci: update django-app image tag to ${IMAGE_TAG}" || echo "No changes to commit"
                            git push origin ${GITOPS_BRANCH}
                        '''
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ Образ ${ECR_REPO_URL}:${IMAGE_TAG} зібрано, запушено в ECR, Helm chart оновлено. Argo CD синхронізує зміни автоматично."
        }
        failure {
            echo "❌ Пайплайн завершився з помилкою. Перевірте логи вище."
        }
    }
}
