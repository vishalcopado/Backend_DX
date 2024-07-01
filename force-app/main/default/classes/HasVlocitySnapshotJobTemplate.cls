public with sharing class HasVlocitySnapshotJobTemplate {
    
    private static final String API_NAME = 'SFDX_Vlocity_Git_Snapshot_1';

    @AuraEnabled
    public static Boolean execute(Id pipelineId) {
        Boolean result = false;
        List<copado__Pipeline_Action__c> pipelineActions = new PipelineActionSelector()
            .byPipelineAndAction(new Set<Id>{ pipelineId }, new Set<String>{ 'TakeSnapshot' });

        for(copado__Pipeline_Action__c action : pipelineActions){
            if(action.copado__Job_Template__r?.copado__ApiName__c == API_NAME) {
                result = true;
                break;
            }
        }
        return result;
    }
}