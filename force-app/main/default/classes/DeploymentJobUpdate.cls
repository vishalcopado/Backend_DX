@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class DeploymentJobUpdate implements copado.JobExecutionCallback {
    // CTOR

    // Note: needed for JobExecutionCallback instantiation
    @SuppressWarnings('PMD.EmptyStatementBlock')
    global DeploymentJobUpdate() {
    }

    // Job Callback, called only after the job finishes
    global void execute(copado__JobExecution__c job, String status) {
        try {
            copado__JobExecution__c jobExecution = new JobExecutionsSelector().byIds(new Set<Id>{ job.Id })[0];
            DeployPackages.PackageVersion version = (DeployPackages.PackageVersion) JSON.deserialize(
                jobExecution.copado__DataJson__c,
                DeployPackages.PackageVersion.class
            );

            if (String.isNotBlank(version.deploymentJobId)) {
                String newStatus = getDeploymentJobStatus(status);
                updateDeploymentJob(version.deploymentJobId, newStatus, job.Id);
            }
        } catch (Exception ex) {
            throw new ApplicationException(ex.getMessage() + ' ' + ex.getStackTraceString());
        }
    }

    // PRIVATE

    private String getDeploymentJobStatus(String jobStatus) {
        Map<String, String> executionToDeploymentJobStatus = new Map<String, String>{
            'Not Started' => 'Pending',
            'In Progress' => 'In progress',
            'Successful' => 'Success',
            'Error' => 'Failed'
        };
        String deploymentJobStatus = executionToDeploymentJobStatus.get(jobStatus);
        return String.isBlank(deploymentJobStatus) ? jobStatus : deploymentJobStatus;
    }

    private void updateDeploymentJob(Id deploymentJobId, String status, Id jobExecutionId) {
        copado__Deployment_Job__c deploymentJob = new DeploymentJobSelector().byIds(new Set<Id>{ deploymentJobId })[0];

        // Here while updating a deployment job status, a web service callout from managed package and we would require a global method with setMock in managed package.
        // For ref: https://blog.moothien.me/2018/12/mock-http-callouts-in-managed-package.html?m=1
        deploymentJob.copado__Status__c = Test.isRunningTest() ? deploymentJob.copado__Status__c : status;

        copado__Result__c result = new copado__Result__c(Id = deploymentJob.copado__Last_Result__c, copado__Result_Data__c = 'Check job execution Id: ' + jobExecutionId, copado__Status__c = status);

        update Security.stripInaccessible(AccessType.UPDATABLE, new List<SObject>{ deploymentJob, result }).getRecords();
    }
}