@IsTest
public class CheckVlocityEnabledTest {
    private static final String APINAME = 'vlocity_enabled';
    private static final String ADMIN_USERNAME = 'username-admin@myemail.com';

    @TestSetup
    private static void setup() {
        TestUtilities.setup();
        TestUtilities.setupAdminUser(ADMIN_USERNAME);
    }

    @IsTest
    private static void checkSystemPropertySharingSuccess() {
        Pipeline pipeline;
        System.runAs(TestUtilities.getRunAsUser(ADMIN_USERNAME)) {
            //SETUP
            pipeline = TestUtilities.createPipeline(TestUtilities.createRepository(), 'SFDX');

            createSystemProperties(pipeline, 'true', APINAME).persist();
        }
        System.runAs(TestUtilities.getRunAsUser()) {
            Boolean vlocityEnabled;

            //EXERCISE
            Test.startTest();
            vlocityEnabled = CheckVlocityEnabled.execute(pipeline.Id);
            Test.stopTest();

            //VERIFY
            Assert.isTrue(vlocityEnabled, 'Vlocity should be enabled');
        }
    }

    @IsTest
    private static void checkVlocityEnabledSuccess() {
        System.runAs(TestUtilities.getRunAsUser()) {
            //SETUP
            Boolean vlocityEnabled;
            Pipeline pipeline = TestUtilities.createPipeline(TestUtilities.createRepository(), 'SFDX');

            createSystemProperties(pipeline, 'true', APINAME).persist();

            //EXERCISE
            Test.startTest();
            vlocityEnabled = CheckVlocityEnabled.execute(pipeline.Id);
            Test.stopTest();

            //VERIFY
            Assert.isTrue(vlocityEnabled, 'Vlocity should be enabled');
        }
    }

    @IsTest
    private static void checkVlocityEnabledOnSalesforceSuccess() {
        System.runAs(TestUtilities.getRunAsUser()) {
            //SETUP
            Boolean vlocityEnabled;
            Pipeline pipeline = TestUtilities.createPipeline(TestUtilities.createRepository(), 'Salesforce');

            createSystemProperties(pipeline, 'true', APINAME);

            //EXERCISE
            Test.startTest();
            vlocityEnabled = CheckVlocityEnabled.execute(pipeline.Id);
            Test.stopTest();

            //VERIFY
            Assert.isFalse(vlocityEnabled, 'Vlocity should not be enabled');
        }
    }

    @IsTest
    private static void checkVlocityDisabledSuccess() {
        System.runAs(TestUtilities.getRunAsUser()) {
            //SETUP
            Boolean vlocityEnabled;
            Pipeline pipeline = TestUtilities.createPipeline(TestUtilities.createRepository(), 'SFDX');

            createSystemProperties(pipeline, 'false', APINAME).persist();

            //EXERCISE
            Test.startTest();
            vlocityEnabled = CheckVlocityEnabled.execute(pipeline.Id);
            Test.stopTest();

            //VERIFY
            Assert.isFalse(vlocityEnabled, 'Vlocity should not be enabled');
        }
    }

    @IsTest
    private static void checkVlocityInvalidSystemPropertyFailure() {
        System.runAs(TestUtilities.getRunAsUser()) {
            //SETUP
            Boolean vlocityEnabled;
            Pipeline pipeline = TestUtilities.createPipeline(TestUtilities.createRepository(), 'SFDX');

            createSystemProperties(pipeline, 'false', 'vlocity_enabled_invalid_api_name').persist();

            //EXERCISE
            Test.startTest();
            vlocityEnabled = CheckVlocityEnabled.execute(pipeline.Id);
            Test.stopTest();

            //VERIFY
            Assert.isFalse(vlocityEnabled, 'Vlocity should not be enabled');
        }
    }

    @IsTest
    private static void checkVlocityEnabledFailure() {
        System.runAs(TestUtilities.getRunAsUser()) {
            //SETUP
            Boolean vlocityEnabled;

            //EXERCISE
            Test.startTest();
            vlocityEnabled = CheckVlocityEnabled.execute(fflib_IDGenerator.generate(copado__Deployment_Flow__c.SObjectType));
            Test.stopTest();

            //VERIFY
            Assert.isFalse(vlocityEnabled, 'Vlocity should not be enabled');
        }
    }

    private static SystemProperty createSystemProperties(Pipeline pipeline, String value, String apiName) {
        return new SystemProperty(pipeline).apiName(apiName).value(value);
    }
}