public inherited sharing class RemoveMetadataGroupImpl {
    private copado__Deployment_Flow__c pipeline;
    private Id environmentId;
    private List<String> metadataGroupNamesToBeRemoved;
    private String fileName;

    private static final String SELECTED_METADATA = 'Selected Metadata';

    // CONSTRUCTOR

    public RemoveMetadataGroupImpl(PipelineInitializer.MetadataGroupRemovalRequest request) {
        List<copado__Deployment_Flow__c> pipelines = new PipelinesSelector().byId(new Set<Id>{ request.pipelineId });
        if (pipelines.isEmpty()) {
            throw new ApplicationException(Label.NoPipelineFound);
        }

        this.pipeline = pipelines[0];
        this.environmentId = request.environmentId;
        this.metadataGroupNamesToBeRemoved = request.metadataGroupNames;
        this.fileName = request.pipelineId + '_' + request.environmentId + '_' + SELECTED_METADATA;
    }

    // PUBLIC STATIC

    public static PipelineInitializer.SelectionsSaveResult execute(PipelineInitializer.MetadataGroupRemovalRequest request) {
        if (request.pipelineId == null || request.environmentId == null || request.metadataGroupNames.isEmpty()) {
            throw new ApplicationException(
                String.format(Label.MissingRequiredParameters, new List<Object>{ String.join(new List<String>{ 'Pipeline Id', 'Environment Id', 'Metadata Group Names' }, ', ') })
            );
        }
        return new RemoveMetadataGroupImpl(request).execute();
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

        if (!updatedMetadataGroups.metadataGroups.isEmpty()) {
            createSelectedMetadataFile(updatedMetadataGroups);
            return getContentDocumentLinks(environmentId, fileName)[0].contentDocumentId;
        }

        return null;
    }

    private List<ContentDocumentLink> getContentDocumentLinks(Id linkedEntityId, String fileName) {
        return new ContentDocumentLinksSelector()
                .byLinkedEntityIdAndTitles(new Set<Id>{ environmentId }, new Set<String>{ fileName });
    }

    private MetadataGroups getUpdatedMetadataGroups(Id contentDocumentId) {
        MetadataGroups result = new MetadataGroups();

        MetadataGroups existingMetadataGroups = getExistingMetadataGroupsFromFile(contentDocumentId);
        for (PipelineInitializer.MetadataGroup metadataGroup : existingMetadataGroups.metadataGroups) {
            if (!metadataGroupNamesToBeRemoved.contains(metadataGroup.groupName)) {
                result.metadataGroups.add(metadataGroup);
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

        public MetadataGroups() {
            this.metadataGroups = new List<PipelineInitializer.MetadataGroup>();
        }
    }
}