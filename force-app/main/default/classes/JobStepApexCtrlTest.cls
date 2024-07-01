@IsTest
private with sharing class JobStepApexCtrlTest {
    @TestSetup
    private static void setup() {
        copado__Function__c function = new copado__Function__c();
        function.Name = 'SFDX Execute Apex';
        function.copado__API_Name__c = 'sfdx_execute_apex';
        function.copado__Parameters__c = '[{"required" : true, "name" : "username", "defaultValue" : "{$Context.Credential.SessionId}"}, {"required" : true, "name" : "instance_url", "defaultValue" : "{$Context.Credential.Endpoint}"}, {"required" : false, "name" : "script"}]';
        insert function;
    }

    @IsTest
    private static void getFunction() {
        // Exercise
        Test.startTest();
        copado__Function__c function = JobStepApexCtrl.getFunctionByApiName('sfdx_execute_apex');
        Test.stopTest();

        // Verify
        System.assertNotEquals(null, function, 'Function should be located by Api name');
    }
}