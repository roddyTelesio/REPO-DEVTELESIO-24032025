public without sharing class AP_CreateLogUtility {
    public AP_CreateLogUtility() {

    }

    public static void createLog(String recordId,String context, String className,String statusCode, String message){
        EventLog__c eventLog = new EventLog__c();
        eventLog.RecordId__c = recordId;
        eventLog.Context__c = context;
        eventLog.ClassName__c = className;
        eventLog.StatusCode__c =  statusCode;
        eventLog.Message__c = message;
        insert eventLog;
    }
}