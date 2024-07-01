public with sharing class MetadataRetrieverMock {

    public String getResponseByType(String type) {
        switch on type {
            when 'ApexClass' {
                return '{' +
                    '"statusCode" : 200,' +
                    '"content" : "{' +
                        '\\"records\\" : [' +
                        '{' +
                                '\\"id\\": \\"a1t09000000YVz8AAG\\",' + 
                                '\\"namespacePrefix\\": \\"\\",' + 
                                '\\"name\\": \\"DummyClassForTest\\",' + 
                                '\\"CreatedDate\\": \\"2021-02-07T01:41:26.000+0000\\",' +
                                '\\"CreatedBy\\": {' +
                                    '\\"Name\\": \\"User User\\"' +
                                '},' +
                                '\\"LastModifiedDate\\": \\"2021-02-07T01:41:26.000+0000\\",' +
                                '\\"LastModifiedBy\\": {' +
                                    '\\"Name\\": \\"User User\\"' +
                                '}' + 
                            '}' +
                        ']' +
                    '}"' +
                '}';
            }
            when 'CustomField' {
                return '{' +
                    '"statusCode" : 200,' +
                    '"content" : "{' +
                        '\\"records\\" : [' +
                        '{' +
                                '\\"id\\": \\"a1t09000000YVz8AAG\\",' + 
                                '\\"entityDefinition\\": {' +
                                    '\\"namespacePrefix\\": \\"copado\\",' +
                                    '\\"developerName\\": \\"User_Story\\",' +
                                    '\\"lastModifiedDate\\": \\"2021-02-07T01:41:26.000+0000\\"' +
                                '},' + 
                                '\\"namespacePrefix\\": \\"\\",' + 
                                '\\"ValidationName\\": \\"Test_Field\\",' + 
                                '\\"CreatedDate\\": \\"2021-02-07T01:41:26.000+0000\\",' +
                                '\\"CreatedBy\\": {' +
                                    '\\"Name\\": \\"User User\\"' +
                                '},' +
                                '\\"LastModifiedDate\\": \\"2021-02-07T01:41:26.000+0000\\",' +
                                '\\"LastModifiedBy\\": {' +
                                    '\\"Name\\": \\"User User\\"' +
                                '}' + 
                            '}' +
                        ']' +
                    '}"' +
                '}';
            }
            when 'Layout' {
                return '{' +
                    '"statusCode" : 200,' +
                    '"content" : "{' +
                        '\\"records\\" : [' +
                        '{' +
                                '\\"id\\": \\"a1t09000000YVz8AAG\\",' + 
                                '\\"entityDefinition\\": {' +
                                    '\\"namespacePrefix\\": \\"copado\\",' +
                                    '\\"developerName\\": \\"User_Story\\",' +
                                    '\\"lastModifiedDate\\": \\"2021-02-07T01:41:26.000+0000\\"' +
                                '},' + 
                                '\\"namespacePrefix\\": \\"copado\\",' + 
                                '\\"ValidationName\\": \\"Test Layout\\",' + 
                                '\\"CreatedDate\\": \\"2021-02-07T01:41:26.000+0000\\",' +
                                '\\"CreatedBy\\": {' +
                                    '\\"Name\\": \\"User User\\"' +
                                '},' +
                                '\\"LastModifiedDate\\": \\"2021-02-07T01:41:26.000+0000\\",' +
                                '\\"LastModifiedBy\\": {' +
                                    '\\"Name\\": \\"User User\\"' +
                                '}' + 
                            '}' +
                        ']' +
                    '}"' +
                '}';
            }
            when 'ValidationRule' {
                return '{' +
                    '"statusCode" : 200,' +
                    '"content" : "{' +
                        '\\"records\\" : [' +
                        '{' +
                                '\\"id\\": \\"a1t09000000YVz8AAG\\",' + 
                                '\\"entityDefinition\\": {' +
                                    '\\"namespacePrefix\\": \\"copado\\",' +
                                    '\\"developerName\\": \\"User_Story\\",' +
                                    '\\"lastModifiedDate\\": \\"2021-02-07T01:41:26.000+0000\\"' +
                                '},' + 
                                '\\"namespacePrefix\\": \\"copado\\",' + 
                                '\\"ValidationName\\": \\"Test_Validation_Rule\\",' + 
                                '\\"CreatedDate\\": \\"2021-02-07T01:41:26.000+0000\\",' +
                                '\\"CreatedBy\\": {' +
                                    '\\"Name\\": \\"User User\\"' +
                                '},' +
                                '\\"LastModifiedDate\\": \\"2021-02-07T01:41:26.000+0000\\",' +
                                '\\"LastModifiedBy\\": {' +
                                    '\\"Name\\": \\"User User\\"' +
                                '}' + 
                            '}' +
                        ']' +
                    '}"' +
                '}';
            }
            when 'Flow' {
                return '{' +
                    '"statusCode" : 200,' +
                    '"content" : "{' +
                        '\\"records\\" : [' +
                        '{' +
                                '\\"id\\": \\"a1t09000000YVz8AAG\\",' +
                                '\\"definition\\": {' +
                                    '\\"namespacePrefix\\": \\"copado\\",' +
                                    '\\"developerName\\": \\"User_Story_Test_Flow\\",' +
                                    '\\"lastModifiedDate\\": \\"2021-02-07T01:41:26.000+0000\\"' +
                                '},' + 
                                '\\"CreatedDate\\": \\"2021-02-07T01:41:26.000+0000\\",' +
                                '\\"CreatedBy\\": {' +
                                    '\\"Name\\": \\"User User\\"' +
                                '},' +
                                '\\"LastModifiedDate\\": \\"2021-02-07T01:41:26.000+0000\\",' +
                                '\\"LastModifiedBy\\": {' +
                                    '\\"Name\\": \\"User User\\"' +
                                '}' + 
                            '}' +
                        ']' +
                    '}"' +
                '}';
            }
            when 'Profile' {
                return '{"statusCode":"200",' +
                       '"content":"'+
                    		'<?xml version=\\"1.0\\" encoding=\\"UTF-8\\"?><soapenv:Envelope xmlns:soapenv=\\"http://schemas.xmlsoap.org/soap/envelope/\\" xmlns=\\"http://soap.sforce.com/2006/04/metadata\\"><soapenv:Body><listMetadataResponse><result><createdById>0053O00000407PrQAI</createdById><createdByName>User User</createdByName><createdDate>2021-10-26T08:30:14.000Z</createdDate><fileName>profiles/Standard Test Profile.profile</fileName><fullName>Standard Test Profile</fullName><id>00e5j000002xPu5AAE</id><lastModifiedById>0053O00000407PrQAI</lastModifiedById><lastModifiedByName>User User</lastModifiedByName><lastModifiedDate>2021-10-26T08:30:14.000Z</lastModifiedDate><type>Profile</type></result></listMetadataResponse></soapenv:Body></soapenv:Envelope>'+
                    '"' +
                '}';
            }
            when 'CustomObject' {
                return '{' +
                    '"statusCode" : 200,' +
                    '"content" : "{' +
                        '\\"records\\" : [' +
                        '{' +
                                '\\"id\\": \\"a1t09000000YVz8AAG\\",' + 
                                '\\"namespacePrefix\\": \\"copado\\",' + 
                                '\\"DeveloperName\\": \\"User_Story_Test\\",' + 
                                '\\"CreatedDate\\": \\"2021-02-07T01:41:26.000+0000\\",' +
                                '\\"CreatedBy\\": {' +
                                    '\\"Name\\": \\"User User\\"' +
                                '},' +
                                '\\"LastModifiedDate\\": \\"2021-02-07T01:41:26.000+0000\\",' +
                                '\\"LastModifiedBy\\": {' +
                                    '\\"Name\\": \\"User User\\"' +
                                '}' + 
                            '}' +
                        ']' +
                    '}"' +
                '}';
            }
            when 'FlexiPage' {
                return '{' +
                    '"statusCode" : 200,' +
                    '"content" : "{' +
                        '\\"records\\" : [' +
                        '{' +
                                '\\"id\\": \\"a1t09000000YVz8AAG\\",' + 
                                '\\"namespacePrefix\\": \\"copado\\",' + 
                                '\\"DeveloperName\\": \\"User_Story_Test_Record_Page\\",' + 
                                '\\"CreatedDate\\": \\"2021-02-07T01:41:26.000+0000\\",' +
                                '\\"LastModifiedDate\\": \\"2021-02-07T01:41:26.000+0000\\"' +
                            '}' +
                        ']' +
                    '}"' +
                '}';
            }
            when 'PermissionSet' {
                return '{' +
                    '"statusCode" : 200,' +
                    '"content" : "{' +
                        '\\"records\\" : [' +
                            '{' +
                                '\\"id\\": \\"a1t09000000YVz8AAG\\",' + 
                                '\\"namespacePrefix\\": \\"copado\\",' + 
                                '\\"name\\": \\"Test_Suite\\",' + 
                                '\\"CreatedDate\\": \\"2021-02-07T01:41:26.000+0000\\",' +
                                '\\"CreatedBy\\": {' +
                                    '\\"Name\\": \\"User User\\"' +
                                '},' +
                                '\\"LastModifiedDate\\": \\"2021-02-07T01:41:26.000+0000\\",' +
                                '\\"LastModifiedBy\\": {' +
                                    '\\"Name\\": \\"User User\\"' +
                                '}' + 
                            '}' +
                        ']' +
                    '}"' +
                '}';
            }
            when 'CompactLayout' {
                return '{' +
                    '"statusCode" : 200,' +
                    '"content" : "{' +
                        '\\"records\\" : [' +
                            '{' +
                                '\\"id\\": \\"a1t09000000YVz8AAG\\",' + 
                                '\\"namespacePrefix\\": \\"copado\\",' + 
                                '\\"DeveloperName\\": \\"Test_Suite\\",' +
                                '\\"FullName\\": \\"copado__User_Story__c.TestHighlightPanel\\",' + 
                                '\\"CreatedDate\\": \\"2021-02-07T01:41:26.000+0000\\",' +
                                '\\"LastModifiedDate\\": \\"2021-02-07T01:41:26.000+0000\\",' +
                                '\\"LastModifiedBy\\": {' +
                                    '\\"Name\\": \\"User User\\"' +
                                '}' + 
                            '}' +
                        ']' +
                    '}"' +
                '}';
            }
            when 'ExternalServiceRegistration' {
                return '{' +
                    '"statusCode" : 200,' +
                    '"content" : "{' +
                        '\\"records\\" : [' +
                            '{' +
                                '\\"id\\": \\"a1t09000000YVz8AAG\\",' + 
                                '\\"namespacePrefix\\": \\"copado\\",' + 
                                '\\"masterLabel\\": \\"Test_Service\\",' +
                                '\\"CreatedBy\\": {' +
                                    '\\"Name\\": \\"User User\\"' +
                                '},' + 
                                '\\"CreatedDate\\": \\"2021-02-07T01:41:26.000+0000\\",' +
                                '\\"LastModifiedDate\\": \\"2021-02-07T01:41:26.000+0000\\",' +
                                '\\"LastModifiedBy\\": {' +
                                    '\\"Name\\": \\"User User\\"' +
                                '}' + 
                            '}' +
                        ']' +
                    '}"' +
                '}';
            }
            when 'Certificate' {
                return '{' +
                    '"statusCode" : 200,' +
                    '"content" : "{' +
                        '\\"records\\" : [' +
                            '{' +
                                '\\"id\\": \\"a1t09000000YVz8AAG\\",' + 
                                '\\"DeveloperName\\": \\"Test_Certificate\\"' + 
                            '}' +
                        ']' +
                    '}"' +
                '}';
            }
            when 'CustomTab' {
                return '{"statusCode":"200",' +
                       '"content":"'+
                    		'<?xml version=\\"1.0\\" encoding=\\"UTF-8\\"?><soapenv:Envelope xmlns:soapenv=\\"http://schemas.xmlsoap.org/soap/envelope/\\" xmlns=\\"http://soap.sforce.com/2006/04/metadata\\"><soapenv:Body><listMetadataResponse><result><createdById>0053O00000407PrQAI</createdById><createdByName>User User</createdByName><createdDate>2021-10-26T08:30:14.000Z</createdDate><fileName>tabs/App_Page_for_Api_Adapters.tab</fileName><fullName>App_Page_for_Api_Adapters</fullName><id>01r3O0000009tSpQAI</id><lastModifiedById>0053O00000407PrQAI</lastModifiedById><lastModifiedByName>User User</lastModifiedByName><lastModifiedDate>2021-10-26T08:30:14.000Z</lastModifiedDate><manageableState>unmanaged</manageableState><type>CustomTab</type></result><result><createdById>0053O00000407PrQAI</createdById><createdByName>User User</createdByName><createdDate>2021-10-19T16:05:03.000Z</createdDate><fileName>tabs/AdaptorCustomObject__c.tab</fileName><fullName>AdaptorCustomObject__c</fullName><id>01r3O0000009qnGQAQ</id><lastModifiedById>0053O00000407PrQAI</lastModifiedById><lastModifiedByName>User User</lastModifiedByName><lastModifiedDate>2021-10-19T16:05:03.000Z</lastModifiedDate><manageableState>unmanaged</manageableState><type>CustomTab</type></result></listMetadataResponse></soapenv:Body></soapenv:Envelope>'+
                    '"' +
                '}';
            }
            when else {
                return '{' +
                    '"statusCode" : 400,' +
                    '"errorMessage" : "ApexComponent with name test is not available",' +
                    '"errorCode" : "INVALID_TYPE"' +
                '}';
            }
        }
    }
}