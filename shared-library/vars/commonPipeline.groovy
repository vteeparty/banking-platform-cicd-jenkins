// ============================================================
// Banking Platform Shared Library — commonPipeline.groovy
// Global pipeline utilities shared across all Jenkinsfiles
// Register this library in Jenkins → Manage Jenkins →
//   Configure System → Global Pipeline Libraries
//   Name: banking-shared-library
// ============================================================

/**
 * Send a build status notification via e-mail and (optionally) Slack.
 *
 * @param args  Map with keys: status, appName, buildNumber, branch, commit
 */
def sendBuildNotification(Map args) {
    String status      = args.status      ?: 'UNKNOWN'
    String appName     = args.appName     ?: 'banking-platform'
    String buildNumber = args.buildNumber ?: env.BUILD_NUMBER
    String branch      = args.branch      ?: env.GIT_BRANCH ?: 'unknown'
    String commit      = args.commit      ?: 'unknown'
    String buildUrl    = env.BUILD_URL    ?: '#'

    String subject = "[${status}] ${appName} — Build #${buildNumber} (${branch})"
    String body    = """
Build Report
============
Application : ${appName}
Status      : ${status}
Build #     : ${buildNumber}
Branch      : ${branch}
Commit      : ${commit}
URL         : ${buildUrl}
Timestamp   : ${new Date().format('yyyy-MM-dd HH:mm:ss z')}
""".stripIndent()

    // E-mail notification (requires Mailer or Email Extension plugin)
    try {
        mail(
            to:      env.NOTIFY_EMAIL ?: 'devops@banking-platform.local',
            subject: subject,
            body:    body
        )
    } catch (Exception e) {
        echo "WARNING: e-mail notification failed — ${e.message}"
    }

    // Slack notification (requires Slack Notification plugin + SLACK_WEBHOOK env var)
    if (env.SLACK_WEBHOOK) {
        try {
            String color = (status == 'SUCCESS') ? 'good' : 'danger'
            slackSend(
                color:   color,
                message: "${subject}\n${buildUrl}"
            )
        } catch (Exception e) {
            echo "WARNING: Slack notification failed — ${e.message}"
        }
    }
}

/**
 * Enforce a mandatory SonarQube quality gate.
 * Aborts the pipeline if the gate fails.
 *
 * @param timeoutMinutes  How long to wait for the gate result (default 5)
 */
def enforceQualityGate(int timeoutMinutes = 5) {
    timeout(time: timeoutMinutes, unit: 'MINUTES') {
        def qg = waitForQualityGate()
        if (qg.status != 'OK') {
            error "SonarQube Quality Gate FAILED: ${qg.status}"
        }
        echo "SonarQube Quality Gate PASSED: ${qg.status}"
    }
}

/**
 * Build and optionally push a Docker image.
 *
 * @param imageName   Full image name, e.g. 'docker.io/banking-platform'
 * @param tag         Image tag
 * @param registryUrl Docker registry URL
 * @param credId      Jenkins credential ID for the registry
 * @param push        Whether to push after build (default true)
 */
def buildAndPushDockerImage(String imageName, String tag, String registryUrl, String credId, boolean push = true) {
    def img = docker.build("${imageName}:${tag}", '--no-cache .')
    echo "Docker image built: ${imageName}:${tag}"
    if (push) {
        docker.withRegistry(registryUrl, credId) {
            img.push(tag)
            img.push('latest')
        }
        echo "Docker image pushed: ${imageName}:${tag}"
    }
}

/**
 * Archive build artifacts and publish test reports.
 *
 * @param artifactPattern  Ant-style glob for artifacts
 * @param testPattern      Ant-style glob for JUnit XML reports
 */
def archiveResults(String artifactPattern = '**/target/*.jar, **/build/libs/*.jar',
                   String testPattern     = '**/surefire-reports/*.xml, **/test-results/**/*.xml') {
    archiveArtifacts artifacts: artifactPattern, allowEmptyArchive: true
    junit allowEmptyResults: true, testResults: testPattern
}
