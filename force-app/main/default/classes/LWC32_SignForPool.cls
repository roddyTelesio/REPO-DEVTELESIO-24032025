public with sharing class LWC32_SignForPool {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Class for lwc32SignForPool
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 08-JUN-2020  SAU    1.0     Initial Version
-- 18-AUG-2020  SAU    1.2     Retrieve Written share
-- 01-DEC-2020  NBI    1.3     Allow signature to Deputy CEO
-- 02-APR-2021  MBE    1.4     W-0938 - Mettre en CC la BAL de la PCC
-- 22-APR-2021  MBE    1.5     W-0929 - Transversal - Respond on behalf et pages de réponses réassureur - affichage champs
--------------------------------------------------------------------------------------
**************************************************************************************/

    /**
    * @description Method to send Email for validation to Users
    * @param List <Request__c> lstRequests
    * @param List <User> lstSelectedValidators
    * @param String comment
    * @param String requestLink
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static string getProgramName(Id programId){
        Program__c program = [SELECT Name FROM Program__c WHERE Id =: programId];
        return program.Name;
    }

    @AuraEnabled
    public static Map<String, Object> getDocuments(Id programId) {
        Set<Id> setContentDocumentId = new Set<Id>();
        Map<Id, String> mapDocThemisDateByContentVersionId = new Map<Id, String>();// RRA - ticket 1089 - 0802023
        Map<Id, ContentVersion> mapContentVersionByDocumentId = new Map<Id, ContentVersion>();
        Map<String, Object> mapResults = new Map<String, Object>();

        for (ContentDocumentLink contentDocLink : [SELECT Id, ContentDocumentId
                                                    FROM ContentDocumentLink
                                                    WHERE LinkedEntityId = :programId]){
            setContentDocumentId.add(contentDocLink.ContentDocumentId);
        }
        System.debug('setContentDocumentId =='+ setContentDocumentId);
        
        // RRA - ticket 1089 - 0802023
        List<ContentVersion> lstContentVersion = [
                SELECT Id, ToLabel(Phase__c), Title, ToLabel(GroupType__c), ToLabel(DocumentType__c), DocumentID__c, IsExternal__c, ContentDocumentId, LastModifiedDate, Tech_NumberPhase__c, VersionData, FromThemis__c, Version__c
                FROM ContentVersion
                WHERE ContentDocumentId IN :setContentDocumentId
                AND GroupType__c = '1'
                ORDER BY Tech_NumberPhase__c, LastModifiedDate DESC
        ];

        for(ContentVersion version : lstContentVersion){
            ContentVersion contentVersionMap = new ContentVersion();
            if(mapContentVersionByDocumentId.containsKey(version.ContentDocumentId)){
                contentVersionMap = mapContentVersionByDocumentId.get(version.ContentDocumentId);
                if(Integer.valueOf(version.VersionNumber) > Integer.valueOf(contentVersionMap.VersionNumber)){
                    mapContentVersionByDocumentId.put(version.ContentDocumentId, version);
                }
            }
            else{
                mapContentVersionByDocumentId.put(version.ContentDocumentId, version);
            }
            // RRA - ticket 1089 - 0802023
            if(!mapDocThemisDateByContentVersionId.containsKey(version.Id)){ 
                mapDocThemisDateByContentVersionId.put(version.Id, version.LastModifiedDate.format('YYYY-MM-dd hh:mm:ss'));
                mapDocThemisDateByContentVersionId.put(version.Id, version.LastModifiedDate.format('M/d/YYYY h:mm:ss'));
          }
        }
        
        System.debug('mapContentVersionByDocumentId =='+ mapContentVersionByDocumentId);
        System.debug('mapDocThemisDateByContentVersionId =='+ mapDocThemisDateByContentVersionId);

        List<ContentVersion> lstContentVersions = mapContentVersionByDocumentId.values();
        mapResults.put('mapDocThemisDateByContentVersionId', mapDocThemisDateByContentVersionId);// RRA - ticket 1089 - 0802023
        mapResults.put('lstContentVersion', lstContentVersion);// RRA - ticket 1089 - 0802023
        System.debug('mapResults =='+ mapResults);
        
        return mapResults;
    }


    /**
    * @description Method to get details of Lead requests of Program and Pool
    * @param Id programId
    * @param Id poolId
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static   Map<String, Object> getLeadRequestDetails(Id programId, Id poolId){
        Map<Id, Map<String,Object>> mapResults = new Map<Id, Map<String,Object>>();
        String recordTypeNameLead = AP_Constant.reqRTLead;
        List <String> lstRecordTypeNameLead = recordTypeNameLead.split('-');
        String recordTypeNameSigning = AP_Constant.reqRTSigning;
        List <String> lstRecordTypeNameSigning = recordTypeNameSigning.split('-');
        List<Id> lstTreatyIds = new List <Id>();
        List<Request__c> lstLeadReqs = new List<Request__c>();
        Map<String, Request__c> mapTreatyIdToSigningReq = new Map<String, Request__c>();
        Set<Id> setChildRequestId = new Set<Id>();
        List<Request__c> lstRequestAll = new List<Request__c>();

        List<OptionWrapper> lstTreaties = new List<OptionWrapper>();
        List<Request__c> lstRequestBrokers = new List<Request__c>();
        Map<String, Object> mapRequestData = new Map<String, Object>();
        Set<Id> setTreatyId = new Set<Id>();
        Set<Id> setSectionId = new Set<Id>();
        Map<String, List<Request__c>> mapSectionRequestByTreatyId = new Map<String, List<Request__c>>();
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
        String reqQuoteRecordTypeId = mapRecTypeId.get(AP_Constant.reqRTQuote);
        String reqLeadRecordTypeId = mapRecTypeId.get(AP_Constant.reqRTLead);
        String reqPlacementRecordTypeId = mapRecTypeId.get(AP_Constant.reqRTPlacement);
        List<String> lstRequestFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjectRequest);
        String strRequestFields = String.join(lstRequestFields , ', ');
        Map<String, Request__c> mapParentRequestByTreatyId = new Map<String, Request__c>(); //for lead
        List<Request__c> lstParentRequest = new List<Request__c>(); //for lead
        List<Request__c> lstRequestForPool = new List<Request__c>(); //for lead
        Map<Id, Request__c> mapParentLeadRequestByTreatyId = new Map<Id, Request__c>(); //for placement
        Map<Id,Decimal> mapChildRequestIdToWrittenShare = new Map <Id, Decimal>();
        Set<String> setIdPool = new Set<String>();
        List<Id> lstUserGroupIds = new List<Id>();
        Set<Id> setIdUserAssigned = new Set<Id>();
        //RRA - Ticket 2239 - 03/03/2025
        Map<String, Decimal> mapCurrencyFxRate = new Map<String, Decimal>(); 
        Program__c program = new Program__c (); 
        List<CededWrapper> lstCededPremiumOtherEUR = new List<CededWrapper>();
        List<TotalCededWrapper> lstCededPremiumTotalOtherEUR = new List<TotalCededWrapper>();
        Decimal totalCededPremiumOther = 0;
        Decimal totalCededPremiumEUR = 0;
        Integer totalCededPremium = 0;
        Map<String, Decimal> mapgetPlacemetShareFromCurrency = new Map<String, Decimal>(); 
        List<Decimal> lstGetCededPremium = new List<Decimal>();
        List<String> lstAvailableCurrency = new  List<String> ();
        List<String> lstAvailableAllCurrency = new  List<String> ();

        //RRA - ticket 2225 - 19122024
        //get Pool associated to User who is connected

       User usr = [SELECT Id, UserRole.DeveloperName  FROM User  WHERE Id =: UserInfo.getUserId()];
        System.debug('usr == ' + usr);
      if (usr.UserRole.DeveloperName == 'Head_of_UGP'){
         if(Pool__c.SObjectType.getDescribe().isAccessible() && Schema.SObjectType.Pool__c.fields.AssignedTo__c.isAccessible()){
           List<Pool__c> lstPoolUser = [SELECT Id, AssignedTo__c FROM  Pool__c WHERE AssignedTo__c =:UserInfo.getUserId()];
            if (lstPoolUser.size()>0){
              for (Pool__c pool : lstPoolUser){
                setIdPool.add(pool.Id);
              }
            }
         }
      }else if (usr.UserRole.DeveloperName == 'CM' || usr.UserRole.DeveloperName == 'AM'){
          //get user access on group member Sign for Pool ReadOnly access C.E
         if(GroupMember.SObjectType.getDescribe().isAccessible() && Schema.SObjectType.GroupMember.fields.UserOrGroupId.isAccessible()){
               for(GroupMember groupMemberRecord : [SELECT Id, GroupId, UserOrGroupId FROM GroupMember WHERE Group.DeveloperName = 'Sign_for_Pool_ReadOnly_CE']){
                  lstUserGroupIds.add(groupMemberRecord.UserOrGroupId);
            }
         }
         if (lstUserGroupIds.contains(usr.Id)){
               List<Pool__c> lstPoolUserForAssigner = [SELECT Id, AssignedTo__c FROM  Pool__c WHERE Id =:poolId];
             if (lstPoolUserForAssigner.size()>0){
              for (Pool__c pool : lstPoolUserForAssigner){
                 setIdUserAssigned.add(pool.AssignedTo__c);
              }
             }
         }

         if (setIdUserAssigned.size()>0){
            List<Pool__c> lstPoolUser = [SELECT Id, AssignedTo__c FROM  Pool__c WHERE AssignedTo__c IN:setIdUserAssigned];
             if (lstPoolUser.size()>0){
              for (Pool__c pool : lstPoolUser){
                setIdPool.add(pool.Id);
              }
            }
         }
      }
        System.debug('lstUserGroupIds == ' + lstUserGroupIds);
        System.debug('setIdUserAssigned == ' + setIdUserAssigned);
        System.debug('setIdPool == ' + setIdPool);
        //get all treaties for pool
        if (setIdPool.size()>0){
           if(PoolTreatySection__c.SObjectType.getDescribe().isAccessible() && Schema.SObjectType.PoolTreatySection__c.fields.Treaty__c.isAccessible()){
               for(PoolTreatySection__c treaty : [ SELECT Treaty__c
                                              FROM PoolTreatySection__c
                                              WHERE Treaty__r.Program__c =: programId
                                              AND Pool__c IN:setIdPool //RRA - ticekt 1873 - 05082024
                                              AND TreatyIsSelected__c = TRUE]){
              lstTreatyIds.add(treaty.Treaty__c );
            }
           } 
        }

        //get info for only pool
        //RRA - ticket 2225 - 19122024
        for(Request__c req : [ SELECT  Id,
                                        Name,
                                        Treaty__c,
                                        Treaty__r.Name,
                                        Section__c,
                                        WrittenShare__c,
                                        SignedShare__c,
                                        TECH_PoolName__c,
                                        ExpectedResponseDate__c,
                                        Accept__c,
                                        Program__c,
                                        Reinsurer__c,
                                        Reinsurer__r.Name,
                                        Broker__c,
                                        Broker__r.Name,
                                        TECH_PhaseType__c,
                                        TECH_TreatyBrokerReinsurer__c,//RRA - ticket 2244 - 09012025
                                        Program__r.PrincipalCedingCompany__c,
                                        Program__r.UwYear__c,
                                        Program__r.TECH_StageName__c,
                                        Pool__c,
                                        RecordType.DeveloperName, TECH_BrokerName__c, TECH_ReinsurerName__c
                                FROM Request__c
                                WHERE Program__c =: programId
                                AND Treaty__c IN: lstTreatyIds
                                AND Pool__c IN:setIdPool
                                AND LastVersionSent__c = TRUE 
                                AND LastVersionAnswered__c = TRUE
                                AND ( RecordType.DeveloperName =: lstRecordTypeNameLead[1]
                                     OR RecordType.DeveloperName =: lstRecordTypeNameSigning[1] )]){

         if(req.RecordType.DeveloperName ==  lstRecordTypeNameSigning[1]){ 
                lstRequestForPool.add(req);
            }
        }

         //get info Program
        //RRA - ticket 2239 - 03/03/2025
         if (programId != null){
          if(Program__c.SObjectType.getDescribe().isAccessible() && Schema.SObjectType.Program__c.fields.UwYear__c.isAccessible()){
             program = [SELECT Id, UwYear__c FROM Program__c WHERE Id = :programId];  //RRA - ticket 0585 - 13032023   
          }
        }

         //get info fxRate
        //RRA - ticket 2239 - 03/03/2025
        if(FXRate__c.SObjectType.getDescribe().isAccessible() && Schema.SObjectType.FXRate__c.fields.Currency__c.isAccessible()){
            for(FXRate__c fxRate : [SELECT Id, Currency__c, FX_Rate__c FROM FXRate__c WHERE UW_Year__c = :program.UwYear__c]){
                if(!mapCurrencyFxRate.containsKey(fxRate.Currency__c)){
                    mapCurrencyFxRate.put(fxRate.Currency__c, fxRate.FX_Rate__c);
                }
            }
        }
         

        //get info BrokerReinsurer
        //RRA - ticket 2239 - 03/03/2025
        /*for(Request__c req : [ SELECT  Id,
                                      Name,
                                      Treaty__c,
                                      Section__c,
                                      toLabel (Section__r.Currency__c),
                                      Treaty__r.TypeofTreaty__c,
                                      CededPremium__c,
                                      Program__c,
                                      Treaty__r.PlacementShare_Perc__c,
                                      Treaty__r.CessionShare__c
                                FROM Request__c
                                WHERE Program__c =: programId
                                AND Treaty__c IN: lstTreatyIds
                                AND Pool__c = NULL
                                AND CededPremium__c != NULL
                                AND LastVersionSent__c = TRUE 
                                AND LastVersionAnswered__c = TRUE]){

         if(req.RecordType.DeveloperName ==  'Lead'){ 
                lstRequestForBroReins.add(req);
            }
        }*/

        // Retrieve the list CededPremium__c without duplication 
            List<AggregateResult> lstRequestCededPremium = [SELECT 
                                                            Section__c,
                                                            Treaty__c,
                                                            Treaty__r.WebXLReference__c, 
                                                            Section__r.SectionNumber__c,
                                                            max(CededPremium__c) maxCededPremium, 
                                                            Section__r.QuoteType__c quoteType,
                                                            max(Section__r.Cession_Perc__c) cessionPerc, 
                                                            max (Treaty__r.PlacementShare_Perc__c) placementShare,  
                                                            max(Section__r.TECH_CessionShare__c) cessionShare, 
                                                            Treaty__r.TypeofTreaty__c typeTreaty, 
                                                            Section__r.Currency__c currency  
                                                            FROM Request__c 
                                                            WHERE Program__c =: programId 
                                                            AND  RecordType.Name = 'Lead Request'  
                                                            AND ((LastVersionSent__c = TRUE AND LastVersionAnswered__c = TRUE) OR (ReinsurerStatus__c ='Setup')) 
                                                            AND CededPremium__c!=null 
                                                            GROUP BY Section__c, Treaty__c, Treaty__r.WebXLReference__c, Section__r.SectionNumber__c, Treaty__r.TypeofTreaty__c, Section__r.QuoteType__c,Section__r.Currency__c
                                                            ORDER BY Treaty__r.WebXLReference__c];
    
            System.debug('lstRequestCededPremium==' + lstRequestCededPremium);
  
        if(lstRequestCededPremium.size()>0){
          String typeOfTreatie;
          Boolean isTypeOfTreatyQS = false;
          Decimal cededOther = 0;
          Decimal cededEUR = 0;
          Boolean isOtherCurrency = false;
          for (AggregateResult rqCededPre : lstRequestCededPremium){
            typeOfTreatie = (String)rqCededPre.get('typeTreaty');
             //Create map between CededPremium and Treaty__c.PlacementShare to retrieve the placement Share attached)
            if (typeOfTreatie == '5'){ 
                isTypeOfTreatyQS = true;
                mapgetPlacemetShareFromCurrency.put((Id)(rqCededPre.get('Treaty__c')) + '_' + (Id)(rqCededPre.get('Section__c')), (Decimal)(rqCededPre.get('cessionShare'))); 
            }else{
                mapgetPlacemetShareFromCurrency.put((Id)(rqCededPre.get('Treaty__c')) + '_' + (Id)(rqCededPre.get('Section__c')), (Decimal)(rqCededPre.get('placementShare'))); 
            }
            if ((String)(rqCededPre.get('currency')) != '9052'){
              isOtherCurrency = true;
              cededOther = (isTypeOfTreatyQS) ? (Decimal)(rqCededPre.get('maxCededPremium')) : (Decimal)(rqCededPre.get('maxCededPremium'));
              cededEUR = (isTypeOfTreatyQS) ? ((Decimal)(rqCededPre.get('maxCededPremium')) / mapCurrencyFxRate.get((String)(rqCededPre.get('currency')))) : ((Decimal)(rqCededPre.get('maxCededPremium')) / mapCurrencyFxRate.get((String)(rqCededPre.get('currency')))) ;
              totalCededPremiumOther = (isTypeOfTreatyQS) ? totalCededPremiumOther + (Decimal)(rqCededPre.get('maxCededPremium')) * (mapgetPlacemetShareFromCurrency.get((Id)(rqCededPre.get('Treaty__c')) + '_' + (Id)(rqCededPre.get('Section__c')))/100) : totalCededPremiumOther + (Decimal)(rqCededPre.get('maxCededPremium')) * (mapgetPlacemetShareFromCurrency.get((Id)(rqCededPre.get('Treaty__c')) + '_' + (Id)(rqCededPre.get('Section__c')))/100); 
              totalCededPremiumEUR = (isTypeOfTreatyQS) ? totalCededPremiumEUR + ((Decimal)(rqCededPre.get('maxCededPremium')) / mapCurrencyFxRate.get((String)(rqCededPre.get('currency')))) * (mapgetPlacemetShareFromCurrency.get((Id)(rqCededPre.get('Treaty__c')) + '_' + (Id)(rqCededPre.get('Section__c')))/100) : totalCededPremiumEUR + ((Decimal)(rqCededPre.get('maxCededPremium')) / mapCurrencyFxRate.get((String)(rqCededPre.get('currency')))) * (mapgetPlacemetShareFromCurrency.get((Id)(rqCededPre.get('Treaty__c')) + '_' + (Id)(rqCededPre.get('Section__c')))/100);
              lstCededPremiumOtherEUR.add(new CededWrapper(Math.roundToLong(cededOther), Math.roundToLong(cededEUR), (String)(rqCededPre.get('currency')), (String)(rqCededPre.get('Treaty__c')) + '_' + (String)(rqCededPre.get('Section__c'))));             
              lstAvailableCurrency.add((String)(rqCededPre.get('currency')));
            }else{
              cededEUR = (isTypeOfTreatyQS) ? ((Decimal)(rqCededPre.get('maxCededPremium')) / mapCurrencyFxRate.get((String)(rqCededPre.get('currency')))) : ((Decimal)(rqCededPre.get('maxCededPremium')) / mapCurrencyFxRate.get((String)(rqCededPre.get('currency'))));
              totalCededPremiumEUR = (isTypeOfTreatyQS) ? totalCededPremiumEUR + ((Decimal)(rqCededPre.get('maxCededPremium')) / mapCurrencyFxRate.get((String)(rqCededPre.get('currency')))) * (mapgetPlacemetShareFromCurrency.get((Id)(rqCededPre.get('Treaty__c')) + '_' + (Id)(rqCededPre.get('Section__c')))/100) : totalCededPremiumEUR + ((Decimal)(rqCededPre.get('maxCededPremium')) / mapCurrencyFxRate.get((String)(rqCededPre.get('currency')))) * (mapgetPlacemetShareFromCurrency.get((Id)(rqCededPre.get('Treaty__c')) + '_' + (Id)(rqCededPre.get('Section__c')))/100);
              lstCededPremiumOtherEUR.add(new CededWrapper(0, Math.roundToLong(cededEUR), (String)(rqCededPre.get('currency')), (String)(rqCededPre.get('Treaty__c')) + '_' + (String)(rqCededPre.get('Section__c'))));
            }  
            lstAvailableAllCurrency.add((String)(rqCededPre.get('currency')));
          }
          if (isOtherCurrency){
             lstCededPremiumTotalOtherEUR.add(new TotalCededWrapper (Math.roundToLong(totalCededPremiumOther), Math.roundToLong(totalCededPremiumEUR)));
          }else{
            lstCededPremiumTotalOtherEUR.add(new TotalCededWrapper (0, Math.roundToLong(totalCededPremiumEUR)));
          }
        }

        System.debug('lstCededPremiumOtherEUR = ' + lstCededPremiumOtherEUR);
        System.debug('lstCededPremiumTotalOtherEUR = ' + lstCededPremiumTotalOtherEUR);
        System.debug('totalCededPremiumOther = ' + totalCededPremiumOther);
        System.debug('totalCededPremiumEUR = ' + totalCededPremiumEUR);


        
        //get all lead request of pool
        //RRA - ticket 2225 - 19122024
        if (!Test.isRunningTest()){
            for(Request__c req : [ SELECT  Id,
                                        Name,
                                        Treaty__c,
                                        Treaty__r.Name,
                                        Section__c,
                                        WrittenShare__c,
                                        SignedShare__c,
                                        TECH_PoolName__c,
                                        ExpectedResponseDate__c,
                                        Accept__c,
                                        Program__c,
                                        Reinsurer__c,
                                        Reinsurer__r.Name,
                                        Broker__c,
                                        Broker__r.Name,
                                        TECH_PhaseType__c,
                                        TECH_TreatyBrokerReinsurer__c,//RRA - ticket 2244 - 09012025
                                        Program__r.PrincipalCedingCompany__c,
                                        Program__r.UwYear__c,
                                        Program__r.TECH_StageName__c,
                                        Pool__c,
                                        RecordType.DeveloperName, TECH_BrokerName__c, TECH_ReinsurerName__c
                                FROM Request__c
                                WHERE Program__c =: programId
                                AND Treaty__c IN: lstTreatyIds
                                AND LastVersionSent__c = TRUE 
                                AND LastVersionAnswered__c = TRUE
                                AND ( RecordType.DeveloperName =: lstRecordTypeNameLead[1]
                                     OR RecordType.DeveloperName =: lstRecordTypeNameSigning[1] )]){

            if(req.RecordType.DeveloperName ==  lstRecordTypeNameLead[1]){
                lstLeadReqs.add(req);
            }
            else if(req.RecordType.DeveloperName ==  lstRecordTypeNameSigning[1]){ // SR for selected pools
                mapTreatyIdToSigningReq.put(req.Treaty__c + '_' + req.Pool__c, req); //RRA - ticket 2225 - 19122024
            }
        }
      }else{
          for(Request__c req : [ SELECT  Id,
                                        Name,
                                        Treaty__c,
                                        Treaty__r.Name,
                                        Section__c,
                                        WrittenShare__c,
                                        SignedShare__c,
                                        TECH_PoolName__c,
                                        ExpectedResponseDate__c,
                                        Accept__c,
                                        Program__c,
                                        Reinsurer__c,
                                        Reinsurer__r.Name,
                                        Broker__c,
                                        Broker__r.Name,
                                        TECH_PhaseType__c,
                                        TECH_TreatyBrokerReinsurer__c,//RRA - ticket 2244 - 09012025
                                        Program__r.PrincipalCedingCompany__c,
                                        Program__r.UwYear__c,
                                        Program__r.TECH_StageName__c,
                                        Pool__c,
                                        RecordType.DeveloperName, TECH_BrokerName__c, TECH_ReinsurerName__c
                                FROM Request__c
                                WHERE Program__c =: programId
                                AND LastVersionSent__c = TRUE 
                                AND LastVersionAnswered__c = TRUE
                                AND ( RecordType.DeveloperName =: lstRecordTypeNameLead[1]
                                     OR RecordType.DeveloperName =: lstRecordTypeNameSigning[1] )]){

            if(req.RecordType.DeveloperName ==  lstRecordTypeNameLead[1]){
                lstLeadReqs.add(req);
            }
            else if(req.RecordType.DeveloperName ==  lstRecordTypeNameSigning[1]){ // SR for selected pools
                mapTreatyIdToSigningReq.put(req.Treaty__c + '_' + req.Pool__c, req); //RRA - ticket 2225 - 19122024
            }
        }
      }
        
        

        System.debug('lstLeadReqs = ' + lstLeadReqs);
        System.debug('mapTreatyIdToSigningReq = ' + mapTreatyIdToSigningReq);
                                            
        // for each lead request
        for(Request__c requestById : lstLeadReqs){
            Id reinsurerId = requestById.Reinsurer__c;
            Id brokerId = requestById.Broker__c;
            String requestPhaseType = requestById.TECH_PhaseType__c;
            Id treatyId = requestById.Treaty__c;

            if(requestPhaseType == '3' || requestPhaseType == '4'){

                //for(Request__c requestParent : lstLeadReqs){
                    if(requestById.Reinsurer__c == reinsurerId && requestById.Broker__c == brokerId ){
                        mapParentRequestByTreatyId.put(requestById.Treaty__c + '_' + requestById.Section__c + '_'+ requestById.Pool__c, requestById); //RRA - ticket 2225 - 19122024
                    }
                //}
                
                for(LeadRequestSelection__c leadRequestSelection : [SELECT Id, Name, LeadRequestChild__c,LeadRequestParent__r.WrittenShare__c
                                                                FROM LeadRequestSelection__c
                                                                WHERE LeadRequestParent__c IN :lstLeadReqs]){
                    setChildRequestId.add(leadRequestSelection.LeadRequestChild__c);
                    mapChildRequestIdToWrittenShare.put(leadRequestSelection.LeadRequestChild__c,leadRequestSelection.LeadRequestParent__r.WrittenShare__c);
                }
            }
        }
        // RRA - 1074
        String queryLeadRequest = 'select Id, Treaty__r.Name,Treaty__r.Layer__c, Program__r.PrincipalCedingCompany__c, Program__r.UwYear__c, Program__r.TECH_StageName__c'
                    + ', Broker__r.Name, TECH_BrokerName__c, TECH_ReinsurerName__c, Program__r.LTA__c, Section__r.TECH_TypeofTreaty__c, Section__r.QuoteType__c, Section__r.SectionNumber__c'
                    + ', Section__r.Cession_Perc__c, Section__r.Name, Section__r.Currency__c, Section__r.Unlimited__c, Treaty__r.TypeofTreaty__c, Treaty__r.LossDeposit__c,Treaty__r.PlacementShare_Perc__c'
                    + ', Section__r.EventLimit__c, Section__r.RetentionLine__c, Section__r.TAL__c, Section__r.Retention__c, Section__r.CessionAmount__c, Program__r.Name, Program__r.LossDeposit__c, Program__r.InceptionDate__c, Program__r.Expirydate__c'
                    + ', Section__r.RetentionAmount__c, Section__r.TotalEPI__c, Section__r.Nature__c, Section__r.LineAmount__c, Section__r.CededLines__c, Section__r.CededPremium__c'
                    + ', Section__r.Capacity__c, Section__r.Limit__c, Section__r.Deductible__c, Section__r.AAD__c, Section__r.AAL__c, TECH_SectionName__c'
                    + ', Section__r.LimitPercent__c, Section__r.DeductiblePercent__c, Section__r.MaxLimitAmount__c, Section__r.MinLimitAmount__c, Section__r.ExpectedMDP__c, Section__r.ExpectedDP__c, Section__r.ExpectedMP__c, Section__r.Sort_SectionNumber__c, '
                    + strRequestFields
                    + ' from Request__c where (Id IN :setChildRequestId AND Program__c = :programId AND Reinsurer__c = null AND RecordTypeId = :reqLeadRecordTypeId AND (LastVersionSent__c = TRUE AND LastVersionAnswered__c = TRUE) ) ORDER BY Treaty__r.Name, Section__r.Sort_SectionNumber__c';  //RRA - ticket 2225 - 19122024

        lstRequestAll = Database.query(queryLeadRequest);

        Set<Id> setAvailableSectionId = new Set<Id>();

        for(Request__c request : lstRequestAll){
            lstTreaties.add(new OptionWrapper(request.Treaty__r.Name, request.Treaty__c + '_' + request.Section__c + '_' + request.Pool__c)); //RRA - ticket 2225 - 19122024
            lstRequestBrokers.add(request);
            setTreatyId.add(request.Treaty__c);
            setSectionId.add(request.Section__c);

            List<Request__c> lstSectionRequests = new List<Request__c>();

            if(!setAvailableSectionId.contains(request.Section__c)){
                setAvailableSectionId.add(request.Section__c);
                if(mapSectionRequestByTreatyId.containsKey(request.Treaty__c)){
                    lstSectionRequests = mapSectionRequestByTreatyId.get(request.Treaty__c + '_' + request.Section__c + '_' + request.Pool__c); //RRA - ticket 2225 - 19122024
                    lstSectionRequests.add(request);
                }
                else{
                    lstSectionRequests.add(request);
                }
                mapSectionRequestByTreatyId.put(request.Treaty__c + '_' + request.Section__c + '_' + request.Pool__c , lstSectionRequests); //RRA - ticket 2225 - 19122024

            }
        }

        Map<Id, String> mapReinstatementBySectionId = new Map<Id, String>();
        List<Reinstatement__c> lstReinstatements = [SELECT Id, Order__c, Percentage__c, toLabel(Prorata__c), Section__c
                                                    FROM Reinstatement__c
                                                    WHERE Section__c IN :setSectionId];

        for(Reinstatement__c reinstatement : lstReinstatements){
            String reinstatementStr = null;
            Decimal percentage = 0;
            String prorata = '';
            if(reinstatement.Percentage__c != null){
                percentage = reinstatement.Percentage__c;
            }
            else{
                percentage = 0;
            }
            if(reinstatement.Prorata__c != null){
                prorata = reinstatement.Prorata__c;
            }
            else{
                prorata = '';
            }
            if(mapReinstatementBySectionId.containsKey(reinstatement.Section__c)){
                reinstatementStr = mapReinstatementBySectionId.get(reinstatement.Section__c);
                reinstatementStr += ' / 1 @ ' + percentage + '% - ' + prorata;
            }
            else{
                reinstatementStr = '1 @ ' + percentage + '% - ' + prorata;
            }
            mapReinstatementBySectionId.put(reinstatement.Section__c, reinstatementStr);
        }

        List<Request__c> lstRequestById = new  List<Request__c> ();
        List<Request__c> lstRequestByDataSigning = new  List<Request__c> ();
        List<String> lstRequestPhaseType = new  List<String> ();
        List<String> lstRequestId = new  List<String> ();

        // RRA - 1074 et 1076
        //RRA - ticket 2225 - 19122024
        List<AggregateResult> lstTreatyNonDuplicate = [SELECT Id, Treaty__c treaty, Pool__c pool, Treaty__r.Name, max(SignedShare__c) signeShare, max (WrittenShare__c)  writtenShare FROM Request__c WHERE program__c=: programId AND LastVersionSent__c = TRUE AND LastVersionAnswered__c = TRUE   AND SignedShare__c!=null AND Pool__c != null AND ( RecordType.DeveloperName =: lstRecordTypeNameLead[1] OR RecordType.DeveloperName =: lstRecordTypeNameSigning[1] ) GROUP BY Id, Treaty__c, Pool__c, Treaty__r.Name ORDER By  Treaty__r.Name ]; //RRA - ticket 1873 - 05082024
        
        for(Request__c requestById : lstLeadReqs){
           // Id treatyID = requestById.Treaty__c;
            //System.debug('treatyID = ' + treatyID);
            //lstRequestId.add(requestById.Id);
            String requestPhaseType = requestById.TECH_PhaseType__c;
            lstRequestPhaseType.add(requestPhaseType);
           // if(mapTreatyIdToSigningReq.containsKey(treatyID)){
                //mapRequestData.put('SigningRequest', mapTreatyIdToSigningReq.get(treatyID));
               // lstRequestByDataSigning.add(mapTreatyIdToSigningReq.get(treatyID));
            //}
        }
       

        for(AggregateResult requestById : lstTreatyNonDuplicate){
            //Id treatyID = (String)(requestById.get('treaty'));
            String key = (String)(requestById.get('treaty')) + '_' + (String)(requestById.get('pool'));
            if(mapTreatyIdToSigningReq.containsKey(key)){
                //mapRequestData.put('SigningRequest', mapTreatyIdToSigningReq.get(treatyID));
                lstRequestByDataSigning.add(mapTreatyIdToSigningReq.get(key));
            }
        }
             // RRA - 1074 
            mapRequestData.put('SigningRequestForPool', lstRequestForPool);
            //RRA - Ticket 2239 - 04/03/2025
            mapRequestData.put('lstCededPremiumOtherEUR', lstCededPremiumOtherEUR); 
            mapRequestData.put('lstCededPremiumTotalOtherEUR', lstCededPremiumTotalOtherEUR); 
            mapRequestData.put('totalCededPremiumOther', totalCededPremiumOther);
            mapRequestData.put('totalCededPremiumEUR', totalCededPremiumEUR);
            mapRequestData.put('lstAvailableCurrency', lstAvailableCurrency);
             mapRequestData.put('lstAvailableAllCurrency', lstAvailableAllCurrency);  
            //mapRequestData.put('SigningRequestForBrokerRein', lstRequestForBroReins);
            mapRequestData.put('SigningRequest', lstRequestByDataSigning);
            mapRequestData.put('requestPhaseType', lstRequestPhaseType); 
            mapRequestData.put('selectedRequestDetail', lstRequestById);
            mapRequestData.put('lstTreaties', lstTreaties);
            mapRequestData.put('mapSectionRequestByTreatyId', mapSectionRequestByTreatyId);
            mapRequestData.put('mapReinstatementBySectionId', mapReinstatementBySectionId);
            mapRequestData.put('lstRequestBrokers', lstRequestBrokers);
            mapRequestData.put('lstRequestAll', lstRequestAll);
            mapRequestData.put('mapParentRequestByTreatyId', mapParentRequestByTreatyId);
            mapRequestData.put('lstParentLeadRequest', lstLeadReqs);
            mapRequestData.put('mapParentLeadRequestByTreatyIdPlacement', mapParentLeadRequestByTreatyId);
            mapRequestData.put('mapChildRequestIdToWrittenShare',mapChildRequestIdToWrittenShare);
            //mapResults.put(requestById.Id, mapRequestData);
            //lstRequestByDataSigning.add(mapResults);
        //}

        //System.debug(' mapResults= ' + mapResults);
       return mapRequestData; 
    }


    /**
    * @description Method to get details of Lead requests of Program and Pool
    * @param Id programId
    * @param Id poolId
    * @return Map<String, Object>
    */
   /* @AuraEnabled
    public static   Map<String, Object> getLeadRequestDetails(Id programId, Id poolId){
        Map<Id, Map<String,Object>> mapResults = new Map<Id, Map<String,Object>>();
        String recordTypeNameLead = AP_Constant.reqRTLead;
        List <String> lstRecordTypeNameLead = recordTypeNameLead.split('-');
        String recordTypeNameSigning = AP_Constant.reqRTSigning;
        List <String> lstRecordTypeNameSigning = recordTypeNameSigning.split('-');
        List<Id> lstTreatyIds = new List <Id>();
        List<Request__c> lstLeadReqs = new List<Request__c>();
         List<Request__c> lstLeadPlacementReqs = new List<Request__c>();
        Map<String, Request__c> mapTreatyIdToSigningReq = new Map<String, Request__c>();
        Set<Id> setChildRequestId = new Set<Id>();
        Set<Id> setIdReqPlacement = new Set<Id>();
        Set<Id> setIdParentleadreq = new Set<Id>();
        List<Request__c> lstRequestAll = new List<Request__c>();

        List<OptionWrapper> lstTreaties = new List<OptionWrapper>();
        List<Request__c> lstRequestBrokers = new List<Request__c>();
        Map<String, Object> mapRequestData = new Map<String, Object>();
        Set<Id> setTreatyId = new Set<Id>();
        Set<Id> setSectionId = new Set<Id>();
        Map<Id, List<Request__c>> mapSectionRequestByTreatyId = new Map<Id, List<Request__c>>();
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
        String reqQuoteRecordTypeId = mapRecTypeId.get(AP_Constant.reqRTQuote);
        String reqLeadRecordTypeId = mapRecTypeId.get(AP_Constant.reqRTLead);
        String reqPlacementRecordTypeId = mapRecTypeId.get(AP_Constant.reqRTPlacement);
        List<String> lstRequestFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjectRequest);
        String strRequestFields = String.join(lstRequestFields , ', ');
        
        Map<Id, Request__c> mapParentRequestByTreatyId = new Map<Id, Request__c>(); //for lead
        List<Request__c> lstParentRequest = new List<Request__c>(); //for lead
        Map<Id, Request__c> mapParentLeadRequestByTreatyId = new Map<Id, Request__c>(); //for placement
        Map<Id,Decimal> mapChildRequestIdToWrittenShare = new Map <Id, Decimal>();

        //get all treaties for pool
        for(PoolTreatySection__c treaty : [ SELECT Treaty__c
                                            FROM PoolTreatySection__c
                                            WHERE Treaty__r.Program__c =: programId
                                            AND (Pool__c =: poolId OR Pool__c != NULL) //RRA - ticekt 1873 - 05082024
                                            AND TreatyIsSelected__c = TRUE]){
            lstTreatyIds.add(treaty.Treaty__c );
        }

        //get all lead request of pool
        for(Request__c req : [ SELECT  Id,
                                        Name,
                                        Treaty__c,
                                        Treaty__r.Name,
                                        WrittenShare__c,
                                        SignedShare__c,
                                        ExpectedResponseDate__c,
                                        Accept__c,
                                        TECH_PoolName__c,
                                        TECH_RelatedLeadPlacementRequest__c,
                                        TECH_Recovery_RelatedLeadPlacementReq__c,
                                        Program__c,
                                        Reinsurer__c,
                                        Reinsurer__r.Name,
                                        Broker__c,
                                        Broker__r.Name,
                                        TECH_PhaseType__c,
                                        Program__r.PrincipalCedingCompany__c,
                                        Program__r.UwYear__c,
                                        Program__r.TECH_StageName__c,
                                        Pool__c,
                                        RecordType.DeveloperName, TECH_BrokerName__c, TECH_ReinsurerName__c
                                FROM Request__c
                                WHERE Program__c =: programId
                                AND Treaty__c IN: lstTreatyIds
                                AND LastVersionSent__c = TRUE 
                                AND LastVersionAnswered__c = TRUE
                                AND ( RecordType.DeveloperName =: lstRecordTypeNameLead[1]
                                     OR RecordType.DeveloperName =: lstRecordTypeNameSigning[1] )]){

            if(req.RecordType.DeveloperName ==  lstRecordTypeNameLead[1]){
                lstLeadReqs.add(req);
            }
            else if(req.RecordType.DeveloperName ==  lstRecordTypeNameSigning[1]){ // SR for selected pools
                lstLeadPlacementReqs.add(req);
                mapTreatyIdToSigningReq.put(req.Treaty__c + '_' + req.Pool__c, req);
            }
        }

        System.debug('lstLeadPlacementReqs = ' + lstLeadPlacementReqs);
        System.debug('mapTreatyIdToSigningReq = ' + mapTreatyIdToSigningReq);
         System.debug('lstLeadReqs = ' + lstLeadReqs);
                                            
        // for each lead request
        for(Request__c requestParent : lstLeadPlacementReqs){
            Id reinsurerId = requestParent.Reinsurer__c;
            Id brokerId = requestParent.Broker__c;
            String requestPhaseType = requestParent.TECH_PhaseType__c;
            Id treatyId = requestParent.Treaty__c;

            if((requestPhaseType == '6' || requestPhaseType == '4')){
                //for(Request__c requestParent : lstLeadPlacementReqs){
                if(requestParent.Reinsurer__c == reinsurerId && requestParent.Broker__c == brokerId ){
                    mapParentRequestByTreatyId.put(requestParent.Treaty__c, requestParent);
                }
                //}

                if (requestParent.TECH_Recovery_RelatedLeadPlacementReq__c == 'Lead'){
                  setIdParentleadreq.add(requestParent.TECH_RelatedLeadPlacementRequest__c);
                }else if (requestParent.TECH_Recovery_RelatedLeadPlacementReq__c == 'Placement'){
                  setIdReqPlacement.add(requestParent.TECH_RelatedLeadPlacementRequest__c);
                }
                
                /*if (requestParent.TECH_Recovery_RelatedLeadPlacementReq__c == 'Lead'){
                     for(LeadRequestSelection__c leadRequestSelection : [SELECT Id, Name, LeadRequestChild__c,LeadRequestParent__r.WrittenShare__c
                                                                FROM LeadRequestSelection__c
                                                                WHERE LeadRequestParent__c IN :lstLeadReqs]){
                    setChildRequestId.add(leadRequestSelection.LeadRequestChild__c);
                    mapChildRequestIdToWrittenShare.put(leadRequestSelection.LeadRequestChild__c,leadRequestSelection.LeadRequestParent__r.WrittenShare__c);
                  }
                }else if (requestParent.TECH_Recovery_RelatedLeadPlacementReq__c == 'Placement'){
                  setIdReqPlacement.add(requestParent.TECH_RelatedLeadPlacementRequest__c);
                }*/
       /*     }
        }

         System.debug('setIdParentleadreq = ' + setIdParentleadreq);

        if (setIdParentleadreq.size()>0){
            for(LeadRequestSelection__c leadRequestSelection : [SELECT Id, Name, LeadRequestChild__c,LeadRequestParent__r.WrittenShare__c
                                                                FROM LeadRequestSelection__c
                                                                WHERE LeadRequestParent__c IN :setIdParentleadreq]){
             setChildRequestId.add(leadRequestSelection.LeadRequestChild__c);                                                                                                       }
        }

        

          System.debug('setChildRequestId = ' + setChildRequestId);
            System.debug('setIdReqPlacement = ' + setIdReqPlacement);
          Set<Id> setIdAll = new Set<Id>();
          setIdAll.addAll(setChildRequestId);
          setIdAll.addAll(setIdReqPlacement);

           System.debug('setIdAll = ' + setIdAll);
        // RRA - 1074
        String queryLeadRequest = 'select Id, Treaty__r.Name,Treaty__r.Layer__c, Program__r.PrincipalCedingCompany__c, Program__r.UwYear__c, Program__r.TECH_StageName__c'
                    + ', Broker__r.Name, TECH_BrokerName__c, TECH_ReinsurerName__c, Program__r.LTA__c, Section__r.TECH_TypeofTreaty__c, Section__r.QuoteType__c, Section__r.SectionNumber__c'
                    + ', Section__r.Cession_Perc__c, Section__r.Name, Section__r.Currency__c, Section__r.Unlimited__c, Treaty__r.TypeofTreaty__c, Treaty__r.LossDeposit__c,Treaty__r.PlacementShare_Perc__c'
                    + ', Section__r.EventLimit__c, Section__r.RetentionLine__c, Section__r.TAL__c, Section__r.Retention__c, Section__r.CessionAmount__c, Program__r.Name, Program__r.LossDeposit__c, Program__r.InceptionDate__c, Program__r.Expirydate__c'
                    + ', Section__r.RetentionAmount__c, Section__r.TotalEPI__c, Section__r.Nature__c, Section__r.LineAmount__c, Section__r.CededLines__c, Section__r.CededPremium__c'
                    + ', Section__r.Capacity__c, Section__r.Limit__c, Section__r.Deductible__c, Section__r.AAD__c, Section__r.AAL__c, TECH_SectionName__c'
                    + ', Section__r.LimitPercent__c, Section__r.DeductiblePercent__c, Section__r.MaxLimitAmount__c, Section__r.MinLimitAmount__c, Section__r.ExpectedMDP__c, Section__r.ExpectedDP__c, Section__r.ExpectedMP__c, '
                    + strRequestFields
                    + ' from Request__c where Id IN :setChildRequestId AND Program__c =: programId AND OriginalRequest__c = NULL ORDER BY Treaty__r.Name';

        lstRequestAll = Database.query(queryLeadRequest);
         System.debug('lstRequestAll = ' + lstRequestAll);

        Set<Id> setAvailableSectionId = new Set<Id>();

        for(Request__c request : lstRequestAll){
            lstTreaties.add(new OptionWrapper(request.Treaty__r.Name, request.Treaty__c));
            lstRequestBrokers.add(request);
            setTreatyId.add(request.Treaty__c);
            setSectionId.add(request.Section__c);

            List<Request__c> lstSectionRequests = new List<Request__c>();

            if(!setAvailableSectionId.contains(request.Section__c)){
                setAvailableSectionId.add(request.Section__c);
                if(mapSectionRequestByTreatyId.containsKey(request.Treaty__c)){
                    lstSectionRequests = mapSectionRequestByTreatyId.get(request.Treaty__c);
                    lstSectionRequests.add(request);
                }
                else{
                    lstSectionRequests.add(request);
                }
                mapSectionRequestByTreatyId.put(request.Treaty__c + '_' + request.Pool__c, lstSectionRequests);

            }
        }

          System.debug('mapSectionRequestByTreatyId = ' + mapSectionRequestByTreatyId);

        Map<Id, String> mapReinstatementBySectionId = new Map<Id, String>();
        List<Reinstatement__c> lstReinstatements = [SELECT Id, Order__c, Percentage__c, toLabel(Prorata__c), Section__c
                                                    FROM Reinstatement__c
                                                    WHERE Section__c IN :setSectionId];

        for(Reinstatement__c reinstatement : lstReinstatements){
            String reinstatementStr = null;
            Decimal percentage = 0;
            String prorata = '';
            if(reinstatement.Percentage__c != null){
                percentage = reinstatement.Percentage__c;
            }
            else{
                percentage = 0;
            }
            if(reinstatement.Prorata__c != null){
                prorata = reinstatement.Prorata__c;
            }
            else{
                prorata = '';
            }
            if(mapReinstatementBySectionId.containsKey(reinstatement.Section__c)){
                reinstatementStr = mapReinstatementBySectionId.get(reinstatement.Section__c);
                reinstatementStr += ' / 1 @ ' + percentage + '% - ' + prorata;
            }
            else{
                reinstatementStr = '1 @ ' + percentage + '% - ' + prorata;
            }
            mapReinstatementBySectionId.put(reinstatement.Section__c, reinstatementStr);
        }

        List<Request__c> lstRequestById = new  List<Request__c> ();
        List<Request__c> lstRequestByDataSigning = new  List<Request__c> ();
        List<String> lstRequestPhaseType = new  List<String> ();
        List<String> lstRequestId = new  List<String> ();

        // RRA - 1074 et 1076
        List<AggregateResult> lstTreatyNonDuplicate = [SELECT Id, Treaty__c treaty, Pool__c pool, Treaty__r.Name, max(SignedShare__c) signeShare, max (WrittenShare__c)  writtenShare FROM Request__c WHERE program__c=: programId AND LastVersionSent__c = TRUE AND LastVersionAnswered__c = TRUE   AND SignedShare__c!=null AND Pool__c != null AND RecordType.DeveloperName =: lstRecordTypeNameSigning[1] GROUP BY Id, Treaty__c, Pool__c, Treaty__r.Name ORDER By  Treaty__r.Name ]; //RRA - ticket 1873 - 05082024
        System.debug('lstTreatyNonDuplicate = ' + lstTreatyNonDuplicate);
        for(Request__c requestById : lstLeadPlacementReqs){
           // Id treatyID = requestById.Treaty__c;
            //System.debug('treatyID = ' + treatyID);
            //lstRequestId.add(requestById.Id);
            String requestPhaseType = requestById.TECH_PhaseType__c;
            lstRequestPhaseType.add(requestPhaseType);
           // if(mapTreatyIdToSigningReq.containsKey(treatyID)){
                //mapRequestData.put('SigningRequest', mapTreatyIdToSigningReq.get(treatyID));
               // lstRequestByDataSigning.add(mapTreatyIdToSigningReq.get(treatyID));
            //}
        }
       

        for(AggregateResult requestById : lstTreatyNonDuplicate){
           String key = (String)(requestById.get('treaty')) + '_' + (String)(requestById.get('pool'));
            if(mapTreatyIdToSigningReq.containsKey(key)){
                //mapRequestData.put('SigningRequest', mapTreatyIdToSigningReq.get(treatyID));
                lstRequestByDataSigning.add(mapTreatyIdToSigningReq.get(key));
            }
        }
             // RRA - 1074
            mapRequestData.put('SigningRequest', lstRequestByDataSigning);
            mapRequestData.put('requestPhaseType', lstRequestPhaseType); 
            mapRequestData.put('selectedRequestDetail', lstRequestById);
            mapRequestData.put('lstTreaties', lstTreaties);
            mapRequestData.put('mapSectionRequestByTreatyId', mapSectionRequestByTreatyId);
            mapRequestData.put('mapReinstatementBySectionId', mapReinstatementBySectionId);
            mapRequestData.put('lstRequestBrokers', lstRequestBrokers);
            mapRequestData.put('lstRequestAll', lstRequestAll);
            mapRequestData.put('mapParentRequestByTreatyId', mapParentRequestByTreatyId);
            mapRequestData.put('lstParentLeadRequest', lstLeadPlacementReqs);
            mapRequestData.put('mapParentLeadRequestByTreatyIdPlacement', mapParentLeadRequestByTreatyId);
            mapRequestData.put('mapChildRequestIdToWrittenShare',mapChildRequestIdToWrittenShare);
             System.debug('mapRequestData = ' + mapRequestData);
            //mapResults.put(requestById.Id, mapRequestData);
            //lstRequestByDataSigning.add(mapResults);
        //}

        //System.debug(' mapResults= ' + mapResults);
       return mapRequestData; 
    }*/

    /**
    * @description Method to get Signing requests of Program and Pool
    * @param Id programId
    * @param Id poolId
    * @return List <Request__c>
    */
    @AuraEnabled
    public static List <Request__c> getSigningReqDetails(Id poolId, Id programId){
        String recordTypeNameSigning = AP_Constant.reqRTSigning;
        Set<Id> setIdPool = new Set<Id>();
         List<Pool__c> lstPoolUser = [SELECT Id, AssignedTo__c FROM  Pool__c WHERE AssignedTo__c =:UserInfo.getUserId()];
        List <String> lstRecordTypeNameSigning = recordTypeNameSigning.split('-');
        //RRA - ticket 2225 - 20/12/2025 
        if (lstPoolUser.size()>0){
          for (Pool__c pool : lstPoolUser){
            setIdPool.add(pool.Id);
          }
        }

        //RRA - ticket 1761 - 15112023
        List <Request__c> lstReqDetails = [ SELECT Id,
                                                   ReinsurerStatus__c,
                                                   Broker__c,
                                                   Reinsurer__c,
                                                   TECH_ReinsurerName__c,
                                                   TECH_PoolName__c,    //RRA - ticket 2225 - 20/12/2025 
                                                   TECH_BrokerName__c,
                                                   ResponseDate__c,
                                                   SigningRegionalManager__c,
                                                   SigningRegionalManager__r.Name,
                                                   TECH_DateSigned__c,
                                                   Pool__r.Name
                                            FROM Request__c
                                            WHERE (Pool__c =: poolId OR Pool__c IN:setIdPool) //RRA - ticket 1873 - 05082024
                                            AND Program__c =: programId
                                            AND RecordType.DeveloperName =: lstRecordTypeNameSigning[1]];
        return lstReqDetails;
    }

    /**
    * @description Method to get check if button SFP is visible to User
    * @param List <Request__c> lstSigningReqs
    * @return Boolean
    */
    @AuraEnabled
    public static Boolean getButtonVisibility(List <Request__c> lstSigningReqs){
        Boolean btnVisible = true;
        for(Request__c request : lstSigningReqs){
            if(request.ReinsurerStatus__c == AP_Constant.statusSigned){
                btnVisible = false;
            }
        }
        if(UserInfo.getUserRoleId() != null){
            List <UserRole> userRole = [SELECT DeveloperName
                                    FROM UserRole
                                    WHERE Id =: UserInfo.getUserRoleId()];

            if(userRole[0].DeveloperName != AP_Constant.HeadUGP && userRole[0].DeveloperName != AP_Constant.DeputyCEO){
                btnVisible = false;
            }
        }
        else{
            btnVisible = false;
        }

        return btnVisible;
    }

    /**
    * @description Method to sign Pool and change status for Requests
    * @param List <Request__c> lstSigningReqs
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static Map<String, Object> signPools(List <Request__c> lstSigningReqs){
        Map<String, Object> mapResults = new Map<String, Object>();
        List<String> lstCCEmailsToSend = new List<String>();
        String strLstCCEmail = null;
        String strLstCCEmailDisplay = null;
        List<Id> lstIdRequest = new List<Id>();
        //RRA - ticket 1387 - 22122022
        Boolean isFileExist = false;
        String someDocsAttached = null;
        Set<String> setNamePool = new Set<String>();
        String namePool;

        try{
            for(Request__c request : lstSigningReqs){
                //RRA - ticket 2225 - 20/12/2024
                setNamePool.add(request.TECH_PoolName__c);
                //RRA - ticket 1387 - 22122022
                isFileExist = (request.Utility_Icon_Attachment__c != null && !String.isBlank(request.Utility_Icon_Attachment__c)) ? true : false;
                request.ReinsurerStatus__c = AP_Constant.statusSigned;
                request.TECH_DateSigned__c = System.today();
                request.ResponseDate__c = System.today();
                request.SigningRegionalManager__c = UserInfo.getUserId();
            }

            update lstSigningReqs;
            String label = 'Signed by ' + UserInfo.getName() + ' on ' + System.today().format();

            //27-01
            EmailTemplate emailTemplateRequestAnswer = [SELECT Id, Name FROM EmailTemplate WHERE Name = :AP_Constant.emailTemplatePoolAnswer];
            List<Messaging.SingleEmailMessage> lstMails = new List<Messaging.SingleEmailMessage>();

            User user = [SELECT Id, ContactId, Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            
            //RRA - ticket 1761 - 14112023
            //For AXA SA used as sender email address
            User userAXASA = [SELECT Id, Name, Email FROM User WHERE Id =:System.label.AXA_SA_Sender LIMIT 1];

            Messaging.SingleEmailMessage message;
            message = Messaging.renderStoredEmailTemplate(emailTemplateRequestAnswer.Id, UserInfo.getUserId(), lstSigningReqs[0].Id);
            message.setSaveAsActivity(false);

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            List<String> sendTo = new List<String>();
            sendTo.add(user.Email);
            mail.setToAddresses(sendTo);
            //RRA - ticket 1761 - 14112023
            OrgWideEmailAddress[] owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'actor.po@axa.com'];
            if (owea.size()>0) {
                mail.setOrgWideEmailAddressId(owea.get(0).Id);
            }
            mail.setReplyTo(userAXASA.Email); //RRA - ticket 1761 - 14112023
            String subject = message.getSubject(); //RRA - ticket 1761 - 14112023
            subject = subject.replace('{brokerReinsurerName}', ' '); //RRA - ticket 1761 - 14112023
            mail.setSubject(subject); //RRA - ticket 1761 - 14112023
            //mail.setReplyTo(UserInfo.getUserEmail());
            //mail.setSenderDisplayName(UserInfo.getFirstName() + ' ' + UserInfo.getLastName());

            Id programId = lstSigningReqs[0].Program__c;

            if(programId != null){
                Program__c program = [SELECT Id, Macro_L_O_B__c, Name, PrincipalCedingCompany__r.Name, PrincipalCedingCompany__r.EmailPCLife__c
                                        FROM Program__c 
                                        WHERE Id = :programId];

                strLstCCEmail = program.PrincipalCedingCompany__r.EmailPCLife__c;

                if(strLstCCEmail != null ){
                    if(strLstCCEmail.contains(';')){
                        lstCCEmailsToSend = strLstCCEmail.split(';');
                    }
                    else{
                        lstCCEmailsToSend.add(strLstCCEmail);
                    }
                }

                for(String pccEmail : lstCCEmailsToSend){
                    if(strLstCCEmailDisplay == null){
                        strLstCCEmailDisplay = pccEmail;
                    }
                    else{
                        strLstCCEmailDisplay = strLstCCEmailDisplay + ' ' + pccEmail;   
                    }
                }
            }

            if(lstCCEmailsToSend.size() > 0){
                mail.setCcAddresses(lstCCEmailsToSend);
            }

             //RRA - ticket 2225 - 20/12/2024
            if (setNamePool.size()>0){
              List<String> lstStrNamePool = new List<String>();
              lstStrNamePool.addAll(setNamePool);
               namePool = String.join(lstStrNamePool, ',');
            }
           
            String htmlBody = message.htmlBody;
            String domainURL = URL.getSalesforceBaseUrl().toExternalForm();
            String htmlInternetLink = '<a href="' + domainURL + '/lightning/page/home">ACTOR NewGen Page</a>';
            
            //RRA - ticket 1387 - 22122022
            if(isFileExist){
                someDocsAttached = System.Label.SomeDocumetsAttached;
                htmlBody = htmlBody.replace('{SomeDocumentsAttached}', '<b style="color:blue";><font face="Arial" size="50px">' + someDocsAttached) + '</font></b>';//1387
             }else{
                htmlBody = htmlBody.replace('{SomeDocumentsAttached}', '');
            }

            htmlBody = htmlBody.replace('{InternetLink}', htmlInternetLink);
            htmlBody = htmlBody.replace('{statusSentChanged}', 'sent');
            //RRA - ticket 2225 - 20/12/2024
            htmlBody = htmlBody.replace('{listPoolEmail}', namePool);

            if(strLstCCEmailDisplay != null ){
                htmlBody = htmlBody.replace('[Actor Mail box per instance]', strLstCCEmailDisplay);
            }
            else{
                htmlBody = htmlBody.replace('[Actor Mail box per instance]', '');
            }

            mail.setHtmlBody(htmlBody);
            //mail.setSubject(message.getSubject());
            lstMails.add(mail);
            Messaging.sendEmail((List<Messaging.Email>) lstMails);


            mapResults.put('Success', label);
            mapResults.put('lstSigningReqs', lstSigningReqs);
        }
        catch(Exception ex){
            mapResults.put('Error', ex.getMessage());
        }
        return mapResults;
    }

     @AuraEnabled
    public static   Map<String, Object>  getSignForPoolVisibility(){
         Map<String, Object> mapResults = new Map<String, Object>();
        Boolean isVisibleButton = true;
        Boolean isVisibleDocuments = true;
        List<Id> lstUserGroupIds = new List<Id>(); 
        User usr = [SELECT Id, UserRole.DeveloperName  FROM User  WHERE Id =: UserInfo.getUserId()];

        if(GroupMember.SObjectType.getDescribe().isAccessible() && Schema.SObjectType.GroupMember.fields.UserOrGroupId.isAccessible()){
               for(GroupMember groupMemberRecord : [SELECT Id, GroupId, UserOrGroupId FROM GroupMember WHERE Group.DeveloperName = 'Sign_for_Pool_ReadOnly_CE']){
                  lstUserGroupIds.add(groupMemberRecord.UserOrGroupId);
            }
         }
         if (usr.UserRole.DeveloperName == 'Head_of_UGP'){
            isVisibleButton = false;
            isVisibleDocuments = false;
         }else if (lstUserGroupIds.contains(usr.Id)){
            if (usr.UserRole.DeveloperName == 'CM' ||  usr.UserRole.DeveloperName == 'AM'){
                    isVisibleButton = true;
                    isVisibleDocuments = false;
              }
         }else {
                  isVisibleButton = true;
                  isVisibleDocuments = true;
              }
       mapResults.put('isVisibleButton', isVisibleButton);
      mapResults.put('isVisibleDocuments', isVisibleDocuments);
     return mapResults;
  }

    public class OptionWrapper {
        @AuraEnabled
        public String label {get; set;}
        @AuraEnabled
        public String value {get; set;}

        public OptionWrapper(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    public class CededWrapper {
        @AuraEnabled
        public String key {get; set;}
        @AuraEnabled
        public Decimal cededOther {get; set;}
        @AuraEnabled
        public Decimal cededEUR {get; set;}
         @AuraEnabled
        public String currencyLabel {get; set;}
        
        public CededWrapper(Decimal cededOther, Decimal cededEUR, String currencyLabel, String key) {
            this.cededOther = cededOther;
            this.cededEUR = cededEUR;
            this.currencyLabel = currencyLabel;
            this.key = key;
        }
    }

     public class TotalCededWrapper {
        @AuraEnabled
        public Decimal cededTotalOther {get; set;}
        @AuraEnabled
        public Decimal cededTotalEUR {get; set;}
        
        public TotalCededWrapper(Decimal cededTotalOther, Decimal cededTotalEUR) {
            this.cededTotalOther = cededTotalOther;
            this.cededTotalEUR = cededTotalEUR;
        } 
    }
}