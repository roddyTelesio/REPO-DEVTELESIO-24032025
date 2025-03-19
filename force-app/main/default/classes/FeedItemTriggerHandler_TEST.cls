@isTest
public with sharing class FeedItemTriggerHandler_TEST {
    public static User testUserAdmin;

    static{
        testUserAdmin = TestFactory.createUser('testUserAdmin', TestFactory.getProfileAdminId());
       
        insert testUserAdmin;
    }

    @isTest
    static void testFeedItemTriggerInsert() {
        System.runAs(testUserAdmin){
            // Create a test FeedItem
            FeedItem testFeedItem = new FeedItem(
                Body = 'This is a test phrase that should trigger the status change.',
                ParentId = testUserAdmin.Id // Replace with a valid ParentId
            );
            // Start the test
            Test.startTest();
            insert testFeedItem;
            Test.stopTest();
        }
    
    }
    @isTest
    static void testFeedItemTriggerUpdate() {
        System.runAs(testUserAdmin){
            // Create a test FeedItem
            FeedItem testFeedItem = new FeedItem(
                Body = 'This is a test phrase that should trigger the status change.',
                ParentId = testUserAdmin.Id // Replace with a valid ParentId
            );
            // Start the test
            Test.startTest();
            insert testFeedItem;
            testFeedItem.Body='xxxx';
            update testFeedItem;
            Test.stopTest();
        }
    
    }
    @isTest
    static void testFeedItemTriggerDel() {
        System.runAs(testUserAdmin){
            // Create a test FeedItem
            FeedItem testFeedItem = new FeedItem(
                Body = 'This is a test phrase that should trigger the status change.',
                ParentId = testUserAdmin.Id // Replace with a valid ParentId
            );
            // Start the test
            Test.startTest();
            insert testFeedItem;
            delete testFeedItem;
            Test.stopTest();
        }
    
    }
}