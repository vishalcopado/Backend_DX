public with sharing class RefreshMetadataCallout {
    private final static Integer MIN_TIME_INTERVAL_FOR_METADATA_REFRESH_IN_MINUTES = 1;
    @TestVisible
    private static final String METADATA_FILE_NAME = 'MetaData';
    // PUBLIC

    @InvocableMethod(label='Refresh Metadata callout' category='2nd Gen Git Snapshot')
    public static List<Response> execute(List<Request> request) {
        List<Response> response;
        try {
            Id credentialId = request[0].credentialId;
            Id resultId = request[0].resultId;
            String scope = getScope(resultId);
            String jobId;
            String errorMessage;
            List<ContentDocumentLink> contentDocumentLinks = getContentDocumentLinks(credentialId, METADATA_FILE_NAME);
            List<ContentVersion> contentVersions = !contentDocumentLinks.isEmpty()
                ? getContentVersions(contentDocumentLinks[0].ContentDocumentId)
                : new List<ContentVersion>();
            if (scope == null) {
                errorMessage = Label.Snapshot_Empty_Scope_Banner;
            } else if (skipStep(scope)) {
                publishSuccessEvent('{\"message\": \"' + Label.Snapshot_Refresh_Metadata_Step_Skip + '\"}', resultId);
            } else if (validateIntervalForRefresh(contentVersions)) {
                refreshOrgMetadataCache(credentialId);
                String nextFireCron = calculateNextFireCron();
                jobId = System.schedule(
                    'Poll Copado Notification for Refresh Metadata ' + nextFireCron,
                    nextFireCron,
                    new PollCopadoNotification(credentialId, null, resultId, 0)
                );
            } else {
                Id contentVersionId = contentVersions[0].Id;
                publishSuccessEvent('{\"contentVersionId\": \"' + contentVersionId + '\"}', resultId);
            }

            response = new List<Response>{ new Response(jobId, errorMessage) };
        } catch (Exception ex) {
            response = new List<Response>{ new Response('', ex.getMessage()) };
        }
        return response;
    }

    @SuppressWarnings('PMD.EmptyCatchBlock')
    private static Boolean skipStep(String scope) {
        Boolean result = false;
        try {
            Map<String, Object> scopeObj = (Map<String, Object>) JSON.deserializeUntyped(scope);
            if (scopeObj.get('SFDX') == null) {
                result = true;
            }
        } catch (Exception error) {
            // Exception means could not deserialize JSON, presvious version doesn't contain JSON. Handling previous version by making result false.
        }
        return result;
    }

    private static String getScope(Id resultId) {
        String result = '';
        List<copado__Result__c> results = new ResultsSelector().byIdsForSnapshot(new Set<Id>{ resultId });

        if (!results.isEmpty()) {
            result = results[0].copado__JobStep__r.copado__JobExecution__r.copado__Snapshot__r.copado__Scope__c;
        }
        return result;
    }

    private static void refreshOrgMetadataCache(Id credentialId) {
        if (!Test.isRunningTest()) {
            copado.RefreshOrgMetadataCache.InvocableVariables invocableVariable = new copado.RefreshOrgMetadataCache.InvocableVariables();
            invocableVariable.orgId = credentialId;
            invocableVariable.isMetadataSavedToFile = true;
            invocableVariable.queryParameters = new Set<String>{ 'dates=format' };
            copado.RefreshOrgMetadataCache.executeRefresh(invocableVariable);
        }
    }

    private static String calculateNextFireCron() {
        CronCalculator result = new CronCalculator();
        return result.nextFireCron(3);
    }

    private static Boolean validateIntervalForRefresh(List<ContentVersion> contentVersions) {
        Boolean result = true;
        if (!contentVersions.isEmpty()) {
            result = validateRefreshTimeInterval(Datetime.now(), contentVersions[0].LastModifiedDate);
        }
        return result;
    }

    private static Boolean validateRefreshTimeInterval(Datetime startTimeStamp, Datetime endTimeStamp) {
        Long timeDifferenceInMinutes = (startTimeStamp.getTime() - endTimeStamp.getTime()) / (1000 * 60);
        return timeDifferenceInMinutes > MIN_TIME_INTERVAL_FOR_METADATA_REFRESH_IN_MINUTES;
    }

    private static void publishSuccessEvent(String data, Id resultId) {
        new EventPayload(true, '', data).publish(resultId);
    }

    private static List<ContentDocumentLink> getContentDocumentLinks(Id linkedEntityId, String title) {
        List<ContentDocumentLink> result = new ContentDocumentLinksSelector()
            .byLinkedEntityIdAndTitles(new Set<Id>{ linkedEntityId }, new Set<String>{ title });
        return result;
    }

    private static List<ContentVersion> getContentVersions(Id contentDocumentId) {
        List<ContentVersion> result = contentDocumentId != null
            ? new ContentVersionsSelector().byContentDocumentId(new Set<Id>{ contentDocumentId })
            : new List<ContentVersion>();
        return result;
    }

    // INNER

    public class Request {
        @InvocableVariable
        public Id credentialId;
        @InvocableVariable
        public Id resultId;
    }

    public class Response {
        @InvocableVariable
        public String result;
        @InvocableVariable
        public String message;

        public Response(String result, String message) {
            this.result = result;
            this.message = message;
        }
    }
}