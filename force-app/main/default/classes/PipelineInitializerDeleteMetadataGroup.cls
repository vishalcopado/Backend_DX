public with sharing class PipelineInitializerDeleteMetadataGroup {

    private static final String SELECTED_METADATA = 'Selected Metadata';
    
    @AuraEnabled
    public static Id removeMetadataGroup(Id pipelineId, Id environmentId, String groupName){
        try {
            String fileName = pipelineId + '_' + environmentId + '_' + SELECTED_METADATA;

            PipelineInitializer.MetadataGroupRemovalRequest request = new PipelineInitializer.MetadataGroupRemovalRequest(
                pipelineId, environmentId, new List<String> { groupName }
            );
            PipelineInitializer.Selections.removeMetadataGroups(request);

            List<ContentDocumentLink> contentDocumentLinks = getContentDocumentLinks(environmentId , fileName);
            
            return contentDocumentLinks.isEmpty() ? null : contentDocumentLinks[0].Id ;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    // PRIVATE

    private static List<ContentDocumentLink> getContentDocumentLinks(Id linkedEntityId, String fileName) {
        return new ContentDocumentLinksSelector()
                .byLinkedEntityIdAndTitles(new Set<Id>{ linkedEntityId }, new Set<String>{ fileName });
    }
}