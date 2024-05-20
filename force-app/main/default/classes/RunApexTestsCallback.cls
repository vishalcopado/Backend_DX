@SuppressWarnings('PMD.AvoidGlobalModifier')global with sharing class RunApexTestsCallback implements copado.MCCallback {
    @SuppressWarnings('PMD.EmptyStatementBlock')
    global void execute(copado__Function__c function, copado__Result__c result, String status) {
        /*
        ======================================================================
        NOTE: The logic in this apex class is deprecated because of US-0032169. 
        We can't remove this apex class as this is already packaged hence commenting its logic. 
        
        Old logic : This apex class was created for US-0031746 for updating the user story apex test coverage fields via a callback in the "SFDX Run Apex Tests" function. 
        It was enqueuing the apex class UpdateTestsInfoOnStories for doing that calculation asynchronously.
        
        New logic : The calculation of apex test coverage is now calculated synchronously with the help of apex class EvaluateApexTestsCriteria which call UpdateTestsInfoOnStories.
        ======================================================================
        */
    }
}