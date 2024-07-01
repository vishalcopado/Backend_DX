public with sharing class CheckPackageDistributionLicense {
    // PUBLIC

    @InvocableMethod(label='Check Package Distribution License')
    public static List<Response> checkLicense(List<Request> request) {
        try {
            CheckLicense userLicense = new CheckLicense(request[0].userId);
            Boolean hasLicense = userLicense.has('Copado User') || userLicense.has('Copado Admin');

            return new List<Response>{ new Response(hasLicense) };
        } catch (Exception e) {
            throw new ApplicationException(e.getMessage());
        }
    }

    // INNER

    public class Request {
        @InvocableVariable
        public Id userId;
    }

    public class Response {
        @InvocableVariable
        public Boolean hasLicense;

        public Response(Boolean hasLicense) {
            this.hasLicense = hasLicense;
        }
    }
}