@IsTest
private with sharing class AddFileLinksOnPromotionTest {
    private static final String COPADO_ROLLBACK_CHANGES = 'Copado Rollback Changes';
    
    @TestSetup
    private static void testSetup() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            makeData();
        }
    }

    @IsTest
    private static void executeFileLinkingOnPromotionWithCorrectFile() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            copado__Result__c result = getResult();
            copado__Promotion__c promotion = getPromotion();
            ContentVersion contentVersion = getContentVersion();

            // EXERCISE

            AddFileLinksOnPromotion.Request request = new AddFileLinksOnPromotion.Request();
            request.resultId = result.Id;
            request.fileName = COPADO_ROLLBACK_CHANGES;
            AddFileLinksOnPromotion.execute(new List<AddFileLinksOnPromotion.Request>{ request });

            // VERIFY

            List<ContentDocumentLink> contentDocumentLinks = getContentDocumentLink(promotion.Id);
            Assert.areEqual(1, contentDocumentLinks.size(), COPADO_ROLLBACK_CHANGES + ' file should be present on promotion');
            Assert.areEqual(
                contentVersion.ContentDocumentId,
                contentDocumentLinks[0].ContentDocumentId,
                COPADO_ROLLBACK_CHANGES + ' file should be present on promotion'
            );
        }
    }

    @IsTest
    private static void executeFileLinkingOnPromotionWithInCorrectFile() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            copado__Result__c result = getResult();
            copado__Promotion__c promotion = getPromotion();
            String fileName = COPADO_ROLLBACK_CHANGES + 'Test';

            // EXERCISE

            AddFileLinksOnPromotion.Request request = new AddFileLinksOnPromotion.Request();
            request.resultId = result.Id;
            request.fileName = fileName;
            AddFileLinksOnPromotion.execute(new List<AddFileLinksOnPromotion.Request>{ request });

            // VERIFY

            List<ContentDocumentLink> contentDocumentLinks = getContentDocumentLink(promotion.Id);
            Assert.isTrue(contentDocumentLinks.isEmpty(), 'There should be no file on the promotion record');
        }
    }

    @IsTest
    private static void executeFileLinkingOnPromotionWithIncorrectRequest() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            copado__Promotion__c promotion = getPromotion();

            // EXERCISE

            AddFileLinksOnPromotion.Request request = new AddFileLinksOnPromotion.Request();
            request.fileName = COPADO_ROLLBACK_CHANGES;
            AddFileLinksOnPromotion.execute(new List<AddFileLinksOnPromotion.Request>{ request });

            // VERIFY

            List<ContentDocumentLink> contentDocumentLinks = getContentDocumentLink(promotion.Id);
            Assert.isTrue(contentDocumentLinks.isEmpty(), 'There should be no file on the promotion record');
        }
    }

    @IsTest
    private static void executeFileRelinkingOnPromotionWithCorrectFile() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            copado__Result__c result = getResult();
            copado__Promotion__c promotion = getPromotion();
            ContentVersion contentVersion = getContentVersion();

            // EXERCISE

            AddFileLinksOnPromotion.Request request = new AddFileLinksOnPromotion.Request();
            request.resultId = result.Id;
            request.fileName = COPADO_ROLLBACK_CHANGES;
            AddFileLinksOnPromotion.execute(new List<AddFileLinksOnPromotion.Request>{ request });
            // Here we are re-runnig the file creation logic to check that the old link will get deleted
            // and the new link will get created and we will not have multiple links
            AddFileLinksOnPromotion.execute(new List<AddFileLinksOnPromotion.Request>{ request });

            // VERIFY

            List<ContentDocumentLink> contentDocumentLinks = getContentDocumentLink(promotion.Id);
            Assert.areEqual(1, contentDocumentLinks.size(), COPADO_ROLLBACK_CHANGES + ' file should be present on promotion');
            Assert.areEqual(
                contentVersion.ContentDocumentId,
                contentDocumentLinks[0].ContentDocumentId,
                COPADO_ROLLBACK_CHANGES + ' file should be present on promotion'
            );
        }
    }

    @IsTest
    private static void executeFileLinkingOnPromotionWithFailedResult() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            copado__Result__c result = getResult();
            result.copado__Status__c = 'Failed';
            update result;
            copado__Promotion__c promotion = getPromotion();

            // EXERCISE

            AddFileLinksOnPromotion.Request request = new AddFileLinksOnPromotion.Request();
            request.resultId = result.Id;
            request.fileName = COPADO_ROLLBACK_CHANGES;
            AddFileLinksOnPromotion.execute(new List<AddFileLinksOnPromotion.Request>{ request });

            // VERIFY

            List<ContentDocumentLink> contentDocumentLinks = getContentDocumentLink(promotion.Id);
            Assert.isTrue(contentDocumentLinks.isEmpty(), 'There should be no file on the promotion record');
        }
    }

    // PRIVATE
    private static void makeData() {
        Environment sourceEnv = new Environment();
        Environment destinationEnv = new Environment();
        Credential sourceCred = new Credential(sourceEnv);
        Credential destinationCred = new Credential(destinationEnv);
        new Promotion(
            new Project(new Pipeline(new Repository().name('Repo 1')).platform('SFDX')),
            sourceCred,
            sourceEnv,
            destinationCred,
            destinationEnv
        );

        JobTemplate jobTemplate = new JobTemplate().name('SFDX Deploy').type('Custom');
        JobStep jobStep = new JobStep(jobTemplate).name('SFDX Deploy').type('Function');
        new JobExecution(jobTemplate, destinationEnv).add(jobStep);
        new Result(jobStep).type('Integration').status('Success').persist();

        copado__Deployment__c deployment = createDeployment();
        addDeploymentOnJobExecution(deployment);
        addFileOnResult();
    }

    private static copado__Deployment__c createDeployment() {
        copado__Promotion__c promotion = [SELECT Id FROM copado__Promotion__c LIMIT 1];
        copado__Deployment__c deployment = new copado__Deployment__c();
        deployment.copado__Promotion__c = promotion.Id;
        insert deployment;
        return deployment;
    }

    private static void addDeploymentOnJobExecution(copado__Deployment__c deployment) {
        copado__JobExecution__c jobExecution = [SELECT Id FROM copado__JobExecution__c LIMIT 1];
        jobExecution.copado__Deployment__c = deployment.Id;
        update jobExecution;
    }

    private static void addFileOnResult() {
        copado__Result__c result = getResult();
        new ContentVersion_t()
            .title(COPADO_ROLLBACK_CHANGES)
            .pathOnClient(COPADO_ROLLBACK_CHANGES + '.json')
            .firstPublishLocationId(result.Id)
            .versionData(getRollbackContent())
            .persist();
    }

    private static Blob getRollbackContent() {
        List<TestUtilities.RollbackChanges> content = new List<TestUtilities.RollbackChanges>();
        content.add(new TestUtilities.RollbackChanges('Test1', 'ApexClass', 'Delete', 'SFDX', false, true, false));
        content.add(new TestUtilities.RollbackChanges('Test2', 'ApexClass', 'Delete', 'SFDX', false, true, false));
        return Blob.valueOf(JSON.serialize(content));
    }

    private static copado__Result__c getResult() {
        return [SELECT Id FROM copado__Result__c LIMIT 1];
    }

    private static copado__Promotion__c getPromotion() {
        return [SELECT Id FROM copado__Promotion__c LIMIT 1];
    }

    private static List<ContentDocumentLink> getContentDocumentLink(Id entityId) {
        return [SELECT ContentDocumentId FROM ContentDocumentLink WHERE ContentDocument.Title = :COPADO_ROLLBACK_CHANGES AND LinkedEntityId = :entityId];
    }

    private static ContentVersion getContentVersion() {
        return [SELECT ContentDocumentId FROM ContentVersion WHERE Title = :COPADO_ROLLBACK_CHANGES LIMIT 1];
    }
}