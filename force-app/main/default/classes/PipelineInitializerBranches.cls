public with sharing class PipelineInitializerBranches {

    @AuraEnabled
    public static void createBranches(Id recordId, String initializationData) {
        try {
            Set<String> wipModes = new Set<String>{'WIP Full', 'WIP Diff'};
            PipelineInitializationDetails initializationJsonData = (PipelineInitializationDetails) JSON.deserialize(initializationData, PipelineInitializationDetails.class);

            if (wipModes.contains(initializationJsonData?.initializationType)) {
                initializationJsonData.areChangesSelected = true;
                updateInitializationData(recordId, JSON.serializePretty(initializationJsonData));
            }

            PipelineInitializer.Initialize.execute(recordId);
        } catch(Exception ex) {
            throw new ApplicationException(ex.getMessage() + ' ' + ex.getStackTraceString());
        }
    }

    @AuraEnabled
    public static void runDifferenceAnalysis(Id pipelineId) {
        try {
            PipelineInitializer.PreSteps.refreshMetadata(new PipelineInitializer.RefreshMetadataRequest(pipelineId, true));
        } catch (Exception ex) {
            throw new ApplicationException().auraHandled(ex);
        }
    }

    // PRIVATE

    private static void updateInitializationData(Id pipelineId, String latestInitializationData) {
        copado__Deployment_Flow__c pipelineWithInitializationData = new copado__Deployment_Flow__c(
            Id = pipelineId,
            Initialization_Data__c = latestInitializationData
        );
        Utilities.performDML(new List<copado__Deployment_Flow__c>{ pipelineWithInitializationData }, 'update', AccessLevel.USER_MODE);
    }
}