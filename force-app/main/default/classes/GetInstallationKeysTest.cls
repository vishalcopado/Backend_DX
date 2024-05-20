@IsTest
private class GetInstallationKeysTest {
    private static final String CHILD_VERSION_ID = fflib_IDGenerator.generate('04t');
    private static final String PARENT_VERSION_ID = fflib_IDGenerator.generate('04t');

    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void withKeysSuccess() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            createJobStep('Get dependencies', 'Function', getResult().Id, 1);
            createJobStep('Install Package', 'Function', null, 2);

            addInstallationKeys();

            // EXERCISE

            String data = new GetInstallationKeys().execute(getJobStep('Install Package').Id);

            // VERIFY

            List<GetInstallationKeys.Response> responses = (List<GetInstallationKeys.Response>) JSON.deserialize(
                data,
                List<GetInstallationKeys.Response>.class
            );
            Assert.areEqual('parent key here', responses[0].key, 'Key should be what is provided in Custom Setting');
            Assert.areEqual(PARENT_VERSION_ID, responses[0].id, 'Id should be same as in dependencies');
            Assert.areEqual(2, responses.size(), 'Package Versions with Dependencies and keys should be returned.');
            Assert.areEqual(CHILD_VERSION_ID, responses[1].id, 'Package Version should be last element.');
            Assert.areEqual('child key here', responses[1].key, 'Key should be what is provided in Custom Setting');
            Assert.areEqual('0.1.0.4', responses[1].versionNumber, 'Version Number should be same as the package version');
            Assert.areEqual('033XX', responses[1].subscriberPackageId, 'Subscriber Package Id should be same as the package version');
        }
    }

    @IsTest
    private static void withoutKeysSuccess() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            createJobStep('Get Dependencies', 'Function', getResult().Id, 1);
            createJobStep('Install Package', 'Function', null, 2);

            // EXERCISE

            String data = new GetInstallationKeys().execute(getJobStep('Install Package').Id);

            // VERIFY

            List<GetInstallationKeys.Response> responses = (List<GetInstallationKeys.Response>) JSON.deserialize(
                data,
                List<GetInstallationKeys.Response>.class
            );
            Assert.areEqual(null, responses[0].key, 'Key should be null');
            Assert.areEqual(PARENT_VERSION_ID, responses[0].id, 'Id should be same as in dependencies');
            Assert.areEqual(2, responses.size(), 'Package Version with Dependencies and keys should be returned.');
            Assert.areEqual(CHILD_VERSION_ID, responses[1].id, 'Package Version should be last element.');
            Assert.areEqual(null, responses[1].key, 'Key should be null');
            Assert.areEqual('0.1.0.4', responses[1].versionNumber, 'Version Number should be same as the package version');
            Assert.areEqual('033XX', responses[1].subscriberPackageId, 'Subscriber Package Id should be same as the package version');
        }
    }

    @IsTest
    private static void noJobStepFailure() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            createJobStep('Get Dependencies', 'Function', getResult().Id, 3);
            createJobStep('Install Package', 'Function', null, 2);
            String exceptionMessage;

            // EXERCISE

            try {
                new GetInstallationKeys().execute(getJobStep('Install Package').Id);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            // VERIFY

            Assert.isTrue(
                exceptionMessage.contains(Label.JobStepsNotConfiguredCorrectly),
                'Exception should be thrown here as job step order is not correct'
            );
        }
    }

    private static void createData() {
        createResult(
            '{"subscriberVersionId":"' +
            CHILD_VERSION_ID +
            '","dependencies":["' +
            PARENT_VERSION_ID +
            '"],"versionNumber":"0.1.0.4","subscriberPackageId":"033XX"}'
        );

        createJobTemplate('SFDX Package Distribution');
    }

    private static void createJobTemplate(String name) {
        new JobTemplate().name(name).persist();
    }

    private static void createResult(String resultData) {
        new Result().data(resultData).type('SFDX_Get_Package_Version_Dependencies').persist();
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static void createJobStep(String name, String type, Id result, Integer order) {
        new JobStep(getTemplateObj()).name(name).type(type).result(result).order(order).persist();
    }

    private static void addInstallationKeys() {
        List<PackageVersionInstallationKey__c> keys = new List<PackageVersionInstallationKey__c>();
        PackageVersionInstallationKey__c versionKey = new PackageVersionInstallationKey__c(
            Name = 'parentPckgVersion@1.0.0-1',
            PackageVersionId__c = PARENT_VERSION_ID,
            InstallationKey__c = 'parent key here'
        );
        PackageVersionInstallationKey__c versionKey1 = new PackageVersionInstallationKey__c(
            Name = 'childPckgVersion@1.0.0-1',
            PackageVersionId__c = CHILD_VERSION_ID,
            InstallationKey__c = 'child key here'
        );
        keys.add(versionKey);
        keys.add(versionKey1);

        insert keys;
    }

    private static JobTemplate getTemplateObj() {
        return new JobTemplate().recordId(getJobTemplate().Id);
    }

    private static copado__Result__c getResult() {
        return [SELECT copado__Result_Data__c FROM copado__Result__c LIMIT 1];
    }

    private static copado__JobStep__c getJobStep(String name) {
        return [SELECT copado__Order__c FROM copado__JobStep__c WHERE NAme = :name LIMIT 1];
    }

    private static copado__JobTemplate__c getJobTemplate() {
        return [SELECT Name, copado__Version__c FROM copado__JobTemplate__c LIMIT 1];
    }
}