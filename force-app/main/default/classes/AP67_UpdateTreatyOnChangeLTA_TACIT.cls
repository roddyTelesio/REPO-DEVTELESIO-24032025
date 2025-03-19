public with sharing class AP67_UpdateTreatyOnChangeLTA_TACIT {
    public static void updateTreaty(List<Treaty__c> lstTreaty) {
       //RRA - ticket 2264 - 22/01/2025
      List<Id> lstIdTreaty = new List<Id>();
       List<Treaty__c> lstTreatyToUpdate = new List<Treaty__c> (); 
      for (Treaty__c treaty : lstTreaty) {
          lstIdTreaty.add(treaty.Id);
      } 
      if(Treaty__c.SObjectType.getDescribe().isAccessible() && Schema.SObjectType.Treaty__c.fields.TECH_LTAFromPrg__c.isAccessible()){
           lstTreatyToUpdate = [SELECT Id, Program__c, TECH_LTAFromPrg__c, TECH_LTAExpiryFromPrg__c, TECH_LTAInceptionFromPrg__c, TECH_TacitFromPrg__c, LTAExpiryDate__c, LTAInceptionDate__c	, Program__r.LTA__c,  Program__r.TRInceptionDate__c FROM Treaty__c WHERE Id IN:lstIdTreaty];
      }
        System.debug('lstTreatyToUpdate  av AP67_UpdateTreatyOnChangeLTA_TACIT== ' + lstTreatyToUpdate);
      if (lstTreatyToUpdate.size()>0){
        for (Treaty__c treaty :lstTreatyToUpdate ){
          treaty.LTA__c = treaty.TECH_LTAFromPrg__c;
          treaty.TacitRenewal__c = treaty.TECH_TacitFromPrg__c;

          //LTA
          if(treaty.TECH_LTAFromPrg__c == '1'){
            treaty.LTAInceptionDate__c = treaty.TECH_LTAInceptionFromPrg__c;
            treaty.LTAExpiryDate__c = treaty.TECH_LTAExpiryFromPrg__c;
          }else if(treaty.TECH_LTAFromPrg__c == '2'){
            treaty.LTAInceptionDate__c = null;
            treaty.LTAExpiryDate__c = null;
          }

          //TACIT
          if(treaty.TECH_TacitFromPrg__c == '1'){
            treaty.TacitRenewal__c  ='1';
          }else if(treaty.TECH_TacitFromPrg__c == '2'){
            treaty.TacitRenewal__c = '2';
          }
        }
        if(Treaty__c.SObjectType.getDescribe().isUpdateable()){
           update lstTreatyToUpdate;
        }
       
          System.debug('lstTreatyToUpdate  ap AP67_UpdateTreatyOnChangeLTA_TACIT== ' + lstTreatyToUpdate);
      }

    }
}