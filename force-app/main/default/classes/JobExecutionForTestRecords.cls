@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class JobExecutionForTestRecords implements copado.JobExecutionCallback {
    @SuppressWarnings('PMD.EmptyStatementBlock')
    global void execute(copado__JobExecution__c commitJob, String status) {
        /*
        ======================================================================
        NOTE: The logic in this apex class is deprecated because of US-0038370. 
        We can't remove this apex class as this is already packaged hence commenting its logic. 
        
        It was created for US-0032151 in which we were creating a new job execution 'SFDX Test Records Creation In User Story_1' which used to create apex test record for quality gates.
        Now we have done some changes as per US-0038370, due to which this apex class is not required.
        ======================================================================
        */
    }
}