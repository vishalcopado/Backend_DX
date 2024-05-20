public with sharing class HandleApexTestRecord {
    // PUBLIC
    private final static String NO_CHANGES = 'No Changes';

    @InvocableMethod(label='Apex Test Record Management' category='Apex Tests')
    public static List<Response> execute(List<Request> requests) {
        List<Response> result = new List<Response>(); 
        if (isRequestValid(requests)) {
            try {
                ApexTestInfo apexTestInfo = new ApexTestInfo(requests[0].recreateFeatureBranch,requests[0].fileWithSelectedChanges);
                AddApexTestsController.getApexTestClassList(null, requests[0].userStoryId, apexTestInfo);
            } catch (Exception ex) {
                result.add(new Response(ex.getMessage() + ex.getStackTraceString()));
            }
        }
        return result;
    }

    // PRIVATE

    private static Boolean isRequestValid(List<Request> requests) {
        Boolean isValid =
            !requests.isEmpty() &&
            String.isNotBlank(requests[0].userStoryId) &&
            requests[0].recreateFeatureBranch != null &&
            String.isNotBlank(requests[0].fileWithSelectedChanges) &&
            String.isNotBlank(requests[0].commitResult);
            if (isValid) {
                CommitResultWrapper result = (CommitResultWrapper) JSON.deserialize(requests[0].commitResult, CommitResultWrapper.class);
                if (result.status == NO_CHANGES) {
                    isValid = false;
                }
            }

        return isValid;
    }

    // INNER

    public class Request {
        @InvocableVariable(label='User Story Id' required=true)
        public String userStoryId;
        @InvocableVariable(label='Recreate Feature Branch' required=true)
        public Boolean recreateFeatureBranch;
        @InvocableVariable(label='Commit Result' required=true)
        public String commitResult;
        @InvocableVariable(label='File With Selected Changes' required=true)
        public Id fileWithSelectedChanges;
    }

    public class Response {
        @InvocableVariable(label='Response')
        public String message;

        public Response(String message) {
            this.message = message;
        }
    }

    private class CommitResultWrapper {
        String commitId;
        String status;
    }
}