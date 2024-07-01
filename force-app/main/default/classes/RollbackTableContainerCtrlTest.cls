@IsTest
private class RollbackTableContainerCtrlTest {
    private static final String COPADO_ROLLBACK_CHANGES = 'Copado Rollback changes';

    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void updateFileSuccess() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            Id promotionId = getPromotionId();
            Id contentId = createFile(promotionId);
            List<TestUtilities.RollbackChanges> items = (List<TestUtilities.RollbackChanges>) JSON.deserialize(
                getContent(),
                List<TestUtilities.RollbackChanges>.class
            );

            for (TestUtilities.RollbackChanges item : items) {
                if (item.n == 'ctx_AccountAutomations1') {
                    item.s = false;
                }
            }
            String currentSelections = JSON.serialize(items);

            // EXERCISE
            RollbackTableContainerCtrl.updateRollbackFile(currentSelections, promotionId, COPADO_ROLLBACK_CHANGES);

            // VALIDATE
            List<ContentVersion> contentVersions = [
                SELECT Id, PathOnClient, ContentLocation, Title, VersionData, ContentDocumentId
                FROM ContentVersion
                WHERE isLatest = TRUE
            ];
            ContentVersion latestVersion = contentVersions[0];

            Assert.areEqual(1, contentVersions.size(), 'There is one content version.');
            Assert.areEqual('S', latestVersion.ContentLocation, 'The content location matches.');
            Assert.areEqual('Copado Rollback changes.json', latestVersion.PathOnClient, 'The PathOnClient matches.');
            Assert.areEqual('Copado Rollback changes', latestVersion.Title, 'The title of the file matches.');
            Assert.areEqual(currentSelections, latestVersion.VersionData.toString(), 'The content is updated to match the provided body');
            Assert.areEqual(contentId, latestVersion.ContentDocumentId, 'The content Id of the file matches with the previous version');
        }
    }

    @IsTest
    private static void updateFileWhenFileDoesnotExist() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            String exceptionMessage;
            Id promotionId = getPromotionId();
            List<TestUtilities.RollbackChanges> items = (List<TestUtilities.RollbackChanges>) JSON.deserialize(
                getContent(),
                List<TestUtilities.RollbackChanges>.class
            );

            for (TestUtilities.RollbackChanges item : items) {
                if (item.n == 'ctx_AccountAutomations1') {
                    item.s = false;
                }
            }
            String currentSelections = JSON.serialize(items);

            // EXERCISE
            try {
                RollbackTableContainerCtrl.updateRollbackFile(currentSelections, promotionId, COPADO_ROLLBACK_CHANGES);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            // VALIDATE
            List<ContentVersion> contentVersions = [
                SELECT Id, PathOnClient, ContentLocation, Title, VersionData, ContentDocumentId
                FROM ContentVersion
                WHERE isLatest = TRUE
            ];

            Assert.areEqual(0, contentVersions.size(), 'There are no files created.');
            Assert.areEqual('Script-thrown exception', exceptionMessage, 'The exception messages match.');
        }
    }

    @IsTest
    private static void updateWithEmptyFile() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            String exceptionMessage;
            Id promotionId = getPromotionId();
            String currentSelections = '';

            // EXERCISE
            try {
                RollbackTableContainerCtrl.updateRollbackFile(currentSelections, promotionId, COPADO_ROLLBACK_CHANGES);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            // VALIDATE
            List<ContentVersion> contentVersions = [
                SELECT Id, PathOnClient, ContentLocation, Title, VersionData, ContentDocumentId
                FROM ContentVersion
                WHERE isLatest = TRUE
            ];

            Assert.areEqual(0, contentVersions.size(), 'There are no files created.');
            Assert.areEqual('Script-thrown exception', exceptionMessage, 'The exception messages match.');
        }
    }

    @IsTest
    private static void updateFileWithAsciiCharacters() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            Id promotionId = getPromotionId();
            Id contentId = createFile(promotionId);
            List<TestUtilities.RollbackChanges> items = (List<TestUtilities.RollbackChanges>) JSON.deserialize(
                getContent(),
                List<TestUtilities.RollbackChanges>.class
            );

            for (TestUtilities.RollbackChanges item : items) {
                if (item.n == 'Account.July13αβγ__c') {
                    item.s = false;
                }
            }
            String currentSelections = JSON.serialize(items);
            // EXERCISE
            RollbackTableContainerCtrl.updateRollbackFile(currentSelections, promotionId, COPADO_ROLLBACK_CHANGES);

            // VALIDATE
            List<ContentVersion> contentVersions = [
                SELECT Id, PathOnClient, ContentLocation, Title, VersionData, ContentDocumentId
                FROM ContentVersion
                WHERE isLatest = TRUE
            ];
            ContentVersion latestVersion = contentVersions[0];

            Assert.areEqual(1, contentVersions.size(), 'There is one content version.');
            Assert.areEqual('S', latestVersion.ContentLocation, 'The content location matches.');
            Assert.areEqual('Copado Rollback changes.json', latestVersion.PathOnClient, 'The PathOnClient matches.');
            Assert.areEqual('Copado Rollback changes', latestVersion.Title, 'The title of the file matches.');
            Assert.areEqual(currentSelections, latestVersion.VersionData.toString(), 'The content is updated to match the provided body');
            Assert.areEqual(contentId, latestVersion.ContentDocumentId, 'The content Id of the file matches with the previous version');
        }
    }

    @IsTest
    private static void getRepositoryDetails() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            Id promotionId = getPromotionId();

            // EXERCISE
            RollbackTableContainerCtrl.Response response = RollbackTableContainerCtrl.getRepositoryDetails(promotionId);

            // VERIFY
            Assert.areEqual(null, response.destinationEnvironmentBranch, 'Destination branch should be null, it has been never set.');
            Assert.isNotNull(response.promotion.Id, 'Promotion record should be fetched.');
            Assert.isNotNull(response.pipeline.Id, 'Promotion associated pipeline record should be fetched.');
            Assert.isFalse(response.isMerged, 'Promotion Deployment is not completed.');
        }
    }

    // HELPER

    private static void createData() {
        Environment sourceEnv = new Environment().name('Dev').platform('SFDX').type('Production/Developer');
        Environment destinationEnv = new Environment().name('Test').platform('SFDX').type('Production/Developer');

        Credential sourceCred = new Credential(sourceEnv).type('Production/Developer');
        Credential destinationCred = new Credential(destinationEnv).type('Production/Developer');

        new Promotion(
                new Project(new Pipeline(new Repository().name('Repo 1')).platform('SFDX')),
                sourceCred,
                sourceEnv,
                destinationCred,
                destinationEnv
            )
            .persist();
    }

    private static Id createFile(Id promotionId) {
        ContentVersion content = new ContentVersion(
            Title = 'Copado Rollback changes',
            origin = 'C',
            PathOnClient = 'Copado Rollback changes.json',
            VersionData = Blob.valueOf(getContent())
        );
        insert content;

        ContentVersion contentVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :content.Id LIMIT 1];
        ContentDocumentLink link = new ContentDocumentLink(LinkedEntityId = promotionId, ContentDocumentId = contentVersion.ContentDocumentId);
        insert link;

        return link.ContentDocumentId;
    }

    private static Id getPromotionId() {
        return [SELECT Id FROM copado__Promotion__c LIMIT 1].Id;
    }

    private static String getContent() {
        List<TestUtilities.RollbackChanges> result = new List<TestUtilities.RollbackChanges>();
        TestUtilities.RollbackChanges item1 = new TestUtilities.RollbackChanges(
            'ClassWithCustomLabel',
            'Profile',
            'Unchanged',
            'SFDX',
            false,
            true,
            true
        );
        TestUtilities.RollbackChanges item2 = new TestUtilities.RollbackChanges(
            'ctx_AccountAutomations1',
            'ApexClass',
            'Update',
            'SFDX',
            false,
            true,
            false
        );
        TestUtilities.RollbackChanges item3 = new TestUtilities.RollbackChanges(
            'Account.July13αβγ__c',
            'CustomField',
            'Delete',
            'SFDX',
            false,
            true,
            false
        );

        result.add(item1);
        result.add(item2);
        result.add(item3);

        return JSON.serialize(result);
    }
}