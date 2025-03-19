@isTest
public class LWC65_GenericReadOnlyCmp_TEST {
    public static User readOnlyUser;
   
    static {
        Profile readOnly = [SELECT Id FROM Profile WHERE Name = 'AGRE_Read Only' LIMIT 1];
        readOnlyUser = new User(
            Alias = 'read',
            Email = 'read@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Admin',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = readOnly.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'readonlyusertest@example.com'
        );
        insert readOnlyUser;

           // Query the Permission Set
           PermissionSet permSet = [SELECT Id FROM PermissionSet WHERE Name = 'AGRE_ReadOnly' LIMIT 1];
        
           // Create the PermissionSetAssignment
           PermissionSetAssignment permSetAssign = new PermissionSetAssignment(
               AssigneeId = readOnlyUser.Id,
               PermissionSetId = permSet.Id
           );
           
           // Insert the PermissionSetAssignment
           insert permSetAssign;
    }

    @isTest
    static void testReadOnlyConfig() {
        
        System.runAs(readOnlyUser) {
            Map<String, Object> result = LWC65_GenericReadOnlyCmp.readOnlyConfig('Generic');
            System.assert(result.containsKey('isReadOnlyProfile'));
            System.assertEquals(true, result.get('isReadOnlyProfile'));
        }
    }

    @isTest
    static void testReadOnlyApexError() {
        
        System.runAs(readOnlyUser) {
            Test.startTest();
            String fileContent = 'Test data';
            Blob fileContentInBlob = Blob.valueOf(fileContent);
            List<ContentVersion> lstNewContentVersion = new List<ContentVersion>{
                TestFactory.createContentVersion('2','1'
                                                , '1', 'CV1', fileContentInBlob, 'CV1.pdf')
            };
            insert lstNewContentVersion;
            
            LWC65_GenericReadOnlyCmp.readOnlyApexError('ContentDocumentLink',lstNewContentVersion[0],null);
           Test.stopTest();
            
        }
    }

    @isTest
    static void testReadOnlyApexRollbackInit() {
        
        System.runAs(readOnlyUser) {
            LWC65_GenericReadOnlyCmp.readOnlyApexRollbackInit('TP_Path','updateStage');
        }
    }


    @isTest
    static void testFlowReadOnlyConfigs() {
        
        System.runAs(readOnlyUser) {
            List<String> scopes = new List<String>{'flow'};
            List<LWC65_GenericReadOnlyCmp.Result> results = LWC65_GenericReadOnlyCmp.flowReadOnlyConfigs(scopes);
        }
    }

    @isTest
    static void testIsReadOnlyConfig() {
        
        System.runAs(readOnlyUser) {
            Boolean isReadOnly = LWC65_GenericReadOnlyCmp.isReadOnlyConfig('SA_Init');
        }
    }
}