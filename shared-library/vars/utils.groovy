// ============================================================
// Banking Platform Shared Library — utils.groovy
// Low-level helper utilities used across pipelines
// ============================================================

/**
 * Print a formatted summary of the current build environment.
 * Call this early in the pipeline to aid debugging.
 */
def printBuildInfo() {
    echo """
╔══════════════════════════════════════════╗
║        Banking Platform — Build Info     ║
╠══════════════════════════════════════════╣
║  Job Name    : ${env.JOB_NAME}
║  Build #     : ${env.BUILD_NUMBER}
║  Branch      : ${env.GIT_BRANCH ?: 'unknown'}
║  Commit      : ${env.GIT_COMMIT ?: 'unknown'}
║  Node        : ${env.NODE_NAME}
║  Workspace   : ${env.WORKSPACE}
║  Build URL   : ${env.BUILD_URL}
╚══════════════════════════════════════════╝
""".stripIndent()
}

/**
 * Determine whether the current branch is the main/release branch.
 *
 * @return true if running on main or master
 */
boolean isMainBranch() {
    String branch = env.GIT_BRANCH ?: ''
    return branch == 'main' || branch == 'master' ||
           branch == 'origin/main' || branch == 'origin/master'
}

/**
 * Determine whether the current build was triggered by a pull request.
 *
 * @return true if the branch name indicates a PR
 */
boolean isPullRequest() {
    String branch = env.GIT_BRANCH ?: ''
    return branch.startsWith('PR-') || branch.contains('/PR-')
}

/**
 * Construct a Docker image tag from the build number and short commit hash.
 *
 * @param buildNumber  Jenkins BUILD_NUMBER
 * @param commitShort  Short (7-char) git commit hash
 * @return             Tag string, e.g. '42-a1b2c3d'
 */
String buildDockerTag(String buildNumber = env.BUILD_NUMBER,
                      String commitShort = env.GIT_COMMIT_SHORT ?: 'unknown') {
    return "${buildNumber}-${commitShort}"
}

/**
 * Fail the build with a descriptive error message.
 *
 * @param message  Human-readable reason for the failure
 */
void failBuild(String message) {
    error("[BANKING-CI] Build aborted: ${message}")
}

/**
 * Run a shell command and return its trimmed stdout.
 * Throws if the command exits with a non-zero status.
 *
 * @param cmd  Shell command string
 * @return     Trimmed stdout string
 */
String shellOutput(String cmd) {
    return sh(script: cmd, returnStdout: true).trim()
}

/**
 * Check that a required environment variable is set and non-empty.
 * Aborts the build if the variable is missing.
 *
 * @param varName  Name of the environment variable
 */
void requireEnvVar(String varName) {
    if (!env[varName]) {
        failBuild("Required environment variable '${varName}' is not set.")
    }
    echo "ENV CHECK PASSED: ${varName} is set."
}

/**
 * Sleep with a visible countdown log (useful between retries).
 *
 * @param seconds  Number of seconds to wait
 */
void waitWithLog(int seconds) {
    echo "Waiting ${seconds}s..."
    sleep(time: seconds, unit: 'SECONDS')
}
