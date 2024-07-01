@IsTest
private class RefreshOrgMetadataCacheTest {
    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void refreshMetadataWithNullCredentialId() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id credentialId = null;
            Exception exceptionMessage;

            // EXERCISE

            Test.startTest();
            try {
                new RefreshOrgMetadataCache(credentialId).execute();
            } catch (Exception ex) {
                exceptionMessage = ex;
            }
            Test.stopTest();

            // VERIFY

            Assert.isTrue(
                exceptionMessage.getMessage().contains(Label.Credential_Not_Found),
                'The exception message should be ' + Label.Credential_Not_Found
            );
        }
    }

    @IsTest
    private static void refreshMetadataWithInvalidCredentialId() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id credentialId = fflib_IDGenerator.generate('001');
            Exception exceptionMessage;

            // EXERCISE

            Test.startTest();
            try {
                new RefreshOrgMetadataCache(credentialId).execute();
            } catch (Exception ex) {
                exceptionMessage = ex;
            }
            Test.stopTest();

            // VERIFY

            Assert.isTrue(
                exceptionMessage.getMessage().contains(Label.Credential_Not_Found),
                'The exception message should be ' + Label.Credential_Not_Found
            );
        }
    }

    @IsTest
    private static void refreshMetadataWithValidCredentialId() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id credentialId = getCredentialId('Cred1');

            // EXERCISE

            Test.startTest();
            copado__JobExecution__c jobExecution = new RefreshOrgMetadataCache(credentialId).execute();
            Test.stopTest();

            // VERIFY

            List<copado__JobExecution__c> jobExecutions = getJobExecutions();
            Assert.areEqual(1, jobExecutions.size(), 'We should have a job execution record');
            Assert.areEqual(
                RefreshOrgMetadataCache.SFDX_REFRESH_METADATA_TEMPLATE,
                jobExecutions[0].copado__Template__r.copado__ApiName__c,
                'The job execution should belong to the SFDX Refresh Metadata job template'
            );
            Assert.areEqual(jobExecutions[0].Id, jobExecution.Id, 'The job execution records should match');
        }
    }

    @IsTest
    private static void refreshMetadataWithInProgressJobExecution() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id credentialId = getCredentialId('Cred1');
            new JobExecution(getJobTemplate(), getEnvironment('Env1'))
                .source(getEnvironment('Env1'))
                .dataJson('{"credentialId":"' + credentialId + '"}')
                .status('In Progress')
                .add(getJobStep())
                .persist();

            // EXERCISE

            Test.startTest();
            copado__JobExecution__c jobExecution = new RefreshOrgMetadataCache(credentialId).execute();
            Test.stopTest();

            // VERIFY

            List<copado__JobExecution__c> jobExecutions = getJobExecutions();
            Assert.areEqual(1, jobExecutions.size(), 'We should have a job execution record');
            Assert.areEqual(
                RefreshOrgMetadataCache.SFDX_REFRESH_METADATA_TEMPLATE,
                jobExecutions[0].copado__Template__r.copado__ApiName__c,
                'The job execution should belong to the SFDX Refresh Metadata job template'
            );
            Assert.areEqual(jobExecutions[0].Id, jobExecution.Id, 'The job execution records should match');
        }
    }

    @IsTest
    private static void refreshMetadataWithInProgressJobOfDiffEnv() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            new JobExecution(getJobTemplate(), getEnvironment('Env1'))
                .source(getEnvironment('Env1'))
                .dataJson('{"credentialId":"' + getCredentialId('Cred1') + '"}')
                .status('In Progress')
                .add(getJobStep())
                .persist();
            new Credential(new Environment().platform('SFDX').type('Production/Developer').name('Env2'))
                .type('Production/Developer')
                .name('Cred2')
                .persist();
            Id jobExecutionIdForEnv1 = getJobExecutions()[0].Id;
            Id credentialId = getCredentialId('Cred2');

            // EXERCISE

            Test.startTest();
            copado__JobExecution__c jobExecution = new RefreshOrgMetadataCache(credentialId).execute();
            Test.stopTest();

            // VERIFY

            List<copado__JobExecution__c> jobExecutions = getJobExecutions();
            Assert.areEqual(2, jobExecutions.size(), 'We should have two job execution records');
            Assert.areEqual(
                RefreshOrgMetadataCache.SFDX_REFRESH_METADATA_TEMPLATE,
                [SELECT Id, copado__Template__r.copado__ApiName__c FROM copado__JobExecution__c WHERE Id = :jobExecution.Id][0]
                .copado__Template__r.copado__ApiName__c,
                'The job execution should belong to the SFDX Refresh Metadata job template'
            );
            Assert.areNotEqual(jobExecutionIdForEnv1, jobExecution.Id, 'The job execution records should not match');
        }
    }

    private static Id getCredentialId(String credentialName) {
        return [SELECT Id FROM copado__Org__c WHERE Name = :credentialName LIMIT 1].Id;
    }

    private static List<copado__JobExecution__c> getJobExecutions() {
        return [SELECT Id, copado__Template__r.copado__ApiName__c FROM copado__JobExecution__c];
    }

    private static JobTemplate getJobTemplate() {
        Id jobTemplateId = [SELECT Id FROM copado__JobTemplate__c LIMIT 1].Id;
        return new JobTemplate().recordId(jobTemplateId);
    }

    private static Environment getEnvironment(String environmentName) {
        Id environmentId = [SELECT Id FROM copado__Environment__c WHERE Name = :environmentName LIMIT 1].Id;
        return new Environment().recordId(environmentId);
    }

    private static JobStep getJobStep() {
        Id jobStepId = [SELECT Id FROM copado__JobStep__c LIMIT 1].Id;
        return new JobStep(getJobTemplate()).recordId(jobStepId);
    }

    private static void createData() {
        JobTemplate jobTemplate = new JobTemplate()
            .name('SFDX Refresh Metadata')
            .apiName(RefreshOrgMetadataCache.SFDX_REFRESH_METADATA_TEMPLATE)
            .type('Custom');
        new JobStep(jobTemplate).name('Refresh Metadata').type('Function');
        new Credential(new Environment().platform('SFDX').type('Production/Developer').name('Env1'))
            .type('Production/Developer')
            .name('Cred1')
            .persist();

        update new copado__JobTemplate__c(Id = jobTemplate.id, copado__ApiName__c = 'SFDX Refresh Metadata_1');
    }
}