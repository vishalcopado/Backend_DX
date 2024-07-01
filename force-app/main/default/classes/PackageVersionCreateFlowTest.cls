@IsTest
private class PackageVersionCreateFlowTest {
    private static Id package2Id = createFakeId('0Ho');
    private static Id packageVersionId = createFakeId('05i');
    private static Id subscriberversionId = createFakeId('04t');

    @TestSetup
    private static void setUp() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    private static void createData() {
        createRepository().persist();
        createJobTemplate('SFDX Package Version Create').persist();
    }

    @IsTest
    private static void createPackageVersion() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            JobTemplate template = TestUtilities.getTemplateObj('SFDX Package Version Create');
            JobExecution jobExecution = createJobExecution(template, createEnvironment('Environment Test 1'));

            JobStep step = createJobStep(template, jobExecution);
            ArtifactVersion version = createPackageVersion(createPackage(TestUtilities.getRepositoryObj()));

            createResult(step, '').persist();

            String versionJSON = JSON.serialize(updateVersionJSON(version.Id));
            Map<String, Object> flowParams = getFlowParams(getResult().Id, version.Id, jobExecution.Id);

            // EXERCISE

            Test.startTest();
            new Flow.Interview.CreatePackageVersion(flowParams).start();
            Test.stopTest();

            // VERIFY

            System.assertEquals(versionJSON, getResult().copado__Result_Data__c, 'Package version details not updated');
            System.assertEquals(getInstallationkey()[0].InstallationKey__c, 'installation key final check', 'Insallation key updation failed');
        }
    }

    private static Repository createRepository() {
        return new Repository().name('My Repo');
    }

    private static Pipeline createPipeline(Repository repo, String platform) {
        return new Pipeline(repo).platform(platform);
    }

    private static Artifact createPackage(Repository repo) {
        return new Artifact(repo).name('Testpkg').type('Unlocked').recordTypeId('Package_Artifact').packageId(package2Id);
    }

    private static ArtifactVersion createPackageVersion(Artifact pkg) {
        return new ArtifactVersion(pkg).versionName('ver 0.1').versionNumber('1.0.1.0').description('description \' here').codeCoverage(false);
    }

    private static Environment createEnvironment(String name) {
        return new Environment().platform('SFDX').type('Production/Developer');
    }

    private static Credential createCredential() {
        return new Credential().devhub(true).type('Production/Developer');
    }

    private static JobTemplate createJobTemplate(String name) {
        return new JobTemplate().name(name);
    }

    private static JobExecution createJobExecution(JobTemplate template, Environment environment) {
        return new JobExecution(template, environment);
    }

    private static JobStep createJobStep(JobTemplate template, JobExecution execution) {
        return new JobStep(template).name('Upsert Package Version').type('Flow').execution(execution);
    }

    private static Result createResult(JobStep step, String data) {
        return new Result(step).type('Integration').data(data);
    }

    private static Map<String, Object> getFlowParams(Id resultId, Id versionId, Id jobExecutionId) {
        Map<String, Object> flowParams = new Map<String, Object>{
            'packageVersionJson' => '{"Package2Id":"' +
            package2Id +
            '","Branch":null,"Tag":null,"MajorVersion":0,"MinorVersion":1,"PatchVersion":0,"BuildNumber":1,"Id":"' +
            packageVersionId +
            '","SubscriberPackageVersionId":"' +
            subscriberversionId +
            '","Name":"ver 0.1","NamespacePrefix":null,"Package2Name":"Testpkg","Description":"description \' here","Version":"0.1.0.1","IsPasswordProtected":false,"IsReleased":false,"CreatedDate":"2021-09-01 11:42","LastModifiedDate":"2021-09-01 11:42","InstallUrl":"https://login.salesforce.com/packaging/installPackage.apexp?p0=04t5g000000xwXMAAY","CodeCoverage":"","ValidationSkipped":false,"AncestorId":"N/A","AncestorVersion":"N/A","Alias":""}',
            'resultId' => resultId,
            'jsonInformation' => getDataJson('test description', '\\"' + versionId + '\\"'),
            'jobExecutionId' => jobExecutionId
        };
        return flowParams;
    }

    private static String getDataJson(String description, String versionId) {
        return '{"versionNumber":null,"versionName":null,"packageId":"a057Q000008dDMXQA2","jsonInformation":"{\\"apiversion\\":null,\\"tag\\":null,\\"postinstallscript\\":null,\\"skipvalidation\\":false,\\"uninstallscript\\":null,\\"postinstallurl\\":null,\\"releasenotesurl\\":null,\\"versiondescription\\":\\"' +
            description +
            '\\",\\"installationkeybypass\\":false,\\"installationkey\\":\\"installation key final check\\",\\"codecoverage\\":false,\\"definitionfile\\":null,\\"branch\\":\\"master\\",\\"versionId\\":' +
            versionId +
            '}","description":"","actionCallback":null}';
    }

    private static copado__Artifact_Version__c updateVersionJSON(Id versionId) {
        String dataJSON = '{\"codecoverage":""}';

        copado__Artifact_Version__c result = new copado__Artifact_Version__c(Id = versionId);
        result.copado__Package_Version_Id__c = packageVersionId;
        result.copado__Subscriber_Version_Id__c = subscriberversionId;
        result.copado__Is_released__c = false;
        result.copado__Branch__c = null;
        result.copado__Version_Name__c = 'ver 0.1';
        result.copado__Tag__c = null;
        result.copado__Version_Description__c = 'description \' here';
        result.copado__Version_number__c = '0.1.0.1';
        result.copado__Data_JSON__c = dataJSON;
        result.Has_Installation_Key__c = false;
        result.Ancestor_Id__c = 'N/A';
        result.Ancestor_Version__c = 'N/A';
        result.Skip_Validation__c = false;
        result.Post_Install_URL__c = 'https://login.salesforce.com/packaging/installPackage.apexp?p0=04t5g000000xwXMAAY';
        result.Name = 'Testpkg - 0.1.0.1';

        return result;
    }

    private static Id createFakeId(String keyPrefix) {
        return fflib_IDGenerator.generate(keyPrefix);
    }

    private static copado__Result__c getResult() {
        return [SELECT copado__Result_Data__c FROM copado__Result__c LIMIT 1];
    }

    private static copado__Artifact_Version__c getVersion() {
        return [SELECT Id FROM copado__Artifact_Version__c LIMIT 1];
    }

    private static List<PackageVersionInstallationKey__c> getInstallationkey() {
        return [SELECT InstallationKey__c FROM PackageVersionInstallationKey__c];
    }
}