@IsTest
private class CommitChangesTest {

    private final static String APEX_CLASS = 'ApexClass';
    private final static String APEX_TRIGGER = 'ApexTrigger';
    private final static String ADD = 'Add';

    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    private static void byTypeAndOperation() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP

            CommitChanges commitChanges = new CommitChanges(getContentVersionId(), getUserStoryId());

            // EXERCISE

            List<CommitChanges.Change> result = commitChanges.byTypeAndOperation(new Set<String>{ APEX_CLASS } , new Set<String>{ ADD } );

            // VERIFY

            for(CommitChanges.Change change :  result ) {
                Assert.areEqual('ApexClass', change.t, 'The type of the change should be ApexClass');
                Assert.areEqual('Add', change.a, 'The action of the change should be Add');
            }
        }
    }

    @IsTest
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    private static void toUserStoryMetadata() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            Id userStoryId = getUserStoryId();
            CommitChanges commitChanges = new CommitChanges(getContentVersionId(), getUserStoryId());

            // EXERCISE

            List<copado__User_Story_Metadata__c> result = commitChanges.toUserStoryMetadata(getCommitChangesWithAddApexClassOnly());

            // VERIFY

            Assert.areEqual(result[0].copado__Action__c, 'Add', 'copado__Action__c should be set correctly');
            Assert.areEqual(result[0].copado__Category__c, '', 'copado__Category__c should be set correctly');
            Assert.areEqual(result[0].copado__ModuleDirectory__c, 'File path is handled automatically', 'copado__ModuleDirectory__c should be set correctly');
            Assert.areEqual(result[0].copado__Type__c, 'ApexClass', 'copado__Type__c should be set correctly');
            Assert.areEqual(result[0].copado__User_Story__c, userStoryId , 'copado__User_Story__c should be set correctly');
            Assert.areEqual(result[0].copado__Metadata_API_Name__c, 'SampleClass1', 'copado__Action__c should be set correctly');
            Assert.areEqual(result[0].Name, 'ApexClass.SampleClass1', 'copado__Action__c should be set correctly');

        }
    }

    private static void createData() {
        Credential credential = new Credential(new Environment().type('Production/Developer')).type('Production/Developer');
        new UserStory().title('US 1').status('Draft').credential(credential);
        
        new ContentVersion_t()
            .title('Copado Commit changes')
            .pathOnClient('Copado Commit changes.json')
            .versionData(Blob.valueOf(getCommitChanges())).persist();
    }

    private static String getCommitChanges() {
        List<CommitChanges.Change> changeList = new List<CommitChanges.Change>();
        changeList.add(getCommitChange('ApexClass', 'SampleClass1', 'File path is handled automatically', '', 'Add'));
        changeList.add(getCommitChange('ApexTrigger', 'SampleTrigger1', 'File path is handled automatically', '', 'Add'));
        changeList.add(getCommitChange('ApexClass', 'SampleClass2', 'File path is handled automatically', '', 'Delete'));
        changeList.add(getCommitChange('ApexTrigger', 'SampleTrigger2', 'File path is handled automatically', '', 'Delete'));
        changeList.add(getCommitChange('CustomObject', 'Test__c', 'File path is handled automatically', '', 'Add'));
        return JSON.serialize(changeList);
    }

    private static List<CommitChanges.Change> getCommitChangesWithAddApexClassOnly() {
        List<CommitChanges.Change> changeList = new List<CommitChanges.Change>();
        changeList.add(getCommitChange('ApexClass', 'SampleClass1', 'File path is handled automatically', '', 'Add'));
        return changeList;
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static CommitChanges.Change getCommitChange(String type, String name, String module, String category, String action) {
        return new CommitChanges.Change(type, name, module, category, action);
    }

    private static Id getContentVersionId() {
        return [ SELECT Id FROM ContentVersion LIMIT 1].Id;
    }

    private static Id getUserStoryId() {
        return [ SELECT Id FROM copado__User_Story__c LIMIT 1].Id;
    }
}