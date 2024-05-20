public with sharing class DeploymentTaskCreate {
    private Id versionId;
    private Id userStoryId;
    private String taskName;
    private String installSecurityType;

    // CTOR

    @SuppressWarnings('PMD.ExcessiveParameterList')
    public DeploymentTaskCreate(Id packageVersionId, Id storyId, String name, String installSecurityType) {
        versionId = packageVersionId;
        userStoryId = storyId;
        taskName = name;
        this.installSecurityType = installSecurityType;
    }

    // PUBLIC

    public void execute() {
        copado__Deployment_Task__c task = new copado__Deployment_Task__c(
            Name = taskName,
            copado__User_Story__c = userStoryId,
            copado__Type__c = 'Salesforce Flow',
            copado__Perform_Manual_Task__c = 'After Deployment',
            copado__Order__c = getOrder(),
            copado__dataJSON__c = buildConfigJson()
        );

        insert Security.stripInaccessible(AccessType.CREATABLE, new List<SObject>{ task }).getRecords();
    }

    // PRIVATE

    private String buildConfigJson() {
        List<List<String>> parameters = new List<List<String>>{
            new List<String>{ 'packageVersionId', versionId },
            new List<String>{ 'deploymentId', '{!Deployment.Id}' },
            new List<String>{ 'deploymentJobId', '{!Deployment.JobId}' },
            new List<String>{ 'installSecurityType', installSecurityType }
        };

        ConfigJson configJson = new ConfigJson(Settings.NAMESPACE_DOT + 'Initiate_Classic_Pipeline_Distribution');
        configJson.flowLabel = 'Initiate Classic Pipeline Distribution';
        configJson.type = 'wait';
        configJson.flowParameters = parameters;

        return JSON.serialize(configJson);
    }

    private Decimal getOrder() {
        Decimal maxOrder = (Decimal) [
                SELECT MAX(copado__Order__c) MaxOrder
                FROM copado__Deployment_Task__c
                WHERE copado__User_Story__c = :userStoryId AND copado__Perform_Manual_Task__c = 'After Deployment'
            ]
            .get(0)
            .get('MaxOrder');

        return (maxOrder == null) ? 1 : (maxOrder + 1);
    }

    @TestVisible
    private class ConfigJson {
        @TestVisible
        private String flowApiName;

        @TestVisible
        private String flowLabel;

        @TestVisible
        private String type;

        @TestVisible
        private List<List<String>> flowParameters;

        // CTOR

        private ConfigJson(String flowApiName) {
            this.flowApiName = flowApiName;
        }
    }
}