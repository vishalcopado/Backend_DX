@IsTest
private class DeployPackagesTest {
    private static String installSecurityType = 'AdminsOnly';

    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    private static void createData() {
        JobTemplate template = createJobTemplate('SFDX Package Distribution');
        createJobStep(template, 'Get Dependencies', 'Function');
        createJobStep(template, 'Install package', 'Function');
        Repository repo = createRepository();
        createPipeline(repo, 'SFDX');
        Credential cred = createCredential(false);
        createEnvironment().add(cred).persist();
        update new copado__JobTemplate__c(Id = template.id, copado__ApiName__c = 'SFDX Package Distribution_1');
    }

    @IsTest
    private static void deployPackagewithEmptyApiVersion() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            createPackageVersion(createPackage(getRepositoryObj(), '', createCredential(true)), '').persist();
            Id versionId = getVersion().Id;
            Id credentialId = getCredential(false).Id;

            // EXERCISE

            List<copado__JobExecution__c> result = new DeployPackages(versionId, new List<Id>{ credentialId }, installSecurityType).execute();
            copado__JobExecution__c execution = getJobExecution(result[0].Id);
            DeployPackages.PackageVersion version = (DeployPackages.PackageVersion) JSON.deserialize(
                execution.copado__DataJson__c,
                DeployPackages.PackageVersion.class
            );

            // VERIFY
            Assert.areEqual(getPipeline().Id, execution.copado__Pipeline__c, 'Job execution pipeline should be correct.');
            Assert.areEqual(1, result.size(), 'Job Executions creation has failed.');
            Assert.areEqual(getEnvironment().Id, result[0].copado__Destination__c, 'Job executed created for incorrect environment.');
            Assert.areEqual(
                getCredential(true).copado__Environment__c,
                execution.copado__Source__c,
                'Job execution source credential should be devhub.'
            );
            Assert.areEqual(null, version.deploymentJobId, 'DeploymentJobId is not updated on the Job Execution DataJSON');
            Assert.areEqual(
                installSecurityType,
                version.installSecurityType,
                'Package Installation security type should be updated on Job Execution DataJSON'
            );
            Assert.areEqual(null, version.apiVersion, 'Api Version should be null on the Job Execution DataJSON');
            Assert.areEqual(null, version.installationKey, 'Installation key should be updated on the Job Execution DataJSON');
            Assert.areEqual(
                getVersion().copado__Subscriber_Version_Id__c,
                version.subscriberId,
                'Subscriber Version Id should be updated on the Job Execution DataJSON'
            );
        }
    }

    @IsTest
    private static void deployPackagewithApiversionFromPackageVersion() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            createPackageVersion(createPackage(getRepositoryObj(), '53.0', createCredential(true)), '54.0').persist();
            Id versionId = getVersion().Id;
            Id credentialId = getCredential(false).Id;

            // EXERCISE

            List<copado__JobExecution__c> result = new DeployPackages(versionId, new List<Id>{ credentialId }, installSecurityType).execute();
            copado__JobExecution__c execution = getJobExecution(result[0].Id);
            DeployPackages.PackageVersion version = (DeployPackages.PackageVersion) JSON.deserialize(
                execution.copado__DataJson__c,
                DeployPackages.PackageVersion.class
            );

            // VERIFY
            Assert.areEqual(getPipeline().Id, execution.copado__Pipeline__c, 'Job execution pipeline should be correct.');
            Assert.areEqual(1, result.size(), 'Job Executions creation has failed.');
            Assert.areEqual(getEnvironment().Id, result[0].copado__Destination__c, 'Job executed created for incorrect environment.');
            Assert.areEqual(null, version.deploymentJobId, 'DeploymentJobId is not updated on the Job Execution DataJSON');
            Assert.areEqual(
                installSecurityType,
                version.installSecurityType,
                'Package Installation security type should be updated on Job Execution DataJSON'
            );
            Assert.areEqual(
                getCredential(true).copado__Environment__c,
                execution.copado__Source__c,
                'Job execution source credential should be devhub.'
            );
            Assert.areEqual('54.0', version.apiVersion, 'Api Version should be updated from package version record on the Job Execution DataJSON');
            Assert.areEqual(null, version.installationKey, 'Installation key should be updated on the Job Execution DataJSON');
            Assert.areEqual(
                getVersion().copado__Subscriber_Version_Id__c,
                version.subscriberId,
                'Subscriber Version Id should be updated on the Job Execution DataJSON'
            );
        }
    }

    @IsTest
    private static void deployPackagewithApiversionFromPackage() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            createPackageVersion(createPackage(getRepositoryObj(), '53.0', createCredential(true)), null).persist();
            Id versionId = getVersion().Id;
            Id credentialId = getCredential(false).Id;

            // EXERCISE

            List<copado__JobExecution__c> result = new DeployPackages(versionId, new List<Id>{ credentialId }, installSecurityType).execute();
            copado__JobExecution__c execution = getJobExecution(result[0].Id);
            DeployPackages.PackageVersion version = (DeployPackages.PackageVersion) JSON.deserialize(
                execution.copado__DataJson__c,
                DeployPackages.PackageVersion.class
            );

            // VERIFY
            Assert.areEqual(getPipeline().Id, execution.copado__Pipeline__c, 'Job execution pipeline should be correct.');
            Assert.areEqual(1, result.size(), 'Job Executions creation has failed.');
            Assert.areEqual(getEnvironment().Id, result[0].copado__Destination__c, 'Job executed created for incorrect environment.');
            Assert.areEqual(
                getCredential(true).copado__Environment__c,
                execution.copado__Source__c,
                'Job execution source credential should be devhub.'
            );
            Assert.areEqual(
                installSecurityType,
                version.installSecurityType,
                'Package Installation security type should be updated on Job Execution DataJSON'
            );
            Assert.areEqual(null, version.deploymentJobId, 'DeploymentJobId is not updated on the Job Execution DataJSON');
            Assert.areEqual('53.0', version.apiVersion, 'Api Version should be updated from package record on the Job Execution DataJSON');
            Assert.areEqual(null, version.installationKey, 'Installation key should be updated on the Job Execution DataJSON');
            Assert.areEqual(
                getVersion().copado__Subscriber_Version_Id__c,
                version.subscriberId,
                'Subscriber Version Id should be updated on the Job Execution DataJSON'
            );
        }
    }

    @IsTest
    private static void classicPipelineDeployWithPackageApiVersion() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Deployment deployment = createDeployment(getCredentialObj(false));
            Step step = createStep(deployment);
            DestinationCredential destination = createDestinationCredential(deployment, getCredentialObj(false));
            createDeploymentJob(step, destination);
            createPackageVersion(createPackage(getRepositoryObj(), '53.0', createCredential(true)), '').persist();

            Id versionId = getVersion().Id;
            copado__Org__c credential = getCredential(false);
            Id deploymentJobId = getDeploymentJob().Id;

            // EXERCISE

            List<copado__JobExecution__c> result = new DeployPackages(versionId, new List<Id>{ credential.Id }, installSecurityType, deploymentJobId)
                .execute();
            // VERIFY

            copado__JobExecution__c execution = getJobExecution(result[0].Id);
            DeployPackages.PackageVersion version = (DeployPackages.PackageVersion) JSON.deserialize(
                execution.copado__DataJson__c,
                DeployPackages.PackageVersion.class
            );

            Assert.areEqual(getPipeline().Id, execution.copado__Pipeline__c, 'Job execution pipeline should be correct.');
            Assert.areEqual(1, result.size(), 'Job Executions creation has failed.');
            Assert.areEqual(credential.copado__Environment__c, result[0].copado__Destination__c, 'Job executed created for incorrect environment.');
            Assert.areEqual(
                getCredential(true).copado__Environment__c,
                execution.copado__Source__c,
                'Job execution source credential should be devhub.'
            );
            Assert.areEqual(version.deploymentJobId, deploymentJobId, 'DeploymentJobId is not updated on the Job Execution DataJSON');
            Assert.areEqual(
                installSecurityType,
                version.installSecurityType,
                'Package Installation security type should be updated on Job Execution DataJSON'
            );
            Assert.areEqual('53.0', version.apiVersion, 'Api Version should be updated from package version record on the Job Execution DataJSON');
            Assert.areEqual(null, version.installationKey, 'Installation key should be updated on the Job Execution DataJSON');
            Assert.areEqual(
                getVersion().copado__Subscriber_Version_Id__c,
                version.subscriberId,
                'Subscriber Version Id should be updated on the Job Execution DataJSON'
            );
        }
    }

    @IsTest
    private static void classicPipelineDeployWithPackageVersionApiVersion() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Deployment deployment = createDeployment(getCredentialObj(false));
            Step step = createStep(deployment);
            DestinationCredential destination = createDestinationCredential(deployment, getCredentialObj(false));
            createDeploymentJob(step, destination);
            createPackageVersion(createPackage(getRepositoryObj(), '53.0', createCredential(true)), '54.0').persist();

            Id versionId = getVersion().Id;
            copado__Org__c credential = getCredential(false);
            Id deploymentJobId = getDeploymentJob().Id;

            // EXERCISE

            List<copado__JobExecution__c> result = new DeployPackages(versionId, new List<Id>{ credential.Id }, installSecurityType, deploymentJobId)
                .execute();

            // VERIFY

            copado__JobExecution__c execution = getJobExecution(result[0].Id);
            DeployPackages.PackageVersion version = (DeployPackages.PackageVersion) JSON.deserialize(
                execution.copado__DataJson__c,
                DeployPackages.PackageVersion.class
            );

            Assert.areEqual(getPipeline().Id, execution.copado__Pipeline__c, 'Job execution pipeline should be correct.');
            Assert.areEqual(1, result.size(), 'Job Executions creation has failed.');
            Assert.areEqual(credential.copado__Environment__c, result[0].copado__Destination__c, 'Job executed created for incorrect environment.');
            Assert.areEqual(
                getCredential(true).copado__Environment__c,
                execution.copado__Source__c,
                'Job execution source credential should be devhub.'
            );
            Assert.areEqual(version.deploymentJobId, deploymentJobId, 'DeploymentJobId is not updated on the Job Execution DataJSON');
            Assert.areEqual('54.0', version.apiVersion, 'Api Version should be updated from package version record on the Job Execution DataJSON');
            Assert.areEqual(
                installSecurityType,
                version.installSecurityType,
                'Package Installation security type should be updated on Job Execution DataJSON'
            );
            Assert.areEqual(null, version.installationKey, 'Installation key should be updated on the Job Execution DataJSON');
            Assert.areEqual(
                getVersion().copado__Subscriber_Version_Id__c,
                version.subscriberId,
                'Subscriber Version Id should be updated on the Job Execution DataJSON'
            );
        }
    }

    @IsTest
    private static void exception() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Exception expectedException = null;

            // EXERCISE

            try {
                new DeployPackages(null, null, null).execute();
            } catch (Exception ex) {
                expectedException = ex;
            }

            // VERIFY

            Assert.isTrue(expectedException != null, 'Exception should be thrown.');
        }
    }

    private static Repository createRepository() {
        return new Repository().name('My Repo');
    }

    private static Pipeline createPipeline(Repository repo, String platform) {
        return new Pipeline(repo).platform(platform);
    }

    private static Artifact createPackage(Repository repo, String apiVersion, Credential devhub) {
        return new Artifact(repo)
            .name('Testpkg')
            .type('Unlocked')
            .recordTypeId('Package_Artifact')
            .apiVersion(apiVersion)
            .targetDevHub(devhub)
            .pipeline(getPipelineObj());
    }

    private static ArtifactVersion createPackageVersion(Artifact pkg, String apiVersion) {
        return new ArtifactVersion(pkg).name('ver 0.1').versionNumber('0.1.0.1').apiVersion(apiVersion);
    }

    private static Environment createEnvironment() {
        return new Environment().platform('SFDX').type('Production/Developer');
    }

    private static Credential createCredential(Boolean isDevhub) {
        return new Credential().devhub(isDevhub).type('Production/Developer');
    }

    private static JobTemplate createJobTemplate(String name) {
        return new JobTemplate().name(name);
    }

    private static JobStep createJobStep(String stepName, String stepType) {
        return new JobStep().name(stepName).type(stepType);
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

    private static copado__Artifact_Version__c getVersion() {
        return [
            SELECT Name, copado__Artifact__c, copado__Version_Name__c, copado__Version_number__c, copado__Subscriber_Version_Id__c
            FROM copado__Artifact_Version__c
            LIMIT 1
        ];
    }

    private static copado__Org__c getCredential(Boolean isDevhub) {
        return [
            SELECT Id, copado__Environment__c, copado__is_Developer_Hub_Org__c
            FROM copado__Org__c
            WHERE copado__is_Developer_Hub_Org__c = :isDevhub
            LIMIT 1
        ];
    }

    private static copado__Deployment_Job__c getDeploymentJob() {
        return [SELECT Id FROM copado__Deployment_Job__c LIMIT 1];
    }

    private static copado__Environment__c getEnvironment() {
        return [SELECT Id FROM copado__Environment__c LIMIT 1];
    }

    private static copado__JobExecution__c getJobExecution(Id executionId) {
        return [SELECT Id, copado__DataJson__c, copado__Source__c, copado__Pipeline__c FROM copado__JobExecution__c WHERE Id = :executionId];
    }

    private static copado__Git_Repository__c getRepository() {
        return [SELECT Id FROM copado__Git_Repository__c LIMIT 1];
    }

    private static copado__Deployment_Flow__c getPipeline() {
        return [SELECT Id FROM copado__Deployment_Flow__c LIMIT 1];
    }

    private static Repository getRepositoryObj() {
        return new Repository().recordId(getRepository().Id);
    }

    private static Credential getCredentialObj(Boolean isDevhub) {
        return new Credential().recordId(getCredential(isDevhub).Id);
    }

    private static Pipeline getPipelineObj() {
        return new Pipeline().recordId(getPipeline().Id);
    }

    private static JobStep createJobStep(JobTemplate template, String stepName, String stepType) {
        return new JobStep(template).name(stepName).type(stepType);
    }
}