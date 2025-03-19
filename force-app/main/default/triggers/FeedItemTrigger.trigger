trigger FeedItemTrigger on FeedItem (before insert, before update, before delete) {
    FeedItemTriggerHandler handler = new FeedItemTriggerHandler();

    if(Trigger.isBefore && Trigger.isInsert){
        handler.handleBeforeInsert(Trigger.new);
    }
    else if(Trigger.isBefore && Trigger.isUpdate){
        handler.handleBeforeUpdate(Trigger.oldMap, Trigger.new);
    }
    else if(Trigger.isBefore && Trigger.isDelete){
        handler.handleBeforeDelete(Trigger.old);
    }
}