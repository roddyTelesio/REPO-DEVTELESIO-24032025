trigger ContentVersionAfterInsert on ContentVersion (after insert) {

    // Bypass des Triggers en mode Batch, future ou queuable (pour gérer la réentrance). 
    if (system.isBatch() || system.isFuture() || system.isQueueable()) {
        System.debug('EventLogAfterInsert: END trigger bypassed (mode)');
        return;
    }

    // notify when datafactory response is received
    if ((ContentVersion_CST.SETTING.CanAfterInsert__c && ContentVersion_CST.DoAfterInsert) || Test.isRunningTest()){ 
        System.debug('ContentVersion_DMN : can after insert true');
        if(ContentVersion_CST.SETTING.canNotifyCRMUsers__c || Test.isRunningTest() ){
            System.debug('ContentVersion_DMN : Notify CRM users true');
            ContentVersion_DMN.notifyCRMUsers(Trigger.new); 
        }
    } 
}