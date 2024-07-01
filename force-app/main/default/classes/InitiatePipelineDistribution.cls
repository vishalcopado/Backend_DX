public with sharing class InitiatePipelineDistribution {
    // PUBLIC

    @InvocableMethod(label='Executes Package Distribution Job' category='Package Distribution')
    public static List<Result> startExecution(List<Request> requests) {
        Result result = new Result();

        copado__Deployment__c deployment = new DeploymentsSelector().byIds(new Set<Id>{ requests[0].deploymentId }).get(0);

        Id destinationCredential = deployment.copado__Promotion__r.copado__Destination_Org_Credential__c;

        result.job = new DeployPackages(requests[0].packageVersionId, new List<Id>{ destinationCredential }, requests[0].installSecurityType, requests[0].deploymentJobId)
            .execute()
            .get(0);

        return new List<Result>{ result };
    }

    // INNER

    public class Request {
        @InvocableVariable(label='Package Version Id' required=true)
        public String packageVersionId;

        @InvocableVariable(label='Deployment Id' required=true)
        public String deploymentId;

        @InvocableVariable(label='Deployment Job Id')
        public Id deploymentJobId;

        @InvocableVariable(label='Package Install Security Type')
        public String installSecurityType;
    }

    public class Result {
        @InvocableVariable(label='Job Execution')
        public copado__JobExecution__c job;
    }
}