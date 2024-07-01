public inherited sharing class Utilities {
    public static List<String> getPicklistValues(String objectApiName, String fieldApiName) {
        List<String> result = new List<String>();

        List<Schema.PicklistEntry> picklistValues = Schema.getGlobalDescribe()
            .get(objectApiName)
            .getDescribe()
            .fields.getMap()
            .get(fieldApiName)
            .getDescribe()
            .getPicklistValues();

        for (Schema.PicklistEntry ple : picklistValues) {
            result.add(ple.getValue());
        }

        return result;
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    public static void performDML(List<SObject> sobjects, String operationType, AccessLevel accessLevel) {
        switch on operationType.toLowerCase() {
            when 'insert' {
                Database.insert(sobjects, true, accessLevel);
            }
            when 'update' {
                Database.update(sobjects, true, accessLevel);
            }
            when 'delete' {
                Database.delete(sobjects, true, accessLevel);
            }
        }
    }

    // INNER

    public without sharing class DeleteSObjectWithoutSharing {
        public void execute(List<SObject> sobjectList) {
            // We are running the deletion logic in SYSTEM_MODE, because we need the
            // data to be deleted irrespective of its sharing and other permissions with respect to the current logged in user.
            Utilities.performDML(sobjectList, 'delete', AccessLevel.SYSTEM_MODE);
        }
    }
}