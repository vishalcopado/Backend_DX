public with sharing class MCDDConfigurationChecker {
    @InvocableMethod(label='Check if MCDD is applicable' description='Checks various configurations to determine MCDD applicability')
    public static List<Boolean> checkMCDDConfigurations() {
        List<Boolean> mcddEnabledResults  = new List<Boolean>();
        DataDeploy.CheckConfigurationRequest request = new DataDeploy.CheckConfigurationRequest();
        DataDeploy.CheckConfigurationResult result = DataDeploy.DataDeployConfiguration.checkConfiguration(request);
        mcddEnabledResults.add(result.isMCDDEnabled);
        return mcddEnabledResults;   
    }
}