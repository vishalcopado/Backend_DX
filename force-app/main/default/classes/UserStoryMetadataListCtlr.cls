@SuppressWarnings('PMD.CyclomaticComplexity')
public with sharing class UserStoryMetadataListCtlr {
    private static String sfdxMetadataFile;
    private static String vlocityFile;
    @TestVisible
    private static final String SFDX_CREATE_DELETED_METADATA = 'SFDX_Create_Deleted_Metadata';
    @TestVisible
    private static final String METADATA_FILE = 'MetaData';
    @TestVisible
    private static final String DELETED_METADATA_FILE = 'DeletedMetaData';
    @TestVisible
    private static copado__Result__c mockResult;

    // PUBLIC

    @SuppressWarnings('PMD.ExcessiveParameterList')
    @AuraEnabled
    public static List<Response> getMetadataAndVlocityFiles(
        Id credentialId,
        List<String> fileNames,
        Boolean isVlocityEnabled,
        Boolean hasChangesForDeletedMetadataFile
    ) {
        List<Response> results = new List<Response>{ new Response(true, '') };

        sfdxMetadataFile = !fileNames.isEmpty() ? fileNames[0] : '';
        vlocityFile = isVlocityEnabled && fileNames.size() == 2 ? fileNames[1] : '';

        validateCredentialId(credentialId);

        List<Attachment> attachments = new AttachmentsSelector()
            .byParentIdsAndNames(new Set<Id>{ credentialId }, new Set<String>{ sfdxMetadataFile }, 1);

        Map<String, List<ContentDocumentLink>> contentDocumentLinksByTitle = createContentDocumentLinksByTitle(credentialId);

        try {
            if (attachments.isEmpty() && !contentDocumentLinksByTitle.containsKey(vlocityFile)) {
                return results;
            } else {
                Map<String, Id> contentVersionIdsByFileName = getContentVersionIdByTitle(contentDocumentLinksByTitle, attachments);
                if (!attachments.isEmpty() && String.isBlank(contentVersionIdsByFileName.get(sfdxMetadataFile))) {
                    contentVersionIdsByFileName.put(sfdxMetadataFile, createFile(credentialId, sfdxMetadataFile, attachments[0].Body));
                    if (hasChangesForDeletedMetadataFile) {
                        executeFunctionToFindDeletedMetadata(credentialId);
                    }
                }
                results = createResponse(contentVersionIdsByFileName);
            }
        } catch (Exception ex) {
            results = new List<Response>{ new Response(false, ex.getMessage() + ' ' + ex.getStackTraceString()) };
        }

        return results;
    }

    @AuraEnabled
    public static copado__Result__c executeFunctionToFindDeletedMetadata(Id credentialId) {
        copado__Result__c result;
        Map<String, List<Id>> contentDocumentIdsByTitle = getContentDocumentIdsByTitle(
            credentialId,
            new Set<String>{ METADATA_FILE, DELETED_METADATA_FILE }
        );
        /*
            Here we are checking that we have more than one METADATA file, 
            so that we can do the comparison between them to find the deleted metadata.
        */
        if (contentDocumentIdsByTitle.get(METADATA_FILE)?.size() > 1) {
            Set<Id> contentDocumentIds = getContentDocumentIds(contentDocumentIdsByTitle);
            Map<Id, Id> contentVersionIdByContentDocumentId = getContentVersionIdByContentDocumentId(contentDocumentIds);
            List<copado.CopadoFunctions.FunctionParameter> functionParameters = getParametersForDeletedMetadataFunction(
                contentDocumentIdsByTitle,
                contentVersionIdByContentDocumentId,
                credentialId
            );
            copado.CopadoFunctions.ExecuteRequest request = new copado.CopadoFunctions.ExecuteRequest();
            request.functionApiName = SFDX_CREATE_DELETED_METADATA;
            request.contextId = credentialId;
            request.parameters = functionParameters;
            result = Test.isRunningTest() ? mockResult : copado.CopadoFunctions.execute(request).result;
        }
        return result;
    }

    //PRIVATE

    private static List<Response> createResponse(Map<String, Id> contentVersionIdsByFileName) {
        List<Response> responses = new List<Response>();
        for (String fileName : contentVersionIdsByFileName.keySet()) {
            if (!String.isBlank(contentVersionIdsByFileName.get(fileName))) {
                Response result = new Response(true, '');
                result.fileName = fileName;
                result.recordId = contentVersionIdsByFileName.get(fileName);
                responses.add(result);
            }
        }

        return responses;
    }

    private static Map<String, List<ContentDocumentLink>> createContentDocumentLinksByTitle(Id credentialId) {
        Map<String, List<ContentDocumentLink>> result = new Map<String, List<ContentDocumentLink>>();
        for (
            ContentDocumentLink documentLink : new ContentDocumentLinksSelector()
                .byLinkedEntityIdAndTitles(new Set<Id>{ credentialId }, new Set<String>{ sfdxMetadataFile, vlocityFile })
        ) {
            if (result.containsKey(documentLink.ContentDocument.Title)) {
                result.get(documentLink.ContentDocument.Title).add(documentLink);
            } else {
                result.put(documentLink.ContentDocument.Title, new List<ContentDocumentLink>{ documentLink });
            }
        }
        return result;
    }

    private static Id createFile(Id credentialId, String name, Blob versionData) {
        ContentVersion contentVersion = createContentVersion(credentialId, name, versionData);
        return contentVersion.Id;
    }

    private static ContentVersion createContentVersion(Id credentialId, String name, Blob versionData) {
        ContentVersion result = new ContentVersion(
            ContentLocation = 'S', // S = Document is located within Salesforce
            PathOnClient = name + '.json',
            Title = name,
            VersionData = versionData,
            FirstPublishLocationId = credentialId
        );

        fflib_ISObjectUnitOfWork unitOfWork = new fflib_SObjectUnitOfWork(new List<SObjectType>{ ContentVersion.SObjectType });
        fflib_SecurityUtils.checkInsert(ContentVersion.SObjectType, getContentVersionFields());
        unitOfWork.registerNew(result);
        unitOfWork.commitWork();
        return result;
    }

    private static List<String> getContentVersionFields() {
        return new List<String>{ 'ContentLocation', 'PathOnClient', 'Title', 'VersionData', 'FirstPublishLocationId' };
    }

    private static void validateCredentialId(Id credentialId) {
        if (String.isBlank(credentialId)) {
            throw new ApplicationException(Label.Credential_Not_Found);
        }
    }

    private static Map<String, Id> getContentVersionIdByTitle(
        Map<String, List<ContentDocumentLink>> contentDocumentLinksByTitle,
        List<Attachment> attachments
    ) {
        Id nullId;
        Map<String, Id> result = new Map<String, Id>{ sfdxMetadataFile => nullId, vlocityFile => nullId };

        List<ContentDocumentLink> vlocityDocumentLinks = getDocumentLinksByTitle(vlocityFile, contentDocumentLinksByTitle);
        List<ContentDocumentLink> sfdxDocumentLinks = getDocumentLinksByTitle(sfdxMetadataFile, contentDocumentLinksByTitle);

        Set<Id> contentDocumentIds = getContentDocumentIds(sfdxDocumentLinks, vlocityDocumentLinks);
        Map<String, ContentVersion> contentVersionsByTitle = getContentVersionsByTitle(contentDocumentIds);

        List<ContentDocument> contentDocumentsToBeDeleted = new List<ContentDocument>();
        if (!vlocityDocumentLinks.isEmpty() && vlocityDocumentLinks.size() > 1) {
            contentDocumentsToBeDeleted.add(new ContentDocument(Id = vlocityDocumentLinks[1].ContentDocumentId));
        }

        if (!sfdxDocumentLinks.isEmpty() && !attachments.isEmpty()) {
            ContentVersion sfdxContentVersion = contentVersionsByTitle.get(sfdxMetadataFile);
            if (attachments[0].LastModifiedDate < sfdxContentVersion.LastModifiedDate) {
                result.put(sfdxMetadataFile, sfdxContentVersion.Id);
            }
        }
        if (!vlocityDocumentLinks.isEmpty() && contentVersionsByTitle.containsKey(vlocityFile)) {
            result.put(vlocityFile, contentVersionsByTitle.get(vlocityFile).Id);
        }
        new Utilities.DeleteSObjectWithoutSharing().execute(contentDocumentsToBeDeleted);
        return result;
    }

    private static Set<Id> getContentDocumentIds(List<ContentDocumentLink> sfdxDocumentLinks, List<ContentDocumentLink> vlocityDocumentLinks) {
        Set<Id> result = new Set<Id>();
        if (!sfdxDocumentLinks.isEmpty()) {
            result.add(sfdxDocumentLinks[0].ContentDocumentId);
        }
        if (!vlocityDocumentLinks.isEmpty()) {
            result.add(vlocityDocumentLinks[0].ContentDocumentId);
        }
        return result;
    }

    private static Map<String, ContentVersion> getContentVersionsByTitle(Set<Id> contentDocumentIds) {
        Map<String, ContentVersion> result = new Map<String, ContentVersion>();

        for (ContentVersion version : new ContentVersionsSelector().byContentDocumentId(contentDocumentIds)) {
            result.put(version.Title, version);
        }

        return result;
    }

    private static List<ContentDocumentLink> getDocumentLinksByTitle(
        String name,
        Map<String, List<ContentDocumentLink>> contentDocumentLinksByTitle
    ) {
        List<ContentDocumentLink> result = new List<ContentDocumentLink>();
        if (contentDocumentLinksByTitle.containsKey(name)) {
            result = contentDocumentLinksByTitle.get(name);
        }
        return result;
    }

    private static Map<String, List<Id>> getContentDocumentIdsByTitle(Id credentialId, Set<String> fileNames) {
        Map<String, List<Id>> result = new Map<String, List<Id>>();
        for (
            ContentDocumentLink contentDocumentLink : new ContentDocumentLinksSelector()
                .byLinkedEntityIdAndTitles(new Set<Id>{ credentialId }, fileNames)
        ) {
            String fileTitle = contentDocumentLink.ContentDocument?.Title;
            if (!result.containsKey(fileTitle)) {
                result.put(fileTitle, new List<Id>());
            }
            result.get(fileTitle).add(contentDocumentLink.ContentDocumentId);
        }
        return result;
    }

    private static Set<Id> getContentDocumentIds(Map<String, List<Id>> contentDocumentIdsByTitle) {
        Set<Id> result = new Set<Id>();
        for (List<Id> contentDocumentIds : contentDocumentIdsByTitle.values()) {
            result.addAll(contentDocumentIds);
        }
        return result;
    }

    private static Map<Id, Id> getContentVersionIdByContentDocumentId(Set<Id> contentDocumentIds) {
        Map<Id, Id> result = new Map<Id, Id>();
        for (ContentVersion contentVersion : new ContentVersionsSelector().byContentDocumentId(contentDocumentIds)) {
            result.put(contentVersion.ContentDocumentId, contentVersion.Id);
        }
        return result;
    }

    private static List<copado.CopadoFunctions.FunctionParameter> getParametersForDeletedMetadataFunction(
        Map<String, List<Id>> contentDocumentIdsByTitle,
        Map<Id, Id> contentVersionIdByContentDocumentId,
        Id credentialId
    ) {
        /* 
            The variable metadataContentDocumentIds contains the content document ids for the METADATA file
            in the desc order of their creation date. So the latest one will come first. 
            The same is for variable deletedMetadataContentDocumentIds.
        */
        List<Id> metadataContentDocumentIds = contentDocumentIdsByTitle.get(METADATA_FILE);
        List<Id> deletedMetadataContentDocumentIds = contentDocumentIdsByTitle.get(DELETED_METADATA_FILE);
        List<copado.CopadoFunctions.FunctionParameter> functionParameters = new List<copado.CopadoFunctions.FunctionParameter>();

        functionParameters.add(
            new copado.CopadoFunctions.FunctionParameter(
                'newMetadataFileId',
                getContentVersionId(metadataContentDocumentIds[0], contentVersionIdByContentDocumentId)
            )
        );
        functionParameters.add(
            new copado.CopadoFunctions.FunctionParameter(
                'oldMetadataFileId',
                getContentVersionId(metadataContentDocumentIds[1], contentVersionIdByContentDocumentId)
            )
        );
        if (deletedMetadataContentDocumentIds?.size() > 0) {
            functionParameters.add(
                new copado.CopadoFunctions.FunctionParameter(
                    'deletedMetadataFileId',
                    getContentVersionId(deletedMetadataContentDocumentIds[0], contentVersionIdByContentDocumentId)
                )
            );
        }
        functionParameters.add(new copado.CopadoFunctions.FunctionParameter('credentialRecordId', credentialId));
        return functionParameters;
    }

    private static Id getContentVersionId(Id contentDocumentId, Map<Id, Id> contentVersionIdByContentDocumentId) {
        Id result = contentVersionIdByContentDocumentId.containsKey(contentDocumentId)
            ? contentVersionIdByContentDocumentId.get(contentDocumentId)
            : null;
        return result;
    }

    // INNER

    public class Response extends LwcResponse {
        @AuraEnabled
        public String recordId;
        @AuraEnabled
        public String fileName;

        public Response(Boolean isSuccess, String message) {
            super(isSuccess, message);
        }
    }
}