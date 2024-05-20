// NOTE - Class executes in without sharing mode as System Property records are private
//  {$Destination.Property.rollback_enabled} does not be executed without sharing.
@SuppressWarnings('PMD.AvoidGlobalModifier')
global without sharing class IsRollBackEnabled implements copado.ParameterExpressionCallable {
    private static final String ROLLBACK_ENABLED = 'rollback_enabled';

    // GLOBAL
    global String execute(Id contextId) {
        Id destinationId = getJobExecutionData(contextId)?.copado__JobExecution__r?.copado__Destination__c;
        List<copado__System_Property__c> systemProperties = new SystemPropertiesSelector()
            .byEnvironmentForSFDX(new Set<Id>{ destinationId }, ROLLBACK_ENABLED);

        return String.valueOf(!systemProperties.isEmpty() && systemProperties[0]?.copado__Value__c?.toLowerCase() == 'true');
    }

    // PRIVATE
    private copado__JobStep__c getJobExecutionData(Id stepId) {
        List<copado__JobStep__c> result = new JobStepsSelector().jobExecutionbyStepIds(new Set<Id>{ stepId });

        return result.isEmpty() ? new copado__JobStep__c() : result[0];
    }
}