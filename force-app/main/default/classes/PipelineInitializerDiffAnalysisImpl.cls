public inherited sharing class PipelineInitializerDiffAnalysisImpl {

    private copado__Deployment_Flow__c pipeline;
    private Map<Id, Id> versionIdByEnvironmentId = new Map<Id, Id>();
    private Map<Id, Id> destinationEnvironmentsBySourceEnvironments = new Map<Id, Id>();

    // CONSTRUCTOR

    public PipelineInitializerDiffAnalysisImpl(Id pipelineId) {
        List<copado__Deployment_Flow__c> pipelines = new PipelinesSelector().byId(new Set<Id>{ pipelineId });
        if (pipelines.isEmpty()) {
            throw new ApplicationException(Label.NoPipelineFound);
        }

        this.pipeline = pipelines[0];

        PipelineDescriptor pipelineDescriptor = new PipelineDescriptor(pipeline.Id, pipelines[0].copado__Main_Branch__c);

        List<copado__Deployment_Flow_Step__c> pipelineConnections = pipelineDescriptor.getOrderedPipelineConnections();
        destinationEnvironmentsBySourceEnvironments = pipelineDescriptor.getDestinationEnvironmentsByIntermediateEnvironments(pipelineConnections);

        if (destinationEnvironmentsBySourceEnvironments.isEmpty()) {
            throw new ApplicationException(Label.NoEnvironmentsForDifferenceAnalysis);
        }

        versionIdByEnvironmentId = getContentVersionIdByEnvironmentId(allEnvironmentIds());
    }

    // PUBLIC STATIC

    public static void execute(Id pipelineId) {
        if(pipelineId == null) {
            throw new ApplicationException(String.format(Label.MissingRequiredParameters, new List<String> {'Pipeline Id'}));
        }

        new PipelineInitializerDiffAnalysisImpl(pipelineId).execute();
    }

    // PUBLIC

    public void execute() {
        if (pipeline.copado__Platform__c != 'SFDX') {
            throw new ApplicationException(Label.PipelineUnavailableForInitializationMessage);
        }

        new DifferenceAnalysisForEnvironmentsImpl(asRequests()).execute();
    }


    // PRIVATE

    private Set<Id> allEnvironmentIds() {
        Set<Id> result = new Set<Id>();

        result.addAll(destinationEnvironmentsBySourceEnvironments.keySet());
        result.addAll(destinationEnvironmentsBySourceEnvironments.values());

        return result;
    }

    private List<DifferenceAnalysisForEnvironmentsImpl.Request> asRequests() {
        List<DifferenceAnalysisForEnvironmentsImpl.Request> result = new List<DifferenceAnalysisForEnvironmentsImpl.Request>();

        for (Id sourceId : destinationEnvironmentsBySourceEnvironments.keySet()) {
            DifferenceAnalysisForEnvironmentsImpl.Request request = new DifferenceAnalysisForEnvironmentsImpl.Request();
            request.pipeline = pipeline;
            request.sourceId = sourceId;
            request.destinationId = destinationEnvironmentsBySourceEnvironments.get(sourceId);
            request.sourceMetaFileId = versionIdByEnvironmentId.get(sourceId);
            request.destinationMetaFileId = versionIdByEnvironmentId.get(request.destinationId);
            result.add(request);
        }

        return result;
    }


    private Map<Id, Id> getContentVersionIdByEnvironmentId(Set<Id> environmentIds) {
        Map<Id, Id> result = new Map<Id, Id>();
        Map<Id, Id> credentialIdByEnvironment = getCredentialIdByEnvironment(environmentIds);
        Map<Id, Id> contentVersionByOrgId = contentVersionByOrgId(credentialIdByEnvironment.values());

        for(Id environmentId : credentialIdByEnvironment.keySet()) {
            Id orgId = credentialIdByEnvironment.get(environmentId);
            result.put(environmentId, contentVersionByOrgId.get(orgId));
        }


        return result;
    }


    private Map<Id, Id> contentVersionByOrgId(List<Id> orgIds) {
        Map<Id, Id> result = new Map<Id, Id>();
        List<copado__Org__c> orgCredentials = [SELECT Id, copado__Environment__c, copado__Default_Credential__c, OwnerId,
                                                (SELECT ContentDocument.LatestPublishedVersionId
                                                    FROM ContentDocumentLinks
                                                    WHERE ContentDocument.Title = 'MetaData'
                                                    ORDER BY ContentDocument.CreatedDate Desc LIMIT 1)
                                                FROM copado__Org__c
                                                WHERE Id IN :orgIds
                                                WITH USER_MODE];

        for(copado__Org__c orgCred : orgCredentials) {
            if(orgCred.ContentDocumentLinks != null && !orgCred.ContentDocumentLinks.isEmpty()) {
                ContentDocumentLink contentDocumentLink = orgCred.ContentDocumentLinks[0];
                result.put(orgCred.Id, contentDocumentLink.ContentDocument.LatestPublishedVersionId);
            }
        }

        return result;
    }


    private Map<Id, Id> getCredentialIdByEnvironment(Set<Id> environmentIds) {
        Map<Id, Id> result = new Map<Id, Id>();

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
            result.put(environment.Id, userCredentialId(environment.copado__Org_Credentials__r));
        }

        return result;
    }


    private Id userCredentialId(List<copado__Org__c> orgs) {
        copado__Org__c result;

        for (copado__Org__c org : orgs) {
            if (org.OwnerId == UserInfo.getUserId()) {
                result = org;
                break;
            } else if (org.copado__Default_Credential__c == true) {
                result = org;
            }
        }

        return result?.Id;
    }
}