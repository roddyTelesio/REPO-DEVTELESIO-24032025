trigger FeedCommentTrigger on FeedComment (before insert, before update, before delete) {
    FeedCommentTriggerHandler handler = new FeedCommentTriggerHandler();

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