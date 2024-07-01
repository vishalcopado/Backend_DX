public with sharing class ParseImportPackageJson {
    public String devhub;

    // PUBLIC
    @InvocableMethod(label='Get credential from JSON information' category='Package Import')
    public static List<Result> getCredential(List<Request> requests) {
        String jsonInfo = requests[0].jsonInformation;
        String credential = String.isNotBlank(jsonInfo) ? ParseImportPackageJson.parse(jsonInfo).devhub : null;

        return new List<Result>{ new Result(credential) };
    }

    public static ParseImportPackageJson parse(String jsonString) {
        return (ParseImportPackageJson) JSON.deserialize(
            jsonString.unescapeEcmaScript(),
            ParseImportPackageJson.class
        );
    }

    // INNER
    public class Request {
        @InvocableVariable(label='Platform related arguments in JSON format' required=true)
        public String jsonInformation;
    }

    public class Result {
        @InvocableVariable(label='Credential Id')
        public String credentialId;

        // CTOR
        public Result(String credentialId) {
            this.credentialId = credentialId;
        }
    }
}