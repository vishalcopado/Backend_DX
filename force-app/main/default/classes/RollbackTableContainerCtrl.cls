public with sharing class RollbackTableContainerCtrl {
    private final static String SUCCESSFUL = 'Successful';

    @AuraEnabled
    public static void updateRollbackFile(String body, Id recordId, String fileTitle) {
        try {
            List<ContentVersion> result = new List<ContentVersion>();

            List<ContentDocumentLink> contentDocumentLinks = new ContentDocumentLinksSelector()
                .byLinkedEntityIdAndTitles(new Set<Id>{ recordId }, new Set<String>{ fileTitle });

            if (!contentDocumentLinks.isEmpty()) {
                ContentVersion contentVersion = new ContentVersion();
                contentVersion.ContentLocation = 'S';
                contentVersion.PathOnClient = fileTitle + '.json';
                contentVersion.Title = fileTitle;
                contentVersion.VersionData = Blob.valueOf(body);
                contentVersion.contentDocumentId = contentDocumentLinks[0].ContentDocumentId;

                result.add(contentVersion);

                Utilities.performDML(result, 'insert', AccessLevel.USER_MODE);
            } else {
                throw new AuraHandledException(Label.Copado_Rollback_changes_does_not_exists);
            }
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage() + ' ' + ex.getStackTraceString());
        }
    }

    @AuraEnabled
    public static Response getRepositoryDetails(Id recordId) {
        try {
            Response result = new Response();

            List<copado__Promotion__c> promotions = new PromotionsSelector().fetchRepositoryInfoByIds(new Set<Id>{ recordId });

            if (!promotions.isEmpty()) {
                result.promotion = promotions[0];
                result.pipeline = getPipeline(promotions[0]);
                result.destinationEnvironmentBranch = getDestinationEnvironmentBranch(promotions[0]);
                result.isMerged = promotionIsMerged(promotions[0].Id);
            }

            return result;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage() + ' ' + ex.getStackTraceString());
        }
    }

    // PRIVATE

    private static String getDestinationEnvironmentBranch(copado__Promotion__c promotion) {
        Id pipelineId = getPipeline(promotion)?.Id;
        Id destinationId = promotion?.copado__Destination_Environment__c;
        Id sourceId = promotion?.copado__Source_Environment__c;

        List<copado__Deployment_Flow_Step__c> pipelineConnections = new PipelineConnectionsSelector()
            .byPipelineAndSourceEnvAndDestinationEnv(new Set<Id>{ pipelineId }, new Set<Id>{ sourceId }, new Set<Id>{ destinationId });

        return pipelineConnections.isEmpty() ? null : pipelineConnections[0]?.copado__Destination_Branch__c;
    }

    private static Boolean promotionIsMerged(Id promotionId) {
        return new JobExecutionsSelector().byPromotionId(promotionId)?.copado__Status__c == SUCCESSFUL;
    }

    private static copado__Deployment_Flow__c getPipeline(copado__Promotion__c promotion) {
        return String.isNotBlank(promotion.copado__Project__r?.copado__Deployment_Flow__c)
            ? promotion.copado__Project__r?.copado__Deployment_Flow__r
            : String.isNotBlank(promotion.copado__Release__r?.copado__Project__r?.copado__Deployment_Flow__c)
                  ? promotion.copado__Release__r?.copado__Project__r?.copado__Deployment_Flow__r
                  : null;
    }

    // INNER

    public with sharing class Response {
        @AuraEnabled
        public copado__Promotion__c promotion;
        @AuraEnabled
        public copado__Deployment_Flow__c pipeline;
        @AuraEnabled
        public String destinationEnvironmentBranch;
        @AuraEnabled
        public Boolean isMerged;
    }
}