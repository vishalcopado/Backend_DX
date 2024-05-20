public with sharing class CommitData {
    @AuraEnabled
    public static Id execute(CommitDataPayload payload) {
        try {
            DXCommitData.Request request = createCommitDataRequest(payload);
            return new DXCommitData().create(request);
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled(cacheable=false)
    public static DataTemplateConfiguration fetchDataTemplateConfiguration(Id dataTemplateId) {
        try {
            DataTemplateConfiguration result = new DataTemplateConfiguration();
            JobStepDataDeployController.DataTemplate dataTemplate = JobStepDataDeployController.loadDataTemplateById(new List<Id>{ dataTemplateId })
                .get(dataTemplateId);
            result.filters = DataTemplateFilterController.convertQueryFilters(dataTemplate.queryFilterList);
            result.queryFilterList = dataTemplate.queryFilterList;
            result.filterLogic = dataTemplate.filterLogic;
            result.totalRelatedObjects = dataTemplate.totalRelatedObjects;
            return result;
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled
    public static Boolean validateOrgCredential(Id orgCredentialId) {
        try {
            copado.ValidateOrgAction.Request request = new copado.ValidateOrgAction.Request();
            request.orgId = orgCredentialId;
            return copado.ValidateOrgAction.execute(new List<copado.ValidateOrgAction.Request>{ request })?.get(0).isValidOrg;
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled
    public static Boolean fetchMCDDEnabledStatus(Id userStoryId) {
        try {
            Id pipelineId = new UserStoriesSelector().byIds(new Set<Id>{ userStoryId })?.get(0)?.copado__Project__r?.copado__Deployment_Flow__c;
            if (String.isBlank(pipelineId)) {
                throw new ApplicationException(Label.Pipeline_Missing);
            }
            DataDeploy.CheckConfigurationRequest request = new DataDeploy.CheckConfigurationRequest();
            request.pipelineId = pipelineId;
            return DataDeploy.DataDeployConfiguration.checkConfiguration(request)?.isMCDDEnabled;
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    private static DXCommitData.Request createCommitDataRequest(CommitDataPayload payload) {
        DXCommitData.Request request = new DXCommitData.Request();
        request.userStoryId = payload.userStoryId;
        request.sourceType = DXCommitData.Source.ENVIRONMENT;
        request.dataTemplateId = payload.dataTemplateId;
        request.dataSetId = payload.dataSetId;
        request.commitMessage = payload.commitMessage;
        request.filters = payload.filters;
        request.filterLogic = payload.filterLogic;
        return request;
    }

    public class DataTemplateConfiguration {
        @AuraEnabled
        public List<DataFilter> filters;
        @AuraEnabled
        public List<QueryEditor.CriteriaWrapper> queryFilterList;
        @AuraEnabled
        public String filterLogic;
        @AuraEnabled
        public Integer totalRelatedObjects;
    }
}