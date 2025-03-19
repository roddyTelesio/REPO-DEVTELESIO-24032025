/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 12-27-2024
 * @last modified by  : Bhavesh Bhuckory
**/
public with sharing class CLM_AmmendAgreement {
    
    
    public class ObjectContext {     
        @InvocableVariable(required=true label='Initial Agreement record' )
        public String agreementId;
        @InvocableVariable(required=false label='Custom suffix' )
        public String customSuffix;

    }

    public class Result {
        @InvocableVariable(required=false label='Is Success ?')
        public Boolean isSuccess;

        @InvocableVariable(required=false label='Error Message')
        public String errorMsg;

        @InvocableVariable(required=false label='Agreement Generated')
        public Apttus__APTS_Agreement__c agreementGenerated;

        public Result(Boolean isSuccess, String errorMsg){
            this.isSuccess = isSuccess;
            this.errorMsg = errorMsg;
        }


        public Result(Boolean isSuccess, String errorMsg, Apttus__APTS_Agreement__c agreementGenerated){
            this.isSuccess = isSuccess;
            this.errorMsg = errorMsg;
            this.agreementGenerated = agreementGenerated;
        }
    }


    /***
    * @description	Ammend agreement record
    * @param	    obj 
    * @return		List<Slots> 
    * @exception   	None
    ***/   
    @InvocableMethod(label='[CLM] Ammend an agreement' description='Creates ammendment record for the given agreement' callout=true)
    public static List<Result> createAmmendment(List<ObjectContext> obj) {
        try{
            System.debug('createAmmendment: Start ');
            Apttus__APTS_Agreement__c  ammendedAgreement = Apttus.AgreementWebService.amendAgreement(obj[0].agreementId);
            System.debug('createAmmendment record created: ' + ammendedAgreement);
            if(String.isNotBlank(obj[0].customSuffix)){//BBH - 27.12.24 W-2243
                Apttus__APTS_Agreement__c initAgree = new Apttus__APTS_Agreement__c();
                initAgree = [SELECT Id, name,FullName__c from Apttus__APTS_Agreement__c where id = :obj[0].agreementId];
                ammendedAgreement.Name = initAgree.Name +' '+ obj[0].customSuffix;
                ammendedAgreement.FullName__c = initAgree.FullName__c +' '+ obj[0].customSuffix;
            }
            insert ammendedAgreement; 
            system.debug('BBU '+ammendedAgreement.Name+' '+ammendedAgreement.FullName__c);
            System.debug('createAmmendment: End ');
            return new List<Result>{ new Result(true, null, ammendedAgreement)};
            
        }
        catch(Exception e){  
            System.debug('createAmmendment Exception  : ' + e.getMessage());
            return new List<Result>{ new Result(false, e.getMessage())};
        }
    }
}