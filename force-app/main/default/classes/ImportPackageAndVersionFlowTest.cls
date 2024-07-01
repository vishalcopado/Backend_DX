@IsTest
@SuppressWarnings('PMD.AvoidHardcodingId')
private class ImportPackageAndVersionFlowTest {
    private final static String PACKAGE_VERSION_DETAILS_FILENAME = 'PackageAndVersions.json';
    private static final String SUBSCRIBER_VERSION_ID = fflib_IDGenerator.generate('04t5i0');
    private static final String PACKAGE_ID = fflib_IDGenerator.generate('0Ho5i0');
    private static final String PACKAGE_VERSION_ID = 'MockVersionId';
    

    @TestSetup
    private static void setUp() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    private static void createData() {
        JobTemplate template = createJobTemplate('SFDX Package Import');
        createPipeline(createRepository(), 'SFDX');
        Credential cred = createCredential();
        Environment env = createEnvironment().add(cred);

        JobStep step1 = createJobStep(template, 'Get Devhub Info', 'Function');
        createResult(step1, 'Success');
        JobStep step2 = createJobStep(template, 'Update Package Version Info', 'Flow');
        createResult(step2, 'Success');

        new JobExecution(template, env).dataJson('{"sampleKey":"sampleValue"}').add(step1).add(step2).persist();
    }

    @IsTest
    private static void insertPackageAndVersion() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            String data = getDataJSON(PACKAGE_ID, SUBSCRIBER_VERSION_ID);

            Id jobExecutionId = getJobExecutionObj(getJobTemplate('SFDX Package Import').Id).Id;
            copado__Result__c prevResult = getResult(getJobStep(jobExecutionId, 'Get Devhub Info').Id);
            copado__Result__c currentResult = getResult(getJobStep(jobExecutionId, 'Update Package Version Info').Id);

            createContentVersionOn(data, 'PackageAndVersions.json', prevResult.Id);
            Map<String, Object> flowParams = getFlowParams(prevResult.Id, null, getPipeline().Id, currentResult.Id);

            // EXERCISE

            Test.startTest();
            new Flow.Interview.ImportPackageAndVersions(flowParams).start();
            Test.stopTest();

            // VERIFY

            String response = getDataFromContentDocument(currentResult.Id);

            Map<String, Object> packageWithVersions = (Map<String, Object>) JSON.deserializeUntyped(
                response.unescapeEcmaScript()
            );
            Map<String, Object> packageRecord = (Map<String, Object>) packageWithVersions.get('packageRecord');

            Assert.areEqual('Unlocked', packageRecord.get('copado__Package_Type__c'), 'Package Type should be Unlocked.');
            Assert.areEqual('Test_New', packageRecord.get('Name'), 'Package name should be updated.');
            Assert.areEqual(null, packageRecord.get('Id'), 'Package Record Id shold not be present for insert.');
            Assert.areEqual(getPipeline().Id, packageRecord.get('copado__Pipeline__c'), 'Pipeline should be part of record info.');
            Assert.areEqual(getRepository().Id, packageRecord.get('copado__Artifact_Repository__c'), 'Repository should be part of record info.');

            List<Object> packageVersionsList = (List<Object>) (packageWithVersions.get('packageVersions'));
            Map<String, Object> packageVersions = (Map<String, Object>) packageVersionsList[0];

            Assert.areEqual('1.0.0.1', packageVersions.get('copado__Version_number__c'), 'Package version number should be updated.');
            Assert.areEqual('Test_New', packageVersions.get('copado__Version_Name__c'), 'Package version name should be updated.');
            Assert.areEqual('Test_New - 1.0.0.1', packageVersions.get('Name'), 'Package version name should be updated.');
        }
    }

    @IsTest
    private static void updatePackageAndVersion() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Repository repo = new Repository().recordId(getRepository().Id);
            createPackageVersion(createPackage(repo, 'Unlocked')).persist();

            String data = getDataJSON(PACKAGE_ID, SUBSCRIBER_VERSION_ID);

            Id jobExecutionId = getJobExecutionObj(getJobTemplate('SFDX Package Import').Id).Id;
            copado__Result__c prevResult = getResult(getJobStep(jobExecutionId, 'Get Devhub Info').Id);
            copado__Result__c currentResult = getResult(getJobStep(jobExecutionId, 'Update Package Version Info').Id);
            createContentVersionOn(data, 'PackageAndVersions.json', prevResult.Id);

            Map<String, Object> flowParams = getFlowParams(prevResult.Id, null, getPipeline().Id, currentResult.Id);

            // EXERCISE

            Test.startTest();
            new Flow.Interview.ImportPackageAndVersions(flowParams).start();
            Test.stopTest();

            // VERIFY

            String response = getDataFromContentDocument(currentResult.Id);

            Map<String, Object> packageWithVersions = (Map<String, Object>) JSON.deserializeUntyped(
                response.unescapeEcmaScript()
            );
            Map<String, Object> packageRecord = (Map<String, Object>) packageWithVersions.get('packageRecord');

            Assert.areEqual('Unlocked', packageRecord.get('copado__Package_Type__c'), 'Package Type should be Unlocked.');
            Assert.areEqual('Test_New', packageRecord.get('Name'), 'Package name should be updated.');
            Assert.areEqual(getPackage().Id, packageRecord.get('Id'), 'Package Record Id shold not be present for insert.');
            Assert.areEqual(getPipeline().Id, packageRecord.get('copado__Pipeline__c'), 'Pipeline should be part of record info.');
            Assert.areEqual(getRepository().Id, packageRecord.get('copado__Artifact_Repository__c'), 'Repository should be part of record info.');

            List<Object> packageVersionsList = (List<Object>) (packageWithVersions.get('packageVersions'));
            Map<String, Object> packageVersions = (Map<String, Object>) packageVersionsList[0];

            Assert.areEqual('1.0.0.1', packageVersions.get('copado__Version_number__c'), 'Package version number should be updated.');
            Assert.areEqual('Test_New', packageVersions.get('copado__Version_Name__c'), 'Package version name should be updated.');
            Assert.areEqual('Test_New - 1.0.0.1', packageVersions.get('Name'), 'Package version name should be updated.');
            Assert.areEqual(1, packageVersionsList.size(), 'Existing pakcage version should be updated.');
        }
    }

    @IsTest
    private static void importNewVersion() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            String newSubscriberVersionId = fflib_IDGenerator.generate('04t5i0');
            Repository repo = new Repository().recordId(getRepository().Id);
            createPackageVersion(createPackage(repo, 'Unlocked')).persist();

            String data = getDataJSON(PACKAGE_ID, newSubscriberVersionId);

            Id jobExecutionId = getJobExecutionObj(getJobTemplate('SFDX Package Import').Id).Id;
            copado__Result__c prevResult = getResult(getJobStep(jobExecutionId, 'Get Devhub Info').Id);
            copado__Result__c currentResult = getResult(getJobStep(jobExecutionId, 'Update Package Version Info').Id);
            createContentVersionOn(data, 'PackageAndVersions.json', prevResult.Id);

            Map<String, Object> flowParams = getFlowParams(prevResult.Id, null, getPipeline().Id, currentResult.Id);

            // EXERCISE

            Test.startTest();
            new Flow.Interview.ImportPackageAndVersions(flowParams).start();
            Test.stopTest();

            // VERIFY

            String response = getDataFromContentDocument(currentResult.Id);

            Map<String, Object> packageWithVersions = (Map<String, Object>) JSON.deserializeUntyped(
                response.unescapeEcmaScript()
            );
            Map<String, Object> packageRecord = (Map<String, Object>) packageWithVersions.get('packageRecord');

            Assert.areEqual('Unlocked', packageRecord.get('copado__Package_Type__c'), 'Package Type should be Unlocked.');
            Assert.areEqual('Test_New', packageRecord.get('Name'), 'Package name should be updated.');
            Assert.areEqual(getPipeline().Id, packageRecord.get('copado__Pipeline__c'), 'Pipeline should be part of record info.');
            Assert.areEqual(getRepository().Id, packageRecord.get('copado__Artifact_Repository__c'), 'Repository should be part of record info.');

            List<Object> packageVersionsList = (List<Object>) (packageWithVersions.get('packageVersions'));
            Map<String, Object> packageVersions = (Map<String, Object>) packageVersionsList[0];

            Assert.areEqual('1.0.0.1', packageVersions.get('copado__Version_number__c'), 'Package version number should be updated.');
            Assert.areEqual('Test_New', packageVersions.get('copado__Version_Name__c'), 'Package version name should be updated.');
            Assert.areEqual('Test_New - 1.0.0.1', packageVersions.get('Name'), 'Package version name should be updated.');
            Assert.areEqual(newSubscriberVersionId, packageVersions.get('copado__Subscriber_Version_Id__c'), 'New Subscriber version Id should be updated.');
            Assert.areEqual(SUBSCRIBER_VERSION_ID, getVersion().copado__Subscriber_Version_Id__c, 'Existing Subscriber version Id should return.');
        }
    }

    @IsTest
    private static void throwInvalidPipelineException() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            String data = getDataJSON(PACKAGE_ID, SUBSCRIBER_VERSION_ID);
            Id jobExecutionId = getJobExecutionObj(getJobTemplate('SFDX Package Import').Id).Id;
            copado__Result__c prevResult = getResult(getJobStep(jobExecutionId, 'Get Devhub Info').Id);
            copado__Result__c currentResult = getResult(getJobStep(jobExecutionId, 'Update Package Version Info').Id);

            createContentVersionOn(data, 'PackageAndVersions.json', prevResult.Id);
            
            Id pipelineId = getFakeId(copado__Deployment_Flow__c.SObjectType);
            Map<String, Object> flowParams = getFlowParams(prevResult.Id, null, pipelineId, currentResult.Id);

            // EXERCISE

            Test.startTest();
            new Flow.Interview.ImportPackageAndVersions(flowParams).start();
            Test.stopTest();

            // VERIFY

            String errorMessage = getResult(getJobStep(jobExecutionId, 'Update Package Version Info').Id).copado__Error_Message__c;
            Assert.isTrue(
                errorMessage.contains('Invalid payload'),
                'Invalid payload error should be visible on invalid pipeline.'
            );
        }
    }

    private static String getDataFromContentDocument(Id byLinkedEntityId) {
        List<ContentDocumentLink> packageVersionFileDetails = getContentDocumentLink(byLinkedEntityId);
        String data;
        if (!packageVersionFileDetails.isEmpty()) {
            List<ContentVersion> contentVersions = new ContentVersionsSelector().byContentDocumentIdWithLatest(new Set<Id>{packageVersionFileDetails[0].ContentDocumentId });
            if(!contentVersions.isEmpty()) {
                data = contentVersions[0]?.VersionData?.toString();
            }
        }
        return data;
    }

    private static void createContentVersionOn(String data, String fileName, Id linkedEntityId) {
        ContentVersion contentVersion = new ContentVersion(
            Title = fileName,
            origin = 'C',
            PathOnClient = fileName,
            VersionData = Blob.valueOf(data)
        );
        insert contentVersion;

        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id LIMIT 1].ContentDocumentId;
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink(LinkedEntityId = linkedEntityId, ContentDocumentId = contentDocumentId);
        insert contentDocumentLink;
    }

    private static List<ContentDocumentLink> getContentDocumentLink(Id recordId) {
        return new ContentDocumentLinksSelector().byLinkedEntityIdAndTitles(new Set<Id>{ recordId }, new Set<String>{ PACKAGE_VERSION_DETAILS_FILENAME });
    }

    private static Repository createRepository() {
        return new Repository().name('My Repo');
    }

    private static Pipeline createPipeline(Repository repo, String platform) {
        return new Pipeline(repo).platform(platform);
    }

    private static Artifact createPackage(Repository repo, String type) {
        return new Artifact(repo).name('Test_New').type(type).packageId(PACKAGE_ID).recordTypeId('Package_Artifact');
    }

    private static ArtifactVersion createPackageVersion(Artifact pkg) {
        return new ArtifactVersion(pkg).name('ver 0.1').versionNumber('0.1.0.1').versionId(SUBSCRIBER_VERSION_ID);
    }

    private static Environment createEnvironment() {
        return new Environment().platform('SFDX').type('Production/Developer');
    }

    private static Credential createCredential() {
        return new Credential().devhub(true).type('Production/Developer');
    }

    private static JobTemplate createJobTemplate(String name) {
        return new JobTemplate().name(name);
    }

    private static JobStep createJobStep(JobTemplate template, String name, String type) {
        return new JobStep(template).name(name).type(type);
    }

    private static Result createResult(JobStep step, String data) {
        return new Result(step).type('Integration').data(data);
    }

    private static String getFakeId(Schema.SObjectType sObjectName) {
        Integer num = 1;
        String resultId = String.valueOf(num++);
        return sObjectName.getDescribe(SObjectDescribeOptions.DEFERRED).getKeyPrefix() + '0'.repeat(12 - resultId.length()) + resultId;
    }

    private static copado__Artifact__c retrievePackage(String name, Id repositoryId) {
        copado__Artifact__c pkg = new copado__Artifact__c();
        pkg.Name = name;
        pkg.copado__Package_Type__c = 'Unlocked';
        pkg.copado__Artifact_Repository__c = repositoryId;
        pkg.RecordTypeId = SObjectType.copado__Artifact__c.getRecordTypeInfosByDeveloperName().get('Package_Artifact').getRecordTypeId();

        return pkg;
    }

    private static copado__Artifact_Version__c retrievePackageVersion(String name, copado__Artifact__c pkg) {
        copado__Artifact_Version__c version = new copado__Artifact_Version__c();
        version.copado__Artifact__c = pkg.Id;
        version.Name = pkg.Name + ' - 1.1.1.1';
        version.copado__Version_Name__c = name;
        version.copado__Version_number__c = '1.1.1.1';

        return version;
    }

    private static String getDataJSON(Id packageId, Id versionSubscriberId) {
        return '{' + 
            '"pkg":{' +
                (String.isNotBlank(packageId) ? '"Id":"'+ packageId + '",': '') +
                '"Name":"Test_New","Description":"test description","NamespacePrefix":null,"ContainerOptions":"Unlocked","ConvertedFromPackageId":null,"Alias":"","IsOrgDependent":"Yes","PackageErrorUsername":null},' +
                '"versions":[' +
                    '{"Package2Id":"MockId","Branch":"feature/new_branch","Tag":null,"MajorVersion":1,"MinorVersion":0,"PatchVersion":0,"BuildNumber":1,' +
                    '"Id": "' + PACKAGE_VERSION_ID + '",' + 
                    '"SubscriberPackageVersionId":"' + versionSubscriberId + 
                    '","Name":"Test_New","NamespacePrefix":null,"Package2Name":"Test_New","Description":null,"Version":"1.0.0.1","IsPasswordProtected":false,"IsReleased":true}' +
                ']' + 
            '}';
    }

    private static JobExecution getJobExecutionObj(Id jobTemplateId) {
        return new JobExecution().recordId(getJobExecution(jobTemplateId).Id);
    }

    private static copado__Artifact__c getPackage() {
        return [
            SELECT Name, copado__Package_Type__c, copado__Artifact_Repository__c, copado__Package_Id__c, RecordTypeId
            FROM copado__Artifact__c
            LIMIT 1
        ];
    }

    private static copado__Artifact_Version__c getVersion() {
        return [SELECT Name, copado__Artifact__c, copado__Version_Name__c, copado__Version_number__c, copado__Subscriber_Version_Id__c FROM copado__Artifact_Version__c LIMIT 1];
    }

    private static copado__JobStep__c getJobStep(Id jobExecutionId, String stepName) {
        return [SELECT Id, Name, copado__JobExecution__c FROM copado__JobStep__c WHERE copado__JobExecution__c = :jobExecutionId AND Name =:stepName LIMIT 1];
    }

    private static copado__Deployment_Flow__c getPipeline() {
        return [SELECT Id FROM copado__Deployment_Flow__c LIMIT 1];
    }

    private static copado__Result__c getResult(Id jobStepId) {
        return [SELECT Id, Name, copado__Result_Data__c, copado__Error_Message__c, copado__JobStep__c FROM copado__Result__c WHERE copado__JobStep__c = :jobStepId LIMIT 1];
    }

    private static copado__Git_Repository__c getRepository() {
        return [SELECT Id FROM copado__Git_Repository__c LIMIT 1];
    }

    private static copado__JobExecution__c getJobExecution(Id templateId) {
        return [SELECT Id, copado__DataJson__c, copado__ErrorMessage__c, copado__Template__c FROM copado__JobExecution__c WHERE copado__Template__c = :templateId LIMIT 1];
    }

    private static copado__JobTemplate__c getJobTemplate(String name) {
        return [SELECT Id, Name FROM copado__JobTemplate__c WHERE Name =: name LIMIT 1];
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static Map<String, Object> getFlowParams(Id prevResultId, Id credentialId, Id pipelineId, Id resultId) {
        Map<String, Object> flowParams = new Map<String, Object>{
            'prevResultId' => prevResultId,
            'pipelineId' => pipelineId,
            'jsonInformation' => JSON.serialize(new Map<String, Object>{ 'devhub' => credentialId }),
            'resultId' => resultId
        };

        return flowParams;
    }
}