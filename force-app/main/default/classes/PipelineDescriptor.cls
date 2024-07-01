public with sharing class PipelineDescriptor {
    private Id pipelineId;
    private String mainBranch;

    private List<copado__Deployment_Flow_Step__c> pipelineConnections {
        get {
            if (pipelineConnections == null) {
                pipelineConnections = new PipelineConnectionsSelector().byPipelineId(pipelineId);
            }
            return pipelineConnections;
        }
        set;
    }

    public PipelineDescriptor(Id pipelineId) {
        this.pipelineId = pipelineId;
    }

    public PipelineDescriptor(Id pipelineId, String mainBranch) {
        this.pipelineId = pipelineId;
        this.mainBranch = mainBranch;
    }

    // PUBLIC

    public Map<Id, copado__Environment__c> getEnvironments() {
        Map<Id, copado__Environment__c> result = new Map<Id, copado__Environment__c>();

        for (copado__Deployment_Flow_Step__c pipelineConnection : pipelineConnections) {
            Id sourceEnvironmentId = pipelineConnection.copado__Source_Environment__c;
            copado__Environment__c sourceEnvironment = pipelineConnection.copado__Source_Environment__r;
            Id destinationEnvironmentId = pipelineConnection.copado__Destination_Environment__c;
            copado__Environment__c destinationEnvironment = pipelineConnection.copado__Destination_Environment__r;
            if (!result.containsKey(sourceEnvironmentId)) {
                result.put(sourceEnvironmentId, sourceEnvironment);
            }

            if (!result.containsKey(destinationEnvironmentId)) {
                result.put(destinationEnvironmentId, destinationEnvironment);
            }
        }

        return result;
    }

    public copado__Environment__c findFinalEnvironment() {
        copado__Environment__c result;

        Map<Id, copado__Environment__c> environments = new Map<Id, copado__Environment__c>();
        Set<Id> sourceEnvironments = new Set<Id>();

        for (copado__Deployment_Flow_Step__c pipelineConnection : pipelineConnections) {
            Id sourceEnvironmentId = pipelineConnection.copado__Source_Environment__c;
            copado__Environment__c sourceEnvironment = pipelineConnection.copado__Source_Environment__r;
            Id destinationEnvironmentId = pipelineConnection.copado__Destination_Environment__c;
            copado__Environment__c destinationEnvironment = pipelineConnection.copado__Destination_Environment__r;

            environments.put(sourceEnvironmentId, sourceEnvironment);
            environments.put(destinationEnvironmentId, destinationEnvironment);

            sourceEnvironments.add(sourceEnvironmentId);
        }

        for (Id destinationEnvironmentId : environments.keySet()) {
            if (!sourceEnvironments.contains(destinationEnvironmentId)) {
                result = environments.get(destinationEnvironmentId);
            }
        }

        return result;
    }

    public Boolean areCredentialsAuthenticated(Set<Id> environmentIds) {
        Set<Id> authenticatedEnvironments = new Set<Id>();

        for (AggregateResult credential : [
            SELECT
                copado__Environment__c,
                COUNT(Id) authenticatedCredentialsCount
            FROM copado__Org__c
            WHERE
                copado__Environment__c IN :environmentIds
                AND ((copado__Validated_Status__c = 'OK'
                OR copado__Validated_Status__c = 'None')
                AND copado__SFDC_Org_ID__c != null
                AND copado__Default_Credential__c = true)
            WITH USER_MODE
            GROUP BY copado__Environment__c
            HAVING COUNT(Id) > 0
        ]){
            authenticatedEnvironments.add((Id)credential.get('copado__Environment__c'));
        }

        return environmentIds.equals(authenticatedEnvironments);

    }

    public Map<String, String> getDestinationBranchesBySourceBranches() {
        Map<String, String> result = new Map<String, String>();

        for (copado__Deployment_Flow_Step__c pipelineConnection : pipelineConnections) {
            result.put(pipelineConnection.copado__Branch__c, pipelineConnection.copado__Destination_Branch__c);
        }

        return result;
    }

    public List<copado__Deployment_Flow_Step__c> getOrderedPipelineConnections() {
        List<copado__Deployment_Flow_Step__c> result = new List<copado__Deployment_Flow_Step__c>();

        Map<String, List<copado__Deployment_Flow_Step__c>> pipelineConnectionsByDestinationBranch = new Map<String, List<copado__Deployment_Flow_Step__c>>();

        for (copado__Deployment_Flow_Step__c step : pipelineConnections) {
            String destinationBranch = step.copado__Destination_Branch__c;
            if (!pipelineConnectionsByDestinationBranch.containsKey(destinationBranch)) {
                pipelineConnectionsByDestinationBranch.put(destinationBranch, new List<copado__Deployment_Flow_Step__c>{step});
            } else {
                pipelineConnectionsByDestinationBranch.get(destinationBranch).add(step);
            }
        }

        result.addAll(pipelineConnectionsByDestinationBranch.get(mainBranch));

        traverseHierarchy(mainBranch, pipelineConnectionsByDestinationBranch, result);

        return result;
    }

    public Map<Id, Id> getDestinationEnvironmentsByIntermediateEnvironments(List<copado__Deployment_Flow_Step__c> pipelineConnections) {
        Map<Id, Id> result = new Map<Id, Id>();

        Set<Id> destinationEnvironments = new Set<Id>();
        for (copado__Deployment_Flow_Step__c connection : pipelineConnections) {
            destinationEnvironments.add(connection.copado__Destination_Environment__c);
        }

        for (copado__Deployment_Flow_Step__c connection : pipelineConnections) {
            if (destinationEnvironments.contains(connection.copado__Source_Environment__c)) {
                result.put(connection.copado__Source_Environment__c, connection.copado__Destination_Environment__c);
            }
        }

        return result;
    }

    // PRIVATE

    private static void traverseHierarchy(String destinationBranch, Map<String, List<copado__Deployment_Flow_Step__c>> pipelineConnectionsByDestinationBranch, List<copado__Deployment_Flow_Step__c> result) {
        if (pipelineConnectionsByDestinationBranch.containsKey(destinationBranch)) {
            List<copado__Deployment_Flow_Step__c> steps = pipelineConnectionsByDestinationBranch.get(destinationBranch);
            for (copado__Deployment_Flow_Step__c step : steps) {
                if (pipelineConnectionsByDestinationBranch.containsKey(step.copado__Branch__c)) {
                    result.addAll(pipelineConnectionsByDestinationBranch.get(step.copado__Branch__c));
                    traverseHierarchy(step.copado__Branch__c, pipelineConnectionsByDestinationBranch, result);
                }
            }
        }
    }
}