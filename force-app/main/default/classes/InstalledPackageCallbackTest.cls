@IsTest
private class InstalledPackageCallbackTest {
    private static final String SUBSCRIBER_ID = createFakeId('04t');

    @TestSetup
    private static void setUp() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    private static void createData() {
        JobTemplate template = createJobTemplate('SFDX Package Install');
        Repository repo = createRepository();
        Credential cred = createCredential();
        Environment env = createEnvironment().add(cred);
        Deployment deployment = createDeployment(cred);
        Step step = createStep(deployment);
        DestinationCredential destination = createDestinationCredential(deployment, cred);
        createDeploymentJob(step, destination);
        createJobStep(template, createJobExecution(template, env));
        createPackageVersion(createPackage(repo, 'Unlocked')).persist();
    }

    @IsTest
    private static void testInstalledPackageSFDXFlow() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            createResult(getJobStepObj(), getVersionDeploymentStatus(SUBSCRIBER_ID, 'success')).persist();
            copado__Result__c result = getResult(getJobStepObj().Id);

            Map<String, Object> parameters = new Map<String, Object>();
            parameters.put('status', 'Success');
            parameters.put('result', result);
            parameters.put('jobExecutionId', result.copado__JobStep__r.copado__JobExecution__c);
            parameters.put('dataJson', result.copado__JobStep__r.copado__JobExecution__r.copado__DataJson__c);

            // EXERCISE

            Test.startTest();
            new Flow.Interview.Installed_Package_Callback(parameters).start();
            Test.stopTest();

            // VERIFY

            List<copado__Installed_Artifact_Version__c> installedversions = getInstalledversion();

            System.assertEquals(1, installedversions.size(), 'There should be one record');
            System.assertEquals(
                getEnvironment().Id,
                installedversions[0].copado__Environment__c,
                'Environment should be updated on the installed version.'
            );
        }
    }

    @IsTest
    private static void skipPackageInstallationSFDXFlow() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            createResult(getJobStepObj(), getVersionDeploymentStatus(SUBSCRIBER_ID, 'skipped')).persist();
            copado__Result__c result = getResult(getJobStepObj().Id);

            Map<String, Object> parameters = new Map<String, Object>();
            parameters.put('status', 'Success');
            parameters.put('result', result);
            parameters.put('jobExecutionId', result.copado__JobStep__r.copado__JobExecution__c);
            parameters.put('dataJson', result.copado__JobStep__r.copado__JobExecution__r.copado__DataJson__c);

            // EXERCISE

            Test.startTest();
            new Flow.Interview.Installed_Package_Callback(parameters).start();
            Test.stopTest();

            // VERIFY

            System.assertEquals(0, getInstalledversion().size(), 'No version installed, status skipped');
        }
    }

    @IsTest
    private static void testInstalledPackageClassicFlow() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            String dataJSON = '{"subscriberId":"' + SUBSCRIBER_ID + '","deploymentJobId":"' + getDeploymentJob().Id + '"}';
            createResult(getJobStepObj(), getVersionDeploymentStatus(SUBSCRIBER_ID, 'success')).persist();
            copado__Result__c result = getResult(getJobStepObj().Id);

            Id environmentId = getEnvironment().Id;
            updateJobExecution(getJobTemplate().Id, environmentId, dataJSON);

            Map<String, Object> parameters = new Map<String, Object>();
            parameters.put('status', 'Success');
            parameters.put('result', result);
            parameters.put('jobExecutionId', result.copado__JobStep__r.copado__JobExecution__c);
            parameters.put('dataJson', result.copado__JobStep__r.copado__JobExecution__r.copado__DataJson__c);

            // EXERCISE

            Test.startTest();
            new Flow.Interview.Installed_Package_Callback(parameters).start();
            Test.stopTest();

            // VERIFY

            List<copado__Installed_Artifact_Version__c> installedversions = getInstalledversion();

            System.assertEquals(1, installedversions.size(), 'There should be one record');
            System.assertEquals(
                environmentId,
                installedversions[0].copado__Environment__c,
                'Environment should be updated on the installed version.'
            );
        }
    }

    @IsTest
    private static void skipPackageInstallationClassicFlow() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            String dataJSON = '{"subscriberId":"' + SUBSCRIBER_ID + '","deploymentJobId":"' + getDeploymentJob().Id + '"}';
            createResult(getJobStepObj(), getVersionDeploymentStatus(SUBSCRIBER_ID, 'skipped')).persist();
            copado__Result__c result = getResult(getJobStepObj().Id);

            Id environmentId = getEnvironment().Id;
            updateJobExecution(getJobTemplate().Id, environmentId, dataJSON);

            Map<String, Object> parameters = new Map<String, Object>();
            parameters.put('status', 'Success');
            parameters.put('result', result);
            parameters.put('jobExecutionId', result.copado__JobStep__r.copado__JobExecution__c);
            parameters.put('dataJson', result.copado__JobStep__r.copado__JobExecution__r.copado__DataJson__c);

            // EXERCISE

            Test.startTest();
            new Flow.Interview.Installed_Package_Callback(parameters).start();
            Test.stopTest();

            // VERIFY

            System.assertEquals(0, getInstalledversion().size(), 'No version installed, status skipped');
        }
    }

    private static Repository createRepository() {
        return new Repository().name('My Repo');
    }

    private static Artifact createPackage(Repository repo, String type) {
        return new Artifact(repo).name('Testpkg').type(type).recordTypeId('Package_Artifact');
    }

    private static ArtifactVersion createPackageVersion(Artifact pkg) {
        return new ArtifactVersion(pkg).name('ver 0.1').versionNumber('0.1.0.1').versionId(SUBSCRIBER_ID);
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
        return new JobStep(template).name('Install Package Version').type('Flow').execution(execution);
    }

    private static JobExecution createJobExecution(JobTemplate template, Environment environment) {
        String dataJSON = '{"subscriberId":"' + SUBSCRIBER_ID + '"}';
        return new JobExecution(template, environment).dataJSON(dataJSON);
    }

    private static JobExecution updateJobExecution(Id templateId, Id environmentId, String dataJSON) {
        return new JobExecution(new JobTemplate().recordId(templateId), new Environment().recordId(environmentId)).dataJSON(dataJSON);
    }

    private static Result createResult(JobStep step, String data) {
        return new Result(step).type('Integration').data(data).contextId(getStep().Id);
    }

    private static Id createFakeId(String keyPrefix) {
        return fflib_IDGenerator.generate(keyPrefix);
    }

    private static Deployment createDeployment(Credential cred) {
        return new Deployment(cred).name('Deployment US');
    }

    private static DestinationCredential createDestinationCredential(Deployment deployment, Credential cred) {
        return new DestinationCredential(deployment).destinationOrg(cred);
    }

    private static Step createStep(Deployment deployment) {
        return new Step(deployment).name('install Package').order(1);
    }

    private static DeploymentJob createDeploymentJob(Step step, DestinationCredential cred) {
        return new DeploymentJob(step, cred);
    }

    private static copado__Result__c getResult(Id jobStepId) {
        return [
            SELECT
                copado__ParentId__c,
                copado__Result_Data__c,
                copado__Job_Type__c,
                copado__JobStep__r.copado__JobExecution__c,
                copado__JobStep__r.copado__JobExecution__r.copado__DataJson__c
            FROM copado__Result__c
            WHERE copado__JobStep__c = :jobStepId
        ];
    }

    private static copado__JobStep__c getStep() {
        return [SELECT Id FROM copado__JobStep__c LIMIT 1];
    }

    private static List<copado__Installed_Artifact_Version__c> getInstalledversion() {
        return [SELECT Id, copado__Environment__c, copado__Package_Version__c FROM copado__Installed_Artifact_Version__c];
    }

    private static copado__Deployment_Job__c getDeploymentJob() {
        return [SELECT Id FROM copado__Deployment_Job__c LIMIT 1];
    }

    private static copado__JobTemplate__c getJobTemplate() {
        return [SELECT Id FROM copado__JobTemplate__c LIMIT 1];
    }

    private static copado__Environment__c getEnvironment() {
        return [SELECT Id FROM copado__Environment__c LIMIT 1];
    }

    private static copado__JobExecution__c getJobExecution() {
        return [SELECT Id FROM copado__JobExecution__c LIMIT 1];
    }

    private static JobStep getJobStepObj() {
        return new JobStep().recordId(getStep().Id);
    }

    private static String getVersionDeploymentStatus(String subscriberId, String status) {
        return '[{"versionId":"' + subscriberId + '", "status": "' + status + '"}]';
    }
}