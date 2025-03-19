trigger MinuteAccountAfterDelete on MinuteAccount__C (after delete) {

    // Bypass des Triggers en mode Batch, future ou queuable (pour gérer la réentrance). 
    if (system.isBatch() || system.isFuture() || system.isQueueable()) {
        System.debug('EventLogAfterInsert: END trigger bypassed (mode)');
        return;
    }

    // notify when datafactory response is received
    if ((MinuteAccount_CST.SETTING.CanAfterDelete__c && MinuteAccount_CST.DoAfterDelete) || Test.isRunningTest()){ 
        System.debug('ContentVersion_DMN : can after insert true');
        if(MinuteAccount_CST.SETTING.CanReworkConcatFields__c || Test.isRunningTest() ){
            System.debug('ContentVersion_DMN : Notify CRM users true');
            MinuteAccount_DMN.reworkConcatFields(Trigger.old); 
        }

        if(MinuteAccount_CST.SETTING.CanDeleteMinuteContacts__c || Test.isRunningTest() ){
            
            System.debug('ContentVersion_DMN : Notify CRM users true');
            MinuteAccount_DMN.deleteMinuteContacts(Trigger.old); 
        }
    } 
}