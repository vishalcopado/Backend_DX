@IsTest
public with sharing class PackageVersionIdsTest {
    private static Id deploymentJobId = createFakeId(copado__JobExecution__c.SObjectType);
    private static Id subscriberId = createFakeId('04t');

    @TestSetup
    private static void setupData() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void getPackageVersionIdsSuccess() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            JobTemplate template = TestUtilities.getTemplateObj('SFDX Package Distribution_1');
            SObject jobExecution = TestUtilities.createJobExecution(template, TestUtilities.getEnvironmentObj('Environment Test 2'), getDataJson())
                .persist();

            PackageVersionIds.Request request = new PackageVersionIds.Request();
            request.subscriberId = getRequest();
            request.jobExecutionId = jobExecution.Id;
            request.dataJson = getDataJson();

            // EXERCISE

            Test.startTest();
            List<PackageVersionIds.Result> results = PackageVersionIds.packageVersionsBydId(new List<PackageVersionIds.Request>{ request });
            Test.stopTest();

            // VERIFY

            Assert.areEqual(1, results[0].versions.size(), 'Only successful version should be in the result');
            PackageVersionIds.DataJson data = (PackageVersionIds.DataJson) JSON.deserialize(
                TestUtilities.getJobExecution(jobExecution.Id).copado__DataJson__c,
                PackageVersionIds.DataJson.class
            );
            Assert.areEqual('****', data.installationKey, 'Installation Key in Data Json of Job Execution should be masked');
            Assert.areEqual('54.0', data.apiVersion, 'Api Version should be same');
            Assert.areEqual(deploymentJobId, data.deploymentJobId, 'Deployment Job Id should be same');
            Assert.areEqual('AdminsOnly', data.installSecurityType, 'Install Security Type should be same');
            Assert.areEqual(subscriberId, data.subscriberId, 'Subscriber Id should be same');
        }
    }

    @IsTest
    private static void invalidSubscriberIdFailure() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            String exceptionMessage;
            JobTemplate template = TestUtilities.getTemplateObj('SFDX Package Distribution_1');

            SObject jobExecution = TestUtilities.createJobExecution(template, TestUtilities.getEnvironmentObj('Environment Test 2'), getDataJson())
                .persist();

            PackageVersionIds.Request request = new PackageVersionIds.Request();
            request.subscriberId = 'Invalid Request';
            request.jobExecutionId = jobExecution.Id;
            request.dataJson = getDataJson();

            // EXERCISE

            Test.startTest();
            try {
                PackageVersionIds.packageVersionsBydId(new List<PackageVersionIds.Request>{ request });
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();

            // VERIFY

            Assert.isTrue(exceptionMessage.contains('Unexpected character'), '');
            PackageVersionIds.DataJson data = (PackageVersionIds.DataJson) JSON.deserialize(
                TestUtilities.getJobExecution(jobExecution.Id).copado__DataJson__c,
                PackageVersionIds.DataJson.class
            );
            Assert.areEqual('installation key here', data.installationKey, 'Installation Key in Data Json of Job Execution should be masked');
            Assert.areEqual('54.0', data.apiVersion, 'Api Version should be same');
            Assert.areEqual(deploymentJobId, data.deploymentJobId, 'Deployment Job Id should be same');
            Assert.areEqual('AdminsOnly', data.installSecurityType, 'Install Security Type should be same');
            Assert.areEqual(subscriberId, data.subscriberId, 'Subscriber Id should be same');
        }
    }

    @IsTest
    private static void invalidJobExecutionIdFailure() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            String exceptionMessage;
            JobTemplate template = TestUtilities.getTemplateObj('SFDX Package Distribution_1');

            SObject jobExecution = TestUtilities.createJobExecution(template, TestUtilities.getEnvironmentObj('Environment Test 2'), getDataJson())
                .persist();

            PackageVersionIds.Request request = new PackageVersionIds.Request();
            request.subscriberId = getRequest();
            request.jobExecutionId = createFakeId('04t');
            request.dataJson = getDataJson();

            // EXERCISE

            Test.startTest();
            try {
                PackageVersionIds.packageVersionsBydId(new List<PackageVersionIds.Request>{ request });
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();

            // VERIFY

            Assert.isTrue(exceptionMessage.contains('Invalid id value'), '');
            PackageVersionIds.DataJson data = (PackageVersionIds.DataJson) JSON.deserialize(
                TestUtilities.getJobExecution(jobExecution.Id).copado__DataJson__c,
                PackageVersionIds.DataJson.class
            );
            Assert.areEqual('installation key here', data.installationKey, 'Installation Key in Data Json of Job Execution should be masked');
            Assert.areEqual('54.0', data.apiVersion, 'Api Version should be same');
            Assert.areEqual(deploymentJobId, data.deploymentJobId, 'Deployment Job Id should be same');
            Assert.areEqual('AdminsOnly', data.installSecurityType, 'Install Security Type should be same');
            Assert.areEqual(subscriberId, data.subscriberId, 'Subscriber Id should be same');
        }
    }

    @IsTest
    private static void invalidDataJsonFailure() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            String exceptionMessage;
            JobTemplate template = TestUtilities.getTemplateObj('SFDX Package Distribution_1');
            SObject jobExecution = TestUtilities.createJobExecution(template, TestUtilities.getEnvironmentObj('Environment Test 2'), getDataJson())
                .persist();

            PackageVersionIds.Request request = new PackageVersionIds.Request();
            request.subscriberId = getRequest();
            request.jobExecutionId = jobExecution.Id;
            request.dataJson = 'Invalid Data json';

            // EXERCISE

            Test.startTest();
            try {
                PackageVersionIds.packageVersionsBydId(new List<PackageVersionIds.Request>{ request });
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();

            // VERIFY

            Assert.isTrue(exceptionMessage.contains('Unexpected character'), '');
            PackageVersionIds.DataJson data = (PackageVersionIds.DataJson) JSON.deserialize(
                TestUtilities.getJobExecution(jobExecution.Id).copado__DataJson__c,
                PackageVersionIds.DataJson.class
            );
            Assert.areEqual('installation key here', data.installationKey, 'Installation Key in Data Json of Job Execution should be masked');
            Assert.areEqual('54.0', data.apiVersion, 'Api Version should be same');
            Assert.areEqual(deploymentJobId, data.deploymentJobId, 'Deployment Job Id should be same');
            Assert.areEqual('AdminsOnly', data.installSecurityType, 'Install Security Type should be same');
            Assert.areEqual(subscriberId, data.subscriberId, 'Subscriber Id should be same');
        }
    }

    private static String getRequest() {
        return '[{"versionId":"' +
            TestUtilities.getPackageVersions()[0].copado__Subscriber_Version_Id__c +
            '","status":"success"}, {"versionId":"' +
            createFakeId('04t') +
            '","status":"skipped"}]';
    }

    private static void createData() {
        TestUtilities.createEnvironment('Environment Test 2');
        TestUtilities.createJobTemplate('SFDX Package Distribution_1').persist();
        createPackageVersion(createPackage(TestUtilities.createRepository(), 'Unlocked', null)).persist();
    }

    private static Artifact createPackage(Repository repo, String type, Credential cred) {
        return new Artifact(repo).name('Testpkg').type(type).recordTypeId('Package_Artifact').targetDevHub(cred);
    }

    private static Id createFakeId(String keyPrefix) {
        return fflib_IDGenerator.generate(keyPrefix);
    }

    private static Id createFakeId(SObjectType keyPrefix) {
        return fflib_IDGenerator.generate(keyPrefix);
    }

    private static ArtifactVersion createPackageVersion(Artifact pkg) {
        return new ArtifactVersion(pkg)
            .name('ver 0.1')
            .versionNumber('0.1.0.1')
            .versionId(createFakeId('04t'))
            .description('Winter 20XX Release')
            .ancestorId(createFakeId('04t'));
    }

    private static String getDataJson() {
        return '{"subscriberId":"' +
            subscriberId +
            '","installSecurityType":"AdminsOnly","installationKey":"installation key here","deploymentJobId":"' +
            deploymentJobId +
            '","apiVersion":"54.0"}';
    }
}