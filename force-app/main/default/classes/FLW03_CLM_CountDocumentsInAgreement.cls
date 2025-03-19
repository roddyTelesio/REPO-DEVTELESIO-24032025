public with sharing class FLW03_CLM_CountDocumentsInAgreement {
    public class Result {
        @InvocableVariable(required=false label='Is Success ?')
        public Boolean isSuccess;

        @InvocableVariable(required=false label='Error Message')
        public String errorMsg;

        public Result(Boolean isSuccess, String errorMsg){
            this.isSuccess = isSuccess;
            this.errorMsg = errorMsg;
        }
    }

    public class InputVariables{
        @InvocableVariable(required=false label='Id Agreements' )
        public String AgreementId;
        @InvocableVariable(required=false label='Id excluded dvd id' )
        public String excludeDVDId;
    }

    @InvocableMethod(label='Count Documents on Agreement' description='Counts Total number of word documents on agreement')
    public static List<Result> countDocs(List<InputVariables> inputVars) {
      
         Map<Id,Apttus__APTS_Agreement__c> mapAggToUpdate = new Map<id,Apttus__APTS_Agreement__c>();
         List<Result> lstResult = new List<Result>();

         List<String> AgreementIds = new List<String>();
         List<String> lstExcludeIds = new List<String>();
         for(InputVariables inputVar: inputVars){
            AgreementIds.add(inputVar.AgreementId);
            if(String.isNotBlank(inputVar.excludeDVDId)){
                lstExcludeIds.add(inputVar.excludeDVDId);
            }
         }
        try {
            String queryString = 'SELECT count(Id) numDocs,Apttus__DocumentVersionId__r.Apttus__AgreementId__c aggId ';
            queryString += 'FROM Apttus__DocumentVersionDetail__c ';
            queryString += 'WHERE Apttus__DocumentVersionId__r.Apttus__AgreementId__c IN :AgreementIds ';
            queryString += 'and (FileExtension__c like \'%doc%\' or (FileExtension__c =null and Apttus__DocumentVersionId__r.Apttus__Title__c   like \'%.doc%\')) ';
            queryString += 'AND Apttus__VersionRevision__c = 0 ';
            queryString += 'AND Apttus__DocumentVersionId__r.NAME != \'Upload Signed Document\' ';
            if(!lstExcludeIds.isEmpty()){
                queryString += 'AND Id NOT IN :lstExcludeIds ';
            }
            queryString += 'GROUP BY Apttus__DocumentVersionId__r.Apttus__AgreementId__c ';
            Decimal total = 0;
            for (AggregateResult aggResult : Database.query(queryString)) {
                Id aggreementId = (Id) aggResult.get('aggId');
                total=(Decimal)aggResult.get('numDocs');
                mapAggToUpdate.put(aggreementId,new Apttus__APTS_Agreement__c(Id = aggreementId,NumberOfDocAttached__c = (Decimal)aggResult.get('numDocs')) );
             }
            
            for (Id aggrId : AgreementIds) {
                if(!mapAggToUpdate.containsKey(aggrId)){
                    mapAggToUpdate.put(aggrId,new Apttus__APTS_Agreement__c(Id = aggrId,NumberOfDocAttached__c = 0 ));
                }
            }

            if(!mapAggToUpdate.isEmpty()){
                update mapAggToUpdate.values();
            }

            for(InputVariables inputVar: inputVars){
                lstResult.add(new Result(true, 'Success'+ total)); //The number of results must match the number of interviews that were executed in a single bulk execution request.
            }
        } catch (Exception e ) {
            for(InputVariables inputVar: inputVars){
                lstResult.add(new Result(false, e.getMessage()+' '+e.getStackTraceString()+' ')); //The number of results must match the number of interviews that were executed in a single bulk execution request.
            }
        }
        return lstResult;
      
    }
}