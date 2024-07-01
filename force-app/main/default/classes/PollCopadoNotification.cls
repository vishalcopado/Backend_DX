public with sharing class PollCopadoNotification implements Schedulable {
    private Id parentId;
    private Id recordId;
    private Id resultId;
    private Integer iteration;

    @TestVisible
    private static final String METADATA_FILE_NAME = 'MetaData';

    // CTR
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public PollCopadoNotification(Id credentialId, Id recordId, Id resultId, Integer iteration) {
        this.parentId = credentialId;
        this.recordId = recordId;
        this.resultId = resultId;
        this.iteration = iteration;
    }

    // PUBLIC
    public void execute(SchedulableContext sc) {
        try {
            List<copado__Copado_Notification__c> copadoNotifications = new CopadoNotificationSelector()
                .byParentIdsAndFinishedFlag(new Set<Id>{ parentId }, false);

            if (recordId == null && copadoNotifications.isEmpty()) {
                // 120 iterations are 10 minutes not receiving Copado Notification RecordId
                if (iteration > 120) {
                    publishFailureEvent('Time Out', resultId);
                    return;
                }
                iteration++;
                scheduleJob(parentId, null, resultId, iteration);
            } else {
                recordId = recordId == null ? copadoNotifications[0].Id : recordId;
                List<copado__Copado_Notification__c> notification = new CopadoNotificationSelector().byIds(new Set<Id>{ recordId });
                String status = getJobStatus(notification[0]);
                switch on status {
                    when 'Success' {
                        List<ContentDocumentLink> contentDocumentLinks = getContentDocumentLinks(
                            notification[0].copado__ParentId__c,
                            METADATA_FILE_NAME
                        );
                        if (contentDocumentLinks.isEmpty()) {
                            throw new ApplicationException(Label.No_Metadata_File_Found);
                        } else if (contentDocumentLinks.size() > 1) {
                            UserStoryMetadataListCtlr.executeFunctionToFindDeletedMetadata(notification[0].copado__ParentId__c);
                        }
                        List<ContentVersion> contentVersions = getContentVersions(contentDocumentLinks[0].ContentDocumentId);
                        publishSuccessEvent(contentVersions[0].Id, resultId);
                    }
                    when 'Error' {
                        String errorMessage = getErrorMessages(notification[0].copado__Message__c);
                        publishFailureEvent(errorMessage, resultId);
                    }
                    when else {
                        scheduleJob(null, notification[0].Id, resultId, 0);
                    }
                }
            }
        } catch (Exception ex) {
            publishFailureEvent('Error: ' + ex.getMessage() + ' ' + ex.getStackTraceString(), resultId);
        }
    }

    // PRIVATE

    private String getJobStatus(copado__Copado_Notification__c notification) {
        String result = 'In Progress';
        if (notification.copado__isFinished__c == true && notification.copado__status__c == 'done' && notification.copado__isSuccess__c == true) {
            result = 'Success';
        } else if (
            notification.copado__isFinished__c == true &&
            notification.copado__status__c == 'done' &&
            notification.copado__isSuccess__c == false
        ) {
            result = 'Error';
        }
        return result;
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private void scheduleJob(Id credentialId, Id recordId, Id resultId, Integer iteration) {
        String nextFireCron = calculateNextFireCron();
        System.schedule(
            'Poll Copado Notification for Refresh Metadata ' + nextFireCron,
            nextFireCron,
            new PollCopadoNotification(credentialId, recordId, resultId, iteration)
        );
    }

    private String calculateNextFireCron() {
        CronCalculator result = new CronCalculator();
        return result.nextFireCron(5);
    }

    private void publishFailureEvent(String message, Id resultId) {
        new EventPayload(false, message).publish(resultId);
    }

    private void publishSuccessEvent(Id contentVersionId, Id resultId) {
        new EventPayload(true, '', '{\"contentVersionId\": \"' + contentVersionId + '\"}').publish(resultId);
    }

    private String getErrorMessages(String payload) {
        List<String> messages = ((Notification) JSON.deserialize(payload, Notification.class)).messages;
        return String.join(messages, '\r\n');
    }

    private static List<ContentDocumentLink> getContentDocumentLinks(Id linkedEntityId, String title) {
        List<ContentDocumentLink> result = new ContentDocumentLinksSelector()
            .byLinkedEntityIdAndTitles(new Set<Id>{ linkedEntityId }, new Set<String>{ title });
        return result;
    }

    private static List<ContentVersion> getContentVersions(Id contentDocumentId) {
        List<ContentVersion> result = new ContentVersionsSelector().byContentDocumentId(new Set<Id>{ contentDocumentId });
        return result;
    }

    // INNER
    private class Notification {
        public List<String> messages;
    }
}