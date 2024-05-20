public with sharing class InitializeSFDXProject {
    private static final String SFDX_GIT_INITIALIZATION = 'SFDX Git Initialization_1';

    // PUBLIC
    @AuraEnabled
    public static List<copado__JobExecution__c> execute(String request) {
        List<copado__JobExecution__c> result = new List<copado__JobExecution__c>();
        try {
            ProjectInitializationDetails projectInitDetails = (ProjectInitializationDetails) JSON.deserialize(
                request,
                ProjectInitializationDetails.class
            );
            result.add(sendExecutionRequest(projectInitDetails));
        } catch (Exception ex) {
            throw new ApplicationException().auraHandled(ex);
        }
        return result;
    }

    // PRIVATE

    private static copado__JobExecution__c sendExecutionRequest(ProjectInitializationDetails projectInitDetails) {
        copado__JobExecution__c execution = copado.Jobs.Execution.createFromTemplate(createExecutionRequest(projectInitDetails)).jobExecution;
        copado.Jobs.Execution.execute(new copado.Jobs.ExecutionRequest(execution.Id));
        return getJobExecution(execution.Id);
    }

    private static copado.Jobs.ExecutionCreateFromTemplateRequest createExecutionRequest(ProjectInitializationDetails projectInitDetails) {
        copado.Jobs.ExecutionCreateFromTemplateRequest request = new copado.Jobs.ExecutionCreateFromTemplateRequest();
        request.templateAPIName = SFDX_GIT_INITIALIZATION;
        request.dataJson = JSON.serializePretty(projectInitDetails);
        return request;
    }

    private static copado__JobExecution__c getJobExecution(Id jobExecutionId) {
        List<copado__JobExecution__c> result = new JobExecutionsSelector().byIds(new Set<Id>{ jobExecutionId });
        return result.isEmpty() ? new copado__JobExecution__c() : result[0];
    }

    // INNER
    @TestVisible
    private class ProjectInitializationDetails {
        public Id gitRepositoryId;
        public String defaultDirectory;
        public String branch;
        public String projectName;
        public Boolean recreateProject;
        public String template;
        public String gitRepositoryURI;
    }
}