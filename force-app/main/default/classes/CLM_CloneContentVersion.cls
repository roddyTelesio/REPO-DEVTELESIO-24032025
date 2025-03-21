/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 12-24-2024
 * @last modified by  : Bhavesh Bhuckory
**/
public with sharing class CLM_CloneContentVersion {
   
    public class ObjectContext {     
        @InvocableVariable(required=true label='contentVersionId' )
        public String contentVersionId;
        //BBU W-2159:CLM - Agreement for a specific reinsurer - wrong version number
        @InvocableVariable(required=false label='docVersionTitle' )//set required to false W-2235
        public String documentVersionTitle;
    }

    public class Result {
        @InvocableVariable(required=false label='Is Success ?')
        public Boolean isSuccess;

        @InvocableVariable(required=false label='Error Message')
        public String errorMsg;

        @InvocableVariable(required=false label='Cloned ContentversionId')
        public String clonedContentVersionId;

        @InvocableVariable(required=false label='Cloned ContentDocumentId')
        public String clonedContentDocId;

        public Result(Boolean isSuccess, String errorMsg){
            this.isSuccess = isSuccess;
            this.errorMsg = errorMsg;
        }

        public Result(Boolean isSuccess, String errorMsg, String clonedContentVersionId, String clonedContentDocId){
            this.isSuccess = isSuccess;
            this.errorMsg = errorMsg;
            this.clonedContentDocId = clonedContentDocId;
            this.clonedContentVersionId = clonedContentVersionId;
        }
    }

    /***
    * @description	Method to prepare & do callout to book a b2g appointment
    * @param	    obj 
    * @exception   	None
    ***/   
    @InvocableMethod(label='[CLM] Clone content version' description='Clone content version' callout=false)
    public static List<Result> cloneContentVersion(List<ObjectContext> obj) {
        try{
            System.debug('cloneContentVersion: Start ');
            
            ContentVersion originalVersion = [SELECT Id, Title, FileExtension, pathOnclient, FileType, ContentSize, VersionData FROM ContentVersion WHERE Id =: obj[0].contentVersionId];

            // Create a new ContentVersion for the clone
            ContentVersion clonedVersion = new ContentVersion();
            clonedVersion.Title = String.isNotBlank(obj[0].documentVersionTitle)? obj[0].documentVersionTitle : originalVersion.Title; //correction W-2235
            clonedVersion.VersionData = originalVersion.VersionData; 
            clonedVersion.pathOnclient = originalVersion.pathOnclient; 

            // Insert the new ContentVersion to create the clone
            insert clonedVersion;     
            
            //Get contentDocumentId
            String contentDocId = [select ContentDocumentId from contentversion where Id =: clonedVersion.Id Limit 1].contentDocumentId;

            System.debug('cloneContentVersion: End ');
            return new List<Result>{ new Result(true, null, clonedVersion.Id, contentDocId)};
        }
        catch(Exception e){  
            System.debug('complyImportedDocs Exception  : ' + e.getMessage());
            return new List<Result>{ new Result(false, e.getMessage())};
        }
    }
}