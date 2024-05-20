public inherited sharing class DataDeployConfigurationCheckImpl {
    private Id pipelineId;
    @TestVisible
    private static final String MCDD_DISABLED = 'mcdd_disabled';
    private static final String MCDD_ENABLED = 'mcdd_enabled';
    private static final String NEXTGEN_DD = 'NextGenDD';

    public DataDeployConfigurationCheckImpl(Id pipelineId) {
        this.pipelineId = pipelineId;
    }

    public static DataDeploy.CheckConfigurationResult execute(DataDeploy.CheckConfigurationRequest request) {
        return new DataDeployConfigurationCheckImpl(request.pipelineId).execute();
    }

    private DataDeploy.CheckConfigurationResult execute() {
        Boolean isMCDDDisabledInConfig = checkMCDDDisabledInfo();
        Boolean isMCDDEnabledInConfig = checkMCDDEnabledInfo();
        return new DataDeploy.CheckConfigurationResult(isMCDDEnabledInConfig && !isMCDDDisabledInConfig);
    }

    private Boolean checkMCDDDisabledInfo() {
        String pipelineId = this.pipelineId;
        Boolean result = false;
        List<copado__System_Property__c> properties = new SystemPropertiesSelector().byPipelineIdAndGlobalForMCDD(pipelineId, MCDD_DISABLED);
        for (copado__System_Property__c property : properties) {
            if (property.copado__Is_Global__c &&  property.copado__Value__c?.toLowerCase() == 'true') {
                result = true;
                break;
            } else if (!property.copado__Is_Global__c && property.copado__ParentId__c == pipelineId && property.copado__Value__c?.toLowerCase() == 'true') {
                result = true;
                break;
            }
        }
        return result;
    }

    private Boolean checkMCDDEnabledInfo() {
        String platform = NEXTGEN_DD;
        String key = MCDD_ENABLED;
        List<copado__ExtensionKeyValueSetting__mdt> keyValueSettings = new ExtensionKeyValueSettingsSelector().byPlatformAndKey(platform, key);
        return !keyValueSettings.isEmpty() && Boolean.valueOf(keyValueSettings.get(0).copado__Value__c);
    }
}