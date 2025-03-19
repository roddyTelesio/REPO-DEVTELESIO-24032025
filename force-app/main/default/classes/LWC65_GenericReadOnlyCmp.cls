public without sharing class LWC65_GenericReadOnlyCmp {

    final static string DISABLE_CMP = 'Disable Components';
    final static string AP_TRIGGER = 'Apex Trigger';
    final static string BYPASS_DML = 'Bypass DML';
    final static string BYPASS_FLOW_DML = 'Bypass Flow DML';
    @AuraEnabled
    public static Map<String,Object> readOnlyConfig(String scope){
        return readOnlyController(scope,DISABLE_CMP);
    }

    public static void readOnlyApexError(String scope,SObject recToAddError,String objectRelated){
        Map<String,Object> result = readOnlyController(scope,AP_TRIGGER);
        if(result.containsKey('componentsExcluded') && result.containsKey('isReadOnlyProfile') && (Boolean)result.get('isReadOnlyProfile')){
            system.debug('$$$BBH'+result.get('componentsExcluded')+' '+objectRelated);
            List<String> lstCmpExt = (List<String>)result.get('componentsExcluded');
            if(!lstCmpExt.contains(objectRelated) || objectRelated == null){
                recToAddError.addError(result.containsKey('errorMsg')? (String)result.get('errorMsg') : 'Access denied');
            }
        }
    }

    public static savepoint sp;

    public static void readOnlyApexRollbackInit(String scope,String partToBypass){

        Map<String,Object> result = readOnlyController(scope,BYPASS_DML); 
        if(result.containsKey('isReadOnlyProfile') && (Boolean)result.get('isReadOnlyProfile') && result.containsKey('cmpType')){
            //instantiate rollback
            List<String> lstCmp = (List<String>)result.get('cmpType');
            if(lstCmp.contains(partToBypass)){
                sp = Database.setSavepoint();
            }
        }
    }

    public static void readOnlyApexCheckRollback(){
        if(sp!=null){
            Database.rollback(sp);
        }
    }

    public static Map<String,Object> readOnlyController(String scope,String config){
        Map<String,Object> result = new Map<String,Object>();
        Boolean isReadOnly = false;
        try {
            Profile prof = [SELECT Id,Name from Profile WHERE Id = :UserInfo.getProfileId()];
            Boolean disableAll = false;
            for(AGRE_ReadOnlyProfileConfiguration__mdt mdt : AGRE_ReadOnlyProfileConfiguration__mdt.getAll().values()){
                if(mdt.IsActive__c && mdt.scope__c.equals(scope) && mdt.Configuration__c == config){
                    if(mdt.Profiles__c?.split(';')?.contains(prof.Name)){
                        result.put('configuration',mdt.configuration__c);
                        isReadOnly = true;
                        result.put('cmpType',mdt.ComponentTypesToDisable__c?.split(';'));
                        if(String.isNotBlank(mdt.NameLabelofComponentsExcluded__c)){
                            result.put('componentsExcluded',mdt.NameLabelofComponentsExcluded__c?.split(';'));
                        }
                        if(String.isNotBlank(mdt.ErrorMessage__c)){
                            result.put('errorMsg',mdt.ErrorMessage__c);
                        }
                    }
                    break;
                }
            }
            result.put('isReadOnlyProfile',isReadOnly);
        } catch (Exception e) {
            AP_CreateLogUtility.createLog(UserInfo.getProfileId(),'readOnlyConfig','LWC65_GenericReadOnlyCmp','500',e.getMessage());
            result.put('isReadOnlyProfile',isReadOnly);
            result.put('error',e.getMessage());
            // throw new AuraHandledException(e.getMessage());
        }

        return result;
    }

    public static Boolean isReadOnlyConfig(String scope) {
        List<Result> lstResult = new List<Result>();
        Map<String,Object> result = readOnlyController(scope,BYPASS_DML); 
        if(result.containsKey('isReadOnlyProfile') && (Boolean)result.get('isReadOnlyProfile')){
            return true;
        }
        return false;   
    }


    @InvocableMethod(label='Check ReadOnly Profile' description='bypass dml if readonly profile')
    public static List<Result> flowReadOnlyConfigs(List<String> scope) {
        List<Result> lstResult = new List<Result>();
        Map<String,Object> result = readOnlyController(scope[0],BYPASS_FLOW_DML);
        if(result.containsKey('isReadOnlyProfile') && (Boolean)result.get('isReadOnlyProfile')){
            lstResult.add(new result(true,null));
        }
        else{
            lstResult.add(new result(false,null));
        }
        return lstResult;
    }

    public class Result {
        @InvocableVariable(required=false label='Is Read Only?')
        public Boolean isReadOnly;

        @InvocableVariable(required=false label='Error Message')
        public String errorMsg;

        public Result(Boolean isReadOnly, String errorMsg){
            this.isReadOnly = isReadOnly;
            this.errorMsg = errorMsg;
        }


        public Result(Boolean isReadOnly, String errorMsg, String docId){
            this.isReadOnly = isReadOnly;
            this.errorMsg = errorMsg;
        }
    }

    
}