public with sharing class JobStepCreate {
    private Id versionId;
    private Id userStoryId;
    private String stepName;
    private String installSecurityType;

    // CTOR

    @SuppressWarnings('PMD.ExcessiveParameterList')
    public JobStepCreate(Id packageVersionId, Id storyId, String name, String installSecurityType) {
        versionId = packageVersionId;
        userStoryId = storyId;
        stepName = name;
        this.installSecurityType = installSecurityType;
    }

    // PUBLIC

    public void execute() {
        copado__JobStep__c step = new copado__JobStep__c(
            Name = stepName,
            copado__UserStory__c = userStoryId,
            copado__Type__c = 'Flow',
            copado__CustomType__c = 'Flow',
            copado__ExecutionSequence__c = 'after',
            copado__Order__c = getOrder(),
            copado__ConfigJson__c = buildConfigJson()
        );

        insert Security.stripInaccessible(AccessType.CREATABLE, new List<SObject>{ step }).getRecords();
    }

    // PRIVATE

    private String buildConfigJson() {
        ConfigJson configJson = new ConfigJson(Settings.NAMESPACE_DOT + 'InitiatePipelineDistribution');
        configJson.parameters = new List<Parameter>{
            new Parameter('packageVersionId', versionId),
            // Note: This is deployment job execution
            new Parameter('deploymentId', '{$Job.ExecutionParent.Id}'),
            new Parameter('installSecurityType', installSecurityType)
        };

        return JSON.serialize(configJson);
    }

    private Decimal getOrder() {
        Decimal maxOrder = (Decimal) [
                SELECT MAX(copado__Order__c) MaxOrder
                FROM copado__JobStep__c
                WHERE copado__UserStory__c = :userStoryId AND copado__ExecutionSequence__c = 'after'
            ]
            .get(0)
            .get('MaxOrder');

        return (maxOrder == null) ? 1 : (maxOrder + 1);
    }

    // INNER PRIVATE

    @TestVisible
    private class ConfigJson {
        @TestVisible
        private String flowName;

        @TestVisible
        private List<Parameter> parameters;

        // CTOR

        private ConfigJson(String flowName) {
            this.flowName = flowName;
        }
    }

    @TestVisible
    private class Parameter {
        @TestVisible
        private String name;

        @TestVisible
        private String value;

        // CTOR

        @TestVisible
        private Parameter(String name, String value) {
            this.name = name;
            this.value = value;
        }
    }
}