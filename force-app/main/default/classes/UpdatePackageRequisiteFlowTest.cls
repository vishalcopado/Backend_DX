@IsTest
private class UpdatePackageRequisiteFlowTest {
    private static Id packageId;

    @TestSetup
    private static void setUp() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            packageId = createFakeId('0Ho');
        }
    }

    @IsTest
    private static void updateDestination() {
        // Setup

        System.runAs(TestUtilities.getRunAsUser()) {
            Credential cred = createCredential();
            Environment env = createEnvironment().add(cred);
            JobTemplate template = createJobTemplate('SFDX Package Version Create');

            createPackage(createRepository(), 'Unlocked', cred);
            createResult(createJobStep(template, new JobExecution(template, env)), packageId).persist();

            Map<String, Object> flowParams = getFlowParams(getPackage().Id, getResult().Id);

            // Exercise

            Test.startTest();
            new Flow.Interview.UpdatePackageRequisite(flowParams).start();
            Test.stopTest();

            // Verify

            System.assertEquals(
                getJobExecution().copado__Destination__c,
                getEnvironment().Id,
                'Destination updation on Job Execution has been failed'
            );

            System.assertEquals(getResult().copado__Result_Data__c, packageId, 'Package Id updation on Result has been failed');
        }
    }

    @IsTest
    private static void throwNoDevHubException() {
        // Setup

        System.runAs(TestUtilities.getRunAsUser()) {
            JobTemplate template = createJobTemplate('SFDX Package Version Create');
            createPackage(createRepository(), 'Unlocked', null);
            createResult(createJobStep(template, new JobExecution(template, null)), null).persist();

            Map<String, Object> flowParams = getFlowParams(getPackage().Id, getResult().Id);

            // Exercise

            Test.startTest();
            new Flow.Interview.UpdatePackageRequisite(flowParams).start();
            Test.stopTest();

            // Verify

			System.assertEquals(Label.PopulateTargetDevHub, getResult().copado__Error_Message__c, 'Result should be updated with the error message.');
        }
    }

    @IsTest
    private static void throwNoPackageIdException() {
        // Setup

        System.runAs(TestUtilities.getRunAsUser()) {
            Credential cred = createCredential();
            Environment env = createEnvironment().add(cred);
            JobTemplate template = createJobTemplate('SFDX Package Version Create');

            createPackage(createRepository(), 'Unlocked', cred).packageId('');
            createResult(createJobStep(template, new JobExecution(template, env)), null).persist();

            Map<String, Object> flowParams = getFlowParams(getPackage().Id, getResult().Id);

            // Exercise

            Test.startTest();
            new Flow.Interview.UpdatePackageRequisite(flowParams).start();
            Test.stopTest();

            // Verify

            System.assertEquals(Label.PopulatePackageId, getResult().copado__Error_Message__c, 'Result should be updated with the error message.');
        }
    }

    private static Credential createCredential() {
        return new Credential().devhub(true).type('Production/Developer');
    }

    private static Environment createEnvironment() {
        return new Environment().platform('SFDX').type('Production/Developer');
    }

    private static Repository createRepository() {
        return new Repository().name('My Repo');
    }

    private static Result createResult(JobStep step, String data) {
        return new Result(step).type('Integration').data(data);
    }

    private static Artifact createPackage(Repository repo, String type, Credential cred) {
        return new Artifact(repo).name('Testpkg').type(type).packageId(packageId).recordTypeId('Package_Artifact').targetDevHub(cred);
    }

    private static JobTemplate createJobTemplate(String name) {
        return new JobTemplate().name(name);
    }

    private static JobStep createJobStep(JobTemplate template, JobExecution execution) {
        return new JobStep(template).name('Update Package requisite').type('Flow').execution(execution);
    }

    private static Map<String, Object> getFlowParams(Id packageId, Id resultId) {
        Map<String, Object> flowParams = new Map<String, Object>{ 'packageId' => packageId, 'resultId' => resultId };
        return flowParams;
    }

    private static copado__Artifact__c getPackage() {
        copado__Artifact__c artifact = [SELECT Id FROM copado__Artifact__c LIMIT 1];
        return artifact;
    }

    private static copado__JobExecution__c getJobExecution() {
        return [SELECT copado__Destination__c FROM copado__JobExecution__c LIMIT 1];
    }

    private static copado__Result__c getResult() {
        return [SELECT copado__Error_Message__c, copado__Result_Data__c FROM copado__Result__c LIMIT 1 ];
    }

    private static copado__Environment__c getEnvironment() {
        return [SELECT Id FROM copado__Environment__c LIMIT 1];
    }

    private static Id createFakeId(String keyPrefix){
        return fflib_IDGenerator.generate(keyPrefix);
    }
}