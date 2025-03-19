public with sharing class CLM_GenerateAgreement {
    public class ObjectContext {     
        @InvocableVariable(required=true label='Initial Agreement record' )
        public String agreementId;
        @InvocableVariable(required=false label='Template Name' )
        public String templateName;

    }

    public class Result {
        @InvocableVariable(required=false label='Is Success ?')
        public Boolean isSuccess;

        @InvocableVariable(required=false label='Error Message')
        public String errorMsg;

        @InvocableVariable(required=false label='Content doc Generated')
        public String docId;
        @InvocableVariable(required=false label='Content version Generated')
        public String contentVersionId;
        @InvocableVariable(required=false label='template id')
        public String templateId;

        public Result(Boolean isSuccess, String errorMsg){
            this.isSuccess = isSuccess;
            this.errorMsg = errorMsg;
        }


        public Result(Boolean isSuccess, String errorMsg, String docId){
            this.isSuccess = isSuccess;
            this.errorMsg = errorMsg;
            this.docId = docId;
        }
    }


    /***
    * @description	Ammend agreement record
    * @param	    obj 
    * @return		List<Slots> 
    * @exception   	None
    ***/   
    @InvocableMethod(label='[CLM] Generate A document' description='Creates document for the given agreement' callout=true)
    public static List<Result> createAmmendment(List<ObjectContext> obj) {
        try{
            ID templateId= [SELECT Id from Apttus__APTS_Template__c WHERE Name = :obj[0].templateName LIMIT 1]?.Id;
            Id agreementId = obj[0].agreementId;
            String pLevel = 'Full access';
            String docFormat = 'DOCX';
            String apiServerURL = System.Url.getSalesforceBaseUrl().toExternalForm() + '/services/Soap/u/50.0/' + UserInfo.getOrganizationId();
            String SessionId = UserInfo.getSessionId();  //This is the session Id.
            String generatedDocId = Apttus.MergeWebService.generateDoc(templateId, agreementId, pLevel, docFormat, SessionId, apiServerURL);
            Result r = new Result(true, null, generatedDocId);
            ContentVersion documentVersion = [SELECT Id,title  FROM ContentVersion WHERE ContentDocumentId= :generatedDocId];
            r.contentVersionId = documentVersion?.Id;
            r.templateId = templateId;
            system.debug('### Doc title '+documentVersion?.title);
            return new List<Result>{ r};
            
        }
        catch(Exception e){  
            System.debug('createAmmendment Exception  : ' + e.getMessage());
            return new List<Result>{ new Result(false, e.getMessage())};
        }
    }
}