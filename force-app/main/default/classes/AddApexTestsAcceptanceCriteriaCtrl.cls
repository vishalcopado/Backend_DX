public with sharing class AddApexTestsAcceptanceCriteriaCtrl {
    @AuraEnabled
    public static void storeAcceptanceCriteria(String body, Id recordId) {
        try {
            String sObjectName = getSobjectName(recordId);

            switch on sObjectName {
                when 'copado__ExtensionConfiguration__c' {
                    copado__ExtensionConfiguration__c extConfig = new ExtensionConfigurationsSelector().byIds(new Set<Id>{ recordId })[0];
                    updateExtensionConfigurationInformation(extConfig, body);
                }
                when 'copado__Test__c' {
                    copado__Test__c test = new TestsSelector().byIds(new Set<Id>{ recordId })[0];
                    updateTestInformation(test, body);
                }
                when 'copado__Quality_Gate_Rule_Condition__c' {
                    updateQualityGateRuleConditionInformation(recordId, body);
                }
            }
        } catch (Exception ex) {
            throw new ApplicationException().auraHandled(ex);
        }
    }

    @AuraEnabled
    public static String fetchAcceptanceCriteria(Id recordId) {
        try {
            String acceptanceCriteria = '{}';

            if (String.isNotBlank(recordId) || !QualityGateRuleConditionsSelector.getMock().isEmpty()) {
                String sObjectName = getSobjectName(recordId);
                Set<Id> recordIds = new Set<Id>{ recordId };
                switch on sObjectName {
                    when 'copado__ExtensionConfiguration__c' {
                        acceptanceCriteria = new ExtensionConfigurationsSelector().byIds(recordIds)[0].copado__AcceptanceCriteria__c;
                    }
                    when 'copado__Test__c' {
                        acceptanceCriteria = new TestsSelector().byIds(recordIds)[0].copado__AcceptanceCriteria__c;
                    }
                    when 'copado__Quality_Gate_Rule_Condition__c' {
                        acceptanceCriteria = new QualityGateRuleConditionsSelector().byIds(recordIds)[0].copado__AcceptanceCriteria__c;
                    }
                    when 'copado__JobStep__c' {
                        Id qualityGateRuleCondition = new JobStepsSelector(false, false).qualityGateRuleConditionByIds(recordIds)[0]
                            .copado__Quality_Gate_Rule_Condition__c;
                        acceptanceCriteria = fetchAcceptanceCriteria(qualityGateRuleCondition);
                    }
                }
            }

            return acceptanceCriteria;
        } catch (Exception ex) {
            throw new ApplicationException().auraHandled(ex);
        }
    }

    //PRIVATE

    private static String getSobjectName(Id recordId) {
        return QualityGateRuleConditionsSelector.getMock().isEmpty()
            ? recordId.getSobjectType().getDescribe(SObjectDescribeOptions.DEFERRED).getName()
            : 'copado__Quality_Gate_Rule_Condition__c';
    }

    private static void updateExtensionConfigurationInformation(copado__ExtensionConfiguration__c extConfig, String body) {
        extConfig.copado__AcceptanceCriteria__c = body;
        fflib_ISObjectUnitOfWork unitOfWork = new fflib_SObjectUnitOfWork(new List<SObjectType>{ copado__ExtensionConfiguration__c.SObjectType });
        unitOfWork.registerDirty(extConfig);
        unitOfWork.commitWork();
    }

    private static void updateTestInformation(copado__Test__c test, String body) {
        test.copado__AcceptanceCriteria__c = body;
        fflib_ISObjectUnitOfWork unitOfWork = new fflib_SObjectUnitOfWork(new List<SObjectType>{ copado__Test__c.SObjectType });
        unitOfWork.registerDirty(test);
        unitOfWork.commitWork();
    }

    private static void updateQualityGateRuleConditionInformation(Id recordId, String body) {
        copado__Quality_Gate_Rule_Condition__c condition = new copado__Quality_Gate_Rule_Condition__c(
            Id = recordId,
            copado__AcceptanceCriteria__c = body
        );

        Utilities.performDML(new List<copado__Quality_Gate_Rule_Condition__c>{ condition }, 'update', AccessLevel.USER_MODE);
    }
}