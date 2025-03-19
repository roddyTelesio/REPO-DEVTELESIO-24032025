@isTest
public with sharing class FeedCommentTriggerHandler_TEST {
    public static User testUserAdmin;
    public static FeedItem testFeedItem;

    static{
        testUserAdmin = TestFactory.createUser('testUserAdmin', TestFactory.getProfileAdminId());
       
        insert testUserAdmin;

         // Create a test FeedItem
         testFeedItem = new FeedItem(
            Body = 'This is a test phrase that should trigger the status change.',
            ParentId = testUserAdmin.Id // Replace with a valid ParentId
        );
        insert testFeedItem;
    }

    @isTest
    static void testFeedCommentTriggerInsert() {
        System.runAs(testUserAdmin){
            // Create a test FeedComment
            FeedComment testFeedComment = new FeedComment(
                CommentBody  = 'This is a test phrase that should trigger the status change.',
                // ParentId = testUserAdmin.Id // Replace with a valid ParentId
                FeedItemId=testFeedItem.Id
            );
            // Start the test
            Test.startTest();
            insert testFeedComment;
            Test.stopTest();
        }
    
    }
    @isTest
    static void testFeedCommentTriggerUpdate() {
        System.runAs(testUserAdmin){
            // Create a test FeedComment
            FeedComment testFeedComment = new FeedComment(
                CommentBody  = 'This is a test phrase that should trigger the status change.',
                // ParentId = testUserAdmin.Id // Replace with a valid ParentId
                FeedItemId=testFeedItem.Id
            );
            // Start the test
            Test.startTest();
            insert testFeedComment;
            testFeedComment.CommentBody ='xxxx';
            update testFeedComment;
            Test.stopTest();
        }
    
    }
    @isTest
    static void testFeedCommentTriggerDel() {
        System.runAs(testUserAdmin){
            // Create a test FeedComment
            FeedComment testFeedComment = new FeedComment(
                CommentBody  = 'This is a test phrase that should trigger the status change.',
                // ParentId = testUserAdmin.Id // Replace with a valid ParentId
                FeedItemId=testFeedItem.Id
            );
            // Start the test
            Test.startTest();
            insert testFeedComment;
            delete testFeedComment;
            Test.stopTest();
        }
    
    }
}