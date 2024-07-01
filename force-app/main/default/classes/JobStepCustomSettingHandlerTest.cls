@IsTest
private class JobStepCustomSettingHandlerTest {
    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void getCustomSettings() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            String content = '{"records":[{"QualifiedApiName":"PackageVersionInstallationKey__c","DeveloperName":"PackageVersionInstallationKey"}]}';
            JobStepCustomSettingHandler.mockResponse = mockResponse(200, content);

            // EXERCISE

            Test.startTest();
            List<Object> records = JobStepCustomSettingHandler.getCustomSettings(getCredentialId());
            Test.stopTest();

            // VERIFY

            Map<String, Object> record = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(records[0]));
            System.assertEquals(
                'PackageVersionInstallationKey__c',
                (String) record.get('QualifiedApiName'),
                'Should return QualifiedApiName of Custom Setting'
            );
            System.assertEquals('PackageVersionInstallationKey', (String) record.get('DeveloperName'), 'Should return developer name');
        }
    }

    @IsTest
    private static void getRecordsWithData() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            String customSettingRecordId = fflib_IDGenerator.generate('a1w');
            String orgRecordId = fflib_IDGenerator.generate('00D');
            String content = '{"records":[{"Id":"' + customSettingRecordId + '","Name":"test","SetupOwnerId":"' + orgRecordId + '"}]}';
            JobStepCustomSettingHandler.mockResponse = mockResponse(200, content);

            // EXERCISE

            Test.startTest();
            Map<String, Object> result = JobStepCustomSettingHandler.getRecords('PackageVersionInstallationKey__c', getCredentialId());
            Test.stopTest();

            // VERIFY

            System.assertEquals(true, (Boolean) result.get('isSuccess'), 'The isSuccess parameter of result should be true');
            List<Object> records = (List<Object>) result.get('customSetting');
            Map<String, Object> record = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(records[0]));
            System.assertEquals(customSettingRecordId, (String) record.get('Id'), 'Should return Id of Custom Setting record');
            System.assertEquals('test', (String) record.get('Name'), 'Should return developer name');
            System.assertEquals(orgRecordId, (String) record.get('SetupOwnerId'), 'Should return SetupOwnerId');
        }
    }

    @IsTest
    private static void getRecordsWithoutData() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            JobStepCustomSettingHandler.mockResponse = mockResponse(200, '{"records":[]}');

            // EXERCISE

            Test.startTest();
            Map<String, Object> result = JobStepCustomSettingHandler.getRecords('PackageVersionInstallationKey__c', getCredentialId());
            Test.stopTest();

            // VERIFY

            System.assertEquals(false, (Boolean) result.get('isSuccess'), 'The isSuccess parameter of result should be false');
            System.assertEquals(
                Label.NoCustomSettingRecords,
                (String) result.get('message'),
                'The message parameter of result should be ' + Label.NoCustomSettingRecords
            );
        }
    }

    @IsTest
    private static void getRecordsWithException() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            JobStepCustomSettingHandler.mockResponse = mockResponse(400, '{"records":[]}');

            // EXERCISE

            Test.startTest();
            Map<String, Object> result = JobStepCustomSettingHandler.getRecords('PackageVersionInstallationKey__c', getCredentialId());
            Test.stopTest();

            // VERIFY

            System.assertEquals(false, (Boolean) result.get('isSuccess'), 'The isSuccess parameter of result should be false');
            System.assert(String.isNotBlank((String) result.get('message')), 'The message parameter of result should not be empty');
        }
    }

    @IsTest
    private static void getCustomSettingDependantRecordsForProfile() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            String customSettingRecordId = fflib_IDGenerator.generate('a1w');
            String profileRecordId = fflib_IDGenerator.generate('00e');
            String data = '{"records":[{"Id":"' + customSettingRecordId + '","Name":"test","SetupOwnerId":"' + profileRecordId + '"}]}';
            Map<String, Object> contentData = (Map<String, Object>) JSON.deserializeUntyped(data);
            Map<String, String> objectKeyPrefixes = JobStepCustomSettingHandler.getObjectKeyPrefix();
            String content = '{"records":[{"Id":"' + profileRecordId + '","Name":"Sample Profile"}]}';
            JobStepCustomSettingHandler.mockResponse = mockResponse(200, content);

            // EXERCISE

            Test.startTest();
            Map<String, Object> result = JobStepCustomSettingHandler.getCustomSettingDependantRecords(
                (List<Object>) contentData.get('records'),
                objectKeyPrefixes,
                getCredentialId()
            );
            Test.stopTest();

            // VERIFY

            List<Object> records = (List<Object>) result.get('profile');
            Map<String, Object> record = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(records[0]));
            System.assertEquals(profileRecordId, (String) record.get('Id'), 'Should return Id of profile');
            System.assertEquals('Sample Profile', (String) record.get('Name'), 'Should return name of profile');
        }
    }

    @IsTest
    private static void getCustomSettingDependantRecordsForUser() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            String customSettingRecordId = fflib_IDGenerator.generate('a1w');
            String userRecordId = fflib_IDGenerator.generate('005');
            String data = '{"records":[{"Id":"' + customSettingRecordId + '","Name":"test","SetupOwnerId":"' + userRecordId + '"}]}';
            Map<String, Object> contentData = (Map<String, Object>) JSON.deserializeUntyped(data);
            Map<String, String> objectKeyPrefixes = JobStepCustomSettingHandler.getObjectKeyPrefix();
            String content = '{"records":[{"Id":"' + userRecordId + '","Name":"Sample User"}]}';
            JobStepCustomSettingHandler.mockResponse = mockResponse(200, content);

            // EXERCISE

            Test.startTest();
            Map<String, Object> result = JobStepCustomSettingHandler.getCustomSettingDependantRecords(
                (List<Object>) contentData.get('records'),
                objectKeyPrefixes,
                getCredentialId()
            );
            Test.stopTest();

            // VERIFY

            List<Object> records = (List<Object>) result.get('user');
            Map<String, Object> record = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(records[0]));
            System.assertEquals(userRecordId, (String) record.get('Id'), 'Should return Id of user');
            System.assertEquals('Sample User', (String) record.get('Name'), 'Should return name of user');
        }
    }

    @IsTest
    private static void getCustomSettingDependantRecordsForOrganization() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            String customSettingRecordId = fflib_IDGenerator.generate('a1w');
            String orgRecordId = fflib_IDGenerator.generate('00D');
            String data = '{"records":[{"Id":"' + customSettingRecordId + '","Name":"test","SetupOwnerId":"' + orgRecordId + '"}]}';
            Map<String, Object> contentData = (Map<String, Object>) JSON.deserializeUntyped(data);
            Map<String, String> objectKeyPrefixes = JobStepCustomSettingHandler.getObjectKeyPrefix();
            String content = '{"records":[{"Id":"' + orgRecordId + '","Name":"Sample Org"}]}';
            JobStepCustomSettingHandler.mockResponse = mockResponse(200, content);

            // EXERCISE

            Test.startTest();
            Map<String, Object> result = JobStepCustomSettingHandler.getCustomSettingDependantRecords(
                (List<Object>) contentData.get('records'),
                objectKeyPrefixes,
                getCredentialId()
            );
            Test.stopTest();

            // VERIFY

            List<Object> records = (List<Object>) result.get('organization');
            Map<String, Object> record = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(records[0]));
            System.assertEquals(orgRecordId, (String) record.get('Id'), 'Should return Id of org');
            System.assertEquals('Sample Org', (String) record.get('Name'), 'Should return name of org');
        }
    }

    @IsTest
    private static void getFunctionDetails() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id functionId = getFunctionId();

            // EXERCISE

            Test.startTest();
            List<copado__Function__c> functions = JobStepCustomSettingHandler.getFunctionDetails('TestFunction');
            Test.stopTest();

            // VERIFY

            System.assertEquals(functionId, functions[0].Id, 'Function id should be ' + functionId);
        }
    }

    // HELPER

    private static copado.GlobalAPI.ProxyOrgResponse mockResponse(Integer statusCode, String content) {
        return TestUtilities.getMockedResponse(JSON.serialize(new Map<String, Object>{ 'statusCode' => statusCode, 'content' => content }));
    }

    private static void createData() {
        Credential credential = new Credential(new Environment().type('Production/Developer')).type('Production/Developer');
        new UserStory().title('US 1').status('Draft').credential(credential).persist();

        new Function().name('TestFunction').apiName('TestFunction').persist();
    }

    private static Id getCredentialId() {
        return [SELECT copado__Org_Credential__c FROM copado__User_Story__c LIMIT 1].copado__Org_Credential__c;
    }

    private static Id getFunctionId() {
        return [SELECT Id FROM copado__Function__c LIMIT 1].Id;
    }
}