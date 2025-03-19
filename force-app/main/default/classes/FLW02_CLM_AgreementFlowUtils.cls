/**
 * @description       : APEX ACTION FOR CLM - Agreement - Create Open Agreement FLOW
 *                      Utilité afin d'optimiser le flow (CPU TIME LIMIT)
 * @TICKET            : W-2020 - CLM - Copy Agreement does not work for 1 case in Staging
 * @author            : Bhavesh Bhuckory
 * @last modified on  : 05-27-2024
 * @last modified by  : Bhavesh Bhuckory
**/
public without sharing class FLW02_CLM_AgreementFlowUtils {
    @InvocableMethod(label='Get Reinsurer Ids of Program' description='Returns a list of Account IDs for the given Program')
    public static List<List<Id>> getReinsurerIdsForRequests(List<Id> lstProgramIds) {

         // Use a Set to store unique Account IDs
         Set<Id> uniqueAccountIds = new Set<Id>();
        
         // Query Contacts and related Account IDs using a subquery
         for (AggregateResult aggResult : [ SELECT COUNT(id),Reinsurer__c 
                                            FROM Request__c 
                                            WHERE Program__c IN :lstProgramIds 
                                            AND TECH_RecordType__c != 'Quote'
                                            AND Reinsurer__c!=NULL 
                                            AND OriginalRequest__c=NULL
                                            GROUP BY Reinsurer__c]) {
            Id accId = (Id) aggResult.get('Reinsurer__c');
            if (accId != null) {
                uniqueAccountIds.add(accId);
            }
         }
         
         // Convert the Set to a List and return
         List<List<Id>> result = new List<List<Id>>();
         result.add(new List<Id>(uniqueAccountIds)); // Convert Set to List
         return result;
    }
}