@IsTest
private class UpdateDestinationOnJobExecutionFlowTest {
    @TestSetup
    private static void setUp() {
        TestUtilities.setup();

        System.runAs(TestUtilities.getRunAsUser()) {

            copado__Environment__c environment = TestDataFactory.createEnvironment(
                'DevHub',
                'Production/Developer',
                'SFDX'
            );
            insert environment;

            copado__Org__c credential = TestDataFactory.createCredential(
                'DevHub',
                'test@test.com',
                environment.Id,
                'Production/Developer'
            );

            credential.copado__is_Developer_Hub_Org__c = true;
            insert credential;

            copado__JobTemplate__c template = TestDataFactory.createJobTemplate(
                'SFDX Package Create'
            );
            insert template;

            copado__Result__c result = createResult(
                createJobStep(createJobExecution(template, environment))
            );

            copado__Git_Repository__c repo = createRepository();
            createPackage(repo, createPipeline(repo.Id).Id, credential.Id);
        }
    }

    @IsTest
    private static void updateDestinationId() {
        // Setup

        System.runAs(TestUtilities.getRunAsUser()) {
            Map<String, Object> flowParams = getFlowParams();

            // Exercise
            Test.startTest();
            new Flow.Interview.UpdateDestinationOnJobExecution(flowParams).start();
            Test.stopTest();

            // Verify
            List<copado__JobExecution__c> jobExecutions = getJobExecution();

            System.assertEquals(
                jobExecutions[0].copado__Destination__c,
                getEnvironment()[0].Id,
                'Destination updation on Job Execution has been failed'
            );
        }

    }

    private static copado__JobExecution__c createJobExecution(
        copado__JobTemplate__c template,
        copado__Environment__c environment
    ) {
        copado__JobExecution__c execution = new copado__JobExecution__c(
            copado__Template__c = template.Id,
            copado__Destination__c = environment.Id
        );
        insert execution;
        return execution;
    }

    private static copado__JobStep__c createJobStep(copado__JobExecution__c execution) {
        copado__JobStep__c step = new copado__JobStep__c(
            Name = 'Update Destination on Job Execution',
            copado__JobExecution__c = execution.Id,
            copado__Type__c = 'Flow'
        );
        insert step;
        return step;
    }

    private static copado__Git_Repository__c createRepository() {
        copado__Git_Repository__c repo = new copado__Git_Repository__c(Name = 'My Repo');
        insert repo;
        return repo;
    }

    private static copado__Deployment_Flow__c createPipeline(Id repositoryId) {
        copado__Deployment_Flow__c pipeline = new copado__Deployment_Flow__c(
            Name = 'My Pipeline',
            copado__Platform__c = 'SFDX',
            copado__Git_Repository__c = repositoryId
        );
        insert pipeline;
        return pipeline;
    }

    private static copado__Artifact__c createPackage(
        Copado__Git_Repository__c repo,
        Id pipelineId,
        Id credentialId
    ) {
        copado__Artifact__c pkg = new copado__Artifact__c();
        pkg.Name = 'Testpkg';
        pkg.copado__Package_Type__c = 'Unlocked';
        pkg.copado__Artifact_Repository__c = repo.Id;
        pkg.copado__Pipeline__c = pipelineId;
        pkg.copado__Target_Dev_Hub_Org__c = credentialId;
        pkg.RecordTypeId = SObjectType.copado__Artifact__c.getRecordTypeInfosByDeveloperName()
            .get('Package_Artifact')
            .getRecordTypeId();

        insert pkg;
        return pkg;
    }

    private static copado__Result__c createResult(copado__JobStep__c step) {
        copado__Result__c result = new copado__Result__c();
        result.copado__JobStep__c = step.Id;
        result.copado__Job_Type__c = 'Integration';
        insert result;
        return result;
    }

    private static Map<String, Object> getFlowParams() {
        Map<String, Object> flowParams = new Map<String, Object>{
            'packageId' => getPackage()[0].Id,
            'resultId' => getResult()[0].Id
        };
        return flowParams;
    }

    private static List<copado__Artifact__c> getPackage() {
        return [SELECT Id FROM copado__Artifact__c];
    }

    private static List<copado__Result__c> getResult() {
        return [SELECT Id FROM copado__Result__c];
    }

    private static List<copado__Environment__c> getEnvironment() {
        return [SELECT Id FROM copado__Environment__c];
    }

    private static List<copado__JobExecution__c> getJobExecution() {
        return [SELECT copado__Destination__c FROM copado__JobExecution__c];
    }
}