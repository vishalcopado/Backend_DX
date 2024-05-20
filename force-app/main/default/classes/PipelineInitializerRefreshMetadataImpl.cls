public inherited sharing class PipelineInitializerRefreshMetadataImpl {

    private copado__Deployment_Flow__c pipeline;
    private Boolean isDiffAnalysisNeeded = false;
    private Set<Id> environmentIds = new Set<Id>();
    private Set<Id> credentialIds = new Set<Id>();

    @TestVisible
    private static final String METADATA_FILE_NAME = 'MetaData';

    // CONSTRUCTOR

    public PipelineInitializerRefreshMetadataImpl(PipelineInitializer.RefreshMetadataRequest request) {
        List<copado__Deployment_Flow__c> pipelines = new PipelinesSelector().byId(new Set<Id>{ request.pipelineId });
        if (pipelines.isEmpty()) {
            throw new ApplicationException(Label.NoPipelineFound);
        }

        this.pipeline = pipelines[0];
        this.isDiffAnalysisNeeded = request.isDiffAnalysisNeeded;

        setEnvironmentsIds(request.pipelineId, pipelines[0].copado__Main_Branch__c);
        setCredentialIds();
    }

    // PUBLIC STATIC

    public static void execute(PipelineInitializer.RefreshMetadataRequest request) {
        if(request.pipelineId == null) {
            throw new ApplicationException(String.format(Label.MissingRequiredParameters, new List<String> {'Pipeline Id'}));
        }

        new PipelineInitializerRefreshMetadataImpl(request).execute();
    }

    // PUBLIC

    public void execute() {
        if (pipeline.copado__Platform__c != 'SFDX') {
            throw new ApplicationException(Label.PipelineUnavailableForInitializationMessage);
        }

        refreshMetadataCallout();
    }

    // PRIVATE

    private void setEnvironmentsIds(Id pipelineId, String mainBranch) {
        PipelineDescriptor pipelineDescriptor = new PipelineDescriptor(pipelineId, mainBranch);

        List<copado__Deployment_Flow_Step__c> pipelineConnections = pipelineDescriptor.getOrderedPipelineConnections();
        Map<Id, Id> destinationEnvironmentsBySourceEnvironments = pipelineDescriptor.getDestinationEnvironmentsByIntermediateEnvironments(pipelineConnections);

        if (destinationEnvironmentsBySourceEnvironments.isEmpty()) {
            throw new ApplicationException(Label.NoEnvironmentsForDifferenceAnalysis);
        }

        this.environmentIds.addAll(destinationEnvironmentsBySourceEnvironments.keySet());
        this.environmentIds.addAll(destinationEnvironmentsBySourceEnvironments.values());
    }

    private void setCredentialIds() {
        Map<Id, copado__Org__c> credentialByEnvironment = getCredentialByEnvironment();
        List<copado__Org__c> credentials = credentialByEnvironment.values();
            for (copado__Org__c credential : credentials) {
                credentialIds.add(credential.Id);
            }

        if (credentialIds.isEmpty()) {
            throw new ApplicationException(Label.ValidCredentialNotFound);
        }
    }

    private Map<Id, copado__Org__c> getCredentialByEnvironment() {
        Map<Id, copado__Org__c> result = new Map<Id, copado__Org__c>();

        for (copado__Environment__c environment : [
            SELECT
                Id,
                (
                    SELECT Id, copado__Default_Credential__c, OwnerId, copado__Environment__r.copado__Platform__c
                    FROM copado__Org_Credentials__r
                    WHERE OwnerId = :UserInfo.getUserId() OR copado__Default_Credential__c = TRUE
                )
            FROM copado__Environment__c
            WHERE Id IN :environmentIds
            WITH USER_MODE
        ]) {
            result.put(environment.Id, userCredential(environment.copado__Org_Credentials__r));
        }

        return result;
    }

    private copado__Org__c userCredential(List<copado__Org__c> orgs) {
        copado__Org__c result;

    for (copado__Org__c org : orgs) {
        if (org.OwnerId == UserInfo.getUserId()) {
            result = org;
            break;
        } else if (org.copado__Default_Credential__c == true) {
            result = org;
        }
    }

        return result;
    }

    private void refreshMetadataCallout() {
        // NOTE - TODO - Check for each credential if the file is retrieved in under 6 mins then skip the credential
        Datetime inputDate = DateTime.now();
        refreshOrgMetadataCache(credentialIds);
        String nextFireCron = calculateNextFireCron();
        Id pipelineId = isDiffAnalysisNeeded ? pipeline.Id : null;
        System.schedule(
            'Poll for Refresh Metadata ' + nextFireCron,
            nextFireCron,
            new PollPipelineInitializerRefreshMetadata(credentialIds, 0, pipelineId, inputDate)
        );
    }

    private static void refreshOrgMetadataCache(Set<Id> credentialIds) {
        if (!Test.isRunningTest()) {
            for (Id credentialId : credentialIds) {
                copado.RefreshOrgMetadataCache.InvocableVariables invocableVariable = new copado.RefreshOrgMetadataCache.InvocableVariables();
                invocableVariable.orgId = credentialId;
                invocableVariable.isMetadataSavedToFile = true;
                invocableVariable.queryParameters = new Set<String>{ 'dates=format' };
                copado.RefreshOrgMetadataCache.executeRefresh(invocableVariable);
            }
        }
    }

    private static String calculateNextFireCron() {
        CronCalculator result = new CronCalculator();
        return result.nextFireCron(3);
    }
}