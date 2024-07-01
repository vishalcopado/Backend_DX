@IsTest
private class RefreshMetadataCallbackTest {
    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    private static void executeCallbackWithStatusFailed() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id credentialId = getCredentialId('Cred1');
            JobStep jobStep = getJobStep();
            new JobExecution(getJobTemplate(), getEnvironment()).dataJson('{"credentialId":"' + credentialId + '"}').add(jobStep);
            new Result(jobStep).type('Integration').status('Failed').persist();
            copado__Result__c result = getResult();
            createFileLinks(getContentDocumentIds(), result.Id);
            List<ContentDocumentLink> oldContentDocumentLinks = getContentDocumentLinks(credentialId);

            // EXERCISE

            Test.startTest();
            new RefreshMetadataCallback().execute(new copado__Function__c(), result, result.copado__Status__c);
            Test.stopTest();

            // VERIFY

            List<ContentDocumentLink> newContentDocumentLinks = getContentDocumentLinks(credentialId);
            Assert.areEqual(
                0,
                oldContentDocumentLinks.size(),
                'There should be no content document links present on the credential record'
            );
            Assert.areEqual(
                0,
                newContentDocumentLinks.size(),
                'There should be no content document links present on the credential record'
            );
        }
    }

    @IsTest
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    private static void executeCallbackWithStatusFailedAndFilesOnCredential() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id credentialId = getCredentialId('Cred1');
            JobStep jobStep = getJobStep();
            new JobExecution(getJobTemplate(), getEnvironment()).dataJson('{"credentialId":"' + credentialId + '"}').add(jobStep);
            new Result(jobStep).type('Integration').status('Failed').persist();
            copado__Result__c result = getResult();
            createFileLinks(getContentDocumentIds(), result.Id);
            createFiles(credentialId);
            List<ContentDocumentLink> oldContentDocumentLinks = getContentDocumentLinks(credentialId);

            // EXERCISE

            Test.startTest();
            new RefreshMetadataCallback().execute(new copado__Function__c(), result, result.copado__Status__c);
            Test.stopTest();

            // VERIFY

            List<ContentDocumentLink> newContentDocumentLinks = getContentDocumentLinks(credentialId);
            Assert.areEqual(
                2,
                oldContentDocumentLinks.size(),
                'There should be only two content document links present on the credential record'
            );
            Assert.areEqual(
                2,
                newContentDocumentLinks.size(),
                'There should be only two content document links present on the credential record'
            );
            Assert.areEqual('DeletedMetaData', newContentDocumentLinks[0].ContentDocument.Title, 'The file name should be DeletedMetaData');
            Assert.areEqual('MetaData', newContentDocumentLinks[1].ContentDocument.Title, 'The file name should be MetaData');
            Assert.areEqual(oldContentDocumentLinks[0].Id, newContentDocumentLinks[0].Id, 'The old and new file should be same');
            Assert.areEqual(oldContentDocumentLinks[1].Id, newContentDocumentLinks[1].Id, 'The old and new file should be same');
        }
    }

    @IsTest
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    private static void executeCallbackWithStatusSuccessful() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id credentialId = getCredentialId('Cred1');
            JobStep jobStep = getJobStep();
            new JobExecution(getJobTemplate(), getEnvironment()).dataJson('{"credentialId":"' + credentialId + '"}').add(jobStep);
            new Result(jobStep).type('Integration').status('Success').persist();
            copado__Result__c result = getResult();
            createFileLinks(getContentDocumentIds(), result.Id);
            List<ContentDocumentLink> oldContentDocumentLinks = getContentDocumentLinks(credentialId);

            // EXERCISE

            Test.startTest();
            new RefreshMetadataCallback().execute(new copado__Function__c(), result, result.copado__Status__c);
            Test.stopTest();

            // VERIFY

            List<ContentDocumentLink> newContentDocumentLinks = getContentDocumentLinks(credentialId);
            Assert.areEqual(
                0,
                oldContentDocumentLinks.size(),
                'There should be no content document links present on the credential record'
            );
            Assert.areEqual(
                2,
                newContentDocumentLinks.size(),
                'There should be only two content document links present on the credential record'
            );
            Assert.areEqual('DeletedMetaData', newContentDocumentLinks[0].ContentDocument.Title, 'The file name should be DeletedMetaData');
            Assert.areEqual('MetaData', newContentDocumentLinks[1].ContentDocument.Title, 'The file name should be MetaData');
        }
    }

    @IsTest
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    private static void executeCallbackWithStatusSuccessfulAndFilesOnCredential() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id credentialId = getCredentialId('Cred1');
            JobStep jobStep = getJobStep();
            new JobExecution(getJobTemplate(), getEnvironment()).dataJson('{"credentialId":"' + credentialId + '"}').add(jobStep);
            new Result(jobStep).type('Integration').status('Success').persist();
            copado__Result__c result = getResult();
            createFileLinks(getContentDocumentIds(), result.Id);
            createFiles(credentialId);
            List<ContentDocumentLink> oldContentDocumentLinks = getContentDocumentLinks(credentialId);

            // EXERCISE

            Test.startTest();
            new RefreshMetadataCallback().execute(new copado__Function__c(), result, result.copado__Status__c);
            Test.stopTest();

            // VERIFY

            List<ContentDocumentLink> newContentDocumentLinks = getContentDocumentLinks(credentialId);
            Assert.areEqual(
                2,
                oldContentDocumentLinks.size(),
                'There should be only two content document links present on the credential record'
            );
            Assert.areEqual(
                2,
                newContentDocumentLinks.size(),
                'There should be only two content document links present on the credential record'
            );
            Assert.areEqual('DeletedMetaData', newContentDocumentLinks[0].ContentDocument.Title, 'The file name should be DeletedMetaData');
            Assert.areEqual('MetaData', newContentDocumentLinks[1].ContentDocument.Title, 'The file name should be MetaData');
            Assert.areNotEqual(oldContentDocumentLinks[0].Id, newContentDocumentLinks[0].Id, 'The old and new file should be diff');
            Assert.areNotEqual(oldContentDocumentLinks[1].Id, newContentDocumentLinks[1].Id, 'The old and new file should be diff');
        }
    }

    @IsTest
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    private static void executeCallbackWithStatusSuccessfulAndMetaDataFileOnResult() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id credentialId = getCredentialId('Cred1');
            JobStep jobStep = getJobStep();
            new JobExecution(getJobTemplate(), getEnvironment()).dataJson('{"credentialId":"' + credentialId + '"}').add(jobStep);
            new Result(jobStep).type('Integration').status('Success').persist();
            copado__Result__c result = getResult();
            createFileLinks(getContentDocumentIds(), result.Id);
            createFiles(credentialId);
            List<ContentDocumentLink> oldContentDocumentLinks = getContentDocumentLinks(credentialId);
            List<ContentDocumentLink> contentDocumentLinksForResult = getContentDocumentLinks(result.Id);
            // Delete DeletedMetaData file from result record
            delete contentDocumentLinksForResult[0];

            // EXERCISE

            Test.startTest();
            new RefreshMetadataCallback().execute(new copado__Function__c(), result, result.copado__Status__c);
            Test.stopTest();

            // VERIFY

            List<ContentDocumentLink> newContentDocumentLinks = getContentDocumentLinks(credentialId);
            Assert.areEqual(
                2,
                oldContentDocumentLinks.size(),
                'There should be only two content document links present on the credential record'
            );
            Assert.areEqual(
                2,
                newContentDocumentLinks.size(),
                'There should be only two content document links present on the credential record'
            );
            Assert.areEqual('DeletedMetaData', newContentDocumentLinks[0].ContentDocument.Title, 'The file name should be DeletedMetaData');
            Assert.areEqual('MetaData', newContentDocumentLinks[1].ContentDocument.Title, 'The file name should be MetaData');
            // The DeletedMetaData file should not be recreated as it is not present on the result record
            Assert.areEqual(oldContentDocumentLinks[0].Id, newContentDocumentLinks[0].Id, 'The old and new file should be same');
            Assert.areNotEqual(oldContentDocumentLinks[1].Id, newContentDocumentLinks[1].Id, 'The old and new file should be diff');
        }
    }

    @IsTest
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    private static void executeCallbackWithStatusSuccessfulAndDeletedMetaDataFileOnResult() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id credentialId = getCredentialId('Cred1');
            JobStep jobStep = getJobStep();
            new JobExecution(getJobTemplate(), getEnvironment()).dataJson('{"credentialId":"' + credentialId + '"}').add(jobStep);
            new Result(jobStep).type('Integration').status('Success').persist();
            copado__Result__c result = getResult();
            createFileLinks(getContentDocumentIds(), result.Id);
            createFiles(credentialId);
            List<ContentDocumentLink> oldContentDocumentLinks = getContentDocumentLinks(credentialId);
            List<ContentDocumentLink> contentDocumentLinksForResult = getContentDocumentLinks(result.Id);
            // Delete MetaData file from result record
            delete contentDocumentLinksForResult[1];

            // EXERCISE

            Test.startTest();
            new RefreshMetadataCallback().execute(new copado__Function__c(), result, result.copado__Status__c);
            Test.stopTest();

            // VERIFY

            List<ContentDocumentLink> newContentDocumentLinks = getContentDocumentLinks(credentialId);
            Assert.areEqual(
                2,
                oldContentDocumentLinks.size(),
                'There should be only two content document links present on the credential record'
            );
            Assert.areEqual(
                2,
                newContentDocumentLinks.size(),
                'There should be only two content document links present on the credential record'
            );
            Assert.areEqual('DeletedMetaData', newContentDocumentLinks[0].ContentDocument.Title, 'The file name should be DeletedMetaData');
            Assert.areEqual('MetaData', newContentDocumentLinks[1].ContentDocument.Title, 'The file name should be MetaData');
            Assert.areNotEqual(oldContentDocumentLinks[0].Id, newContentDocumentLinks[0].Id, 'The old and new file should be diff');
            // The MetaData file should not be recreated as it is not present on the result record
            Assert.areEqual(oldContentDocumentLinks[1].Id, newContentDocumentLinks[1].Id, 'The old and new file should be same');
        }
    }

    @IsTest
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    private static void executeCallbackWithStatusSuccessfulAndNoFileOnResult() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id credentialId = getCredentialId('Cred1');
            JobStep jobStep = getJobStep();
            new JobExecution(getJobTemplate(), getEnvironment()).dataJson('{"credentialId":"' + credentialId + '"}').add(jobStep);
            new Result(jobStep).type('Integration').status('Success').persist();
            copado__Result__c result = getResult();
            createFileLinks(getContentDocumentIds(), result.Id);
            createFiles(credentialId);
            List<ContentDocumentLink> oldContentDocumentLinks = getContentDocumentLinks(credentialId);
            List<ContentDocumentLink> contentDocumentLinksForResult = getContentDocumentLinks(result.Id);
            delete contentDocumentLinksForResult;

            // EXERCISE

            Test.startTest();
            new RefreshMetadataCallback().execute(new copado__Function__c(), result, result.copado__Status__c);
            Test.stopTest();

            // VERIFY

            List<ContentDocumentLink> newContentDocumentLinks = getContentDocumentLinks(credentialId);
            Assert.areEqual(
                2,
                oldContentDocumentLinks.size(),
                'There should be only two content document links present on the credential record'
            );
            Assert.areEqual(
                2,
                newContentDocumentLinks.size(),
                'There should be only two content document links present on the credential record'
            );
            Assert.areEqual('DeletedMetaData', newContentDocumentLinks[0].ContentDocument.Title, 'The file name should be DeletedMetaData');
            Assert.areEqual('MetaData', newContentDocumentLinks[1].ContentDocument.Title, 'The file name should be MetaData');
            // The DeletedMetaData and MetaData file should not be recreated as they are not present on the result record
            Assert.areEqual(oldContentDocumentLinks[0].Id, newContentDocumentLinks[0].Id, 'The old and new file should be same');
            Assert.areEqual(oldContentDocumentLinks[1].Id, newContentDocumentLinks[1].Id, 'The old and new file should be same');
        }
    }

    @IsTest
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    private static void executeCallbackWithStatusSuccessfulAndNoFiles() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id credentialId = getCredentialId('Cred1');
            JobStep jobStep = getJobStep();
            new JobExecution(getJobTemplate(), getEnvironment()).dataJson('{"credentialId":"' + credentialId + '"}').add(jobStep);
            new Result(jobStep).type('Integration').status('Success').persist();
            copado__Result__c result = getResult();
            createFileLinks(getContentDocumentIds(), result.Id);
            List<ContentDocumentLink> oldContentDocumentLinks = getContentDocumentLinks(credentialId);
            List<ContentDocumentLink> contentDocumentLinksForResult = getContentDocumentLinks(result.Id);
            delete contentDocumentLinksForResult;

            // EXERCISE

            Test.startTest();
            new RefreshMetadataCallback().execute(new copado__Function__c(), result, result.copado__Status__c);
            Test.stopTest();

            // VERIFY

            List<ContentDocumentLink> newContentDocumentLinks = getContentDocumentLinks(credentialId);
            Assert.areEqual(
                0,
                oldContentDocumentLinks.size(),
                'There should be no content document links present on the credential record'
            );
            Assert.areEqual(
                0,
                newContentDocumentLinks.size(),
                'There should be no content document links present on the credential record'
            );
        }
    }

    private static JobTemplate getJobTemplate() {
        Id jobTemplateId = [SELECT Id FROM copado__JobTemplate__c LIMIT 1].Id;
        return new JobTemplate().recordId(jobTemplateId);
    }

    private static Environment getEnvironment() {
        Id environmentId = [SELECT Id FROM copado__Environment__c LIMIT 1].Id;
        return new Environment().recordId(environmentId);
    }

    private static JobStep getJobStep() {
        Id jobStepId = [SELECT Id FROM copado__JobStep__c LIMIT 1].Id;
        return new JobStep().recordId(jobStepId);
    }

    private static Id getCredentialId(String credentialName) {
        return [SELECT Id FROM copado__Org__c WHERE Name = :credentialName LIMIT 1].Id;
    }

    private static copado__Result__c getResult() {
        return [SELECT Id, copado__Status__c FROM copado__Result__c LIMIT 1];
    }

    private static void createFileLinks(Set<Id> contentDocumentIds, Id linkedEntityId) {
        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
        for (Id contentDocumentId : contentDocumentIds) {
            contentDocumentLinks.add(
                new ContentDocumentLink(LinkedEntityId = linkedEntityId, ContentDocumentId = contentDocumentId, ShareType = 'v')
            );
        }
        insert contentDocumentLinks;
    }

    private static Set<Id> getContentDocumentIds() {
        Set<Id> contentDocumentIds = new Set<Id>();
        for (ContentVersion contentVersion : [SELECT Id, ContentDocumentId FROM ContentVersion]) {
            contentDocumentIds.add(contentVersion.ContentDocumentId);
        }
        return contentDocumentIds;
    }

    private static void createFiles(Id recordId) {
        List<ContentVersion> contentVersions = new List<ContentVersion>();
        contentVersions.add(
            new ContentVersion(
                Title = 'MetaData',
                PathOnClient = 'MetaData',
                VersionData = Blob.valueOf(getMetadataItem('CustomField', 'Field1', 'Test Test', '1900-01-01'))
            )
        );
        contentVersions.add(
            new ContentVersion(
                Title = 'DeletedMetaData',
                PathOnClient = 'DeletedMetaData',
                VersionData = Blob.valueOf(getMetadataItem('ApexClass', 'SampleClass2', 'Test Test', '1900-01-01'))
            )
        );
        insert contentVersions;

        Set<Id> contentDocumentIds = new Set<Id>();
        for (ContentVersion contentVersion : [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersions]) {
            contentDocumentIds.add(contentVersion.ContentDocumentId);
        }
        createFileLinks(contentDocumentIds, recordId);
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static String getMetadataItem(String metadataType, String name, String createdBy, String createdDate) {
        return JSON.serialize(TestDataFactory.getMetadataItem(metadataType, name, createdBy, createdDate));
    }

    private static List<ContentDocumentLink> getContentDocumentLinks(Id recordId) {
        return [SELECT Id, ContentDocument.Title FROM ContentDocumentLink WHERE LinkedEntityId = :recordId ORDER BY ContentDocument.Title];
    }

    private static void createData() {
        JobTemplate jobTemplate = new JobTemplate().name('SFDX Refresh Metadata').type('Custom');
        new JobStep(jobTemplate).name('Refresh Metadata').type('Function');
        Environment environment = new Environment().platform('SFDX').type('Production/Developer').name('Env1');
        new Credential(environment).type('Production/Developer').name('Cred1');
        new ContentVersion_t()
            .title('MetaData')
            .pathOnClient('MetaData')
            .versionData(Blob.valueOf(getMetadataItem('ApexClass', 'SampleClass1', 'Test Test', '1900-01-01')));
        new ContentVersion_t()
            .title('DeletedMetaData')
            .pathOnClient('DeletedMetaData')
            .versionData(Blob.valueOf(getMetadataItem('ApexClass', 'SampleClass2', 'Test Test', '1900-01-01')))
            .persist();
    }
}