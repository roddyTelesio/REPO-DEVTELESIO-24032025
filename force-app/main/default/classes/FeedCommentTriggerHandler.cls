public without sharing class FeedCommentTriggerHandler {
    public void handleBeforeInsert(List<FeedComment> lstFeedNew){
        for (FeedComment feed : lstFeedNew) {
            //BBH 30.10.2024 - Dev ReadOnly W-2163:AUDIT - Create a Read only profile for all platform except Works tab
            String sObjectType = SObjectTypeIdentifier.getSObjectTypeById(feed.ParentId);
            LWC65_GenericReadOnlyCmp.readOnlyApexError('FeedComment',feed,sObjectType);
        }
    }
    
    public void handleBeforeUpdate(Map<Id,FeedComment> mapOldFI,List<FeedComment> lstFeedNew){
        for (FeedComment feed : lstFeedNew) {
            //BBH 30.10.2024 - Dev ReadOnly W-2163:AUDIT - Create a Read only profile for all platform except Works tab
            String sObjectType = SObjectTypeIdentifier.getSObjectTypeById(feed.ParentId);
            LWC65_GenericReadOnlyCmp.readOnlyApexError('FeedComment',feed,sObjectType);
        }
    }

    public void handleBeforeDelete(List<FeedComment> lstFeedOld){
        for (FeedComment feed : lstFeedOld) {
            //BBH 30.10.2024 - Dev ReadOnly W-2163:AUDIT - Create a Read only profile for all platform except Works tab
            String sObjectType = SObjectTypeIdentifier.getSObjectTypeById(feed.ParentId);
            LWC65_GenericReadOnlyCmp.readOnlyApexError('FeedComment',feed,sObjectType);
        }
    }
}