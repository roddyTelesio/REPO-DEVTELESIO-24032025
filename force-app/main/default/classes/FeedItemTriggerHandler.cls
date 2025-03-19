public without sharing class FeedItemTriggerHandler {
    
    public void handleBeforeInsert(List<FeedItem> lstFeedNew){
        for (FeedItem feed : lstFeedNew) {
            //BBH 30.10.2024 - Dev ReadOnly W-2163:AUDIT - Create a Read only profile for all platform except Works tab
            String sObjectType = SObjectTypeIdentifier.getSObjectTypeById(feed.ParentId);
            LWC65_GenericReadOnlyCmp.readOnlyApexError('FeedItem',feed,sObjectType);
        }
    }
    
    public void handleBeforeUpdate(Map<Id,FeedItem> mapOldFI,List<FeedItem> lstFeedNew){
        for (FeedItem feed : lstFeedNew) {
            //BBH 30.10.2024 - Dev ReadOnly W-2163:AUDIT - Create a Read only profile for all platform except Works tab
            String sObjectType = SObjectTypeIdentifier.getSObjectTypeById(feed.ParentId);
            LWC65_GenericReadOnlyCmp.readOnlyApexError('FeedItem',feed,sObjectType);
        }
    }

    public void handleBeforeDelete(List<FeedItem> lstFeedOld){
        for (FeedItem feed : lstFeedOld) {
            //BBH 30.10.2024 - Dev ReadOnly W-2163:AUDIT - Create a Read only profile for all platform except Works tab
            String sObjectType = SObjectTypeIdentifier.getSObjectTypeById(feed.ParentId);
            LWC65_GenericReadOnlyCmp.readOnlyApexError('FeedItem',feed,sObjectType);
        }
    }
}