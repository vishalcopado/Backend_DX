public with sharing class JobStepDataSet {

    @AuraEnabled(cacheable=true)
    public static Map<Id, DataSet> loadRelatedDataSets() {
        try {
            Map<Id, DataSet> dataSetsByIds = getDataSets();
            return dataSetsByIds;
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getCurrentEnvironmentId() {
        try {
            String sfdcOrgId = UserInfo.getOrganizationId() + '_' + UserInfo.getUserId();
            List<copado__Org__c> orgs = new CredentialsSelector().bySFDCOrgId(new Set<String> {sfdcOrgId});
            if (orgs.isEmpty()) {
                throw new ApplicationException(Label.Error_Validate_Current_Org_Credential);
            }
            return (String) orgs[0].copado__Environment__c;
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    // PRIVATE

    private static Map<Id, DataSet> getDataSets() {
        Map<Id, DataSet> result = new Map<Id, DataSet>();
        List<copado__Data_Set__c> dataSets = new DataSetsSelector().byEnabled();

        for (copado__Data_Set__c dataSet : dataSets) {
            result.put(
                dataSet.Id,
                new DataSet(dataSet.Id, dataSet.Name)
            );
        }
        return result;
    }

    // INNER

    public class DataSet {
        @AuraEnabled
        public Id dataSetId;
        @AuraEnabled
        public String name;

        public DataSet(Id dataSetId, String name) {
            this.dataSetId = dataSetId;
            this.name = name;
        }
    }
}