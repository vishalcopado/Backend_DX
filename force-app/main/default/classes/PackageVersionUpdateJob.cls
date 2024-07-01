public with sharing class PackageVersionUpdateJob {
    private String jobTemplate;
    private Version version;

    // CTOR

    public PackageVersionUpdateJob(Version version, String jobTemplate) {
        this.version = version;
        this.jobTemplate = jobTemplate;
    }

    // PUBLIC

    public copado__JobExecution__c execute() {
        copado.CreateExecution.Request request = createJobRequest();
        copado__JobExecution__c job = startJob(request);
        stampJobId(job.Id);

        return job;
    }

    // PRIVATE

    private copado.CreateExecution.Request createJobRequest() {
        copado.CreateExecution.Request request = new copado.CreateExecution.Request();

        request.templateName = jobTemplate;
        request.destinationId = version.packageVersion.copado__Artifact__r.copado__Target_Dev_Hub_Org__r.copado__Environment__c;
        request.dataJson = JSON.serialize(version);
        request.runAfterInstantiation = true;
        request.pipelineId = version.packageVersion.copado__Artifact__r.copado__Pipeline__c;

        return request;
    }

    private copado__JobExecution__c startJob(copado.CreateExecution.Request request) {
        return copado.CreateExecution.execute(new List<copado.CreateExecution.Request>{ request }).get(0);
    }

    private void stampJobId(Id jobId) {
        copado__Artifact_Version__c packageVersion = new copado__Artifact_Version__c(
            Id = version.packageVersion.Id,
            copado__LastJobExecutionId__c = jobId
        );
        update Security.stripInaccessible(AccessType.UPDATABLE, new List<SObject>{ packageVersion }).getRecords();
    }

    // INNER

    public class Version {
        public copado__Artifact_Version__c packageVersion;
        public String installationKey;
        public String apiVersion;
    }
}