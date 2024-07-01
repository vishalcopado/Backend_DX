@isTest
private class RollbackHeaderCtrlTest {
    private final static String COPADO_ROLLBACK_CHANGES = 'Copado Rollback changes';
    private final static String SFDX_ROLLBACK = 'SFDX Rollback';

    @TestSetup
    private static void setUp() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @isTest
    private static void executeWithProperRequest() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            Id promotionId = getPromotion().Id;

            RollbackHeaderCtrl.RollbackActionRequest rollbackRequest = new RollbackHeaderCtrl.RollbackActionRequest();
            rollbackRequest.isValidation = true;
            rollbackRequest.promotionId = promotionId;
            rollbackRequest.startExecution = true;
            rollbackRequest.testLevel = 'No Test Run';

            // EXERCISE
            Test.startTest();
            Id jobId = RollbackHeaderCtrl.executeRollback(JSON.serialize(rollbackRequest));
            Test.stopTest();

            // VERIFY
            Assert.isNotNull(jobId, 'No job execution gets created.');
            copado__JobExecution__c jobExecution = [
                SELECT Id, copado__Promotion__c, copado__Template__c
                FROM copado__JobExecution__c
                WHERE Id = :jobId
            ];
            Assert.areEqual(promotionId, jobExecution.copado__Promotion__c, 'Promotion Id is not correct');
            Assert.areEqual(getTemplateId(SFDX_ROLLBACK), jobExecution.copado__Template__c, 'Template Id is not correct');
        }
    }

    @isTest
    private static void executeWithoutStartExecutionFlag() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            Id promotionId = getPromotion().Id;

            RollbackHeaderCtrl.RollbackActionRequest rollbackRequest = new RollbackHeaderCtrl.RollbackActionRequest();
            rollbackRequest.isValidation = true;
            rollbackRequest.promotionId = promotionId;
            rollbackRequest.startExecution = false;
            rollbackRequest.testLevel = 'No Test Run';

            // EXERCISE
            Test.startTest();
            Id jobId = RollbackHeaderCtrl.executeRollback(JSON.serialize(rollbackRequest));
            Test.stopTest();

            // VERIFY
            Assert.isNotNull(jobId, 'No job execution gets created.');
            copado__JobExecution__c jobExecution = [
                SELECT Id, copado__Promotion__c, copado__Status__c, copado__Template__c
                FROM copado__JobExecution__c
                WHERE Id = :jobId
            ];
            Assert.areEqual('Not Started', jobExecution.copado__Status__c, 'Job Status is not correct');
            Assert.areEqual(promotionId, jobExecution.copado__Promotion__c, 'Promotion Id is not correct');
            Assert.areEqual(getTemplateId(SFDX_ROLLBACK), jobExecution.copado__Template__c, 'Template Id is not correct');
        }
    }

    @isTest
    private static void executeWithIncompleteRequest() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            String exceptionMessage;
            Id promotionId = getPromotion().Id;
            Id jobId;

            RollbackHeaderCtrl.RollbackActionRequest rollbackRequest = new RollbackHeaderCtrl.RollbackActionRequest();
            rollbackRequest.isValidation = true;
            rollbackRequest.promotionId = promotionId;

            // EXERCISE
            Test.startTest();
            try {
                jobId = RollbackHeaderCtrl.executeRollback(JSON.serialize(rollbackRequest));
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();

            // VERIFY
            Assert.isNull(jobId, 'No job execution gets created.');
            Assert.isNotNull(exceptionMessage, 'There is no exception');
            Assert.areEqual('Script-thrown exception', exceptionMessage, 'The messages do not match');
        }
    }

    @isTest
    private static void executeWithIncorrectParams() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            String exceptionMessage;
            Id jobId;

            String params = '{"testLevel":"No Test Run","startExecution":false,"wrongFlag":"test","isValidation":true}';

            // EXERCISE
            Test.startTest();
            try {
                jobId = RollbackHeaderCtrl.executeRollback(params);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();

            // VERIFY
            Assert.isNull(jobId, 'No job execution gets created.');
            Assert.isNotNull(exceptionMessage, 'There is no exception');
            Assert.areEqual('Script-thrown exception', exceptionMessage, 'The messages do not match');
        }
    }

    @isTest
    private static void executeWithEmptyRequest() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            String exceptionMessage;
            Id jobId;

            // EXERCISE
            Test.startTest();
            try {
                jobId = RollbackHeaderCtrl.executeRollback('');
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();

            // VERIFY
            Assert.isNull(jobId, 'No job execution gets created.');
            Assert.isNotNull(exceptionMessage, 'There is no exception');
            Assert.areEqual('Script-thrown exception', exceptionMessage, 'The messages do not match');
        }
    }

    @isTest
    private static void executeWithWrongContextInRequest() {
        User user = TestUtilities.getRunAsUser();
        System.runAs(user) {
            // SETUP
            String exceptionMessage;
            Id jobId;

            RollbackHeaderCtrl.RollbackActionRequest rollbackRequest = new RollbackHeaderCtrl.RollbackActionRequest();
            rollbackRequest.isValidation = true;
            rollbackRequest.promotionId = user.Id;
            rollbackRequest.startExecution = true;
            rollbackRequest.testLevel = 'No Test Run';

            // EXERCISE
            Test.startTest();
            try {
                jobId = RollbackHeaderCtrl.executeRollback(JSON.serialize(rollbackRequest));
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();

            // VERIFY
            Assert.isNull(jobId, 'No job execution gets created.');
            Assert.isNotNull(exceptionMessage, 'There is no exception');
            Assert.areEqual('Script-thrown exception', exceptionMessage, 'The messages do not match');
        }
    }

    @IsTest
    private static void testCreateExecutionWithFakePromotion() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            copado__Promotion__c promotion = getPromotion().clone(false, false, false, false);
            insert promotion;
            Id promotionFakeId = promotion.Id;
            delete promotion;
            String error;
            Id jobId;

            RollbackHeaderCtrl.RollbackActionRequest rollbackRequest = new RollbackHeaderCtrl.RollbackActionRequest();
            rollbackRequest.isValidation = true;
            rollbackRequest.promotionId = promotionFakeId;
            rollbackRequest.startExecution = true;
            rollbackRequest.testLevel = 'No Test Run';

            // EXERCISE
            Test.startTest();
            try {
                jobId = RollbackHeaderCtrl.executeRollback(JSON.serialize(rollbackRequest));
            } catch (Exception ex) {
                error = ex.getMessage();
            }
            Test.stopTest();

            // VERIFY
            Assert.isNull(jobId, 'No job execution gets created.');
            Assert.isNotNull(error, 'There is no exception');
            Assert.areEqual('Script-thrown exception', error, 'The messages do not match');
        }
    }

    @IsTest
    private static void getNamespace() {
        //Exercise

        String namespace;
        System.runAs(TestUtilities.getRunAsUser()) {
            Test.startTest();
            namespace = RollbackHeaderCtrl.getNamespace();
            Test.stopTest();
        }

        // Verify
        Assert.areEqual(Settings.NS, namespace, 'Namespace returned incorrectly.');
    }

    // HELPER

    private static void createData() {
        System.runAs(TestUtilities.getRunAsUser()) {
            Project project = new Project();

            Environment dev1 = new Environment().name('Dev1');
            Environment staging = new Environment().name('Staging');
            new Credential(dev1);
            new Credential(staging);

            Pipeline pipeline = new Pipeline()
                .name('MyPipeline')
                .platform('SFDX')
                .repository(new Repository())
                .add(project)
                .add(new PipelineConnection().sourceEnvironment(dev1).destinationEnvironment(staging).destinationBranch('staging'));
            pipeline.persist();

            JobTemplate jobTemplate = new JobTemplate().name(SFDX_ROLLBACK).type('Custom').apiName('SFDX_Rollback_1');
            new JobStep(jobTemplate).name('Rollback Step').type('Function').persist();

            // I can't use Domain Builder here.
            copado__Promotion__c promotion = new copado__Promotion__c(
                copado__Project__c = getProjectId(),
                copado__Source_Environment__c = getEnvironmentId('Dev1'),
                copado__Source_Org_Credential__c = getCredentialId('dev1'),
                copado__Destination_Environment__c = getEnvironmentId('Staging'),
                copado__Destination_Org_Credential__c = getCredentialId('staging')
            );
            insert promotion;
            createFile(promotion.Id);
        }
    }

    private static copado__Promotion__c getPromotion() {
        return [
            SELECT
                Id,
                Name,
                copado__Project__c,
                copado__Source_Environment__c,
                copado__Source_Org_Credential__c,
                copado__Destination_Environment__c,
                copado__Destination_Org_Credential__c,
                copado__Is_Rolled_Back__c,
                Rolled_Back_Date__c,
                Rollback_Status__c
            FROM copado__Promotion__c
            LIMIT 1
        ][0];
    }

    private static Id getProjectId() {
        return [SELECT Id FROM copado__Project__c LIMIT 1][0].Id;
    }

    private static Id getCredentialId(String name) {
        return [SELECT Id FROM copado__Org__c WHERE Name = :name LIMIT 1][0].Id;
    }

    private static Id getEnvironmentId(String name) {
        return [SELECT Id FROM copado__Environment__c WHERE Name = :name LIMIT 1][0].Id;
    }

    private static Id getTemplateId(String name) {
        return [SELECT Id FROM copado__JobTemplate__c WHERE Name = :name LIMIT 1][0].Id;
    }

    private static copado__Deployment_Flow_Step__c getPipelineConnection() {
        return [SELECT Id, copado__Destination_Branch__c FROM copado__Deployment_Flow_Step__c LIMIT 1][0];
    }

    private static Id getFileId(Id promotionId) {
        return new ContentDocumentLinksSelector().byLinkedEntityIdAndTitles(new Set<Id>{ promotionId }, new Set<String>{ COPADO_ROLLBACK_CHANGES })[0]
            .ContentDocumentId;
    }

    private static void createFile(Id promotionId) {
        String base64Content = EncodingUtil.Base64Encode(Blob.valueOf('Testing File'));
        Blob blobContent = EncodingUtil.base64Decode(base64Content);
        ContentVersion contentVersion = new ContentVersion(
            Title = COPADO_ROLLBACK_CHANGES,
            PathOnClient = COPADO_ROLLBACK_CHANGES + '.json',
            VersionData = blobContent
        );
        insert contentVersion;
        contentVersion = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = :contentVersion.Id
        ];
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink(
            ContentDocumentId = contentVersion.ContentDocumentId,
            LinkedEntityId = promotionId,
            Visibility = 'AllUsers'
        );
        insert contentDocumentLink;
    }
}