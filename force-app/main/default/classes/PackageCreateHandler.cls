public with sharing class PackageCreateHandler {
    @AuraEnabled
    public static void startCreate(Id recordId) {
        Map<String, Object> jsonInformation = getPackageInfo(recordId);
        List<Copado.PackageCreateAction.Response> response = Copado.PackageCreateAction.create(
            new List<Copado.PackageCreateAction.Request>{ new Copado.PackageCreateAction.Request(recordId, JSON.serialize(jsonInformation)) }
        );
        update Security.stripInaccessible(
                AccessType.UPDATABLE,
                new List<copado__Artifact__c>{ new copado__Artifact__c(Id = recordId, copado__LastJobExecutionId__c = response[0]?.job?.Id) }
            )
            .getRecords();
    }

    private static Map<String, Object> getPackageInfo(Id recordId) {
        copado__Artifact__c pkg = new PackagesSelector().byIds(new Set<Id>{ recordId })?.get(0);
        validatePackageInfo(pkg);
        Map<String, Object> result = new Map<String, Object>();
        result.put('apiversion', pkg?.Api_Version__c);
        result.put('packagetype', pkg?.copado__Package_Type__c);
        result.put('nonamespace', pkg?.copado__No_Namespace__c);
        result.put('namespaceprefix', pkg?.copado__Package_Namespace__c);
        result.put('orgdependent', pkg?.IsOrgDependent__c);
        result.put('devhub', pkg?.copado__Target_Dev_Hub_Org__c);

        return result;
    }

    private static void validatePackageInfo(copado__Artifact__c pkg){
   
        if (String.isBlank(pkg.copado__Target_Dev_Hub_Org__c)) {
            throw new ApplicationException(Label.Target_DevHub_Required_For_Package_Generation);
        }
        if (String.isBlank(pkg.copado__DefaultBranch__c)){
            throw new ApplicationException(Label.Branch_Required_For_Package_Generation);
        }
}
}