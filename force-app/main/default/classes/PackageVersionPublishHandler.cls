public with sharing class PackageVersionPublishHandler {
    @AuraEnabled
    public static void startPublish(Id recordId) {
        List<Copado.PackageVersionPublishAction.Response> response = Copado.PackageVersionPublishAction.publish(
            new List<Copado.PackageVersionPublishAction.Request>{ new Copado.PackageVersionPublishAction.Request(recordId) }
        );

        update Security.stripInaccessible(
                AccessType.UPDATABLE,
                new List<copado__Artifact_Version__c>{
                    new copado__Artifact_Version__c(Id = recordId, copado__LastJobExecutionId__c = response[0]?.job?.Id)
                }
            )
            .getRecords();
    }

    @AuraEnabled
    public static void validatepackageVersionInfo(String recordId) {
        copado__Artifact_Version__c version = getVersion(recordId);
        if (String.isBlank(version.copado__Subscriber_Version_Id__c)) {
            throw new ApplicationException(Label.Package_Version_Publish_Error);
        }
    }
    private static copado__Artifact_Version__c getVersion(Id recordId) {
        return new PackageVersionsSelector().byIds(new Set<Id>{ recordId }).get(0);
    }
}