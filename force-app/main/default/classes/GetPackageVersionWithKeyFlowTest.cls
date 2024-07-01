/*
TODO: We are not using the corresponsing flow anymore, this class needs to be removed from the package.
*/

@IsTest
private class GetPackageVersionWithKeyFlowTest {
    private static Id package2Id = createFakeId('0Ho');
    private static final Id DEPENDENCY_SUBSCRIBER_ID = createFakeId('04t');
    private static final Id MAIN_SUBSCRIBER_ID = createFakeId('04t');

    @TestSetup
    private static void setUp() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void getPackageVersionKeySuccessful() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            copado__Artifact_Version__c mainVersion = getVersion('Pkg1');

            GetPackageVersionWithKeys.VersionDetails details = new GetPackageVersionWithKeys.VersionDetails();
            details.subscriberPackageId = 'Test';
            details.dependencies = new List<Id>{ getVersion('Pkg2').copado__Subscriber_Version_Id__c };
            details.subscriberVersionId = mainVersion.copado__Subscriber_Version_Id__c;
            details.versionNumber = '0.1.0.1';

            Map<String, Object> flowParams = new Map<String, Object>{
                'subscriberVersionId' => mainVersion.copado__Subscriber_Version_Id__c,
                'versionDetails' => JSON.serialize(details),
                'resultId' => getResult().Id
            };

            // EXERCISE

            Test.startTest();
            new Flow.Interview.GetPackageVersionWithKey(flowParams).start();
            Test.stopTest();

            // VERIFY

            List<GetPackageVersionWithKeys.PackageVersion> versions = (List<GetPackageVersionWithKeys.PackageVersion>) JSON.deserialize(
                getResult().copado__Result_Data__c.unescapeEcmaScript(),
                List<GetPackageVersionWithKeys.PackageVersion>.class
            );

            System.assertEquals(DEPENDENCY_SUBSCRIBER_ID, versions[0].id, 'Dependency subscriber id should be first in index');
            System.assertEquals(null, versions[0].key, 'Dependency installation key is null and should be first in index');
            System.assertEquals(DEPENDENCY_SUBSCRIBER_ID, versions[0].id, 'Main package version subscriber id should be last in index');
            System.assertEquals(null, versions[1].key, 'Main package version installation key shooudl be null and last in index');
        }
    }

    @IsTest
    private static void getPackageVersionKeyFailure() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id fakeSubscriberId = createFakeId('04t');

            Map<String, Object> flowParams = new Map<String, Object>{
                'subscriberVersionId' => fakeSubscriberId,
                'versionDetails' => JSON.serialize(new GetPackageVersionWithKeys.VersionDetails()),
                'resultId' => getResult().Id
            };

            // EXERCISE

            Test.startTest();
            new Flow.Interview.GetPackageVersionWithKey(flowParams).start();
            Test.stopTest();

            // VERIFY
            System.assertEquals('Failed', getResult().copado__Status__c, 'Result record will fail');
            System.assertNotEquals(null, getResult().copado__Error_Message__c, 'Error message field would be updated');
        }
    }

    private static void createData() {
        Repository repo = createRepository();
        Credential cred = createCredential();
        Pipeline pipeline = createPipeline(repo, 'SFDX');
        JobTemplate template = createJobTemplate('SFDX Package Version Create');
        Environment env = createEnvironment().add(cred);
        Artifact pkg = createPackage('Pkg1', repo, cred, pipeline);
        JobStep step = createJobStep(template, createJobExecution(template, env));
        createPackageVersion(pkg, MAIN_SUBSCRIBER_ID);
        Artifact pkg2 = createPackage('Pkg2', repo, cred, pipeline);
        createPackageVersion(pkg2, DEPENDENCY_SUBSCRIBER_ID);
        createResult(step, '').persist();
    }

    private static Repository createRepository() {
        return new Repository().name('My Repo');
    }

    private static Pipeline createPipeline(Repository repo, String platform) {
        return new Pipeline(repo).platform(platform);
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static Artifact createPackage(String name, Repository repo, Credential cred, Pipeline pipeline) {
        return new Artifact(repo)
            .name(name)
            .type('Unlocked')
            .recordTypeId('Package_Artifact')
            .targetDevHub(cred)
            .pipeline(pipeline)
            .packageId(package2Id);
    }

    private static ArtifactVersion createPackageVersion(Artifact pkg, Id subscriberVersionId) {
        return new ArtifactVersion(pkg)
            .versionName('ver 0.1')
            .versionNumber('1.0.1.0')
            .description('Package Version description')
            .codeCoverage(false)
            .subscriberId(subscriberVersionId);
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

    private static JobExecution createJobExecution(JobTemplate template, Environment environment) {
        return new JobExecution(template, environment);
    }

    private static JobStep createJobStep(JobTemplate template, JobExecution execution) {
        return new JobStep(template).name('Get Keys').type('Flow').execution(execution);
    }

    private static Result createResult(JobStep step, String data) {
        return new Result(step).type('Integration').data(data);
    }

    private static Id createFakeId(String keyPrefix) {
        return fflib_IDGenerator.generate(keyPrefix);
    }

    private static copado__Result__c getResult() {
        return [SELECT copado__Result_Data__c, copado__Status__c, copado__Error_Message__c FROM copado__Result__c LIMIT 1];
    }

    private static copado__Artifact_Version__c getVersion(String pkgName) {
        return [
            SELECT Id, copado__Subscriber_Version_Id__c, copado__Artifact__c
            FROM copado__Artifact_Version__c
            WHERE copado__Artifact__r.Name = :pkgName
        ];
    }
}