@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class HasVlocityChanges implements copado.ParameterExpressionCallable {
    private static final String VLOCITY = 'Vlocity';
    // GLOBAL

    global String execute(Id contextId) {
        String result = 'false';
        try {
            Id fileChangesId = getFileChangesId(contextId);
            if (fileChangesId != null) {
                String data = getContentVersion(fileChangesId);

                if (!String.isBlank(data)) {
                    result = String.valueOf(vlocityChangesExist(data));
                }
            }
            return result;
        } catch (Exception ex) {
            throw new ApplicationException(ex.getMessage() + ' ' + ex.getStackTraceString());
        }
    }

    // PRIVATE

    private Id getFileChangesId(Id jobStepId) {
        Id result;

        List<copado__JobStep__c> jobStep = new JobStepsSelector().byIds(new Set<Id>{ jobStepId });
        String dataJson = jobStep[0].copado__JobExecution__r.copado__DataJson__c;

        Map<String, Object> parsedDataJson = (Map<String, Object>) JSON.deserializeUntyped(dataJson);

        if (parsedDataJson?.containsKey('fileWithSelectedChanges') && !String.isBlank(parsedDataJson.get('fileWithSelectedChanges').toString())) {
            result = (Id) parsedDataJson.get('fileWithSelectedChanges');
        }
        return result;
    }

    private static String getContentVersion(Id contentVersionId) {
        String result = '';
        List<ContentVersion> contentVersions = new ContentVersionsSelector().byIds(new Set<Id>{ contentVersionId });

        if (contentVersions.size() != 0) {
            result = contentVersions[0]?.VersionData?.toString();
        }
        return result;
    }

    private static Boolean vlocityChangesExist(String data) {
        Boolean result = false;

        List<VersionDataWrapper> versions = (List<VersionDataWrapper>) JSON.deserialize(data, List<VersionDataWrapper>.class);
        for (VersionDataWrapper version : versions) {
            if (version.c == VLOCITY) {
                result = true;
                break;
            }
        }

        return result;
    }

    //INNER

    private class VersionDataWrapper {
        private String u;
        private String t;
        private String n;
        private String m;
        private String c;
        private String a;
    }
}