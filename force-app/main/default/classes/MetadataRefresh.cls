public with sharing class MetadataRefresh {
    /*
        This variable holds the minimum time interval (in minutes)
        which is required to restart the metadata refresh job in backend side
    */
    @TestVisible
    private final static Integer MIN_INTERVAL_FOR_METADATA_REFRESH_OLD_PAGE = 6;
    @TestVisible
    private final static Integer MIN_INTERVAL_FOR_METADATA_REFRESH_NEW_PAGE = 1;
    @TestVisible
    private final static String INFO = 'info';

    // PUBLIC

    @AuraEnabled
    public static Response execute(Id credentialId, MetadataRefreshDetails metadataRefreshDetails) {
        Response result = new Response(true, null, null);
        validateCredentialId(credentialId);
        try {
            /*
                Validate if there is already a copado notification record (which is still not finished) present for the credential,
                if there is, then no need to run the backend job.
            */
            if (!hasNotification(credentialId)) {
                Boolean isMetadataSavedToFile = metadataRefreshDetails?.isMetadataSavedToFile;
                Boolean isRefreshValid = isMetadataSavedToFile
                    ? isFileContentValid(credentialId, metadataRefreshDetails)
                    : isAttachmentValid(credentialId, metadataRefreshDetails);
                if (isRefreshValid) {
                    requestMetadataRefresh(credentialId, metadataRefreshDetails);
                } else {
                    result = new Response(
                        false,
                        String.format(
                            Label.Metadata_Refresh_Job_Cannot_Be_Executed,
                            new List<Object>{
                                isMetadataSavedToFile ? MIN_INTERVAL_FOR_METADATA_REFRESH_NEW_PAGE : MIN_INTERVAL_FOR_METADATA_REFRESH_OLD_PAGE
                            }
                        ),
                        INFO
                    );
                }
            } else {
                result = new Response(false, Label.Metadata_Refresh_Job_Already_In_Progress, INFO);
            }
        } catch (Exception ex) {
            result = new Response(false, ex.getMessage(), null);
        }
        return result;
    }

    // PRIVATE

    private static void requestMetadataRefresh(Id credentialId, MetadataRefreshDetails metadataRefreshDetails) {
        Boolean isMetadataSavedToFile = metadataRefreshDetails?.isMetadataSavedToFile;
        if (isMetadataSavedToFile) {
            refreshOrgMetadataCacheWithFile(credentialId, metadataRefreshDetails?.selectedMetadata, isMetadataSavedToFile);
        } else {
            refreshOrgMetadataCache(credentialId);
        }
    }

    private static Boolean hasNotification(Id credentialId) {
        List<copado__Copado_Notification__c> copadoNotifications = new CopadoNotificationSelector()
            .byParentIdsAndFinishedFlag(new Set<Id>{ credentialId }, false);
        return !copadoNotifications.isEmpty();
    }

    private static Boolean isAttachmentValid(Id credentialId, MetadataRefreshDetails metadataRefreshDetails) {
        Boolean result = true;
        List<Attachment> attachments = new AttachmentsSelector()
            .byParentIdsAndNames(new Set<Id>{ credentialId }, new Set<String>{ metadataRefreshDetails.name }, 1);
        if (!attachments.isEmpty()) {
            result = isRefreshTimeIntervalValid(Datetime.now(), attachments[0].LastModifiedDate, metadataRefreshDetails?.isMetadataSavedToFile);
        }
        return result;
    }

    private static Boolean isFileContentValid(Id credentialId, MetadataRefreshDetails metadataRefreshDetails) {
        Boolean result = true;
        List<ContentVersion> latestContentVersion = getContentVersionsByLinkedEntinityAndFileName(credentialId, metadataRefreshDetails.name);
        if (!latestContentVersion.isEmpty()) {
            result = isRefreshTimeIntervalValid(
                Datetime.now(),
                latestContentVersion[0].LastModifiedDate,
                metadataRefreshDetails?.isMetadataSavedToFile
            );
        }
        return result;
    }

    private static void validateCredentialId(Id credentialId) {
        if (String.isBlank(credentialId)) {
            throw new ApplicationException(Label.Credential_Not_Found);
        }
    }

    private static Long getDatetimeDiffInMinutes(Datetime startTimeStamp, Datetime endTimeStamp) {
        return (startTimeStamp.getTime() - endTimeStamp.getTime()) / (1000 * 60);
    }

    private static Boolean isRefreshTimeIntervalValid(Datetime startTimeStamp, Datetime endTimeStamp, Boolean isMetadataSavedToFile) {
        return getDatetimeDiffInMinutes(startTimeStamp, endTimeStamp) >
            (isMetadataSavedToFile ? MIN_INTERVAL_FOR_METADATA_REFRESH_NEW_PAGE : MIN_INTERVAL_FOR_METADATA_REFRESH_OLD_PAGE);
    }

    private static void refreshOrgMetadataCache(Id credentialId) {
        if (!Test.isRunningTest()) {
            copado.RefreshOrgMetadataCache.InvocableVariables invocableVariable = new copado.RefreshOrgMetadataCache.InvocableVariables();
            invocableVariable.orgId = credentialId;
            copado.RefreshOrgMetadataCache.execute(new List<copado.RefreshOrgMetadataCache.InvocableVariables>{ invocableVariable });
        }
    }

    private static List<ContentVersion> getContentVersionsByLinkedEntinityAndFileName(Id byLinkedEntityId, String fileName) {
        List<ContentVersion> result = new List<ContentVersion>();
        List<ContentDocumentLink> packageVersionFileDetails = getContentDocumentLink(byLinkedEntityId, fileName);
        if (!packageVersionFileDetails.isEmpty()) {
            result = new ContentVersionsSelector().byContentDocumentIdWithLatest(new Set<Id>{ packageVersionFileDetails[0].ContentDocumentId });
        }
        return result;
    }

    private static List<ContentDocumentLink> getContentDocumentLink(Id recordId, String fileName) {
        return new ContentDocumentLinksSelector().byLinkedEntityIdAndTitles(new Set<Id>{ recordId }, new Set<String>{ fileName });
    }

    private static void refreshOrgMetadataCacheWithFile(Id credentialId, List<String> selectedMetadata, Boolean isMetadataSavedToFile) {
        if (!Test.isRunningTest()) {
            copado.RefreshOrgMetadataCache.InvocableVariables invocableVariable = new copado.RefreshOrgMetadataCache.InvocableVariables();
            invocableVariable.orgId = credentialId;
            invocableVariable.metadataTypesToBeRefreshed = new Set<String>(selectedMetadata);
            invocableVariable.isMetadataSavedToFile = isMetadataSavedToFile;
            invocableVariable.queryParameters = new Set<String>{ 'dates=format' };
            copado.RefreshOrgMetadataCache.executeRefresh(invocableVariable);
        }
    }

    // INNER

    @TestVisible
    private class Response extends LwcResponse {
        @AuraEnabled
        public String variant;

        private Response(Boolean isSuccess, String message, String variant) {
            super(isSuccess, message);
            this.variant = variant;
        }
    }
}