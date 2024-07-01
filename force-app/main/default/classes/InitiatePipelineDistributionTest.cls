@IsTest
private class InitiatePipelineDistributionTest {
    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void startExecution() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // Setup

            Id deploymentId = [SELECT Id FROM copado__Deployment__c LIMIT 1].Id;
            Id packageVersionId = [SELECT Id FROM copado__Artifact_Version__c LIMIT 1].Id;
            String installSecurityType = 'AllUsers';

            InitiatePipelineDistribution.Request request = new InitiatePipelineDistribution.Request();
            request.deploymentId = deploymentId;
            request.packageVersionId = packageVersionId;
            request.installSecurityType = installSecurityType;

            // Exercise

            Test.startTest();
            InitiatePipelineDistribution.startExecution(new List<InitiatePipelineDistribution.Request>{ request });
            Test.stopTest();

            // Verify

            List<copado__JobExecution__c> result = [
                SELECT Id, copado__DataJson__c
                FROM copado__JobExecution__c
                WHERE copado__Template__r.Name = 'SFDX Package Distribution'
            ];

            DeployPackages.PackageVersion version = (DeployPackages.PackageVersion) JSON.deserialize(
                result[0].copado__DataJson__c,
                DeployPackages.PackageVersion.class
            );

            Assert.areEqual(1, result.size(), 'Job Executions creation has failed.');
            Assert.areEqual('54.0', version.apiVersion, 'Api Version should be updated from package version record on the Job Execution DataJSON');

            Assert.areEqual(
                installSecurityType,
                version.installSecurityType,
                'Package Installation security type should be updated on Job Execution DataJSON'
            );
            Assert.isNull(version.installationKey, 'Installation key should be updated on the Job Execution DataJSON');
            Assert.areEqual(
                getPackageVersion().copado__Subscriber_Version_Id__c,
                version.subscriberId,
                'Subscriber Version Id should be updated on the Job Execution DataJSON'
            );
        }
    }

    @IsTest
    private static void exception() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // Setup

            Exception expectedException = null;
            InitiatePipelineDistribution.Request request = new InitiatePipelineDistribution.Request();

            // Exercise

            try {
                InitiatePipelineDistribution.startExecution(new List<InitiatePipelineDistribution.Request>{ request });
            } catch (Exception ex) {
                expectedException = ex;
            }

            // Verify

            Assert.isNotNull(expectedException, 'Exception should be thrown.');
        }
    }

    // HELPER

    private static void createData() {
        copado__Git_Repository__c repo = TestDataFactory.createGitRepository('Repo 1');
        insert repo;

        copado__Environment__c sEnv = TestDataFactory.createEnvironment('Src Env', 'Production/Developer', 'SFDX');
        copado__Environment__c dEnv = TestDataFactory.createEnvironment('Dst Env', 'Production/Developer', 'SFDX');
        insert new List<copado__Environment__c>{ sEnv, dEnv };

        copado__Org__c sCred = TestDataFactory.createCredential('Src Cred', UserInfo.getUserName(), sEnv.Id, null);
        copado__Org__c dCred = TestDataFactory.createCredential('Dst Cred', UserInfo.getUserName(), dEnv.Id, null);
        sCred.copado__is_Developer_Hub_Org__c = true;
        insert new List<copado__Org__c>{ sCred, dCred };

        copado__JobTemplate__c promotionJob = TestDataFactory.createJobTemplate('Promotion');
        insert promotionJob;

        copado__Deployment_Flow__c pipeline = TestDataFactory.createPipeline('Pipeline1', repo.Id);
        pipeline.copado__Platform__c = 'SFDX';
        insert pipeline;

        copado__Pipeline_Action__c action = TestDataFactory.createPipelineAction('Promotion', pipeline.Id, promotionJob.Id);
        insert action;

        copado__Deployment_Flow_Step__c pipelineConnection = TestDataFactory.createPipelineConnection(pipeline.Id, sEnv.Id, dEnv.Id);
        insert pipelineConnection;

        copado__Project__c project = TestDataFactory.createProject('Project 1', pipeline.Id);
        insert project;

        copado__User_Story__c stories = new copado__User_Story__c(copado__Project__c = project.Id, copado__Org_Credential__c = sCred.Id);

        insert stories;

        copado__Promotion__c promotion = new copado__Promotion__c(
            copado__Project__c = project.Id,
            copado__Source_Environment__c = sEnv.Id,
            copado__Source_Org_Credential__c = sCred.Id,
            copado__Destination_Environment__c = dEnv.Id,
            copado__Destination_Org_Credential__c = dCred.Id
        );
        insert promotion;

        copado__JobStep__c step = new copado__JobStep__c(
            Name = 'Start Installation Job',
            copado__UserStory__c = stories.Id,
            copado__Type__c = 'Flow',
            copado__CustomType__c = 'Flow',
            copado__ExecutionSequence__c = 'after',
            copado__Order__c = 1
        );
        insert step;

        copado__Deployment__c deployment = new copado__Deployment__c(Name = 'Deployment 1', copado__Promotion__c = promotion.Id);
        insert deployment;

        copado__Artifact__c pkg = TestDataFactory.createPackage('Pkg1', 'Package_Artifact');
        pkg.copado__Artifact_Repository__c = repo.Id;
        pkg.copado__Target_Dev_Hub_Org__c = sCred.Id;
        insert pkg;

        copado__Artifact_Version__c version = TestDataFactory.createPackageVersion('Pkg1_v1', pkg.Id);
        version.Api_Version__c = '54.0';
        insert version;

        JobTemplate template = new JobTemplate().name('SFDX Package Distribution');
        new JobStep(template).name('Get Dependencies').type('Function');
        new JobStep(template).name('Install package').type('Function').persist();
        update new copado__JobTemplate__c(Id = template.id, copado__ApiName__c = 'SFDX Package Distribution_1');
    }

    private static copado__Org__c getCredential(Boolean isDevhub) {
        return [
            SELECT Id, copado__Environment__c, copado__is_Developer_Hub_Org__c
            FROM copado__Org__c
            WHERE copado__is_Developer_Hub_Org__c = :isDevhub
            LIMIT 1
        ];
    }

    private static copado__Artifact_Version__c getPackageVersion() {
        return [SELECT Id, copado__LastJobExecutionId__c, copado__Subscriber_Version_Id__c FROM copado__Artifact_Version__c LIMIT 1];
    }
}