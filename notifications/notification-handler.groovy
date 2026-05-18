// ============================================================
// Banking Platform — Notification Handler
// File: notifications/notification-handler.groovy
// Used by: commonPipeline.groovy (sendBuildNotification)
// ============================================================

/**
 * Resolve the Slack attachment color from a build status string.
 *
 * @param status  'SUCCESS', 'FAILURE', 'UNSTABLE', or 'ABORTED'
 * @return        Slack color string: 'good', 'danger', 'warning', or '#808080'
 */
static String resolveSlackColor(String status) {
    switch (status?.toUpperCase()) {
        case 'SUCCESS':  return 'good'
        case 'FAILURE':  return 'danger'
        case 'UNSTABLE': return 'warning'
        default:         return '#808080'
    }
}

/**
 * Render the e-mail template by substituting {{PLACEHOLDER}} tokens.
 *
 * @param templateText  Raw template string (load from notifications/email-template.txt)
 * @param vars          Map of placeholder-name → value pairs
 * @return              Rendered string with all placeholders replaced
 */
static String renderEmailTemplate(String templateText, Map<String, String> vars) {
    String rendered = templateText
    vars.each { key, value ->
        rendered = rendered.replace("{{${key}}}", value ?: '')
    }
    // Remove unresolved conditional blocks for whichever status did NOT apply
    rendered = rendered.replaceAll(/\{\{#IS_SUCCESS\}\}.*?\{\{\/IS_SUCCESS\}\}/s, '')
    rendered = rendered.replaceAll(/\{\{#IS_FAILURE\}\}.*?\{\{\/IS_FAILURE\}\}/s, '')
    return rendered
}

/**
 * Build the variable map for template rendering from the current build context.
 *
 * @param status   Build status string
 * @param script   The pipeline `this` (provides env, currentBuild)
 * @return         Map ready for renderEmailTemplate or Slack payload interpolation
 */
static Map<String, String> buildTemplateVars(String status, def script) {
    long nowEpoch = System.currentTimeMillis() / 1000L
    return [
        STATUS         : status,
        APP_NAME       : script.env.APP_NAME       ?: 'banking-platform',
        BUILD_NUMBER   : script.env.BUILD_NUMBER   ?: '0',
        BRANCH         : script.env.GIT_BRANCH     ?: 'unknown',
        COMMIT         : script.env.GIT_COMMIT_SHORT ?: 'unknown',
        BUILD_URL      : script.env.BUILD_URL      ?: '#',
        DOCKER_IMAGE   : script.env.DOCKER_IMAGE   ?: 'banking-platform',
        IMAGE_TAG      : script.env.BUILD_TAG_FULL ?: 'latest',
        TRIGGERED_BY   : script.currentBuild?.getBuildCauses()?.getAt(0)?.shortDescription ?: 'unknown',
        DURATION       : script.currentBuild?.durationString ?: 'unknown',
        TIMESTAMP      : new Date().format('yyyy-MM-dd HH:mm:ss z'),
        TIMESTAMP_EPOCH: "${nowEpoch}",
        COLOR          : resolveSlackColor(status),
        IS_SUCCESS     : (status == 'SUCCESS') ? 'true' : '',
        IS_FAILURE     : (status == 'FAILURE') ? 'true' : '',
        STAGE_SUMMARY  : buildStageSummary(script)
    ]
}

/**
 * Produce a plain-text table of stage names and their results.
 *
 * @param script  Pipeline script context
 * @return        Formatted string or a fallback message
 */
static String buildStageSummary(def script) {
    try {
        def stages = script.currentBuild?.rawBuild
            ?.getAction(org.jenkinsci.plugins.workflow.job.views.FlowGraphAction)
            ?.getNodes()
        if (!stages) {
            return '(stage summary not available)'
        }
        StringBuilder sb = new StringBuilder()
        stages.each { node ->
            if (node.getDisplayName()) {
                sb.append(String.format('  %-30s %s%n',
                    node.getDisplayName(),
                    node.getError() ? 'FAILED' : 'OK'))
            }
        }
        return sb.toString() ?: '(no stages recorded)'
    } catch (Exception ignored) {
        return '(stage summary not available)'
    }
}
