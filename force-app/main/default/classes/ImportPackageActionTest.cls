@IsTest
private class ImportPackageActionTest {
    private static final String SUBSCRIBER_VERSION_ID = fflib_IDGenerator.generate('04t5i0');
    private static final String SUBSCRIBER_PACKAGE_ID = fflib_IDGenerator.generate('0Ho5i0');
    private static final String DESCRIPTION_WITH_INVERTED_COMMA = 'Description with \' comma';
    private static final String DESCRIPTION = 'Test Description';
    private final static String PACKAGE_VERSION_DETAILS_FILENAME = 'PackageAndVersions.json';

    @TestSetup
    private static void setUp() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    private static void createData() {
        createPipeline(createRepository(), 'SFDX');
        Credential cred = createCredential();
        createEnvironment().add(cred);
        Repository repo = createRepository();
        JobTemplate jobTemplate = new JobTemplate().name('SFDX Package Import').type('Custom');

        JobStep step1 = createJobStep(jobTemplate, 'Get Devhub Info', 'Function');
        createResult(step1, 'Success');

        JobStep step2 = createJobStep(jobTemplate, 'Update Package Version Info', 'Flow');
        createResult(step2, 'Success');

        new JobExecution(jobTemplate, new Environment()).dataJson('{"sampleKey":"sampleValue"}').add(step1).add(step2);
        createPackageVersion(createPackage(repo, 'Unlocked'), createRelease()).persist();
    }

    @IsTest
    private static void payloadWithInvertedComma() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id jobExecutionId = getJobExecutionObj(getJobTemplate('SFDX Package Import').Id).Id;
            copado__Result__c prevResult = (copado__Result__c) getResult(getJobStep(jobExecutionId, 'Get Devhub Info').Id);
            copado__Result__c currentResult = (copado__Result__c) getResult(getJobStep(jobExecutionId, 'Update Package Version Info').Id );

            String data = getPackageJson(DESCRIPTION_WITH_INVERTED_COMMA);
            createContentVersionOn(data, PACKAGE_VERSION_DETAILS_FILENAME, prevResult.Id);

            List<ImportPackageAction.Request> request = new List<ImportPackageAction.Request>{
                getRequests(getPipeline().Id, DESCRIPTION_WITH_INVERTED_COMMA, prevResult.Id, currentResult.Id)[0]
            };

            // EXERCISE

            Test.startTest();
            ImportPackageAction.execute(request);
            Test.stopTest();

            // VERIFY

            String response = getDataFromContentDocument(currentResult.Id);
            Map<String, Object> packageWithVersions = (Map<String, Object>) JSON.deserializeUntyped(
                response.unescapeEcmaScript()
            );
            Map<String, Object> packageRecord = (Map<String, Object>) packageWithVersions.get('packageRecord');
            System.assertEquals(DESCRIPTION_WITH_INVERTED_COMMA, packageRecord.get('copado__Description__c'), 'Description is escaped here');
        }
    }

    @IsTest
    private static void throwBulkPackageImportNotSupportedException() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            String exceptionMessage;

            // EXERCISE

            try {
                Test.startTest();
                ImportPackageAction.execute(getRequests(getPipeline().Id, DESCRIPTION, null, null));
                Test.stopTest();
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            // VERIFY

            System.assertEquals(Label.BulkPackageImportNotSupported, exceptionMessage, 'Exception should be thrown');
        }
    }

    @IsTest
    private static void throwInvalidPipelineException() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            String exceptionMessage;
            Id pipelineId = fflib_IDGenerator.generate(copado__Deployment_Flow__c.SObjectType);

            Id jobExecutionId = getJobExecutionObj(getJobTemplate('SFDX Package Import').Id).Id;
            copado__Result__c prevResult = (copado__Result__c) getResult( getJobStep(jobExecutionId, 'Get Devhub Info').Id );
            copado__Result__c currentResult = (copado__Result__c) getResult(getJobStep(jobExecutionId, 'Update Package Version Info').Id );

            String data = getPackageJson(DESCRIPTION);
            createContentVersionOn(data, PACKAGE_VERSION_DETAILS_FILENAME, prevResult.Id);

            List<ImportPackageAction.Request> request = new List<ImportPackageAction.Request>{
                getRequests(pipelineId, DESCRIPTION, prevResult.Id, currentResult.Id)[0]
            };

            // EXERCISE

            try {
                Test.startTest();
                ImportPackageAction.execute(request);
                Test.stopTest();
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            // VERIFY

            System.assertEquals(Label.InvalidPipeline, exceptionMessage, 'Exception should be thrown');
        }
    }

    @IsTest
    private static void updatePackageAndVersions() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id jobExecutionId = getJobExecutionObj(getJobTemplate('SFDX Package Import').Id).Id;
            copado__Result__c prevResult = (copado__Result__c) getResult( getJobStep(jobExecutionId, 'Get Devhub Info').Id );
            copado__Result__c currentResult = (copado__Result__c) getResult(getJobStep(jobExecutionId, 'Update Package Version Info').Id );

            String data = getPackageJson(DESCRIPTION);
            createContentVersionOn(data, PACKAGE_VERSION_DETAILS_FILENAME, prevResult.Id);

            List<ImportPackageAction.Request> request = new List<ImportPackageAction.Request>{
                getRequests(getPipeline().Id, DESCRIPTION, prevResult.Id, currentResult.Id)[0]
            };

            // EXERCISE

            Test.startTest();
            ImportPackageAction.execute(request);
            Test.stopTest();

            // VERIFY

            String response = getDataFromContentDocument(currentResult.Id);
            Map<String, Object> packageWithVersions = (Map<String, Object>) JSON.deserializeUntyped(
                response.unescapeEcmaScript()
            );
            Map<String, Object> packageRecord = (Map<String, Object>) packageWithVersions.get('packageRecord');

            String namespacePrefix = TestUtilities.getNamespacePrefix();
            namespacePrefix = String.isNotBlank(namespacePrefix) ? namespacePrefix + '__' : namespacePrefix;

            System.assertEquals(true, packageRecord.get(namespacePrefix + 'IsOrgDependent__c'), 'Package Is Org Dependent check should be true.');
            System.assertEquals('Test_New', packageRecord.get('Name'), 'Package name should be updated.');
            System.assertEquals(DESCRIPTION, packageRecord.get('copado__Description__c'), 'Package description should be updated.');

            List<Object> packageVersionsList = (List<Object>) (packageWithVersions.get('packageVersions'));
            Map<String, Object> packageVersions = (Map<String, Object>) packageVersionsList[0];

            System.assertEquals(true, packageVersions.get('copado__Is_released__c'), 'Package version Is Release check should be true.');
            System.assertEquals('feature/new_branch', packageVersions.get('copado__Branch__c'), 'Package version branch should be updated.');
            System.assertEquals('Test_New - 1.0.0.1', packageVersions.get('Name'), 'Package version name should be updated.');
            System.assertEquals(
                false,
                packageVersions.containsKey('copado__Release_Status__c'),
                'Release status is a formula field should not be part of return response.'
            );
        }
    }

    private static List<ImportPackageAction.Request> getRequests(Id pipelineId, String description, Id prevResultId, Id currentResultId) {
        List<ImportPackageAction.Request> requests = new List<ImportPackageAction.Request>();
        ImportPackageAction.Request request = new ImportPackageAction.Request();
        request.pipelineId = pipelineId;
        request.jsonInformation = '{"devhub": "' + getCredential().Id + '"}';
        request.prevResultId = prevResultId;
        request.currentResultId = currentResultId;
        requests.add(request);

        ImportPackageAction.Request request2 = new ImportPackageAction.Request();
        request2.pipelineId = 'Test Pipeline ID';
        request2.jsonInformation = '{"devhub": "' + getCredential().Id + '"}';
        requests.add(request2);

        return requests;
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

    private static List<ContentDocumentLink> getContentDocumentLink(Id recordId) {
        return new ContentDocumentLinksSelector().byLinkedEntityIdAndTitles(new Set<Id>{ recordId }, new Set<String>{ PACKAGE_VERSION_DETAILS_FILENAME });
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

    private static JobStep createJobStep(JobTemplate template, String stepName, String stepType) {
        return new JobStep(template).name(stepName).type(stepType);
    }

    private static JobTemplate createJobTemplate(String name) {
        return new JobTemplate().name(name);
    }

    private static Pipeline createPipeline(Repository repo, String platform) {
        return new Pipeline(repo).platform(platform);
    }

    private static Credential createCredential() {
        return new Credential().devhub(true).type('Production/Developer');
    }

    private static Environment createEnvironment() {
        return new Environment().platform('SFDX').type('Production/Developer');
    }

    private static Artifact createPackage(Repository repo, String type) {
        return new Artifact(repo).name('Testpkg').type(type).recordTypeId('Package_Artifact');
    }

    private static ArtifactVersion createPackageVersion(Artifact pkg, Release release) {
        return new ArtifactVersion(pkg).name('ver 0.1').versionNumber('0.1.0.1').versionId(SUBSCRIBER_VERSION_ID).release(release);
    }

    private static Repository createRepository() {
        return new Repository().name('My Repo');
    }

    private static Release createRelease() {
        return new Release().name('Fall Release').status('Planned');
    }

    private static Result createResult(JobStep step, String status) {
        return new Result(step).type('Integration').status(status);
    }

    private static copado__Artifact__c getPackage() {
        return [
            SELECT Name, copado__Package_Type__c, copado__Artifact_Repository__c, copado__Package_Id__c, RecordTypeId
            FROM copado__Artifact__c
            LIMIT 1
        ];
    }

    private static copado__Artifact_Version__c getVersion(String subscriberVersion) {
        return [SELECT Name, copado__Artifact__c, copado__Version_Name__c, copado__Version_number__c, copado__Subscriber_Version_Id__c FROM copado__Artifact_Version__c WHERE copado__Subscriber_Version_Id__c =:subscriberVersion LIMIT 1];
    }

    private static copado__Deployment_Flow__c getPipeline() {
        return [SELECT Id FROM copado__Deployment_Flow__c LIMIT 1];
    }

    private static copado__Org__c getCredential() {
        return [SELECT Id FROM copado__Org__c LIMIT 1];
    }

    private static JobExecution getJobExecutionObj(Id jobTemplateId) {
        return new JobExecution().recordId(getJobExecution(jobTemplateId).Id);
    }

    private static JobExecution getJobTemplateObj(String name) {
        return new JobExecution().recordId(getJobTemplate(name).Id);
    }

    private static copado__JobStep__c getStep(String name) {
        return [SELECT Id, Name FROM copado__JobStep__c WHERE Name = :name LIMIT 1];
    }
    
    private static copado__JobTemplate__c getJobTemplate(String name) {
        return [SELECT Id, Name FROM copado__JobTemplate__c WHERE Name =: name LIMIT 1];
    }

    private static copado__Result__c getResult(Id jobStepId) {
        return [SELECT Id, Name, copado__JobStep__c FROM copado__Result__c WHERE copado__JobStep__c = :jobStepId LIMIT 1];
    }

    private static copado__JobStep__c getJobStep(Id jobExecutionId, String stepName) {
        return [SELECT Id, Name, copado__JobExecution__c FROM copado__JobStep__c WHERE copado__JobExecution__c = :jobExecutionId AND Name =:stepName LIMIT 1];
    }
    
    private static copado__JobExecution__c getJobExecution(Id templateId) {
        return [SELECT Id, copado__Template__c FROM copado__JobExecution__c WHERE copado__Template__c = :templateId LIMIT 1];
    }

    private static String getPackageJson(String description) {
        return '{"pkg":{"Id":"' +
            getPackage().Id +
            '","SubscriberPackageId":"' +
            SUBSCRIBER_PACKAGE_ID +
            '","Name":"Test_New","Description":"' +
            description +
            '","NamespacePrefix":null,"ContainerOptions":"Unlocked","ConvertedFromPackageId":null,"Alias":"","IsOrgDependent":"Yes","PackageErrorUsername":null},"versions":[{"Package2Id":"05i5i000000Gn0RAAS","Branch":"feature/new_branch","Tag":null,"MajorVersion":1,"MinorVersion":0,"PatchVersion":0,"BuildNumber":1,"Id":"' +
            getVersion(SUBSCRIBER_VERSION_ID).Id +
            '","SubscriberPackageVersionId":"' +
            SUBSCRIBER_VERSION_ID +
            '","Name":"Test_New","NamespacePrefix":null,"Package2Name":"Test_New","Description":null,"Version":"1.0.0.1","IsPasswordProtected":false,"IsReleased":true}]}';
    }
}