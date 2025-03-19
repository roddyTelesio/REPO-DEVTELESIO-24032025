/**
 * @description       : 
 * @author            : Patrick Randrianarisoa
 * @group             : 
 * @last modified on  : 28-05-2024
 * @last modified by  : Patrick Randrianarisoa 
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   28-05-2024   Patrick Randrianarisoa   Initial Version
**/
trigger CLM_ReviewerTrigger on Apttus__Reviewer__c (After update) {
    CLM_ReviewerHandler handler = new CLM_ReviewerHandler();
    if(Trigger.isAfter && Trigger.isUpdate) {
        handler.handleAfterUpdate(Trigger.old, Trigger.new);
    }
}