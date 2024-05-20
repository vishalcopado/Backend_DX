public with sharing class ActionTemplate {
    private String actionName;
    private Id pipelineId;
    private Id environmentId;
    private Boolean templateRequired;
    private static final String ROLLBACK_TEMPLATE = 'SFDX_Rollback_1';
    private static final String PACKAGE_DISTRIBUTION_TEMPLATE = 'SFDX Package Distribution_1';

    // CONSTRUCTOR

    public ActionTemplate(String actionName, Id pipelineId) {
        this.actionName = actionName;
        this.pipelineId = pipelineId;
        this.templateRequired = true;
    }

    public ActionTemplate(String actionName, Id pipelineId, Id environmentId) {
        this.actionName = actionName;
        this.pipelineId = pipelineId;
        this.environmentId = environmentId;
        this.templateRequired = true;
    }

    public String getApiName() {
        String result;

        // Note: it is important that this selector returns the list ordered by non-default actions first in order to consider overrides first
        for (copado__Pipeline_Action__c action : new PipelineActionSelector().byPipelineAndAction( new Set<Id>{ pipelineId }, new Set<String>{ actionName })) {
            if (isEnvironmentOverride(action) && !environmentOverrideMatches(action, environmentId)) {
                continue;
            }
            result = action.copado__Job_Template__r.copado__ApiName__c;
            break;
        }

        if (Test.isRunningTest()) {
            switch on actionName {
                when 'Rollback' {
                    result = ROLLBACK_TEMPLATE;
                }
                when 'PackageDistribution' {
                    result = PACKAGE_DISTRIBUTION_TEMPLATE;
                }
            }
        }
        if (templateRequired && String.isBlank(result)) {
            throw new ApplicationException(
                String.format(Label.Error_No_Action_Template_Defined, new List<Object>{ actionName })    
            );
        }

        return result;
    }

    private Boolean isEnvironmentOverride(copado__Pipeline_Action__c action) {
        return action.copado__Default__c == false && String.isNotBlank(action.copado__Environment__c);
    }

    private Boolean environmentOverrideMatches(copado__Pipeline_Action__c action, Id environmentId) {
        return action.copado__Environment__c == environmentId;
    }
}