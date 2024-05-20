public with sharing class PipelineInitializerMetadataSelection {

    private static final String SELECTED_METADATA = 'Selected Metadata';
    private static final String DIFFERENCE_METADATA = 'DifferenceMetadata';

    @AuraEnabled
    public static String saveSelectionsOnEnvironment(String selectionsRequest) {
        EnvironmentSelectionsRequest request = (EnvironmentSelectionsRequest) JSON.deserialize(selectionsRequest, EnvironmentSelectionsRequest.class);

        try {
            String fileName = request.pipelineId + '_' + request.environmentId + '_' + SELECTED_METADATA;
            List<ContentDocumentLink> contentDocumentLinks = getContentDocumentLinks(request.environmentId , fileName);

            PipelineInitializer.SelectionsSaveRequest selectionsSaveRequest = new PipelineInitializer.SelectionsSaveRequest(
                request.pipelineId, request.environmentId, request.getMetadataGroups()
            );

            if (contentDocumentLinks.isEmpty()) {
                // create file
                PipelineInitializer.Selections.save(selectionsSaveRequest);
            } else {
                // add group to existing file
                PipelineInitializer.Selections.addMetadataGroups(selectionsSaveRequest);
            }

            return getContentDocumentLinks(request.environmentId , fileName)[0].Id;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Id> getIndexFilesForDifferenceGrid(String environmentId, String pipelineId) {
        try {
            List<Id> result = new List<Id>();

            String fileName = pipelineId + '_' + environmentId + '_' + DIFFERENCE_METADATA;
            List<ContentDocumentLink> contentDocumentLinks = getContentDocumentLinks(environmentId , fileName);

            if (contentDocumentLinks.isEmpty()) {
                throw new ApplicationException(Label.Failure_Fetching_File);
            }
            List<ContentVersion> contentVersions = new ContentVersionsSelector().byContentDocumentId(new Set<Id> { contentDocumentLinks[0].contentDocumentId });
            result.addAll(new Map<Id, ContentVersion>(contentVersions).keySet());

            return result;
        } catch (Exception ex) {
            throw new ApplicationException().auraHandled(ex);
        }
    }

    // PRIVATE

    private static List<ContentDocumentLink> getContentDocumentLinks(Id linkedEntityId, String fileName) {
        return new ContentDocumentLinksSelector()
                .byLinkedEntityIdAndTitles(new Set<Id>{ linkedEntityId }, new Set<String>{ fileName });
    }

    // INNER

    public with sharing class EnvironmentSelectionsRequest {
        @AuraEnabled
        public Id pipelineId { get; set; }
        @AuraEnabled
        public List<copado.Actions.CommitChange> changes { get; set; }
        @AuraEnabled
        public Id environmentId { get; set; }
        @AuraEnabled
        public String groupTitle { get; set; }
        @AuraEnabled
        public String groupDescription { get; set; }

        public List<PipelineInitializer.MetadataGroup> getMetadataGroups() {
            List<PipelineInitializer.MetadataGroup> result = new List<PipelineInitializer.MetadataGroup>();

            PipelineInitializer.MetadataGroup metadataGroup = new PipelineInitializer.MetadataGroup();
            metadataGroup.groupName = groupTitle;
            metadataGroup.groupDescription = groupDescription;
            metadataGroup.selectedMetadata = changes;

            result.add(metadataGroup);

            return result;
        }
    }
}