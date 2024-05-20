@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class DeleteOutdatedFilesOnCredential implements copado.MCCallback {
    @TestVisible
    private static final String METADATA_FILE = 'MetaData';
    @TestVisible
    private static final String DELETED_METADATA_FILE = 'DeletedMetaData';

    // GLOBAL

    global void execute(copado__Function__c function, copado__Result__c result, String status) {
        Id credentialId = getCredentialId(result);
        Map<String, ContentDocumentDetails> outdatedContentDocumentDetailsByTitle = getOutdatedContentDocumentDetails(credentialId);
        List<ContentDocument> contentDocumentsToBeDeleted = getContentDocumentsForDeletion(outdatedContentDocumentDetailsByTitle);
        new Utilities.DeleteSObjectWithoutSharing().execute(contentDocumentsToBeDeleted);
    }

    // PRIVATE

    private static Id getCredentialId(copado__Result__c result) {
        return result.copado__ParentId__c;
    }

    private Map<String, ContentDocumentDetails> getOutdatedContentDocumentDetails(Id credentialId) {
        Map<String, ContentDocumentDetails> outdatedContentDocumentDetailsByTitle = new Map<String, ContentDocumentDetails>();
        /* 
            Here we are getting all the MetaData and DeletedMetaData content document links for the given credential 
            in the descending order of their created date. We want to make sure that we leave 
            the first file, as that will be the latest one with all the correct details and 
            delete the other ones, as they will contain the outdated information.
        */
        for (
            ContentDocumentLink contentDocumentLink : new ContentDocumentLinksSelector()
                .byLinkedEntityIdAndTitles(new Set<Id>{ credentialId }, new Set<String>{ METADATA_FILE, DELETED_METADATA_FILE })
        ) {
            String fileTitle = contentDocumentLink?.ContentDocument?.Title;
            if (!outdatedContentDocumentDetailsByTitle.containsKey(fileTitle)) {
                outdatedContentDocumentDetailsByTitle.put(fileTitle, new ContentDocumentDetails());
            }
            Integer currentFileCount = (outdatedContentDocumentDetailsByTitle.get(fileTitle).fileCount) + 1;
            outdatedContentDocumentDetailsByTitle.get(fileTitle).fileCount = currentFileCount;
            if (currentFileCount > 1) {
                outdatedContentDocumentDetailsByTitle.get(fileTitle)
                    .contentDocumentsToBeDeleted.add(new ContentDocument(Id = ContentDocumentLink.ContentDocumentId));
            }
        }
        return outdatedContentDocumentDetailsByTitle;
    }

    private List<ContentDocument> getContentDocumentsForDeletion(Map<String, ContentDocumentDetails> outdatedContentDocumentDetailsByTitle) {
        List<ContentDocument> result = new List<ContentDocument>();
        if (outdatedContentDocumentDetailsByTitle.containsKey(METADATA_FILE)) {
            result.addAll(outdatedContentDocumentDetailsByTitle.get(METADATA_FILE).contentDocumentsToBeDeleted);
        }
        if (outdatedContentDocumentDetailsByTitle.containsKey(DELETED_METADATA_FILE)) {
            result.addAll(outdatedContentDocumentDetailsByTitle.get(DELETED_METADATA_FILE).contentDocumentsToBeDeleted);
        }
        return result;
    }

    // INNER

    private class ContentDocumentDetails {
        public Integer fileCount;
        public List<ContentDocument> contentDocumentsToBeDeleted;

        public ContentDocumentDetails() {
            fileCount = 0;
            contentDocumentsToBeDeleted = new List<ContentDocument>();
        }
    }
}