public with sharing class GetRefreshIndexContent {
    private static final String METADATA_FILE = 'MetaData';
    private static final String VLOCITY_FILE = 'Vlocity.json';

    @AuraEnabled
    public static List<Response> execute(Id credentialId, List<String> fileNames) {
        List<Response> results = new List<Response>{ new Response(true, '') };

        try {
            validateCredentialId(credentialId);

            Map<String, List<Id>> contentDocumentIdsByTitle = getContentDocumentIdsByTitle(credentialId, fileNames);
            if (fileNames.contains(VLOCITY_FILE)) {
                deleteVlocityContentDocuments(contentDocumentIdsByTitle);
            }

            Set<Id> contentDocumentIds = getLatestContentDocumentIds(contentDocumentIdsByTitle);
            Map<String, Id> contentVersionByTitle = getContentVersionsByTitle(contentDocumentIds, fileNames);

            if (contentDocumentIdsByTitle.get(METADATA_FILE)?.size() > 1) {
                UserStoryMetadataListCtlr.executeFunctionToFindDeletedMetadata(credentialId);
            }

            results = createResponse(contentVersionByTitle);
        } catch (Exception ex) {
            results = new List<Response>{ new Response(false, ex.getMessage() + ' ' + ex.getStackTraceString()) };
        }

        return results;
    }

    // PRIVATE

    private static void validateCredentialId(Id credentialId) {
        if (String.isBlank(credentialId)) {
            throw new ApplicationException(Label.Credential_Not_Found);
        }
    }

    private static Map<String, List<Id>> getContentDocumentIdsByTitle(Id credentialId, List<String> fileNames) {
        Map<String, List<Id>> result = new Map<String, List<Id>>();
        for (
            ContentDocumentLink contentDocumentLink : new ContentDocumentLinksSelector()
                .byLinkedEntityIdAndTitles(new Set<Id>{ credentialId }, new Set<String>(fileNames))
        ) {
            String fileTitle = contentDocumentLink.ContentDocument?.Title;
            if (!result.containsKey(fileTitle)) {
                result.put(fileTitle, new List<Id>());
            }
            result.get(fileTitle).add(contentDocumentLink.ContentDocumentId);
        }
        return result;
    }

    private static Set<Id> getLatestContentDocumentIds(Map<String, List<Id>> contentDocumentIdsByTitle) {
        Map<String, Id> contentdocumentIdByName = new Map<String, Id>();
        for (String fileName : contentDocumentIdsByTitle.keySet()) {
            List<Id> documentIds = contentDocumentIdsByTitle.get(fileName);
            if (documentIds != null && !documentIds.isEmpty()) {
                contentdocumentIdByName.put(fileName, documentIds[0]);
            }
        }
        return new Set<Id>(contentdocumentIdByName.values());
    }

    private static void deleteVlocityContentDocuments(Map<String, List<Id>> contentDocumentIdsByTitle) {
        List<Id> vlocityDocumentIds = contentDocumentIdsByTitle.get(VLOCITY_FILE);

        if (vlocityDocumentIds != null && !vlocityDocumentIds?.isEmpty() && vlocityDocumentIds?.size() > 1) {
            List<ContentDocument> contentDocumentsToBeDeleted = new List<ContentDocument>();
            /*
                We have a list of Vlocity files, with an order of Last Modified Date DESC.
                Here loop initiates with 1 instead of 0, reason behind is to remove all
                old Vlocity index files and only keep latest one.
            */
            for (Integer documentId = 1; documentId < vlocityDocumentIds.size(); documentId++) {
                contentDocumentsToBeDeleted.add(new ContentDocument(Id = vlocityDocumentIds[documentId]));
            }
            new Utilities.DeleteSObjectWithoutSharing().execute(contentDocumentsToBeDeleted);
        }
    }

    private static List<Response> createResponse(Map<String, Id> contentVersionIdsByFileName) {
        List<Response> result = new List<Response>();
        for (String fileName : contentVersionIdsByFileName.keySet()) {
            if (String.isNotBlank(contentVersionIdsByFileName.get(fileName))) {
                Response response = new Response(true, '');
                response.fileName = fileName;
                response.recordId = contentVersionIdsByFileName.get(fileName);
                result.add(response);
            } else {
                result.add(new Response(true, ''));
            }
        }

        return result;
    }

    public static Map<String, Id> getContentVersionsByTitle(Set<Id> contentDocumentIds, List<String> fileNames) {
        Map<String, Id> result = new Map<String, Id>();

        for (ContentVersion version : new ContentVersionsSelector().byContentDocumentId(contentDocumentIds)) {
            result.put(version.Title, version.Id);
        }

        if (contentDocumentIds.isEmpty()) {
            for (String fileName : fileNames) {
                result.put(fileName, null);
            }
        }

        return result;
    }

    // INNER

    public class Response extends LwcResponse {
        @AuraEnabled
        public Id recordId;
        @AuraEnabled
        public String fileName;

        public Response(Boolean isSuccess, String message) {
            super(isSuccess, message);
        }
    }
}