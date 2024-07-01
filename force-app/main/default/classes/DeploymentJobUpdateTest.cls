@IsTest
private class DeploymentJobUpdateTest {
    @SuppressWarnings('PMD.AvoidHardcodingId')
    private static final String DEPLOYMENT_JOB_ID = fflib_IDGenerator.generate(copado__Deployment_Job__c.SObjectType);
    private static final String SUBSCRIBERID = fflib_IDGenerator.generate('04t');


    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void successfullyDistributePackage() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            Id resultId = getResult().Id;
            getJobExecutionObj()
                .dataJSON(
                    '{"subscriberId":"' + SUBSCRIBERID +'","installationKey":"123 321","deploymentJobId":"' +
                    getDeploymentJob(resultId).Id +
                    '"}'
                )
                .persist();
            copado__JobExecution__c jobExecution = getJobExecution();

            // EXERCISE

            Test.startTest();
            DeploymentJobUpdate deploymentJob = new DeploymentJobUpdate();
            deploymentJob.execute(jobExecution, 'Successful');
            Test.stopTest();

            // VERIFY
            System.assertEquals('Success', getResult().copado__Status__c, 'Result status should be success.');
        }
    }

    private static void createData() {
        JobTemplate distributePackageTemplate = new JobTemplate()
            .name('SFDX Package Distribution')
            .type('Custom')
            .apiName('SFDX Package Distribution_1');

        JobStep jobStep = new JobStep(distributePackageTemplate).name('Install package').type('Function');

        Credential sourceCred = new Credential().devhub(false).type('Production/Developer');
        Deployment deployment = new Deployment(sourceCred).name('CD: Deploy - US-XXXX ➠ Classic - Dev');

        new JobExecution(distributePackageTemplate, new Environment())
            .dataJson('{"subscriberId":"' + SUBSCRIBERID + '","installationKey":"123 321","deploymentJobId":"' + DEPLOYMENT_JOB_ID + '"}')
            .add(jobStep);

        Step step = new Step(deployment).name('Package Installation Job').order(1);
        DestinationCredential destCred = new DestinationCredential(deployment)
            .destinationOrg(new Credential().devhub(false).type('Production/Developer'));

        new DeploymentJob(step, destCred).lastResult(new Result().type('Integration')).persist();
    }

    private static copado__JobExecution__c getJobExecution() {
        return [SELECT Id, copado__DataJson__c FROM copado__JobExecution__c LIMIT 1];
    }

    private static copado__Deployment_Job__c getDeploymentJob(Id resultId) {
        return [SELECT Id, copado__Status__c, copado__Last_Result__c FROM copado__Deployment_Job__c WHERE copado__Last_Result__c = :resultId LIMIT 1];
    }

    private static copado__Result__c getResult() {
        return [SELECT Id, copado__Status__c FROM copado__Result__c LIMIT 1];
    }

    private static JobExecution getJobExecutionObj() {
        return new JobExecution().recordId(getJobExecution().Id);
    }
}