@SuppressWarnings('PMD.AvoidGlobalModifier')
public with sharing class ExecuteDataSetJobTemplateAction {

	@InvocableMethod(label='Execute Data Set Job Template Action')
	public static List<DataDeploy.DataSetExecutionResult> execute(List<DataDeploy.DataSetExecutionRequest> requests) {
        List<DataDeploy.DataSetExecutionResult> result = new List<DataDeploy.DataSetExecutionResult>();
        for (DataDeploy.DataSetExecutionRequest request : requests) {
            result.add(new DataDeploy.DataSetExecution().executeDataSetJobTemplate(request));
        }
        return result;
	}

    
    
}