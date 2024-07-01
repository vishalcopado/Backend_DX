@SuppressWarnings('PMD.ExcessivePublicCount, PMD.CyclomaticComplexity')
@IsTest
public with sharing class TestUtilities {
    // PUBLIC

    public static void setup() {
        User runAsUser = createUser();
        assignPermissionSet(runAsUser.Id);
        System.runAs(runAsUser) {
            assignLicense(runAsUser.Id);
        }
    }

    public static void setupAdminUser(String username) {
        User runAsUser = createAdminUser(username);
        assignPermissionSet(runAsUser.Id);
        System.runAs(runAsUser) {
            assignLicense(runAsUser.Id);
        }
    }

    public static User createAdminUser(String username) {
        User runAsUser = new User(
            LastName = 'UserLastName-admin',
            Username = username,
            Email = username,
            Alias = 'MyAlias',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = getProfile('System Administrator').Id,
            LanguageLocaleKey = 'en_US'
        );
        insert runAsUser;
        return runAsUser;
    }

    public static User createUser() {
        User runAsUser = new User(
            LastName = 'UserLastName',
            Username = 'username@myemail.com',
            Email = 'username@myemail.com',
            Alias = 'MyAlias',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = getProfile('Standard User').Id,
            LanguageLocaleKey = 'en_US'
        );
        insert runAsUser;
        return runAsUser;
    }

    private static Profile getProfile(String name) {
        return [SELECT Id, Name FROM Profile WHERE Name = :name];
    }

    public static User getRunAsUser() {
        List<User> runAsUsers = [SELECT Id FROM User WHERE Username = 'username@myemail.com'];
        return runAsUsers[0];
    }

    public static User getRunAsUser(String username) {
        List<User> runAsUsers = [SELECT Id FROM User WHERE Username = :username];
        return runAsUsers[0];
    }

    public static void assignLicense(Id userId) {
        copado.GlobalAPI copadoGlobalAPI = new copado.GlobalAPI();
        copado.GlobalAPI.UserLicense userLicense = new copado.GlobalAPI.UserLicense();
        userLicense.isCCMEnabled = true;
        userLicense.isCopadoEnabled = true;
        userLicense.userId = userId;
        copadoGlobalAPI.upsertCopadoLicense(userLicense);
    }

    public static void assignPermissionSet(Id userId) {
        List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();

        Set<String> permissions = new Set<String>{
            'Copado_User',
            'Copado_Functions',
            'Copado_Job_Engine',
            'CMC_SFDX_Admin',
            'Configure_Snapshot',
            'Access_AQF'
        };

        for (PermissionSet permission : [SELECT Id, Name FROM PermissionSet WHERE Name IN :permissions]) {
            assignments.add(new PermissionSetAssignment(AssigneeId = userId, PermissionSetId = permission.Id));
        }
        insert assignments;
    }

    public static Repository createRepository() {
        return new Repository().name('My Repo');
    }

    public static Environment createEnvironment(String name) {
        return new Environment().name(name).platform('SFDX').type('Production/Developer');
    }

    public static Credential createCredential(Boolean devhub) {
        return new Credential().devhub(devhub).type('Production/Developer');
    }

    public static Credential createCredential(Boolean devhub, Environment env) {
        return new Credential(env).devhub(devhub).type('Production/Developer');
    }

    public static Pipeline createPipeline(Repository repo, String platform) {
        return new Pipeline(repo).platform(platform);
    }

    public static JobExecution createJobExecution(JobTemplate template, Environment environment, String dataJson) {
        return new JobExecution(template, environment).dataJSON(dataJson);
    }

    public static JobStep createJobStep(JobTemplate template, String name, String type) {
        return new JobStep(template).name(name).type(type).order(1);
    }

    public static Repository getRepositoryObj() {
        return new Repository().recordId(getRepository().Id);
    }

    public static Credential getCredentialObj(Boolean devhub) {
        return new Credential().recordId(getCredential(devhub).Id);
    }

    public static Artifact getPackageObj() {
        return new Artifact().recordId(getPackage().Id);
    }

    private static copado__Artifact__c getPackage() {
        return [SELECT Id FROM copado__Artifact__c LIMIT 1];
    }

    private static copado__Git_Repository__c getRepository() {
        return [SELECT Id FROM copado__Git_Repository__c LIMIT 1];
    }

    private static copado__Org__c getCredential(Boolean isDevhub) {
        return [SELECT Id FROM copado__Org__c WHERE copado__is_Developer_Hub_Org__c = :isDevhub LIMIT 1];
    }

    public static List<copado__Artifact__c> getPackages() {
        return [SELECT Id, Api_Version__c, copado__Package_Type__c, copado__No_Namespace__c FROM copado__Artifact__c];
    }

    public static Environment getEnvironmentObj(String name) {
        return new Environment().recordId(getEnvironment(name).Id);
    }

    public static copado__Environment__c getEnvironment(String name) {
        return [SELECT Id FROM copado__Environment__c WHERE Name = :name];
    }

    public static JobExecution getJobExecutionObj(Id jobExecution) {
        return new JobExecution().recordId(jobExecution);
    }

    public static copado__JobExecution__c getJobExecution(Id jobExecution) {
        return [SELECT id, copado__DataJson__c FROM copado__JobExecution__c WHERE id = :jobExecution];
    }

    public static JobTemplate createJobTemplate(String name) {
        return new JobTemplate().name(name);
    }

    public static Result createResult(JobStep step, String data) {
        return new Result(step).type('Integration').data(data);
    }

    public static copado__JobTemplate__c getJobTemplate(String name) {
        return [SELECT Id, Name, copado__Version__c FROM copado__JobTemplate__c WHERE Name = :name];
    }

    public static JobTemplate getTemplateObj(String name) {
        return new JobTemplate().recordId(getJobTemplate(name).Id);
    }

    public static copado__JobStep__c getJobStep(Id jobExecutionId, String stepName) {
        return [
            SELECT Id, Name, copado__JobExecution__c
            FROM copado__JobStep__c
            WHERE copado__JobExecution__c = :jobExecutionId AND Name = :stepName
            LIMIT 1
        ];
    }

    public static JobStep getJobStepObj(Id jobExecutionId, String stepName) {
        return new JobStep().recordId(getJobStep(jobExecutionId, stepName).Id);
    }

    public static List<copado__Artifact_Version__c> getPackageVersions() {
        return [
            SELECT
                Id,
                Name,
                copado__Version_number__c,
                copado__Version_Description__c,
                copado__Version_Name__c,
                Post_Install_URL__c,
                Post_Install_Script__c,
                Release_Notes_URL__c,
                Uninstall_Script__c,
                copado__DefinitionFile__c,
                Has_Installation_Key__c,
                Ancestor_Version__c,
                Ancestor_Id__c,
                copado__Tag__c,
                Api_Version__c,
                copado__LastJobExecutionId__c,
                copado__Subscriber_Version_Id__c
            FROM copado__Artifact_Version__c
        ];
    }

    public static String getNamespacePrefix() {
        return Utilities.class.getName().substringBefore('Utilities').substringBefore('.');
    }

    public static void removePermissionSet(Id userId, Set<String> permissions) {
        List<PermissionSetAssignment> assignments = [
            SELECT Id
            FROM PermissionSetAssignment
            WHERE AssigneeId = :userId AND PermissionSet.Name IN :permissions
        ];

        delete assignments;
    }

    public static copado.GlobalAPI.ProxyOrgResponse getMockedResponse(String response) {
        copado.GlobalAPI.ProxyOrgResponse result = new copado.GlobalAPI.ProxyOrgResponse();
        // Note: We can not deserialize directly into copado.GlobalAPI.ProxyOrgResponse as it is in another namespace (@JsonAccess annotation must be defined in core package)
        // So using an inner class for deserializing
        ProxyOrgResponse proxyOrgResponse = String.isNotBlank(response)
            ? (ProxyOrgResponse) JSON.deserialize(response, ProxyOrgResponse.class)
            : null;
        result.statusCode = proxyOrgResponse?.statusCode;
        result.content = proxyOrgResponse?.content;
        result.errorCode = proxyOrgResponse?.errorCode;
        result.errorMessage = proxyOrgResponse?.errorMessage;
        return result;
    }

    public static String getExtensionTool() {
        List<String> picklistValues = Utilities.getPicklistValues(
            SObjectType.copado__ExtensionConfiguration__c.getName(),
            // PMD is giving a false positive here.
            copado__ExtensionConfiguration__c.copado__ExtensionTool__c.getDescribe(FieldDescribeOptions.DEFAULT).getName()
        );
        return !picklistValues.isEmpty() ? picklistValues[0] : '';
    }

    public static void delay(Integer seconds) {
        DateTime currentDateTime = DateTime.now();
        DateTime expectedDateTime = DateTime.now().addSeconds(seconds);
        while (currentDateTime < expectedDateTime) {
            currentDateTime = DateTime.now();
        }
    }

    //INNER
    public class RollbackChanges {
        public String n;
        public String t;
        public String a;
        public String c;
        public Boolean r;
        public Boolean s;
        public Boolean f;

        @SuppressWarnings('PMD.ExcessiveParameterList')
        public RollbackChanges(String n, String t, String a, String c, Boolean r, Boolean s, Boolean f) {
            this.n = n;
            this.t = t;
            this.a = a;
            this.c = c;
            this.r = r;
            this.s = s;
            this.f = f;
        }
    }
}