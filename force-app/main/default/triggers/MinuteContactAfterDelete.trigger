trigger MinuteContactAfterDelete on MinuteContacts__c (after delete) {



    // Bypass des Triggers en mode Batch, future ou queuable (pour gérer la réentrance). 
    if (system.isBatch() || system.isFuture() || system.isQueueable()) {
        System.debug('MinuteContactAfterDelete: END trigger bypassed (mode)');
        return;
    }

    // notify when datafactory response is received
    if ((MinuteContact_CST.SETTING.CanAfterDelete__c && MinuteContact_CST.DoAfterDelete) || Test.isRunningTest()){ 
        System.debug('MinuteContactAfterDelete : can after delete true');
        if(MinuteContact_CST.SETTING.CanReworkConcatFields__c || Test.isRunningTest() ){
            System.debug('MinuteContactAfterDelete : rework Concat Fields');
            MinuteContact_DMN.reworkConcatFields(Trigger.old); 
        }
    } 



}