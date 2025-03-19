public with sharing class AP65_RecalculateFieldsLeadReq {
    /**************************************************************************************
-- - Author        : Telesio
-- - Description   : update fields MPD__c, Depo Premium and Min premium on Request when one of the fields conditions ExpectedDP__c, ExpectedMDP__c, ExpectedM__c is changed
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 09-11-2023   RRA    1.0     Initial Version ticket 1745
--------------------------------------------------------------------------------------
**************************************************************************************/

    public static void updatefieldsLeadRequests(List<Section__c> lstSections, String strGroup){
        Map<Id, Section__c> mapIdSecSections = new Map<Id, Section__c>();
        Decimal cededPremimum;
        Decimal expectedMDP;
        Decimal expectedDP;
        Decimal expectedMP;
        for (Section__c sec : lstSections){
            mapIdSecSections.put(sec.Id, sec);
        }
        System.debug('mapIdSecSections == ' + mapIdSecSections);
       List<Request__c> lstRequest = [SELECT Id, RecordType.Name, TECH_TypeofTreaty__c, TECH_QuoteType__c, TECH_LeadType__c, FixedRate__c, FlatPremium__c, MinRate__c, MinPerHeadAmount__c, PerHeadPremium__c, Section__c, MDP__c, CededPremium__c , DepoPremium__c, MinPremium__c 
                                      FROM Request__c 
                                      WHERE Section__c IN:mapIdSecSections.KeySet() 
                                      AND TECH_LeadType__c= 'child' 
                                      AND RecordType.Name = 'Lead Request'];
        System.debug('lstRequest beforeupdate == ' + lstRequest);
       if (lstRequest.size()>0){
        for (Request__c req : lstRequest){
            String typeOfTreaty = req.TECH_TypeofTreaty__c;
            String typeOfQuote = req.TECH_QuoteType__c;
          if (strGroup == '1'){
              expectedMDP = mapIdSecSections.get(req.Section__c).ExpectedMDP__c != null ? mapIdSecSections.get(req.Section__c).ExpectedMDP__c : 0;
              expectedDP = mapIdSecSections.get(req.Section__c).ExpectedDP__c != null ? mapIdSecSections.get(req.Section__c).ExpectedDP__c : 0;
              expectedMP = mapIdSecSections.get(req.Section__c).ExpectedMP__c != null ? mapIdSecSections.get(req.Section__c).ExpectedMP__c : 0;

              //fixed Rate
              if (req.FixedRate__c !=null){
                  System.debug('ok 1');
                  cededPremimum =  (Math.roundToLong(mapIdSecSections.get(req.Section__c).TotalEPI__c) * (req.FixedRate__c / 100));
              //Flat Premium 
              }else if (req.FlatPremium__c !=null){
                  System.debug('ok 2');
                  cededPremimum =   Math.roundToLong(req.FlatPremium__c);
              }
              //MDP
              else if (req.MDP__c !=null){
                  System.debug('ok 3');
                  cededPremimum = Math.round(req.MDP__c);
              }
              //Variable
              else if (req.MinRate__c !=null){
                  System.debug('ok 4');
                  cededPremimum =  (Math.roundToLong(mapIdSecSections.get(req.Section__c).TotalEPI__c) * (req.MinRate__c / 100));
              }
              //PerheadPremium
              else if (req.PerHeadPremium__c !=null){
                  System.debug('ok 5');
                  cededPremimum =  (Math.roundToLong(mapIdSecSections.get(req.Section__c).TotalEPI__c) * (req.PerHeadPremium__c));
              }
              //PerHeadVariable
              else if (req.MinPerHeadAmount__c !=null){
                    System.debug('ok 6');
                    cededPremimum =  (Math.roundToLong(mapIdSecSections.get(req.Section__c).TotalEPI__c) * (req.MinPerHeadAmount__c));
              }
              System.debug('total EPI beforeupdate == ' + mapIdSecSections.get(req.Section__c).TotalEPI__c);
              System.debug('PerHeadPremium__c beforeupdate == ' + req.PerHeadPremium__c);
              System.debug('cededPremimum beforeupdate == ' + cededPremimum);
              System.debug('expectedMDP beforeupdate == ' + expectedMDP);
              System.debug('expectedMP beforeupdate == ' + expectedMP);
              System.debug('expectedDP beforeupdate == ' + expectedDP);
              
            
              Decimal mdp = cededPremimum * (expectedMDP/100);
              Decimal expDP = cededPremimum * (expectedDP/100);
              Decimal expMP = cededPremimum * (expectedMP/100);
              
              System.debug('mdp beforeupdate == ' + mdp);
              System.debug('expDP beforeupdate == ' + expDP);
              System.debug('expMP beforeupdate == ' + expMP);
              
              Decimal mdpDiv = Math.roundToLong(mdp);
              Decimal expDPDiv = Math.roundToLong(expDP);
              Decimal expMPDiv = Math.roundToLong(expMP);
              
              
              System.debug('mdpround beforeupdate == ' + mdpDiv);
              System.debug('expDPround beforeupdate == ' + expDPDiv);
              System.debug('expMPDround beforeupdate == ' + expMPDiv);
              
              req.CededPremium__c = cededPremimum;
              req.MDP__c = mdpDiv;
              req.DepoPremium__c =  expDPDiv;
              req.MinPremium__c =  expMPDiv;
              
              
              System.debug('req.MDP__c beforeupdate == ' + req.MDP__c);
              System.debug(' req.DepoPremium__c  beforeupdate == ' +  req.DepoPremium__c );
              System.debug(' req.MinPremium__c beforeupdate == ' +  req.MinPremium__c);
          
          //RRA - Ticket 2248 - 30122024
          } else if (strGroup == '2'){
            //Surplus + (FlatCommission or VariableCommission or RiskPremiumBasis)
            if(typeOfTreaty == '4' && (typeOfQuote == '5' || typeOfQuote == '6' || typeOfQuote == '9')){
                Decimal totalEPI = mapIdSecSections.get(req.Section__c).TotalEPI__c != null ? mapIdSecSections.get(req.Section__c).TotalEPI__c : 0;
                cededPremimum = totalEPI;
                req.CededPremium__c = cededPremimum;
            }//(QS or AXA XL QS or Surplus) + PerHead
            else if((typeOfTreaty == '3' || typeOfTreaty == '4' || typeOfTreaty == '5') && typeOfQuote == '7'){ 
                Decimal totalEPI = mapIdSecSections.get(req.Section__c).TotalEPI__c != null ? mapIdSecSections.get(req.Section__c).TotalEPI__c : 0;
                cededPremimum = totalEPI;
                req.CededPremium__c = cededPremimum;
            }
             //QS or AXA XL QS + (FlatCommission or VariableCommission or RiskPremiumBasis)
             else if((typeOfTreaty == '3' || typeOfTreaty == '5') && (typeOfQuote == '5' || typeOfQuote == '6' || typeOfQuote == '9')){
                Decimal totalEPI = mapIdSecSections.get(req.Section__c).TotalEPI__c != null ? mapIdSecSections.get(req.Section__c).TotalEPI__c : 0;
                Decimal cessionPerc = mapIdSecSections.get(req.Section__c).Cession_Perc__c != null ? mapIdSecSections.get(req.Section__c).Cession_Perc__c : 0;
                cededPremimum = totalEPI * (cessionPerc / 100);
                req.CededPremium__c = cededPremimum;
            }
          }      
        }

        if(Request__c.SObjectType.getDescribe().isUpdateable()){
            update lstRequest;
        }
       
       }
       System.debug('lstRequest afterupdate == ' + lstRequest);
    }
}