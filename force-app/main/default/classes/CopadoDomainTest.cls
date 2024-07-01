@IsTest
private class CopadoDomainTest {

    @TestSetup
    private static void setUp() {
        TestUtilities.setup();
    }

    @IsTest
    private static void promotion() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // Exercise
            Environment sourceEnv = new Environment();
            Environment destinationEnv = new Environment();
            Credential sourceCred = new Credential(sourceEnv);
            Credential destinationCred = new Credential(destinationEnv);
            new Promotion(
                new Project(new Pipeline(new Repository().name('Repo 1')).platform('SFDX')).add(new Release()),
                sourceCred,
                sourceEnv,
                destinationCred,
                destinationEnv
            ).persist();
            
            // Verify
            Assert.areEqual(2, [SELECT Count() FROM copado__Environment__c], 'The count does not match.');
            Assert.areEqual(1, [SELECT Count() FROM copado__Deployment_Flow__c], 'The count does not match.');
            Assert.areEqual(1, [SELECT Count() FROM copado__Git_Repository__c], 'The count does not match.');
            Assert.areEqual(1, [SELECT Count() FROM copado__Deployment_Flow_Step__c], 'The count does not match.');
            Assert.areEqual(1, [SELECT Count() FROM copado__Project__c], 'The count does not match.');
            Assert.areEqual(1, [SELECT Count() FROM copado__Release__c], 'The count does not match.');
            Assert.areEqual(1, [SELECT Count() FROM copado__Promotion__c], 'The count does not match.');
        }
    }
}