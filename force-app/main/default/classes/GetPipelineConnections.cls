public with sharing class GetPipelineConnections {

    @AuraEnabled(cacheable=true)
    public static List<copado__Deployment_Flow_Step__c> getConnections(Id recordId) {
        try {
            return new PipelineConnectionsSelector().byPipelineId(recordId);
        } catch (Exception ex) {
            throw new ApplicationException(ex.getMessage() + ' ' + ex.getStackTraceString());
        }
    }
}