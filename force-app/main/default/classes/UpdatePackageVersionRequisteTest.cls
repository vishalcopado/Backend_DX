@IsTest
private class UpdatePackageVersionRequisteTest {
    private static final String SUBSCRIBER_ID = createFakeId('04t');
    @TestSetup
    private static void setUp() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void executeSucuessfully() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            JobTemplate template = createJobTemplate('SFDX Package Version Publish_1');
            JobStep jobStep = createJobStep(template, createJobExecution(template, getEnvironmentObj()));
            createResult(jobStep).persist();

            List<UpdatePackageVersionRequiste.Request> requests = new List<UpdatePackageVersionRequiste.Request>();
            UpdatePackageVersionRequiste.Request request = new UpdatePackageVersionRequiste.Request();
            request.resultId = getResult().Id;
            request.packageVersionId = getPackageVersion().Id;
            requests.add(request);

            // EXERCISE

            Test.startTest();
            List<UpdatePackageVersionRequiste.Response> result = UpdatePackageVersionRequiste.execute(requests);
            Test.stopTest();

            // VERIFY

            Map<String, Object> versionDetails = (Map<String, Object>) JSON.deserializeUntyped(result[0].versionDetails.unescapeEcmaScript());

            System.assertEquals('55.0', versionDetails.get('apiVersion'), 'Api Version should be updated based on package and version record.');
            System.assertEquals(SUBSCRIBER_ID, versionDetails.get('subscriberId'), 'Subscriber Id should be updated.');
            System.assertEquals(
                getPackageVersion()?.copado__Artifact__r?.copado__Target_Dev_Hub_Org__r?.copado__Environment__c,
                getEnvironment().Id,
                'Job Executon destination environment should have been changed.'
            );
        }
    }

    @IsTest
    private static void resultRecordWithoutJobExecution() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            String exceptionMessage;
            new Result().type('Integration').persist();

            List<UpdatePackageVersionRequiste.Request> requests = new List<UpdatePackageVersionRequiste.Request>();
            UpdatePackageVersionRequiste.Request request = new UpdatePackageVersionRequiste.Request();
            request.resultId = getResult().Id;
            request.packageVersionId = getPackageVersion().Id;
            requests.add(request);

            // EXERCISE

            try {
                Test.startTest();
                UpdatePackageVersionRequiste.execute(requests);
                Test.stopTest();
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            // VERIFY
            System.assert(exceptionMessage.contains(Label.Result_Record_with_valid_Job_Execution), 'Exception should be thrown.');
        }
    }

    private static void createData() {
        Repository repo = createRepository();
        Pipeline pipeline = createPipeline(repo, 'SFDX');
        Credential cred = createCredential();
        Environment env = createEnvironment().add(cred);
        Artifact pkg = createPackage(repo, cred, pipeline);
        createPackageVersion(pkg).persist();
    }

    private static Id createFakeId(String keyPrefix) {
        return fflib_IDGenerator.generate(keyPrefix);
    }

    private static Result createResult(JobStep step) {
        return new Result(step).type('Integration');
    }

    private static Repository createRepository() {
        return new Repository().name('My Repo');
    }

    private static Pipeline createPipeline(Repository repo, String platform) {
        return new Pipeline(repo).platform(platform);
    }

    private static Artifact createPackage(Repository repo, Credential cred, Pipeline pipeline) {
        return new Artifact(repo)
            .name('Testpkg')
            .type('Unlocked')
            .recordTypeId('Package_Artifact')
            .targetDevHub(cred)
            .pipeline(pipeline)
            .apiVersion('54.0');
    }

    private static JobExecution createJobExecution(JobTemplate template, Environment environment) {
        return new JobExecution(template, environment);
    }

    private static ArtifactVersion createPackageVersion(Artifact pkg) {
        return new ArtifactVersion(pkg)
            .versionName('old Version')
            .versionNumber('1.0.1.0')
            .description('old Description')
            .codeCoverage(false)
            .tag('oldTag')
            .branch('oldBranch')
            .versionId(SUBSCRIBER_ID)
            .apiVersion('55.0');
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

    private static JobStep createJobStep(JobTemplate template, JobExecution execution) {
        return new JobStep(template).name('SFDX Package Version Publish_Update Destination on Job Execution').type('Flow').execution(execution);
    }

    private static copado__Result__c getResult() {
        return [SELECT Id, copado__Result_Data__c FROM copado__Result__c LIMIT 1];
    }

    private static Environment getEnvironmentObj() {
        return new Environment().recordId(getEnvironment().Id);
    }

    private static copado__Artifact_Version__c getPackageVersion() {
        return [SELECT Id, copado__Artifact__r.copado__Target_Dev_Hub_Org__r.copado__Environment__c FROM copado__Artifact_Version__c LIMIT 1];
    }

    private static copado__Environment__c getEnvironment() {
        return [SELECT Id FROM copado__Environment__c LIMIT 1];
    }
}