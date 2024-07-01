public with sharing class DeployPackages {
    private copado__Artifact_Version__c pkgVersion;
    private List<Id> credentialIds;
    private Id deploymentJobId;
    private String installSecurityType;
    public static final String DISTRIBUTE_ACTION = 'PackageDistribution';

    // CONSTRUCTOR

    @SuppressWarnings('PMD.ExcessiveParameterList')
    public DeployPackages(Id pkgVersionId, List<Id> credentialIds, String installSecurityType, Id jobId) {
        this(pkgVersionId, credentialIds, installSecurityType);
        this.deploymentJobId = jobId;
    }

    public DeployPackages(Id pkgVersionId, List<Id> credentialIds, String installSecurityType) {
        this.pkgVersion = new PackageVersionsSelector().byIds(new Set<Id>{ pkgVersionId }).get(0);
        this.credentialIds = credentialIds;
        this.installSecurityType = installSecurityType;
    }

    // PUBLIC

    public List<copado__JobExecution__c> execute() {
        try {
            List<copado__JobExecution__c> jobExecutions = new List<copado__JobExecution__c>();

            for (copado__Org__c credential : new CredentialsSelector().byIds(credentialIds)) {
                copado.Jobs.ExecutionCreateFromTemplateRequest executionRequest = createExecutionRequest(credential.copado__Environment__c);
                copado__JobExecution__c execution = copado.Jobs.Execution.createFromTemplate(executionRequest).jobExecution;
                copado.Jobs.Execution.execute( new copado.Jobs.ExecutionRequest (execution.Id));
                jobExecutions.add(execution);
            }

            return new JobExecutionsSelector().byIds( (new Map<Id,copado__JobExecution__c>(jobExecutions)).keySet());

        } catch (Exception ex) {
            throw new ApplicationException().auraHandled(ex);
        }
    }

    // PRIVATE

    private copado.Jobs.ExecutionCreateFromTemplateRequest createExecutionRequest(Id environmentId) {
        copado.Jobs.ExecutionCreateFromTemplateRequest request = new copado.Jobs.ExecutionCreateFromTemplateRequest();
        Id pipelineId = pkgVersion.copado__Artifact__r.copado__Pipeline__c;

        request.templateAPIName = new ActionTemplate(DISTRIBUTE_ACTION, pipelineId, environmentId).getApiName();
        request.destinationId = environmentId;
        request.sourceId = pkgVersion.copado__Artifact__r.copado__Target_Dev_Hub_Org__r.copado__Environment__c;
        request.dataJson = new PackageVersion(pkgVersion.copado__Subscriber_Version_Id__c, deploymentJobId, getApiVersion(pkgVersion), installSecurityType).stringify();
        request.pipelineId = pipelineId;
        request.callback = DeploymentJobUpdate.class.getName();

        return request;
    }

    private String getApiVersion(copado__Artifact_Version__c version) {
        return String.isNotBlank(version.Api_Version__c) ? version.Api_Version__c : version.copado__Artifact__r.Api_Version__c;
    }

    // INNER

    public class PackageVersion {
        public String subscriberId;
        public String installationKey;
        public Id deploymentJobId;
        public String apiVersion;
        public String installSecurityType;

        @SuppressWarnings('PMD.ExcessiveParameterList')
        public PackageVersion(String subscriberId, Id jobId, String apiVersion, String installSecurityType) {
            List<PackageVersionInstallationKey__c> versionKey = new PackageVersionInstallationKeySelector()
                .byPackageVersionId(new Set<Id>{ subscriberId });

            this.subscriberId = subscriberId;
            this.installationKey = versionKey.isEmpty() ? null : versionKey[0].InstallationKey__c;
            this.deploymentJobId = jobId;
            this.apiVersion = apiVersion;
            this.installSecurityType = installSecurityType;
        }

        public String stringify() {
            return JSON.serialize(this);
        }
    }
}