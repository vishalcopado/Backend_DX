public inherited sharing class AddMetadataGroupImpl {
    private copado__Deployment_Flow__c pipeline;
    private Id environmentId;
    private List<PipelineInitializer.MetadataGroup> newMetadataGroups;
    private String fileName;

    private static final String SELECTED_METADATA = 'Selected Metadata';

    // CONSTRUCTOR

    public AddMetadataGroupImpl(PipelineInitializer.SelectionsSaveRequest request) {
        List<copado__Deployment_Flow__c> pipelines = new PipelinesSelector().byId(new Set<Id>{ request.pipelineId });
        if (pipelines.isEmpty()) {
            throw new ApplicationException(Label.NoPipelineFound);
        }

        this.pipeline = pipelines[0];
        this.environmentId = request.environmentId;
        this.newMetadataGroups = request.metadataGroups;
        this.fileName = request.pipelineId + '_' + request.environmentId + '_' + SELECTED_METADATA;
    }

    // PUBLIC STATIC

    public static PipelineInitializer.SelectionsSaveResult execute(PipelineInitializer.SelectionsSaveRequest request) {
        if (request.pipelineId == null || request.environmentId == null || request.metadataGroups.isEmpty()) {
            throw new ApplicationException(
                String.format(Label.MissingRequiredParameters, new List<Object>{ String.join(new List<String>{ 'Pipeline Id', 'Environment Id', 'Metadata Groups' }, ', ') })
            );
        }
        return new AddMetadataGroupImpl(request).execute();
    }

    // PUBLIC

    public PipelineInitializer.SelectionsSaveResult execute() {
        if (pipeline.copado__Platform__c != 'SFDX') {
            throw new ApplicationException(Label.PipelineUnavailableForInitializationMessage);
        }

        Id selectionsFileId = getSelectedMetadataFileId();

        return new PipelineInitializer.SelectionsSaveResult(selectionsFileId);
    }

    // PRIVATE

    private Id getSelectedMetadataFileId() {
        List<ContentDocumentLink> contentDocumentLinks = getContentDocumentLinks(environmentId, fileName);

        if (contentDocumentLinks.isEmpty()) {
            throw new ApplicationException(String.format(Label.MissingRequiredParameters, new List<String> { Label.EnvironmentMetadataFile }));
        }

        MetadataGroups updatedMetadataGroups = getUpdatedMetadataGroups(contentDocumentLinks[0].contentDocumentId);

        deleteExistingFile(contentDocumentLinks[0].contentDocumentId);
        createSelectedMetadataFile(updatedMetadataGroups);

        return getContentDocumentLinks(environmentId, fileName)[0].contentDocumentId;
    }

    private List<ContentDocumentLink> getContentDocumentLinks(Id linkedEntityId, String fileName) {
        return new ContentDocumentLinksSelector()
                .byLinkedEntityIdAndTitles(new Set<Id>{ environmentId }, new Set<String>{ fileName });
    }

    private MetadataGroups getUpdatedMetadataGroups(Id contentDocumentId) {
        MetadataGroups result = getExistingMetadataGroupsFromFile(contentDocumentId);

        Map<String, PipelineInitializer.MetadataGroup> existingGroupsByGroupName = new Map<String, PipelineInitializer.MetadataGroup>();
        for (PipelineInitializer.MetadataGroup existingGroup : result.metadataGroups) {
            existingGroupsByGroupName.put(existingGroup.groupName, existingGroup);
        }

        for (PipelineInitializer.MetadataGroup newGroup : newMetadataGroups) {
            if (existingGroupsByGroupName.containsKey(newGroup.groupName)) {
                PipelineInitializer.MetadataGroup existingGroup = existingGroupsByGroupName.get(newGroup.groupName);
                existingGroup.isProcessed = newGroup.isProcessed;
                existingGroup.groupDescription = newGroup.groupDescription;
                existingGroup.selectedMetadata = newGroup.selectedMetadata;
            } else {
                result.metadataGroups.add(newGroup);
                existingGroupsByGroupName.put(newGroup.groupName, newGroup);
            }
        }
        
        return result;
    }

    private MetadataGroups getExistingMetadataGroupsFromFile(Id contentDocumentId) {
        String fileContent = new ContentVersionsSelector()
                .byContentDocumentIdWithLatest(new Set<Id>{ contentDocumentId })[0].VersionData.toString();

        return (MetadataGroups) JSON.deserialize(fileContent, MetadataGroups.class);
    }

    private void createSelectedMetadataFile(MetadataGroups metadataGroups) {
        ContentVersion contentVersion = new ContentVersion();

        contentVersion.ContentLocation = 'S'; // S = Stored in Salesforce
        contentVersion.PathOnClient = fileName + '.json';
        contentVersion.Title = fileName;
        contentVersion.VersionData = Blob.valueOf(JSON.serializePretty(metadataGroups));
        contentVersion.FirstPublishLocationId = environmentId;

        Utilities.performDML(new List<ContentVersion>{ contentVersion }, 'insert', AccessLevel.USER_MODE);
    }

    private void deleteExistingFile(Id contentDocumentId) {
        List<ContentDocument> contentDocumentsToBeDeleted = new List<ContentDocument>{ new ContentDocument(Id = contentDocumentId) };
        new Utilities.DeleteSObjectWithoutSharing().execute(contentDocumentsToBeDeleted);
    }

    // INNER

    @TestVisible
    private class MetadataGroups {
        public List<PipelineInitializer.MetadataGroup> metadataGroups;
    }
}