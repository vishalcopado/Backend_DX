@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class RefreshMetadataCallback implements copado.MCCallback {
    // GLOBAL

    global void execute(copado__Function__c function, copado__Result__c result, String status) {
        try {
            if (status == 'Success') {
                Id credentialId = getCredentialId(result);
                if (String.isNotBlank(credentialId)) {
                    attachLatestMetadataFilesOnCredential(credentialId, result.Id);
                }
            }
        } catch (Exception ex) {
            throw new ApplicationException(ex.getMessage() + ' ' + ex.getStackTraceString());
        }
    }

    // PRIVATE

    private static Id getCredentialId(copado__Result__c result) {
        Id credentialId;
        List<copado__Result__c> results = new ResultsSelector().byIds(new Set<Id>{ result.Id });
        String dataJson = results[0]?.copado__JobStep__r?.copado__JobExecution__r?.copado__DataJson__c;
        if (String.isNotBlank(dataJson)) {
            Map<String, Object> deserializedDataJson = (Map<String, Object>) JSON.deserializeUntyped(dataJson);
            credentialId = (Id) deserializedDataJson.get('credentialId');
        }
        return credentialId;
    }

    private static void attachLatestMetadataFilesOnCredential(Id credentialId, Id resultId) {
        List<ContentDocumentLink> contentDocumentLinksForResult = new List<ContentDocumentLink>();
        Map<String, ContentDocumentLink> contentDocumentLinkByTitle = new Map<String, ContentDocumentLink>();
        List<ContentDocument> contentDocumentsForDeletion = new List<ContentDocument>();
        List<ContentDocumentLink> newContentDocumentLinksForCredential = new List<ContentDocumentLink>();
        for (
            ContentDocumentLink contentDocumentLink : new ContentDocumentLinksSelector()
                .byLinkedEntityIdAndTitles(new Set<Id>{ credentialId, resultId }, new Set<String>{ 'MetaData', 'DeletedMetaData' })
        ) {
            if (contentDocumentLink.LinkedEntityId == resultId) {
                contentDocumentLinksForResult.add(contentDocumentLink);
            } else if (contentDocumentLink.LinkedEntityId == credentialId) {
                contentDocumentLinkByTitle.put(contentDocumentLink.ContentDocument.Title, contentDocumentLink);
            }
        }

        // We want to replace the credential files, containing the old MetaData and DeletedMetaData content
        // with the new MetaData and DeletedMetaData files present on the result record.
        // In order to do so, we are deleting the old files from credential record and creating new content document links
        // with the files present on result record.
        for (ContentDocumentLink contentDocumentLink : contentDocumentLinksForResult) {
            if (contentDocumentLinkByTitle.containsKey(contentDocumentLink.ContentDocument.Title)) {
                ContentDocumentLink credentialContentDocumentLink = contentDocumentLinkByTitle.get(
                    contentDocumentLink.ContentDocument.Title
                );
                contentDocumentsForDeletion.add(new ContentDocument(Id = credentialContentDocumentLink.ContentDocumentId));
            }
            newContentDocumentLinksForCredential.add(getContentDocumentLink(credentialId, contentDocumentLink.ContentDocumentId, 'V'));
        }

        new DeleteContentDocument(contentDocumentsForDeletion).execute();
        createContentDocumentLinks(newContentDocumentLinksForCredential);
    }

    private static ContentDocumentLink getContentDocumentLink(Id linkedEntityId, Id contentDocumentId, String shareType) {
        ContentDocumentLink result = new ContentDocumentLink(
            LinkedEntityId = linkedEntityId,
            ContentDocumentId = ContentDocumentId,
            ShareType = shareType
        );
        return result;
    }

    private static void createContentDocumentLinks(List<ContentDocumentLink> contentDocumentLinks) {
        fflib_SecurityUtils.checkInsert(
            ContentDocumentLink.SObjectType,
            new List<String>{ 'LinkedEntityId', 'ContentDocumentId', 'ShareType' }
        );
        insert contentDocumentLinks;
    }

    // INNER

    // This inner class runs in without sharing context
    // to handle the deletion of ContentDocument records.
    // As per the standard behavior, only the file owner
    // can delete a file, to bypass it we are using this inner class.
    // https://help.salesforce.com/s/articleView?id=sf.collab_files_deleting.htm&type=5
    private without sharing class DeleteContentDocument {
        private List<ContentDocument> contentDocuments;

        private DeleteContentDocument(List<ContentDocument> contentDocuments) {
            this.contentDocuments = contentDocuments;
        }

        @SuppressWarnings('PMD.ApexCRUDViolation')
        private void execute() {
            delete contentDocuments;
        }
    }
}