public with sharing class ListViewSelector extends fflib_SObjectSelector {
    // CONSTRUCTOR

    public ListViewSelector() {
        this(true, true);
    }

    public ListViewSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(false, enforceCRUD, enforceFLS, false);
    }

    // PUBLIC

    public SObjectType getSObjectType() {
        return ListView.getSObjectType();
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{ ListView.Id };
    }

    public List<ListView> bySobject(String sobjectType) {
        return Database.query(
            newQueryFactory()
                .selectFields(new Set<String>{ 'Name', 'DeveloperName' })
                .setCondition('SobjectType =: sobjectType')
                .toSOQL()
        );
    }
}