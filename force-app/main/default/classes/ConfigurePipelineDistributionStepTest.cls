@IsTest
private class ConfigurePipelineDistributionStepTest {
    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    private static void createData() {
        Repository repo = createRepository();
        Credential cred = createCredential(true);
        Pipeline pipelineSFDX = createPipeline(repo, 'SFDX');
        Pipeline pipelineSalesforce = createPipeline(repo, 'Salesforce');
        new Project(pipelineSFDX);
        new Project(pipelineSalesforce);

        createPackageVersion(createPackage(repo, cred, pipelineSFDX));
        createPackageVersion(createPackage(repo, cred, pipelineSalesforce));
        createEnvironment().add(cred).persist();
    }

    @IsTest
    private static void createDeploymentStepForNewStory() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            copado__Artifact_Version__c version = getVersion('SFDX');

            ConfigurePipelineDistributionStep.Request request = new ConfigurePipelineDistributionStep.Request();
            request.newSerializedUserStory =
                '{"copado__User_Story_Title__c": "Install PackageTest - 1.0.0.0", "copado__Project__c": "' +
                getProject('SFDX').Id +
                '"}';
            request.packageVersionId = version.Id;
            request.installSecurityType = 'AllUsers';

            // EXERCISE

            ConfigurePipelineDistributionStep.Result result = ConfigurePipelineDistributionStep.createDeploymentStep(
                    new List<ConfigurePipelineDistributionStep.Request>{ request }
                )
                .get(0);

            // VERIFY

            List<copado__User_Story__c> story = getUserStoryWithSteps();
            copado__JobStep__c step = story[0].copado__JobSteps__r[0];
            List<JobStepCreate.Parameter> params = new List<JobStepCreate.Parameter>{
                new JobStepCreate.Parameter('packageVersionId', version.Id),
                new JobStepCreate.Parameter('deploymentId', '{$Job.ExecutionParent.Id}'),
                new JobStepCreate.Parameter('installSecurityType', 'AllUsers')
            };
            JobStepCreate.ConfigJson configJson = (JobStepCreate.ConfigJson) JSON.deserialize(
                step.copado__ConfigJson__c,
                JobStepCreate.ConfigJson.class
            );

            System.assertEquals(1, story.size(), 'New user story should be created.');
            System.assertEquals(result.userStoryId, story[0].Id, 'Result should contain new user story.');
            System.assertEquals(1, story[0].copado__JobSteps__r.size(), 'New deployment step should be created for user story.');
            System.assertEquals(1, step.copado__Order__c, 'Order of step should be 1.');
            System.assertEquals('Start Pkg - 0.1.0.1 Installation Job', step.Name, 'Step name should be correct.');
            System.assert(configJson.flowName.contains('InitiatePipelineDistribution'), 'Step name should be correct.');
            System.assertEquals(params.toString(), configJson.parameters.toString(), 'Parameters should be correct.');
        }
    }

    @IsTest
    private static void createDeploymentTaskForNewStory() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            copado__Artifact_Version__c version = getVersion('Salesforce');

            ConfigurePipelineDistributionStep.Request request = new ConfigurePipelineDistributionStep.Request();
            request.newSerializedUserStory =
                '{"copado__User_Story_Title__c": "Install PackageTest - 1.0.0.0", "copado__Project__c": "' +
                getProject('Salesforce').Id +
                '"}';
            request.packageVersionId = version.Id;
            request.installSecurityType = 'AllUsers';

            // EXERCISE

            ConfigurePipelineDistributionStep.Result result = ConfigurePipelineDistributionStep.createDeploymentStep(
                    new List<ConfigurePipelineDistributionStep.Request>{ request }
                )
                .get(0);

            // VERIFY

            List<copado__User_Story__c> story = getUserStoryWithTasks();
            copado__Deployment_Task__c task = story[0].copado__Deployment_Tasks__r[0];
            DeploymentTaskCreate.ConfigJson configJson = (DeploymentTaskCreate.ConfigJson) JSON.deserialize(
                task.copado__dataJSON__c,
                DeploymentTaskCreate.ConfigJson.class
            );

            System.assertEquals(1, story.size(), 'New user story should be created.');
            System.assertEquals(result.userStoryId, story[0].Id, 'Result should contain new user story.');
            System.assertEquals(1, story[0].copado__Deployment_Tasks__r.size(), 'New deployment tasks should be created for user story.');
            System.assertEquals(1, task.copado__Order__c, 'Order of task should be 1.');
            System.assertEquals('Start Pkg - 0.1.0.1 Installation Job', task.Name, 'Task name should be correct.');
            System.assert(configJson.flowApiName.contains('Initiate_Classic_Pipeline_Distribution'), 'Task name should be correct.');
        }
    }

    @IsTest
    private static void createDeploymentStepForExistingStory() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            createJobStep(createUserStory(createCredential(true), getProject('SFDX').Id)).persist();

            ConfigurePipelineDistributionStep.Request request = new ConfigurePipelineDistributionStep.Request();
            request.existingUserStoryId = getUserStoryWithSteps()[0].Id;
            request.packageVersionId = getVersion('SFDX').Id;
            request.installSecurityType = 'AllUsers';

            // EXERCISE

            ConfigurePipelineDistributionStep.Result result = ConfigurePipelineDistributionStep.createDeploymentStep(
                    new List<ConfigurePipelineDistributionStep.Request>{ request }
                )
                .get(0);

            // VERIFY

            List<copado__User_Story__c> story = getUserStoryWithSteps();

            System.assertEquals(1, story.size(), 'Only existing user story should be present.');
            System.assertEquals(result.userStoryId, story[0].Id, 'Result should contain existing user story.');
            System.assertEquals(2, story[0].copado__JobSteps__r.size(), 'New deployment step should be created for user story.');
            System.assertEquals(2, story[0].copado__JobSteps__r[0].copado__Order__c, 'Order of step should be 2.');
        }
    }

    @IsTest
    private static void createDeploymentTaskForExistingStory() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            createDeploymentTask(createUserStory(createCredential(true), getProject('Salesforce').Id)).persist();

            ConfigurePipelineDistributionStep.Request request = new ConfigurePipelineDistributionStep.Request();
            request.existingUserStoryId = getUserStoryWithSteps()[0].Id;
            request.packageVersionId = getVersion('Salesforce').Id;
            request.installSecurityType = 'AllUsers';

            // EXERCISE

            ConfigurePipelineDistributionStep.Result result = ConfigurePipelineDistributionStep.createDeploymentStep(
                    new List<ConfigurePipelineDistributionStep.Request>{ request }
                )
                .get(0);

            // VERIFY

            List<copado__User_Story__c> story = getUserStoryWithTasks();

            System.assertEquals(1, story.size(), 'Only existing user story should be present.');
            System.assertEquals(result.userStoryId, story[0].Id, 'Result should contain existing user story.');
            System.assertEquals(2, story[0].copado__Deployment_Tasks__r.size(), 'New deployment task should be created for user story.');
            System.assertEquals(2, story[0].copado__Deployment_Tasks__r[0].copado__Order__c, 'Order of task should be 2.');
        }
    }

    private static Repository createRepository() {
        return new Repository().name('My Repo');
    }

    private static Pipeline createPipeline(Repository repo, String platform) {
        return new Pipeline(repo).platform(platform);
    }

    private static Artifact createPackage(Repository repo, Credential cred, Pipeline pipeline) {
        return new Artifact(repo).name('Pkg').type('Unlocked').recordTypeId('Package_Artifact').targetDevHub(cred).pipeline(pipeline);
    }

    private static ArtifactVersion createPackageVersion(Artifact pkg) {
        return new ArtifactVersion(pkg).name('ver 0.1').versionNumber('0.1.0.1');
    }

    private static Environment createEnvironment() {
        return new Environment().platform('SFDX').type('Production/Developer');
    }

    private static Credential createCredential(Boolean isDevHub) {
        return new Credential().devhub(isDevHub).type('Production/Developer');
    }

    private static JobStep createJobStep(UserStory story) {
        return new JobStep().name('Step 1').type('Flow').userStory(story).order(1).sequence('after');
    }

    private static DeploymentTask createDeploymentTask(UserStory story) {
        return new DeploymentTask().name('Task 1').type('Salesforce Flow').userStory(story).order(1).sequence('After Deployment');
    }

    private static UserStory createUserStory(Credential cred, Id projectId) {
        return new UserStory().title('US 1').status('Draft').credential(cred).project(new Project().recordId(projectId));
    }

    private static List<copado__User_Story__c> getUserStoryWithSteps() {
        return [
            SELECT Id, (SELECT Name, copado__ConfigJson__c, copado__Order__c FROM copado__JobSteps__r ORDER BY copado__Order__c DESC)
            FROM copado__User_Story__c
        ];
    }

    private static List<copado__User_Story__c> getUserStoryWithTasks() {
        return [
            SELECT Id, (SELECT Name, copado__dataJSON__c, copado__Order__c FROM copado__Deployment_Tasks__r ORDER BY copado__Order__c DESC)
            FROM copado__User_Story__c
        ];
    }

    private static copado__Project__c getProject(String platform) {
        return [SELECT Id FROM copado__Project__c WHERE copado__Deployment_Flow__r.copado__Platform__c = :platform];
    }

    private static copado__Artifact_Version__c getVersion(String platform) {
        return [SELECT Id FROM copado__Artifact_Version__c WHERE copado__Artifact__r.copado__Pipeline__r.copado__Platform__c = :platform LIMIT 1];
    }
}