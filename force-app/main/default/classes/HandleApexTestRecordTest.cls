@IsTest
private class HandleApexTestRecordTest {
    private final static String COPADO_COMMIT_CHANGES = 'Copado Commit changes';
    private final static String USER_SELECTIONS_FILENAME = 'cmcSf_TestClasses';

    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void validateApextTesRecordWithNoApex() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id userStoryId = getUserStoryId();
            List<HandleApexTestRecord.Request> requests = new List<HandleApexTestRecord.Request>();
            HandleApexTestRecord.Request request = new HandleApexTestRecord.Request();
            request.userStoryId = userStoryId;
            request.recreateFeatureBranch = false;
            request.fileWithSelectedChanges = createFile(COPADO_COMMIT_CHANGES, getCommitChangesWithoutApex(), userStoryId);
            request.commitResult = '{ "commitId": "8b39a059c2035a5fac3a26a33abf4f084f0750e" }';
            requests.add(request);

            GetAllTestClassesFromOrg.mockResponse = getResponse();
            createExtensionConfiguration();

            // EXERCISE

            Test.startTest();
            List<HandleApexTestRecord.Response> response = HandleApexTestRecord.execute(requests);
            Test.stopTest();

            // VERIFY

            List<copado__Test__c> apexTests = getApexTest(userStoryId);
            Assert.areEqual(0, apexTests.size(), 'copado__Test__c records should not be created for the user story');
            Assert.isTrue(response.isEmpty(), 'The response should be empty');
        }
    }

    @IsTest
    private static void validateApextTesRecordWithNoApexWithRecreateFeatureBranch() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id userStoryId = getUserStoryId();
            List<HandleApexTestRecord.Request> requests = new List<HandleApexTestRecord.Request>();
            HandleApexTestRecord.Request request = new HandleApexTestRecord.Request();
            request.userStoryId = userStoryId;
            request.recreateFeatureBranch = true;
            request.fileWithSelectedChanges = createFile(COPADO_COMMIT_CHANGES, getCommitChangesWithoutApex(), userStoryId);
            request.commitResult = '{ "commitId": "8b39a059c2035a5fac3a26a33abf4f084f0750e" }';
            requests.add(request);

            GetAllTestClassesFromOrg.mockResponse = getResponse();
            Id extensionConfigurationId = createExtensionConfiguration();
            Id testId = createApexTest(userStoryId, extensionConfigurationId);
            createFile(USER_SELECTIONS_FILENAME, getTestClassesFileContent(), testId);

            // EXERCISE

            Test.startTest();
            List<HandleApexTestRecord.Response> response = HandleApexTestRecord.execute(requests);
            Test.stopTest();

            // VERIFY

            List<copado__Test__c> apexTests = getApexTest(userStoryId);
            Assert.areEqual(0, apexTests.size(), 'copado__Test__c records should not be created for the user story');
            Assert.isTrue(response.isEmpty(), 'The response should be empty');
        }
    }

    @IsTest
    private static void validateApextTesRecordWithNoExtension() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id userStoryId = getUserStoryId();
            List<HandleApexTestRecord.Request> requests = new List<HandleApexTestRecord.Request>();
            HandleApexTestRecord.Request request = new HandleApexTestRecord.Request();
            request.userStoryId = userStoryId;
            request.recreateFeatureBranch = false;
            request.fileWithSelectedChanges = createFile(COPADO_COMMIT_CHANGES, getCommitChangesWithApex(), userStoryId);
            request.commitResult = '{ "commitId": "8b39a059c2035a5fac3a26a33abf4f084f0750e" }';
            requests.add(request);

            GetAllTestClassesFromOrg.mockResponse = getResponse();

            // EXERCISE

            Test.startTest();
            List<HandleApexTestRecord.Response> response = HandleApexTestRecord.execute(requests);
            Test.stopTest();

            // VERIFY

            List<copado__Test__c> apexTests = getApexTest(userStoryId);
            Assert.areEqual(0, apexTests.size(), 'copado__Test__c records should not be created for the user story');
            Assert.isFalse(response.isEmpty(), 'The response should not be empty');
            Assert.isTrue(
                response[0].message.contains(Label.Extension_Configuration_Missing),
                'The response should be present with the message, configuration record not found'
            );
        }
    }

    @IsTest
    private static void validateApextTesRecordWithNoChanges() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id userStoryId = getUserStoryId();
            List<HandleApexTestRecord.Request> requests = new List<HandleApexTestRecord.Request>();
            HandleApexTestRecord.Request request = new HandleApexTestRecord.Request();
            request.userStoryId = userStoryId;
            request.recreateFeatureBranch = false;
            request.fileWithSelectedChanges = createFile(COPADO_COMMIT_CHANGES, getCommitChangesWithApex(), userStoryId);
            request.commitResult = '{ "status": "No Changes" }';
            requests.add(request);

            GetAllTestClassesFromOrg.mockResponse = getResponse();

            // EXERCISE

            Test.startTest();
            List<HandleApexTestRecord.Response> response = HandleApexTestRecord.execute(requests);
            Test.stopTest();

            // VERIFY

            List<copado__Test__c> apexTests = getApexTest(userStoryId);
            Assert.areEqual(0, apexTests.size(), 'copado__Test__c records should not be created for the user story');
            Assert.isTrue(response.isEmpty(), 'The response should be empty');
        }
    }

    @IsTest
    private static void validateApextTesRecordWithApex() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id userStoryId = getUserStoryId();
            createMetadata(userStoryId);

            List<HandleApexTestRecord.Request> requests = new List<HandleApexTestRecord.Request>();
            HandleApexTestRecord.Request request = new HandleApexTestRecord.Request();
            request.userStoryId = userStoryId;
            request.recreateFeatureBranch = false;
            request.fileWithSelectedChanges = createFile(COPADO_COMMIT_CHANGES, getCommitChangesWithApex(), userStoryId);
            request.commitResult = '{ "commitId": "8b39a059c2035a5fac3a26a33abf4f084f0750e" }';
            requests.add(request);

            GetAllTestClassesFromOrg.mockResponse = getResponse();
            createExtensionConfiguration();

            // EXERCISE

            Test.startTest();
            List<HandleApexTestRecord.Response> response = HandleApexTestRecord.execute(requests);
            Test.stopTest();

            // VERIFY

            List<copado__Test__c> apexTests = getApexTest(userStoryId);
            Assert.areEqual(1, apexTests.size(), 'copado__Test__c records should be created for the user story');
            Assert.areEqual(
                '[{"t":"ApexClass","s":false,"ns":"copado","n":"fflib_IDGeneratorTest","md":"2022-03-09T14:53:33.000+0000","mb":"User User","cm":false},{"t":"ApexClass","s":true,"ns":"copado","n":"DXControllerTest","md":"2022-03-09T14:53:33.000+0000","mb":"User User","cm":true},{"t":"ApexClass","s":true,"ns":"copado","n":"SampleClassTest","md":"2022-03-09T14:53:33.000+0000","mb":"User User","cm":true}]',
                getContentVersionData(apexTests[0].Id),
                'The test record should have the committed class as one of the selected classes'
            );
            Assert.isTrue(response.isEmpty(), 'The response should be empty');
        }
    }

    @IsTest
    private static void validateApextTesRecordWithApexWithExistingTestRecord() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id userStoryId = getUserStoryId();
            createMetadata(userStoryId);

            List<HandleApexTestRecord.Request> requests = new List<HandleApexTestRecord.Request>();
            HandleApexTestRecord.Request request = new HandleApexTestRecord.Request();
            request.userStoryId = userStoryId;
            request.recreateFeatureBranch = false;
            request.fileWithSelectedChanges = createFile(COPADO_COMMIT_CHANGES, getCommitChangesWithApex(), userStoryId);
            request.commitResult = '{ "commitId": "8b39a059c2035a5fac3a26a33abf4f084f0750e" }';
            requests.add(request);

            GetAllTestClassesFromOrg.mockResponse = getResponse();
            Id extensionConfigurationId = createExtensionConfiguration();
            Id testId = createApexTest(userStoryId, extensionConfigurationId);
            createFile(USER_SELECTIONS_FILENAME, getTestClassesFileContent(), testId);

            // EXERCISE

            Test.startTest();
            List<HandleApexTestRecord.Response> response = HandleApexTestRecord.execute(requests);
            Test.stopTest();

            // VERIFY

            List<copado__Test__c> apexTests = getApexTest(userStoryId);
            Assert.areEqual(1, apexTests.size(), 'copado__Test__c records should be created for the user story');
            Assert.areEqual(
                '[{"t":"ApexClass","s":false,"ns":"copado","n":"fflib_IDGeneratorTest","md":"2022-03-09T14:53:33.000+0000","mb":"User User","cm":false},{"t":"ApexClass","s":true,"ns":"copado","n":"DXControllerTest","md":"2022-03-09T14:53:33.000+0000","mb":"User User","cm":true},{"t":"ApexClass","s":true,"ns":"copado","n":"SampleClassTest","md":"2022-03-09T14:53:33.000+0000","mb":"User User","cm":true}]',
                getContentVersionData(apexTests[0].Id),
                'The test record should have the committed class as one of the selected classes'
            );
            Assert.isTrue(response.isEmpty(), 'The response should be empty');
        }
    }

    @IsTest
    private static void validateApextTesRecordWithApexWithRecreateFeatureBranch() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id userStoryId = getUserStoryId();
            createMetadata(userStoryId);

            List<HandleApexTestRecord.Request> requests = new List<HandleApexTestRecord.Request>();
            HandleApexTestRecord.Request request = new HandleApexTestRecord.Request();
            request.userStoryId = userStoryId;
            request.recreateFeatureBranch = true;
            request.fileWithSelectedChanges = createFile(COPADO_COMMIT_CHANGES, getCommitChangesWithApex(), userStoryId);
            request.commitResult = '{ "commitId": "8b39a059c2035a5fac3a26a33abf4f084f0750e" }';
            requests.add(request);

            GetAllTestClassesFromOrg.mockResponse = getResponse();
            Id extensionConfigurationId = createExtensionConfiguration();
            Id testId = createApexTest(userStoryId, extensionConfigurationId);
            createFile(USER_SELECTIONS_FILENAME, getTestClassesFileContent(), testId);

            // EXERCISE

            Test.startTest();
            List<HandleApexTestRecord.Response> response = HandleApexTestRecord.execute(requests);
            Test.stopTest();

            // VERIFY

            List<copado__Test__c> apexTests = getApexTest(userStoryId);
            Assert.areEqual(1, apexTests.size(), 'copado__Test__c records should be created for the user story');
            Assert.areEqual(
                '[{"t":"ApexClass","s":false,"ns":"copado","n":"fflib_IDGeneratorTest","md":"2022-03-09T14:53:33.000+0000","mb":"User User","cm":false},{"t":"ApexClass","s":true,"ns":"copado","n":"DXControllerTest","md":"2022-03-09T14:53:33.000+0000","mb":"User User","cm":true},{"t":"ApexClass","s":false,"ns":"copado","n":"SampleClassTest","md":"2022-03-09T14:53:33.000+0000","mb":"User User","cm":false}]',
                getContentVersionData(apexTests[0].Id),
                'The test record should have the committed class as one of the selected classes'
            );
            Assert.isTrue(response.isEmpty(), 'The response should be empty');
        }
    }

    private static Id createApexTest(Id userStoryId, Id extensionConfigurationId) {
        copado__Test__c test = new copado__Test__c(
            Name = 'US-1 Apex Tests',
            copado__ExtensionConfiguration__c = extensionConfigurationId,
            copado__User_Story__c = userStoryId,
            copado__ReadyToRun__c = true
        );
        insert test;
        return test.Id;
    }

    private static String getContentVersionData(Id recordId) {
        String result;
        List<ContentVersion> contentVersion = [SELECT Id, VersionData FROM ContentVersion WHERE FirstPublishLocationId = :recordId];
        if (!contentVersion.isEmpty()) {
            result = contentVersion[0]?.VersionData?.toString();
        }
        return result;
    }

    private static Id createFile(String fileName, String content, Id recordId) {
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.ContentLocation = 'S'; // S = Stored in Salesforce
        contentVersion.PathOnClient = fileName + '.json';
        contentVersion.Title = fileName;
        contentVersion.VersionData = Blob.valueOf(content);
        contentVersion.FirstPublishLocationId = recordId;
        insert contentVersion;
        return contentVersion.Id;
    }

    private static void createData() {
        Credential credential = new Credential(new Environment().type('Production/Developer')).type('Production/Developer');
        new UserStory().title('US 1').status('Draft').credential(credential).persist();
    }

    private static void createMetadata(Id userStoryId) {
        delete [SELECT Id FROM copado__User_Story_Metadata__c WHERE copado__User_Story__c = :userStoryId];

        List<copado__User_Story_Metadata__c> userStoryMetadata = new List<copado__User_Story_Metadata__c>();
        userStoryMetadata.add(
            new copado__User_Story_Metadata__c(
                copado__Metadata_API_Name__c = 'SampleClass',
                copado__Type__c = 'ApexClass',
                copado__Action__c = 'Add',
                copado__User_Story__c = userStoryId
            )
        );
        userStoryMetadata.add(
            new copado__User_Story_Metadata__c(
                copado__Metadata_API_Name__c = 'SampleTrigger',
                copado__Type__c = 'ApexTrigger',
                copado__Action__c = 'Add',
                copado__User_Story__c = userStoryId
            )
        );
        userStoryMetadata.add(
            new copado__User_Story_Metadata__c(
                copado__Metadata_API_Name__c = 'SampleClassTest',
                copado__Type__c = 'ApexClass',
                copado__Action__c = 'Add',
                copado__User_Story__c = userStoryId
            )
        );

        insert userStoryMetadata;
    }

    private static String getUserStoryId() {
        return [SELECT Id FROM copado__User_Story__c LIMIT 1].Id;
    }

    @SuppressWarnings('PMD.EagerlyLoadedDescribeSObjectResult')
    private static Id createExtensionConfiguration() {
        List<String> picklistValues = Utilities.getPicklistValues(
            SObjectType.copado__ExtensionConfiguration__c.getName(),
            // PMD is giving a false positive here.
            copado__ExtensionConfiguration__c.copado__ExtensionTool__c.getDescribe(FieldDescribeOptions.DEFAULT).getName()
        );

        copado__ExtensionConfiguration__c extensionConfiguration = new copado__ExtensionConfiguration__c(
            Name = 'Apex Tests',
            copado__ExtensionTool__c = !picklistValues.isEmpty() ? picklistValues[0] : '', // As "Apex Tests" value is a manual value we have to use a standard one
            copado__Active__c = true,
            copado__ExtensionApplication__c = 'Test'
        );
        insert extensionConfiguration;
        return extensionConfiguration.Id;
    }

    private static void deleteUserStoryMetadata() {
        delete [SELECT Id FROM copado__User_Story_Metadata__c LIMIT 1];
    }

    private static List<copado__Test__c> getApexTest(Id userStoryId) {
        return [SELECT Id FROM copado__Test__c WHERE copado__User_Story__c = :userStoryId];
    }

    private static string getResponse() {
        return '{' +
            '"statusCode" : 200,' +
            '"content" : "{' +
            '\\"searchRecords\\" : [' +
            '{' +
            '\\"Name\\": \\"fflib_IDGeneratorTest\\",' +
            '\\"LastModifiedDate\\": \\"2022-03-09T14:53:33.000+0000\\",' +
            '\\"LastModifiedBy\\": ' +
            '{' +
            '\\"Name\\": \\"User User\\"' +
            '},' +
            '\\"attributes\\": ' +
            '{' +
            '\\"type\\": \\"ApexClass\\"' +
            '},' +
            '\\"NamespacePrefix\\": \\"copado\\"' +
            '},' +
            '{' +
            '\\"Name\\": \\"DXControllerTest\\",' +
            '\\"LastModifiedDate\\": \\"2022-03-09T14:53:33.000+0000\\",' +
            '\\"LastModifiedBy\\": ' +
            '{' +
            '\\"Name\\": \\"User User\\"' +
            '},' +
            '\\"attributes\\": ' +
            '{' +
            '\\"type\\": \\"ApexClass\\"' +
            '},' +
            '\\"NamespacePrefix\\": \\"copado\\"' +
            '},' +
            '{' +
            '\\"Name\\": \\"SampleClassTest\\",' +
            '\\"LastModifiedDate\\": \\"2022-03-09T14:53:33.000+0000\\",' +
            '\\"LastModifiedBy\\": ' +
            '{' +
            '\\"Name\\": \\"User User\\"' +
            '},' +
            '\\"attributes\\": ' +
            '{' +
            '\\"type\\": \\"ApexClass\\"' +
            '},' +
            '\\"NamespacePrefix\\": \\"copado\\"' +
            '}' +
            ']' +
            '}"' +
            '}';
    }

    private static String getCommitChangesWithoutApex() {
        List<CommitChanges.Change> commitChanges = new List<CommitChanges.Change>();
        commitChanges.add(getCommitChange('CustomObject', 'TestDX', 'File path is handled automatically', '', 'Add'));
        commitChanges.add(getCommitChange('ApexPage', 'DXDashboard', 'File path is handled automatically', '', 'Add'));
        return JSON.serialize(commitChanges);
    }

    private static String getCommitChangesWithApex() {
        List<CommitChanges.Change> commitChanges = new List<CommitChanges.Change>();
        commitChanges.add(getCommitChange('ApexClass', 'DXController', 'File path is handled automatically', '', 'Add'));
        commitChanges.add(getCommitChange('ApexClass', 'DXControllerTest', 'File path is handled automatically', '', 'Add'));
        commitChanges.add(getCommitChange('ApexTrigger', 'TestRecordTrigger', 'File path is handled automatically', '', 'Add'));
        return JSON.serialize(commitChanges);
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static CommitChanges.Change getCommitChange(String type, String name, String module, String category, String action) {
        return new CommitChanges.Change(type, name, module, category, action);
    }

    private static String getTestClassesFileContent() {
        List<MetaDataItem> testClassesContent = new List<MetaDataItem>();
        testClassesContent.add(getMetadataItem(false, false, 'copado', 'fflib_IDGeneratorTest'));
        testClassesContent.add(getMetadataItem(true, false, '', 'SampleClassTest'));
        return JSON.serialize(testClassesContent);
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static MetaDataItem getMetadataItem(Boolean s, Boolean r, String ns, String n) {
        MetaDataItem result = new MetaDataItem();
        result.s = s;
        result.r = r;
        result.ns = ns;
        result.n = n;
        return result;
    }
}