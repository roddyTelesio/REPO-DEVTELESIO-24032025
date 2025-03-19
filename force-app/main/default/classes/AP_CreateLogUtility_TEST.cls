@isTest
public class AP_CreateLogUtility_TEST {
    
   public static User testUserAdmin;

    static{
        testUserAdmin = TestFactory.createUser('testUserAdmin', TestFactory.getProfileAdminId());
       
        insert testUserAdmin;
    }

    @isTest
    static void testCreateLog() {
        System.runAs(testUserAdmin) {
            // Test data
            String recordId = '001xx000003DGbPAAW';
            String context = 'Test Context';
            String className = 'AP_CreateLogUtilityTest';
            String statusCode = '200';
            String message = 'Test message';

            // Call the method
            AP_CreateLogUtility.createLog(recordId, context, className, statusCode, message);

            // Verify the log was created
            EventLog__c[] logs = [SELECT Id, RecordId__c, Context__c, ClassName__c, StatusCode__c, Message__c FROM EventLog__c WHERE RecordId__c = :recordId];
            System.assertEquals(1, logs.size());
            System.assertEquals(context, logs[0].Context__c);
            System.assertEquals(className, logs[0].ClassName__c);
            System.assertEquals(statusCode, logs[0].StatusCode__c);
            System.assertEquals(message, logs[0].Message__c);
        }
    }
}