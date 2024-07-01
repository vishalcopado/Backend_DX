public inherited sharing class PipelineInitializerSaveSelectionsImpl {
    private copado__Deployment_Flow__c pipeline;
    private Id environmentId;
    private List<PipelineInitializer.MetadataGroup> metadataGroups;
    private String fileName;

    private static final String SELECTED_METADATA = 'Selected Metadata';

    // CONSTRUCTOR

    public PipelineInitializerSaveSelectionsImpl(PipelineInitializer.SelectionsSaveRequest request) {
        List<copado__Deployment_Flow__c> pipelines = new PipelinesSelector().byId(new Set<Id>{ request.pipelineId });
        if (pipelines.isEmpty()) {
            throw new ApplicationException(Label.NoPipelineFound);
        }

        this.pipeline = pipelines[0];
        this.environmentId = request.environmentId;
        this.metadataGroups = request.metadataGroups;
        this.fileName = request.pipelineId + '_' + request.environmentId + '_' + SELECTED_METADATA;
    }

    // PUBLIC STATIC

    public static PipelineInitializer.SelectionsSaveResult execute(PipelineInitializer.SelectionsSaveRequest request) {
        if (request.pipelineId == null || request.environmentId == null || request.metadataGroups.isEmpty()) {
            throw new ApplicationException(
                String.format(Label.MissingRequiredParameters, new List<Object>{ String.join(new List<String>{ 'Pipeline Id', 'Environment Id', 'Metadata Groups' }, ', ') })
            );
        }
        return new PipelineInitializerSaveSelectionsImpl(request).execute();
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
            createSelectedMetadataFile();
        } else {
            deleteExistingFile(contentDocumentLinks[0].contentDocumentId);
            createSelectedMetadataFile();
        }

        return getContentDocumentLinks(environmentId, fileName)[0].contentDocumentId;
    }

    private List<ContentDocumentLink> getContentDocumentLinks(Id linkedEntityId, String fileName) {
        return new ContentDocumentLinksSelector()
                .byLinkedEntityIdAndTitles(new Set<Id>{ environmentId }, new Set<String>{ fileName });
    }

    private void createSelectedMetadataFile() {
        ContentVersion contentVersion = new ContentVersion();

        contentVersion.ContentLocation = 'S'; // S = Stored in Salesforce
        contentVersion.PathOnClient = fileName + '.json';
        contentVersion.Title = fileName;
        contentVersion.VersionData = Blob.valueOf(JSON.serializePretty(new MetadataGroups(metadataGroups)));
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

        public MetadataGroups(List<PipelineInitializer.MetadataGroup> metadataGroups) {
            this.metadataGroups = metadataGroups;
        }
    }
}