@isTest
public class ContentVersion_DMN_TST {


    public static user UsertestUserAdmin;

    static {

        UsertestUserAdmin = TestFactory.createUser('testUserAdmin', TestFactory.getProfileAdminId());

        System.runAs(UsertestUserAdmin){


            // initializes custom setting for account
            ContentVersionSettings__c contentVersionsSettings = new ContentVersionSettings__c(
                CanAfterInsert__c = true,
                canNotifyCRMUsers__c = true,
                ContentDocumentTitle__c = 'testsbh'
                //default values applied (all active by default)
            );
            insert contentVersionsSettings;

            // Create ContentVersion records
            ContentVersion contentVersion1 = new ContentVersion(
                Title = 'Test Document Version 1',
                ReasonForChange = 'Initial version',
                PathOnClient = 'TestPath1.docx',
                VersionData = Blob.valueOf('Test data 1')
            );

            ContentVersion contentVersion2 = new ContentVersion(
                Title = ContentVersion_CST.secRatingListDocumentTitle, // Use the constant for matching
                ReasonForChange = 'Security rating updated',
                PathOnClient = ContentVersion_CST.secRatingListDocumentTitle + '.xlsx',
                VersionData = Blob.valueOf('Test data 2')
            );

            insert new List<ContentVersion>{contentVersion1, contentVersion2};
        }
        
    }

    @isTest
    static void testNotifyCRMUsers() {
        // Retrieve the test data
        List<ContentVersion> contentVersions = [SELECT Id, Title, ReasonForChange FROM ContentVersion];


        // Start test context
        Test.startTest();
        // Replace the flow invocation with the stub
        // Flow.Interview.CRM_NotifyClientsSecurityList = flowStub;
        ContentVersion_DMN.notifyCRMUsers(contentVersions);
        Test.stopTest();

        // Verify the flow was called correctly
        // System.assertEquals(1, flowStub.invocations.size(), 'One ContentVersion should trigger the flow');
        // System.assertEquals('Security rating updated', flowStub.invocations.get(0).get('MessageBody'), 'Flow parameter should match ReasonForChange');
    }
}