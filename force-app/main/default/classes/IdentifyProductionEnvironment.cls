@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class IdentifyProductionEnvironment implements copado.ParameterExpressionCallable {
    // GLOBAL
    global String execute(Id contextId) {
        Boolean result = true;
        copado__JobStep__c executionData = getJobExecutionData(contextId);
        copado__Environment__c destination = getEnvironmentRecord(executionData.copado__JobExecution__r.copado__Destination__c);
        if (destination.copado__Type__c == 'Sandbox' || destination.copado__Type__c == 'Scratch Org') {
            return String.valueOf(false);
        }

        Set<Id> sources = getSourceEnvironments(executionData.copado__JobExecution__r.copado__Pipeline__c);
        result = !sources.contains(destination.Id);

        return String.valueOf(result);
    }

    // PRIVATE

    private copado__JobStep__c getJobExecutionData(Id stepId) {
        List<copado__JobStep__c> result = new JobStepsSelector().jobExecutionbyStepIds(new Set<Id>{ stepId });

        return !result.isEmpty() ? result[0] : new copado__JobStep__c();
    }

    private copado__Environment__c getEnvironmentRecord(Id environmentId) {
        List<copado__Environment__c> environments = new EnvironmentsSelector().byIds(new Set<Id>{ environmentId });
        return !environments.isEmpty() ? environments[0] : new copado__Environment__c();
    }

    private Set<Id> getSourceEnvironments(Id pipeline) {
        Set<Id> result = new Set<Id>();
        for (copado__Deployment_Flow_Step__c item : new PipelineConnectionsSelector().byPipelineIds(new Set<Id>{ pipeline })) {
            result.add(item.copado__Source_Environment__c);
        }
        return result;
    }
}