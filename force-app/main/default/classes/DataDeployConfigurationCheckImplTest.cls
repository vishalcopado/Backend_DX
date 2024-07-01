@IsTest
private class DataDeployConfigurationCheckImplTest {
    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void executeWithMCDDEnabledByDefault() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP + EXERCISE
            Test.startTest();
            DataDeploy.CheckConfigurationRequest request = new DataDeploy.CheckConfigurationRequest();
            DataDeploy.CheckConfigurationResult result = DataDeployConfigurationCheckImpl.execute(request);
            Test.stopTest();

            // VERIFY
            Assert.isTrue(result.isMCDDEnabled, 'MCDD Feature must be Enabled by default');
        }
    }

    @IsTest
    private static void executeWithMCDDDisabledGlobally() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            new SystemProperty().apiName(DataDeployConfigurationCheckImpl.MCDD_Disabled).value('true').isGlobal(true).persist();

            // EXERCISE
            Test.startTest();
            DataDeploy.CheckConfigurationRequest request = new DataDeploy.CheckConfigurationRequest();
            DataDeploy.CheckConfigurationResult result = DataDeployConfigurationCheckImpl.execute(request);
            Test.stopTest();

            // VERIFY
            Assert.isFalse(result.isMCDDEnabled, 'MCDD Feature must be disabled');
        }
    }

    @IsTest
    private static void executeWithMCDDDisabledInPipeline() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            Pipeline pipeline = getPipelineObj();
            createSystemProperties(pipeline, 'true', DataDeployConfigurationCheckImpl.MCDD_Disabled).persist();
            DataDeploy.CheckConfigurationRequest request = new DataDeploy.CheckConfigurationRequest();
            request.pipelineId = pipeline.Id;

            // EXERCISE
            Test.startTest();
            DataDeploy.CheckConfigurationResult result = DataDeployConfigurationCheckImpl.execute(request);
            Test.stopTest();

            // VERIFY
            Assert.isFalse(result.isMCDDEnabled, 'MCDD Feature must be disabled in pipeline');
        }
    }

    // HELPER

    private static void createData() {
        System.runAs(TestUtilities.getRunAsUser()) {
            new Pipeline().name('MyPipeline').mainBranch('main').platform('SFDX').persist();
        }
    }

    private static SystemProperty createSystemProperties(Pipeline pipeline, String value, String apiName) {
        return new SystemProperty(pipeline).apiName(apiName).value(value);
    }

    private static Pipeline getPipelineObj() {
        return new Pipeline().recordId(getPipeline().Id);
    }

    private static copado__Deployment_Flow__c getPipeline() {
        return [
            SELECT Id, copado__Git_Repository__r.Name
            FROM copado__Deployment_Flow__c
            LIMIT 1
        ];
    }
}