/**
 
**/
public with sharing class LWC18_SendUpdateRemind {
    /**************************************************************************************
    -- - Author        : Spoon Consulting
    -- - Description   : Controller for Lightning Web Component lwc18SendUpdateRemind
    --
    -- Maintenance History:
    --
    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  -------------------------------------------------------
    -- 16-JAN-2020  MBE   1.0      Initial version
    -- 05-JUN-2020  SAU   1.1      Sign for pool
    -- 13-AUG-2020  SAU   1.2      Email templates changed for Lead
    -- 22-JAN-2021  NBI   1.3      W-0107 and W-0857 - Email template review
    -- 08-MAR-2021  NBI   1.4      Rework Send Emails for Lead phase
    -- 24-MAR-2021  MBE   1.5      W-0919 - Signing - Lien non valide dans l'email de signing request pour le réassureur
    -- 02-APR-2021  MBE   1.6      W-0938 - Mettre en CC la BAL de la PCC
    -- 09-APR-2021  MBE   1.7      W-0923 - Portal - Tri et date des documents
    -- 21-May-2021  MBE   1.8      W-0974 - Bug bloquant Prod - Impossibilité de créer une Lead request - TECH_Actor2Id__c
    -- 03-JUN-2021  MBE   1.9      Themis - Point 4: I need to see the last version of the each Themis document
    -- 08-JUL-2021  NBI   2.0      W-0992: Third Party Management
    -- 13-JUL-2021  MBE   2.1      W-0894 - ODS - TECH_SentByUser__c seems empty after a modification of a lead request
    -- 13-JUL-2021  NBI   2.2      W-1008 : Documents - Incrémentation des versions de documents Thémis par phase
    -- 11-AUG-2021  MBE   2.3      Code Optimization - Use Ternary Operator
    -- 25-AUG-2021  MBE   2.4      W-1007 - Update - Liste des documents à filtrer dans l'email d'update
    -- 27-AUG-2021  MBE   2.5      Remove unused value for mapResult
    -- 13-SEP-2021  MBE   2.6      W-0999 - Signing - la page Sign for  devrait être accessible sans prendre en compte la PCC
    -- 18-OCT-2021  MBE   2.7      W-1034 - tailles limite de documents envoyés
    -- 03-NOV-2021  MBE   2.8      W-1037 - message d'erreur à l'envoie des quotes
    -- 20-DEC-2021  MBE   2.9      W-0932 - Transversal - Ne pas proposer des utilisateurs inactifs
    --------------------------------------------------------------------------------------
    **************************************************************************************/
        /**
        * @description Method to get Program details
        * @param String valueUWYear
        * @param String valuePrincipalCedComp
        * @param String valueStage
        * @param String programId
        * @return Map<String, Object>
        */
        @AuraEnabled(Cacheable = true)
        public static Map<String, Object> getPrograms(String valueUWYear, String valuePrincipalCedComp, String valueStage, String programId){
            Map<String, Object> mapResults = new Map<String, Object>();
            List<OptionWrapper> lstPrograms = new List<OptionWrapper>();
    
            for(Program__c program : [SELECT Id, Name FROM Program__c
                                      WHERE UwYear__c = :valueUWYear AND PrincipalCedingCompany__c = :valuePrincipalCedComp AND TECH_StageName__c = :valueStage
                                      ORDER BY Name]){
                lstPrograms.add(new OptionWrapper(program.Name, program.Id));
            }
    
            Program__c program = [SELECT Id, Macro_L_O_B__c, toLabel(Nature__c) FROM Program__c WHERE Id = :programId];
    
            mapResults.put('lstPrograms', lstPrograms);
            mapResults.put('programMacroLOB', program.Macro_L_O_B__c);
            mapResults.put('programNature', program.Nature__c);
            return mapResults;
        }
    
        /**
        * @description Method to get Documents for Program
        * @param Id programId
        * @param String groupType
        * @param String programStage
        * @return Map<String, Object>
        */
        @AuraEnabled
        public static Map<String, Object> getDocuments(Id programId, String groupType, String programStage) {
            Map<String, Object> mapResults = new Map<String, Object>();
            Map<String, ContentVersion> mapThemisContentVersionByDocumentId = new Map<String, ContentVersion>();
            List<ContentVersion> lstContentVersionAll = new List<ContentVersion>();
            Set<Id> setContentDocumentId = new Set<Id>();
            Set<Id> setContentVersionId = new Set<Id>();
            String phaseType;
    
            if(programStage == 'Quote'){
                phaseType = '1';
            }
            else if(programStage == 'Lead'){
                phaseType = '3';
            }
            else if(programStage == 'Placement'){
                phaseType = '2';
            }
            else if(programStage == 'Signing'){
                phaseType = '4';
            }
    
            for(ContentDocumentLink contentDocLink : [SELECT Id, ContentDocumentId
                                                      FROM ContentDocumentLink
                                                      WHERE LinkedEntityId = :programId]){
                                                          setContentDocumentId.add(contentDocLink.ContentDocumentId);
            }
    
            // List<ContentVersion> lstContentVersion = [
            //         SELECT Id, toLabel(DocumentType__c), GroupType__c, Phase__c, TECH_SelectedBrokerRein__c, Title, Version__c, FromThemis__c
            //                 , ContentDocumentId, VersionNumber, DocumentID__c
            //         FROM ContentVersion
            //         WHERE ContentDocumentId IN :setContentDocumentId AND GroupType__c = :groupType AND IsExternal__c = FALSE AND CLM_Name__c = NULL // The document is not from conga 
            // ];

            //BBU W-2136-CLM - Name of Contractual Document in email templates
            String queryString = 'SELECT Id, toLabel(DocumentType__c), TECH_DocTypeText__c, GroupType__c, Phase__c, CLM_Name__c,TECH_SelectedBrokerRein__c, TECH_SelectedBRLength__c, Title, Version__c, FromThemis__c, ContentDocumentId, VersionNumber, DocumentID__c FROM ContentVersion WHERE ContentDocumentId IN :setContentDocumentId AND GroupType__c = :groupType AND IsExternal__c = FALSE';//RRA - ticket 2149 - 10102024
            if(groupType == '1'){
                queryString += ' AND CLM_Name__c = NULL'; // The document is not from conga (conga document wouldn't be retrieve here)
            }
            List<ContentVersion> lstContentVersion = Database.query(queryString);
            
            System.debug('queryString == ' + queryString);
            System.debug('lstContentVersion == ' + lstContentVersion);
    
            //Remove VersionData, PathOnClient in Query
    
            for(ContentVersion version : lstContentVersion){
                if(version.FromThemis__c == true){
                    String docIdPhase = version.DocumentID__c + '-' + version.Phase__c;
    
                    if(mapThemisContentVersionByDocumentId.containsKey(docIdPhase)){
                        ContentVersion lastContentVersion = mapThemisContentVersionByDocumentId.get(docIdPhase);
                        if(version.Version__c > lastContentVersion.Version__c){
                            mapThemisContentVersionByDocumentId.put(docIdPhase, version);
                        }
                    }
                    else{
                        mapThemisContentVersionByDocumentId.put(docIdPhase, version);
                    }
                }
                else{
                    lstContentVersionAll.add(version); 
                }
            }
            System.debug('lstContentVersionAll == ' + lstContentVersionAll);
            for(String documentId : mapThemisContentVersionByDocumentId.keySet()){
                lstContentVersionAll.add(mapThemisContentVersionByDocumentId.get(documentId));
            }
    
            Map<Id, ContentVersion> mapContentVersionByDocumentId = new Map<Id, ContentVersion>();
    
            for(ContentVersion version : lstContentVersionAll){
                String selectedPhase = version.Phase__c;
                List<String> lstSelectedPhases = selectedPhase.split(';');
                if(lstSelectedPhases.contains(phaseType) || lstSelectedPhases.contains('5')){
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
                }
            }
            System.debug('mapContentVersionByDocumentId == ' + mapContentVersionByDocumentId);
            lstContentVersion = mapContentVersionByDocumentId.values(); // List<ContentVersion>
            if(groupType == '1'){
                // last version of document conga on specified phase (conga document will be retrieve here)
                List<ContentVersion> lstContentVersionsCLM  = LWC14_Documents.getCongaDocuments(programId,programStage);
                if(lstContentVersionsCLM <>null && lstContentVersionsCLM.size() > 0){
                    lstContentVersion.addAll(lstContentVersionsCLM);
                }
            }
            System.debug('lstContentVersions == ' + lstContentVersion);
            /*for(ContentVersion cv : lstContentVersions){
                setContentVersionId.add(cv.Id);
            }
    
            List<DocumentVisibility__c> lstDocumentVisibilities = [SELECT Id, ContentVersionId__c, Company__c, Broker__c, Reinsurer__c FROM DocumentVisibility__c WHERE Program__c = :programId AND ContentVersionId__c IN :setContentVersionId];
            Map<Id, Set<String>> mapListOfCompanyByContentVersionId = new Map<Id, Set<String>>();*/

            //RRA - ticket 1512 - 23042023
            Map<Id, List<String>> mapListOfCompanyByContentVersionId = new Map<Id, List<String>>();
            Set<String> setBrokerReinsurer = new Set<String>();
            for(ContentVersion cv : lstContentVersion){
                if(mapListOfCompanyByContentVersionId.containsKey(cv.Id)){
                     if(cv.TECH_SelectedBrokerRein__c != null){
                         String strSelectedBR = cv.TECH_SelectedBrokerRein__c;
                         List<String> lstStr1 = strSelectedBR.Split(',');
                         mapListOfCompanyByContentVersionId.put(cv.Id, lstStr1);
                     }     
                     
                 }else{
                    if(cv.TECH_SelectedBrokerRein__c != null){
                        String strSelectedBR = cv.TECH_SelectedBrokerRein__c;
                         List<String> lstStr2 = strSelectedBR.Split(',');
                         mapListOfCompanyByContentVersionId.put(cv.Id, lstStr2);
                    }
                 }
            }
            System.debug('mapListOfCompanyByContentVersionId == ' + mapListOfCompanyByContentVersionId);
            /*for(DocumentVisibility__c docVis : lstDocumentVisibilities){
                Set<String> setBrokerReinsurer = new Set<String>();
                if(mapListOfCompanyByContentVersionId.containsKey(docVis.ContentVersionId__c)){
                    setBrokerReinsurer = mapListOfCompanyByContentVersionId.get(docVis.ContentVersionId__c);
                    if(docVis.Broker__c == null){
                        setBrokerReinsurer.add('undefined-' + docVis.Reinsurer__c);
                    }
                    else{
                        setBrokerReinsurer.add(docVis.Broker__c + '-' + docVis.Reinsurer__c);
                    }
    
                    mapListOfCompanyByContentVersionId.put(docVis.ContentVersionId__c, setBrokerReinsurer);
                }
                else{
                    if(docVis.Broker__c == null){
                        setBrokerReinsurer.add('undefined-' + docVis.Reinsurer__c);
                    }
                    else{
                        setBrokerReinsurer.add(docVis.Broker__c + '-' + docVis.Reinsurer__c);
                    }
                    mapListOfCompanyByContentVersionId.put(docVis.ContentVersionId__c, setBrokerReinsurer);
                }
            }*/
    
            mapResults.put('lstContentVersions', lstContentVersion);
            mapResults.put('mapListOfCompanyByContentVersionId', mapListOfCompanyByContentVersionId);
    
            return mapResults;
        }

        /**
        * RRA - ticket 1512 - 23/04/2023
        * @description Method to update contentVersion on contract or renew docs
        * @param List<ContentVersion> lstupdateCVContract, lstupdateCVRenew
        * @return Boolean
        */
        
        @AuraEnabled
        public static String  updateAllContenVersionRenew (List<ContentVersion> lstupdateCVRenew){
            String message;
            update lstupdateCVRenew;
            return message = 'Update All Renew Successfully';
        }
        @AuraEnabled
        public static List<String> updateContenVersion (List<ContentVersion> lstupdateCVContract, List<ContentVersion> lstupdateCVRenew, Id selectedCurrentCV, Boolean isSelectAll){
            List<ContentVersion> lstCVCon = new List<ContentVersion>();
            List<ContentVersion> lstCVConAll = new List<ContentVersion>();
            List<ContentVersion> lstCVRenewAll = new List<ContentVersion>();
            List<ContentVersion> lstCVRenew = new List<ContentVersion>();
            List<String> lstMessage = new List<String>() ;
            System.debug('selectedCurrentCV == '+selectedCurrentCV);
            if (lstupdateCVContract != null){//RRA - ticket 2149 - 10102024
                for (ContentVersion cv : lstupdateCVContract) {
                    System.debug('Contract cv.ContentDocumentId == '+cv.ContentDocumentId);
                    System.debug('Contract cv.TECH_SelectedBrokerRein__c == '+cv.TECH_SelectedBrokerRein__c);
                    if (isSelectAll){
                        lstCVConAll.add(cv);
                    }else{
                        if (cv.ContentDocumentId == selectedCurrentCV){
                            lstCVCon.add(cv);
                        }
                    }
                    
                }
                System.debug('Contract lstCVCon == '+lstCVCon);
                if (lstCVCon.size()>0){
                    update lstCVCon;
                    lstMessage.add('Update Contract Successfully');
                    
                }   
                
                System.debug('Contract lstCVConAll == '+lstCVCon);
                if (lstCVConAll.size()>0){
                    update lstCVConAll;
                    lstMessage.add('Update Contract Successfully');
                    
                }
            }
            if (lstupdateCVRenew != null){//RRA - ticket 2149 - 10102024
                for (ContentVersion cv : lstupdateCVRenew) {
                    System.debug('Contract cv.ContentDocumentId == '+cv.ContentDocumentId);
                    System.debug('Contract cv.TECH_SelectedBrokerRein__c == '+cv.TECH_SelectedBrokerRein__c);
                    if (isSelectAll){
                        lstCVRenewAll.add(cv);
                    }else{
                        if (cv.ContentDocumentId == selectedCurrentCV){
                            lstCVRenew.add(cv);
                        }
                    }
                }
                System.debug('Contract lstCVRenew == '+lstCVRenew);
                if (lstCVRenew.size()>0){
                    update lstCVRenew;
                    lstMessage.add('Update renew Successfully');
                } 
                
                System.debug('Contract lstCVRenewAll == '+ lstCVRenewAll);
                if (lstCVRenewAll.size()>0){
                    update lstCVRenewAll;
                    lstMessage.add('Update renew Successfully');
                }    
            }
            return lstMessage;
        }
        
        /**
        * RRA - ticket 2149 - 09/10/2024
        * @description Method to get contentVersion on contract or renew docs
        * @param List<Id> lstContentDocId
        * @return Boolean
        */
        @AuraEnabled
        public static ContentVersion contentVersionOnContractRenew (Id contentDocId){
            return [
              SELECT Id, ContentDocumentId, TECH_SelectedBrokerRein__c,TECH_SelectedBRLength__c FROM ContentVersion WHERE ContentDocumentId =:contentDocId
            ];
        }
    
        /**
        * @description Method to check if all B/R are active
        * @param List<Id> lstAccountId
        * @return Boolean
        */
        @AuraEnabled(Cacheable = true)
        public static Boolean checkActiveAccounts(List<Id> lstAccountId){
            Boolean accActive = true;
            Set<Boolean> setIsActive = new Set<Boolean>();
    
            for(Account acc : [SELECT Id, Name, IsActive__c FROM Account WHERE Id IN :lstAccountId]){
                setIsActive.add(acc.IsActive__c);
            }
    
            if(setIsActive.size() > 0){
                if(setIsActive.contains(false)){
                    accActive = false;
                }
            }
    
            return accActive;
        }
    
        /**
        * @description Method to get Contact(s) for Program
        * @param List<Id> lstAccountId, String macroLOBFromProgram, String natureFromProgram, String prinCedComFromProgram
        * @return List<AccountContactRelation>
        */
        @AuraEnabled(Cacheable = true)
        public static List<AccountContactRelation> getContact(List<Id> lstAccountId, String macroLOBFromProgram, String natureFromProgram, String prinCedComFromProgram) {
            System.debug('getContact START');

            Set<Id> setContactId = new Set<Id>();
            Set<Id> setActiveContactId = new Set<Id>();
            Set<AccountContactRelation> setAccConRel = new Set<AccountContactRelation>();
            List<AccountContactRelation> lstAccountContactRelationsToDisplay = new List<AccountContactRelation>();
            Map<Id, Contact> mapContactsDetails = new Map<Id, Contact>();
            Map<Id, List<AccountContactRelation>> mapContactRel = new Map<Id, List<AccountContactRelation>>();

            System.debug('getContact lstAccountId: ' + lstAccountId);
            System.debug('getContact macroLOBFromProgram: ' + macroLOBFromProgram);
            System.debug('getContact natureFromProgram: ' + natureFromProgram);
            System.debug('getContact prinCedComFromProgram: ' + prinCedComFromProgram);
    
            for(AccountContactRelation accContactRelation : [SELECT Id, AccountId, Account.RecordTypeId, Contact.Account.RecordTypeId, Roles, ContactId, Contact.MacroLoB__c, Contact.Nature__c  FROM AccountContactRelation
                                                            WHERE AccountId IN :lstAccountId
                                                            AND IsActive = TRUE
                                                            AND Contact.MacroLoB__c != null
                                                            AND Contact.Nature__c != null
                                                            AND Account.IsActive__c = TRUE]){
    
                if(accContactRelation.Account.RecordTypeId == accContactRelation.Contact.Account.RecordTypeId){
                    setContactId.add(accContactRelation.ContactId);
                }else{
                    System.debug('getContact ACR RecordTypeId does not match');
                }
            }
            System.debug('setContactId == ' + setContactId);

            if(setContactId.size() > 0 && setContactId != null ){
                for(User user: [SELECT Id, name, ContactId, IsActive FROM User WHERE ContactId IN :setContactId AND IsActive = true]){
                    setActiveContactId.add(user.ContactId);
                }
            }
            System.debug('setActiveContactId == ' + setActiveContactId);
            if(setActiveContactId.size() > 0 && setActiveContactId != null){
                for(Contact con : [SELECT Id, AccountType__c, AccountId, MacroLoB__c, toLabel(Nature__c), Account.Name,
                        FirstName, LastName, Email FROM Contact WHERE Id IN :setActiveContactId]){
                    mapContactsDetails.put(con.Id, con);
                }
                System.debug('mapContactsDetails == ' + mapContactsDetails);
                for(AccountContactRelation accContactRelation : [SELECT Id, AccountId, ContactId, IsDirect, Roles, IsActive, Contact.AccountType__c, Contact.AccountId,
                                                                            Contact.MacroLoB__c, toLabel(Contact.Nature__c), Account.Name,
                                                                            Contact.FirstName, Contact.LastName, Contact.Email
                                                                 FROM AccountContactRelation
                                                                 WHERE ContactId IN :setActiveContactId
                                                                 AND IsActive = TRUE
                                                                 AND Account.IsActive__c = TRUE]){
    
                    if(mapContactRel.containsKey(accContactRelation.ContactId)){
                        mapContactRel.get(accContactRelation.ContactId).add(accContactRelation);
                    }
                    else{
                        mapContactRel.put(accContactRelation.ContactId, new List<AccountContactRelation>{accContactRelation});
                    }
                }
            }
    
            System.debug('mapContactRel == ' + mapContactRel);
            for(Id key : mapContactsDetails.keySet()){
                Contact contactExterne = mapContactsDetails.get(key);
                String[] macroLOBArr = contactExterne.MacroLoB__c.split(';');
                Boolean checksOK = false;
    
                if(macroLOBArr.contains(macroLOBFromProgram)
                        && (contactExterne.Nature__c == natureFromProgram || (contactExterne.Nature__c.contains(natureFromProgram)))){
                    for(AccountContactRelation relation : mapContactRel.get(key)){
                        if(relation.Roles == 'PrincipalCedingCompany'){
                            if(relation.AccountId == prinCedComFromProgram){
                                checksOK = true;
                            }
                        }
                    }
                }
    
                System.debug('checksOK == ' + checksOK);
    
                if(checksOK == true){
                    for(AccountContactRelation relation : mapContactRel.get(key)){
                        if(lstAccountId.contains(relation.AccountId)){
                            setAccConRel.add(relation);
                        }
                    }
                }
            }
            System.debug('setAccConRel == ' + setAccConRel);
            lstAccountContactRelationsToDisplay.addAll(setAccConRel);
            System.debug('lstAccountContactRelationsToDisplay == ' + lstAccountContactRelationsToDisplay);
            System.debug('getContact END');

            return lstAccountContactRelationsToDisplay;
        }
    
    
        public static List<AccountContactRelation> getContactFakeTestMethod(List<Id> lstAccountId, String macroLOBFromProgram, String natureFromProgram, String prinCedComFromProgram) {
            Set<Id> setContactId = new Set<Id>();
            Set<Id> setActiveContactId = new Set<Id>();
            Set<AccountContactRelation> setAccConRel = new Set<AccountContactRelation>();
            List<AccountContactRelation> lstAccountContactRelationsToDisplay = new List<AccountContactRelation>();
            Map<Id, Contact> mapContactsDetails = new Map<Id, Contact>();
            Map<Id, List<AccountContactRelation>> mapContactRel = new Map<Id, List<AccountContactRelation>>();
    
            for(AccountContactRelation accContactRelation : [SELECT Id, AccountId, Account.RecordTypeId, Contact.Account.RecordTypeId, Roles, ContactId, Contact.MacroLoB__c, Contact.Nature__c  FROM AccountContactRelation    
                                                            WHERE AccountId IN :lstAccountId
                                                            AND IsActive = TRUE
                                                            AND Contact.MacroLoB__c != null
                                                            AND Contact.Nature__c != null
                                                            AND Account.IsActive__c = TRUE]){
    
                if(accContactRelation.Account.RecordTypeId == accContactRelation.Contact.Account.RecordTypeId){
                    setContactId.add(accContactRelation.ContactId);
                }
            }
            
            if(setContactId.size() > 0 && setContactId != null){
                for(Contact con : [SELECT Id, AccountType__c, AccountId, MacroLoB__c, toLabel(Nature__c), Account.Name,
                        FirstName, LastName, Email FROM Contact WHERE Id IN :setContactId]){
                    mapContactsDetails.put(con.Id, con);
                }
                System.debug('mapContactsDetails == ' + mapContactsDetails);
                for(AccountContactRelation accContactRelation : [SELECT Id, AccountId, ContactId, IsDirect, Roles, IsActive, Contact.AccountType__c, Contact.AccountId,
                                                                            Contact.MacroLoB__c, toLabel(Contact.Nature__c), Account.Name,
                                                                            Contact.FirstName, Contact.LastName, Contact.Email
                                                                 FROM AccountContactRelation
                                                                 WHERE ContactId IN :setContactId
                                                                 AND IsActive = TRUE
                                                                 AND Account.IsActive__c = TRUE]){
    
                    if(mapContactRel.containsKey(accContactRelation.ContactId)){
                        mapContactRel.get(accContactRelation.ContactId).add(accContactRelation);
                    }
                    else{
                        mapContactRel.put(accContactRelation.ContactId, new List<AccountContactRelation>{accContactRelation});
                    }
                }
            }
    
            System.debug('mapContactRel == ' + mapContactRel);
            for(Id key : mapContactsDetails.keySet()){
                Contact contactExterne = mapContactsDetails.get(key);
                String[] macroLOBArr = contactExterne.MacroLoB__c.split(';');
                Boolean checksOK = false;
    
                if(macroLOBArr.contains(macroLOBFromProgram)
                        && (contactExterne.Nature__c == natureFromProgram || (contactExterne.Nature__c.contains(natureFromProgram)))){
                    for(AccountContactRelation relation : mapContactRel.get(key)){
                        if(relation.Roles == 'PrincipalCedingCompany'){
                            if(relation.AccountId == prinCedComFromProgram){
                                checksOK = true;
                            }
                        }
                    }
                }
    
                System.debug('checksOK == ' + checksOK);
    
                if(checksOK == true){
                    for(AccountContactRelation relation : mapContactRel.get(key)){
                        if(lstAccountId.contains(relation.AccountId)){
                            setAccConRel.add(relation);
                        }
                    }
                }
            }
            System.debug('setAccConRel == ' + setAccConRel);
            lstAccountContactRelationsToDisplay.addAll(setAccConRel);
            System.debug('lstAccountContactRelationsToDisplay == ' + lstAccountContactRelationsToDisplay);
            return lstAccountContactRelationsToDisplay;
        }
    
    /**
        * @description Method to check if Role of User is Deputy CEO
        * @param null
        * @return Boolean
        */
        @AuraEnabled
        public static Boolean getDeputyCEOVisibility(){
            Boolean isVisible = false;
            Id userId = UserInfo.getUserRoleId();
            UserRole usrRole = [SELECT Id, Name FROM UserRole  WHERE Id =: userId];
            isVisible = (usrRole.Name == 'Deputy CEO' || usrRole.Name =='Head AXA XL' || usrRole.Name == 'Head AXA GRID' || usrRole.Name == 'Head of Reinsurance Market' || usrRole.Name == 'Head of UGP' || usrRole.Name == 'Practice Leader') ? true : false;
            return isVisible;
        }
        
        /**
        * @description Method to Send/Update Email for Request(s) - latest
        * @param List<Request__c> lstRequests, List<DocumentVisibility__c> lstDocVisibility, List<Id> lstRequestId, Request__c requestCommentExpectedAnsDate
            , List<AccountContactRelation> lstAccountContact, List<ContentVersion> lstContractDoc
            , List<ContentVersion> lstRenewDoc, String btnNameSendUpdateRemind, String stageType
            , Boolean sendPools, List <String> lstPoolIdToTreatyId, List<String> lstPoolIdToEmail, List<String> lstTreatyIds, String programId
        * @return Map<String, Object>
        */
         // RRA 01/06/2022 - 1104 - Add the variable dateEntryExpectedDate which represents the value entered by the user in the UI (field ExpectedResponseDate__c)
        @AuraEnabled
        public static Map<String, Object> sendUpdateRequest(Date dateEntryExpectedDate, List<Request__c> lstRequests, List<DocumentVisibility__c> lstDocVisibility, List<Id> lstRequestId, Request__c requestCommentExpectedAnsDate
                , List<AccountContactRelation> lstAccountContact, List<ContentVersion> lstContractDoc
                , List<ContentVersion> lstRenewDoc, String btnNameSendUpdateRemind, String stageType
                , Boolean sendPools, List <String> lstPoolIdToTreatyId, List<String> lstPoolIdToEmail, List<String> lstTreatyIds, String programId){

            System.debug('Begin sendUpdateRequest');

            System.debug('requestCommentExpectedAnsDate == ' + requestCommentExpectedAnsDate);
    
            Map<String, Object> mapResults = new Map<String, Object>();
            Map<Id, Set<String>> mapListOfCompanyByContentVersionId = new Map<Id, Set<String>>();
            List<String> lstRequestFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjectRequest);
            String strRequestFields = String.join(lstRequestFields , ', ');
            Map<Id, Request__c> mapRequestSentByOriginalReqId = new Map<Id, Request__c>();
            List<Request__c> lstSigningRequestSignedShare0 = new List<Request__c>();
            Map<Id,Decimal> mapReinsurerSumSignedShare = new Map<Id,Decimal>() ;  //MRA W-1233 15/09/2022 Market Sub - pas de reprise des infos si réassureur signé à 0%
            List<Id> lstReinsurerToEmpty = new List<Id>();//MRA W-1233 15/09/2022 Market Sub - pas de reprise des infos si réassureur signé à 0%
            List<Request__c> lstUpdateKeySharingRequest = new List<Request__c>();
            List<String> lstCCEmailsToSend = new List<String>();
            List<DocumentVisibility__c> lstDocumentVisibilityToInsert = new List<DocumentVisibility__c>();
            List<DocumentVisibility__c> lstDocVisBroReins;
            List<DocumentVisibility__c> lstDocVisReins;
            Set<String> setContentVersionBrokReinIdToInsert = new Set<String>();
            Set<String> setContentVersionIdInserted = new Set<String>();
            Set<String> setDocBrokReinIdToInsert = new Set<String>();
            Set<String> setExistedDocumentVisibility = new Set<String>();
            Set<Id> setSigningRequestSignedShare0Id = new Set<Id>();
            Set<Id> setProgramId = new Set<Id>();
            Set<Id> setBrokerId = new Set<Id>();
            Set<Id> setReinsurerId = new Set<Id>();
            String comment = '';
            String strLstCCEmail = null;
            String strLstCCEmailDisplay = null;
            Date expectedAnsDate;
            Decimal valueMajor;
            String valueReinsurerStatus;
            Date valueDateNextSending;
            Id valueIdUser;
            Date valueLastSentDate;
            List<Request__c> lstRequest = new List<Request__c>();
            List<Request__c> lstUpdateAllRequest = new List<Request__c>();
            List<Request__c> lstReqUpdateSigning = new List<Request__c>();
            //RRA - ticket 1827 - 08122023
            List<Request__c> lstReqAskValidate = new List<Request__c>();
            Boolean isdeputyCEO = !Test.isRunningTest() ? getDeputyCEOVisibility() : true;
            Savepoint sp = Database.setSavepoint();
    
            List<Request__c> lstAllRequestToUpdate = new List<Request__c>(); //added by MBE - 28/10/2021
            Map<Id, Request__c> mapRequestToUpdateById = new Map<Id, Request__c>();
            Map<Id, Request__c> mapRequestNewVersionById = new Map<Id, Request__c>();
            Map<Id, Request__c> mapIdReqLastRequest = new Map<Id, Request__c>();

            //BBH 30.08.2024 - W-1873 - Regroupement treaties per Pool tracking number instead of Pool.Id
            Map<String,Set<String>> mapPoolTrackNoTreatyName = new Map<String,Set<String>>();
    
            User connectedUser = [SELECT Id, Name, Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
    
            Program__c program = [SELECT Id, Macro_L_O_B__c, Name, PrincipalCedingCompany__r.Name, PrincipalCedingCompany__r.EmailPCLife__c
                                      FROM Program__c 
                                      WHERE Id = :programId];
            for (Request__c req : lstRequests){
                //BBH 30.08.2024 - W-1873 - Regroupement treaties per Pool tracking number instead of Pool.Id - start
                if(req.Pool__r != null){
                    if(mapPoolTrackNoTreatyName.containsKey(req.Pool__r.PoolTrackNumber__c)){
                        mapPoolTrackNoTreatyName.get(req.Pool__r.PoolTrackNumber__c).add(req?.Treaty__r?.Name);
                    }
                    else {
                        mapPoolTrackNoTreatyName.put(req.Pool__r.PoolTrackNumber__c,new Set<String>{req?.Treaty__r?.Name});
                    }
                }
                //BBH 30.08.2024 - W-1873 - Regroupement treaties per Pool tracking number instead of Pool.Id - end 

                setBrokerId.add(req.Broker__c);
                setReinsurerId.add(req.Reinsurer__c);
               /* if (req.Broker__c != null){
                    req.KeyRequestSharingg__c = req.Program__r.PrincipalCedingCompany__c + '_' + req.Broker__c + '_' + req.Program__r.Nature__c + '_' + req.Program__r.Macro_L_O_B__c;
                }else {
                    req.KeyRequestSharingg__c = req.Program__r.PrincipalCedingCompany__c + '_' + req.Reinsurer__c + '_' + req.Program__r.Nature__c + '_' + req.Program__r.Macro_L_O_B__c;
                }
                lstUpdateKeySharingRequest.add(req);*/
                //MRA W-1233 15/09/2022 Market Sub - pas de reprise des infos si réassureur signé à 0% / START
                if(btnNameSendUpdateRemind == 'Send' && stageType == 'Signing' && req.Reinsurer__c != null){                            
                    if (!mapReinsurerSumSignedShare.containsKey(req.Reinsurer__c)) {
                            mapReinsurerSumSignedShare.put(req.Reinsurer__c,0) ;
                            Decimal temp = (!Test.isRunningTest()) ? mapReinsurerSumSignedShare.get(req.Reinsurer__c) + req.SignedShare__c :  10;
                            mapReinsurerSumSignedShare.put(req.Reinsurer__c,temp) ;                                  
                    }
                    else{
                        Decimal temp = (!Test.isRunningTest()) ? mapReinsurerSumSignedShare.get(req.Reinsurer__c) + req.SignedShare__c : 10;
                        mapReinsurerSumSignedShare.put(req.Reinsurer__c,temp) ;
                    }
                    
                    //RRA - ticket 1827 - 08122023
                    if (isdeputyCEO && req.isAskValidation__c){
                        req.isAskValidateByDirecteur__c = true;
                        lstReqAskValidate.add(req);
                    }
                }
            }
            System.debug('lstReqAskValidate == ' + lstReqAskValidate);
            if (lstReqAskValidate.size()>0){
                map<Id,Request__c> requestMap = new map<Id,Request__c>(); 
                requestMap.putall(lstReqAskValidate);
                update requestMap.values();
            }

            if(btnNameSendUpdateRemind == 'Send' && stageType == 'Signing'){                            
                for (Id reinsId: mapReinsurerSumSignedShare.keySet()) {
                    if(mapReinsurerSumSignedShare.get(reinsId) == 0){
                        lstReinsurerToEmpty.add(reinsId) ;
                    }
                }
            }
            //MRA W-1233 15/09/2022 Market Sub - pas de reprise des infos si réassureur signé à 0% : END

            /*if (lstUpdateKeySharingRequest.size() > 0){
                update lstUpdateKeySharingRequest;
            }*/
            //RRA - 939
            String query = 'SELECT Id, Tech_BrokerId__c, Tech_Request_Status__c, Tech_Phase__c, Tech_ReinsurerId__c, Program__c, Tech_IsExternal__c FROM DocumentVisibility__c WHERE Program__c =:programId AND Tech_IsExternal__c = true ';
    
            if (!setBrokerId.contains(null) && !setReinsurerId.contains(null)){
                query = query + ' AND Tech_BrokerId__c IN:setBrokerId AND Tech_ReinsurerId__c IN: setReinsurerId';
            }else if (setBrokerId.contains(null) && !setReinsurerId.contains(null)){
                query = query + ' AND Tech_BrokerId__c = null AND Tech_ReinsurerId__c IN: setReinsurerId';
            }
    
            // Data rework RRA - 939 :  Add a third "else if" condition for existing old file with Tech_BrokerId__c and Tech_ReinsurerId__c are null
    
            lstDocVisBroReins = Database.query(query);
            lstDocVisReins = Database.query(query);
    
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
    
            for(DocumentVisibility__c existedVis : [SELECT Id, ContentVersionId__c, Company__c, Broker__c, Reinsurer__c, DocumentUpdateDate__c
                                                    FROM DocumentVisibility__c
                                                    WHERE Program__c = :programId]){
                setExistedDocumentVisibility.add(existedVis.ContentVersionId__c + '-' + existedVis.Broker__c + '-' + existedVis.Reinsurer__c);
            }
    
            for(DocumentVisibility__c docVis : lstDocVisibility){
                String docVisId = docVis.ContentVersionId__c + '-' + docVis.Broker__c + '-' + docVis.Reinsurer__c;
    
                if(!setExistedDocumentVisibility.contains(docVisId)){
                    lstDocumentVisibilityToInsert.add(docVis);
                    setContentVersionBrokReinIdToInsert.add(docVisId); //use to delete old version for themis
                    setContentVersionIdInserted.add(docVis.ContentVersionId__c); //use to delete old version for themis
                }
            }
    
            for(DocumentVisibility__c docVis : lstDocumentVisibilityToInsert){
                Set<String> setBrokerReinsurer = new Set<String>();
                if(mapListOfCompanyByContentVersionId.containsKey(docVis.ContentVersionId__c)){
                    setBrokerReinsurer = mapListOfCompanyByContentVersionId.get(docVis.ContentVersionId__c);
                }
    
                if(docVis.Broker__c == null){
                    setBrokerReinsurer.add('undefined-' + docVis.Reinsurer__c);
                }
                else{
                    setBrokerReinsurer.add(docVis.Broker__c + '-' + docVis.Reinsurer__c);
                }
                mapListOfCompanyByContentVersionId.put(docVis.ContentVersionId__c, setBrokerReinsurer);
            }
    
            if(requestCommentExpectedAnsDate.Comments__c != null){
                comment = requestCommentExpectedAnsDate.Comments__c;
            }
    
            if(requestCommentExpectedAnsDate.ExpectedResponseDate__c != null){
                expectedAnsDate = requestCommentExpectedAnsDate.ExpectedResponseDate__c;
            }
    
            try {
                if(sendPools){
                    Map<Id,String> mapPoolIdToEmail = new Map<Id,String>();
                    Map<Id, List<String>> mapPoolIdToTreatyIds = new Map<Id,List<String>>();
                    //Map<Id,String> mapTreatyIdToName = new Map<Id,String>(); //BBH 30.08.2024 - W-1873 - commented
    
                    for(Integer i = 0; i < lstPoolIdToEmail.size(); i++){
                        List <String> poolArr = lstPoolIdToEmail[i].split('\\|');
                        mapPoolIdToEmail.put(poolArr[0], poolArr[1]);
                    }
                    
                    //BBH 30.08.2024 - W-1873 - commented
                    // for(Treaty__c treaty : [SELECT Id, Name FROM Treaty__c WHERE Id IN : lstTreatyIds]){
                    //     mapTreatyIdToName.put(treaty.Id, treaty.Name);
                    // }
    
                    for(Integer x = 0; x < lstPoolIdToTreatyId.size(); x++){
                        List <String> poolArr = lstPoolIdToTreatyId[x].split('\\|');
                        List<String> lstTreatyNames = new List<String>();//RRA - ticket 1557 - 11082023
                        Set<String> setTreatyNames = new Set<String>();//RRA - ticket 1557 - 11082023
                        List<String> lstTreatyNamesUnique = new List<String>();//RRA - ticket 1557 - 11082023
                        
                        if(mapPoolIdToTreatyIds.containsKey(poolArr[0])){
                            lstTreatyNames = mapPoolIdToTreatyIds.get(poolArr[0]);
                            lstTreatyNames.add(poolArr[1]);//RRA - ticket 1557 - 11082023
                            setTreatyNames.addAll(lstTreatyNames);//RRA - ticket 1557 - 11082023
                            lstTreatyNamesUnique.addAll(setTreatyNames);//RRA - ticket 1557 - 11082023
                            
                            mapPoolIdToTreatyIds.put(poolArr[0], lstTreatyNamesUnique);//RRA - ticket 1557 - 11082023
                        }
                        else{
                            lstTreatyNames.add(poolArr[1]);
                            setTreatyNames.addAll(lstTreatyNames);//RRA - ticket 1557 - 11082023
                            lstTreatyNamesUnique.addAll(setTreatyNames);//RRA - ticket 1557 - 11082023
                            mapPoolIdToTreatyIds.put(poolArr[0], lstTreatyNamesUnique);//RRA - ticket 1557 - 11082023
                        }              
                    }
    
                    Id emailTempSignForPoolId;
                    String emailTempSignPoolName = (btnNameSendUpdateRemind == 'Send') ? AP_Constant.emailTemplateSignForPoolSend : AP_Constant.emailTemplateSignForPoolUpdate;
                    List<Messaging.SingleEmailMessage> lstMailsToSend =  new List<Messaging.SingleEmailMessage>();
                    Set<String> setPoolTrackingNo = new Set<String>();
                    Id userId = UserInfo.getUserId();
                    Id pccIdOfProgram;
                    List<Request__c> lstPoolReq = new List<Request__c>();
                    
                    List<EmailTemplate> lstEmailTempSignPool= [SELECT Id, Name FROM EmailTemplate WHERE Name = :emailTempSignPoolName];
                    emailTempSignForPoolId = lstEmailTempSignPool[0].Id;
    
                    Messaging.SingleEmailMessage mPool = new Messaging.SingleEmailMessage();       
                    mPool = Messaging.renderStoredEmailTemplate(emailTempSignForPoolId, userId, lstRequests[0].Id);
    
                    for(Request__c request : lstRequests){
                        if(request.Pool__r != null){
                            Pool__c pool = request.Pool__r;
                            pccIdOfProgram = request.program__r.principalcedingcompany__c;
                            request.SentBy__c = connectedUser.Id;
    
                            if(!setPoolTrackingNo.contains(pool.PoolTrackNumber__c)){//RRA - ticket 1873 - using PoolTrackNumber__c to send one mail - 08082024
                                setPoolTrackingNo.add(pool.PoolTrackNumber__c);//RRA - ticket 1873 - using PoolTrackNumber__c to send one mail - 08082024
                                Id requestId = request.Id;
                                Messaging.SingleEmailMessage m = new Messaging.SingleEmailMessage();
                                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                                List<String> lstEmailsToSend = new List<String>();
                                System.debug('##BBH POOL '+pool.name);
                                System.debug('##BBH POOLtrack '+pool.PoolTrackNumber__c);
                                m.setSaveAsActivity(false);
                                m.setTemplateId(emailTempSignForPoolId);
                                m.setTargetObjectId(userId);
                                m.setWhatId(requestId);
                                lstEmailsToSend.add(mapPoolIdToEmail.get(pool.Id));
                                mail.setToAddresses(lstEmailsToSend);
                                mail.setReplyTo(UserInfo.getUserEmail());
                                mail.setSenderDisplayName(UserInfo.getFirstName() + ' ' + UserInfo.getLastName());
                                
                                /*OrgWideEmailAddress[] owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'actor.po@axa.com'];
                                if (owea.size()>0) {
                                    mail.setOrgWideEmailAddressId(owea.get(0).Id);
                                }*/
    
                                if(lstCCEmailsToSend.size() > 0){
                                    mail.setCcAddresses(lstCCEmailsToSend);
                                }
    
                                mail.setSubject(mPool.getSubject());
                                String htmlBody = mPool.htmlBody;
                                String htmlTreatysListReinsurers = '<br/>';
    
                                if(btnNameSendUpdateRemind == 'Send'){
                                    String lstTreaties = '';
                                    List<String> lstPoolTreatyIds = new List<String>();//RRA - ticket 1557 - 11082023
                                    Set<String> SetPoolTreatyIds = new Set<String>();//RRA - ticket 1557 - 11082023
                                    List<String> lstPoolTreatyIdsUnique = new List<String>();//RRA - ticket 1557 - 11082023
                                    lstPoolTreatyIds = mapPoolIdToTreatyIds.get(pool.Id);
                                    SetPoolTreatyIds.addAll(lstPoolTreatyIds);//RRA - ticket 1557 - 11082023
                                    lstPoolTreatyIdsUnique.addAll(SetPoolTreatyIds);//RRA - ticket 1557 - 11082023
                                    
                                    //BBH 30.08.2024 - W-1873 - commented
                                    // for(Integer j = 0; j < lstPoolTreatyIdsUnique.size(); j++){
                                    //     System.debug(pool.name+' treaty before BBH : '+mapTreatyIdToName.get(lstPoolTreatyIdsUnique[j]));
                                    //     System.debug('<li style="text-align: left;">'+mapTreatyIdToName.get(lstPoolTreatyIdsUnique[j])+'</li>');
                                    //     lstTreaties += '<li style="text-align: left;">'+mapTreatyIdToName.get(lstPoolTreatyIdsUnique[j])+'</li>'; //RRA - ticket 1557 - 11082023
                                        
                                    // }

                                    //BBH 30.08.2024 - W-1873 - Regroupement treaties per Pool tracking number instead of Pool.Id
                                    for (String treatyName : mapPoolTrackNoTreatyName.get(pool.PoolTrackNumber__c)) {
                                        lstTreaties += '<li style="text-align: left;">'+treatyName+'</li>'; 
                                        System.debug(pool.name+' treaty BBH : '+treatyName);
                                        System.debug('<li style="text-align: left;">'+treatyName+'</li>');
                                    }
                                    //BBH 30.08.2024 - W-1873 - Regroupement treaties per Pool tracking number instead of Pool.Id
    
                                    htmlBody = htmlBody.replace('{listTreatyNames}', lstTreaties);
                                }
    
                                if(requestCommentExpectedAnsDate.ExpectedResponseDate__c != null){
                                    expectedAnsDate = requestCommentExpectedAnsDate.ExpectedResponseDate__c;
                                }
    
                                String linkToPool='/lightning/n/SignForPool?c__program=' + request.Program__c + '-' + request.program__r.principalcedingcompany__c + '-' + request.TECH_UWyear__c + '-' + request.Pool__c;
                                String domainURL = URL.getSalesforceBaseUrl().toExternalForm();
                                String htmlInternetLink = '<a href="' + domainURL + '/lightning/page/home">ACTOR NewGen Page</a>';
                                String signForPoolLink = '<a href="' + domainURL + linkToPool + '">link</a>';
    
                                htmlBody = htmlBody.replace('{InternetLink}', htmlInternetLink);
                                htmlBody = htmlBody.replace('{HomePageLink}', htmlInternetLink);
                                htmlBody = htmlBody.replace('{SignforPoolLink}', signForPoolLink);
    
                                if(strLstCCEmailDisplay != null ){
                                    htmlBody = htmlBody.replace('{contactEmail}', strLstCCEmailDisplay);
                                }else{
                                    htmlBody = htmlBody.replace('{contactEmail}', '');
                                }
    
                                htmlBody = htmlBody.replace('{ExpectedResponseDate}', String.valueOf(expectedAnsDate));
    
                                String strCommentReq = requestCommentExpectedAnsDate.Comments__c != null ? requestCommentExpectedAnsDate.Comments__c : '';
                                String commentStrDesigned = '<b style="color:blue";><font face="Arial" size="50px">' + strCommentReq + '</font></b>'; //RRA - ticket 1382 - 1912202
                                htmlBody = htmlBody.replace('{Comments}', commentStrDesigned); //RRA - ticket 1382 - 1912202
    
                                mail.setHtmlBody(htmlBody);
                                lstMailsToSend.add(mail);
                            }
                            
                            System.debug('lstMailsToSend 11 == ' + lstMailsToSend);
                            System.debug('BBH 1873 Number of emails ' + lstMailsToSend.size());
                            if(btnNameSendUpdateRemind == 'Send'){
                                request.TECH_ValidatorEmail__c = mapPoolIdToEmail.get(request.Pool__r.Id);
                                if(request.SignedShare__c == 0){
                                    request.ReinsurerStatus__c = AP_Constant.statusRequestSigned;
                                }
                            }
    
                            lstPoolReq.add(request);
                        }
                    }
                    System.debug('lstMailsToSend 22 == ' + lstMailsToSend);
                    if(lstMailsToSend.size() > 0){
                        Messaging.SendEmailResult[] results = Messaging.sendEmail((List<Messaging.Email>) lstMailsToSend);
                        if(results[0].success) {
                            mapResults.put('Success','Success');
                            if(btnNameSendUpdateRemind == 'Send'){
                                map<Id,Request__c> requestPoolMap = new map<Id,Request__c>(); //Avoid System.ListException: Duplicate id in list:
                                requestPoolMap.putall(lstPoolReq);
                                update requestPoolMap.values();
                                //update lstPoolReq;
                            }
                        }
                        else {
                            mapResults.put('Error', results[0].errors[0].message);
                        }
                    }
    
                    if(pccIdOfProgram != null){
                        sharePCCWithCustomIntUser(pccIdOfProgram);
                    }
                }
                System.debug('lstRequestId == ' + lstRequestId);
                if(stageType == 'Quote' || stageType == 'Placement' || stageType == 'Signing'){
                    System.debug('Begin Quote');
                    String queryRequest = 'select Id, Program__r.Name, Program__r.PrincipalCedingCompany__r.Name, Program__r.TECH_StageName__c, Reinsurer__r.Name, TECH_TreatyName__c, TECH_SectionName__c, TECH_ReinsurerName__c, Special_Acceptance__r.Name,'
                        + strRequestFields
                        + ' from Request__c where (Id IN :lstRequestId) ';
    
                   lstRequest = Database.query(queryRequest);
                    String programName = null;
                    String cedingCompanyName = null;
    
                    if(lstRequest.size() > 0){
                        programName = lstRequest[0].Program__r.Name;
                        cedingCompanyName = lstRequest[0].Program__r.PrincipalCedingCompany__r.Name;
                    }
    
                    List<Request__c> lstRequestNewVersion = new List<Request__c>();
                    List<Request__c> lstRequestOriginal = new List<Request__c>();
                    List<Request__c> lstRequestDocVis = new List<Request__c>();
                    List<Id> lstOriginalRequestId = new List<Id>();
                    List<String> attach = new List<String>();
                    List<Request__c> lstDateNewversionToUpdated  = new List<Request__c>();
                    System.debug('lstRequest == ' + lstRequest);
                    
                    for(Request__c request : lstRequest){

                        // RRA - 1104 - 02/06/2022
                        if ( btnNameSendUpdateRemind == 'Update'){
                            if (request.LastVersionAnswered__c && request.LastVersionSent__c){
                                request.ExpectedResponseDate__c = dateEntryExpectedDate;
                                request.TECH_ExpectedAnsweredDate__c = dateEntryExpectedDate;
                                request.UpdateRequestDate__c = System.today();//RRA - VERSIONING
                                request.UpdateRequestByUser__c = connectedUser.Id; //RRA - VERSIONING
                                request.isUpdateRequest__c = true; //RRA - VERSIONING
                            }
                        }
                        if(expectedAnsDate >= Date.today() && request.ReinsurerStatus__c == AP_Constant.statusTimeout){
                            request.ReinsurerStatus__c = (btnNameSendUpdateRemind == 'Update' || btnNameSendUpdateRemind == 'Send') ? AP_Constant.statusSent :  request.ReinsurerStatus__c;
                            request.isUpdateRequest__c = (btnNameSendUpdateRemind == 'Update') ? true : request.isUpdateRequest__c; //RRA - VERSIONING
                        }
                        else if(btnNameSendUpdateRemind == 'Send'){
                            if(stageType == 'Signing' && request.SignedShare__c == 0){
                                request.isUpdateRequest__c = false; //RRA - VERSIONING
                                request.ReinsurerStatus__c = AP_Constant.statusRequestSigned;
                                request.ResponseDate__c = System.today();
                                lstSigningRequestSignedShare0.add(request);
                                setSigningRequestSignedShare0Id.add(request.Id);
                            }
                            else{
                                //RRA - VERSIONING
                                //request.ReinsurerStatus__c = (request.ReinsurerStatus__c == AP_Constant.statusAnswered) ? AP_Constant.statusAnswered : AP_Constant.statusSent; //RRA -  ticket 1528 - 23052023   
                            }
                            //RRA - VERSIONING
                            //request.LastSentDate__c = System.today();
                        // RRA - 1104 - 03/06/2022
                        }else if (btnNameSendUpdateRemind == 'Update'){
                            if (stageType == 'Signing' && request.LastVersionAnswered__c && request.LastVersionSent__c){
                                request.ExpectedResponseDate__c = dateEntryExpectedDate;
                                request.isUpdateRequest__c = true; //RRA - VERSIONING
                            }
                        }
    
                        request.TECH_LastSendUpdRemDate__c = System.today();
                        //request.LastSentDate__c = System.today();
                        if(requestCommentExpectedAnsDate.Comments__c != null){
                            request.Comments__c = requestCommentExpectedAnsDate.Comments__c;
                        }

                        //****** */
                        // RRA 01/06/2022 - 1104 this line is to deactivated because it's overwrites all the values ​​of the intermediate request of the field ExpectedResponseDate__c of Quote.
                        //*******
                       /* if(requestCommentExpectedAnsDate.ExpectedResponseDate__c != null){
                            request.ExpectedResponseDate__c = requestCommentExpectedAnsDate.ExpectedResponseDate__c;
                        }*/

                        
                        if(btnNameSendUpdateRemind == 'Send' && (stageType == 'Quote' || stageType == 'Placement' || stageType == 'Signing')){
                            valueMajor = request.VersionMajor__c + 1;
                            valueDateNextSending = request.UpdateRequestDate__c;
                            valueIdUser = request.UpdateRequestByUser__c;
                            System.debug('Begin Send Quote');
                            if (request.OriginalRequest__c == null){
                                if ((request.QuoteType__c == '1' && stageType == 'Quote') || stageType == 'Placement' || stageType == 'Signing'){
                                    if (request.ReinsurerStatus__c == AP_Constant.statusAnswered){
                                        request.ReinsurerStatus__c = AP_Constant.statusAnswered;
                                    }else if (request.ReinsurerStatus__c == AP_Constant.statusRefused){
                                        request.ReinsurerStatus__c = AP_Constant.statusRefused;
                                    }else {
                                        if(stageType == 'Signing' && request.SignedShare__c == 0){
                                            request.ReinsurerStatus__c = AP_Constant.statusRequestSigned;
                                        }else {
                                            request.ReinsurerStatus__c = AP_Constant.statusSent; 
                                        }
                                    }
                                }else if (request.QuoteType__c == '2' && stageType == 'Quote'){
                                    request.ReinsurerStatus__c = 'Informed'; 
                                }                            
                                request.isFirstSending__c = false;
                                request.isUpdateRequest__c = false; //RRA - VERSIONING
                                 //request.LastSentDate__c =  System.today();
                                 request.ExpectedResponseDate__c = dateEntryExpectedDate; 
                            }//RRA VERSIONING
                            else {
                                if (request.LastSentDate__c != null){
                                    if (request.UpdateRequestDate__c != null){
                                        request.UpdateRequestDate__c = valueDateNextSending;
                                        request.UpdateRequestByUser__c = valueIdUser;
                                    }else{
                                        request.UpdateRequestDate__c = System.today();
                                        request.UpdateRequestByUser__c = connectedUser.Id;
                                    }
                                }else{
                                    request.LastSentDate__c = System.today();
                                    request.SentBy__c = connectedUser.Id;
                                    request.isFirstSending__c = true;
                                    request.isUpdateRequest__c = false; //RRA - VERSIONING
                                    //request.UpdateRequestDate__c = (stageType == 'Quote' || stageType == 'Placement') ? null : request.UpdateRequestDate__c;
                                    //request.UpdateRequestByUser__c = (stageType == 'Quote' || stageType == 'Placement') ? null : request.UpdateRequestByUser__c;
                                    request.UpdateRequestDate__c = null;
                                    request.UpdateRequestByUser__c = null;
                                    
                                    
                                }
                            }
                            
                            //request.isUpdateRequest__c = false; //RRA - VERSIONING
                            request.LastVersionSent__c = false;
                            request.LastVersionAnswered__c = false;

                            // RRA - 18/05/2022 - 1104
                            if(request.VersionMajor__c == 0){
                                request.VersionMajor__c = 1;
                                request.LastSentDate__c = System.today();//RRA VERSIONING
                                request.SentBy__c = connectedUser.Id;
                            } 
                            
                            //lstRequestOriginal.add(request);

                            Request__c newVersionRequest = request.clone(false, false, false, false);
                            newVersionRequest.VersionMajor__c = valueMajor; // RRA - 18/05/2022 - 1104
                            
                            //RRA VERSIONING
                            if (newVersionRequest.QuoteType__c == '1' && stageType == 'Quote'){
                                newVersionRequest.ExpectedResponseDate__c = dateEntryExpectedDate; // RRA 01/06/2022 - 1104
                                newVersionRequest.TECH_ExpectedAnsweredDate__c = dateEntryExpectedDate;
                            }else if (newVersionRequest.QuoteType__c == '2' && stageType == 'Quote'){
                                newVersionRequest.ExpectedResponseDate__c = null;
                                newVersionRequest.TECH_ExpectedAnsweredDate__c = dateEntryExpectedDate;
                            }
                            if (stageType == 'Placement' || stageType == 'Signing'){
                                newVersionRequest.ExpectedResponseDate__c = dateEntryExpectedDate;
                            }
                           
                            if(request.OriginalRequest__c == null){
                                //newVersionRequest.VersionMajor__c = request.VersionMajor__c; 
                                newVersionRequest.OriginalRequest__c = request.Id;
                                if (request.QuoteType__c == '1' && stageType == 'Quote'){
                                    request.ExpectedResponseDate__c = dateEntryExpectedDate; // RRA 01/06/2022 - 1104
                                    request.TECH_ExpectedAnsweredDate__c = dateEntryExpectedDate;
                                }else if (request.QuoteType__c == '2' && stageType == 'Quote'){
                                    request.ExpectedResponseDate__c = null;
                                    request.TECH_ExpectedAnsweredDate__c = dateEntryExpectedDate;
                                }
                                if (stageType == 'Placement' || stageType == 'Signing'){
                                    newVersionRequest.ExpectedResponseDate__c = dateEntryExpectedDate;
                                }
                                //lstRequestOriginal.add(request);
                            }
                            else{
                                newVersionRequest.OriginalRequest__c = request.OriginalRequest__c;
                                lstOriginalRequestId.add(request.OriginalRequest__c);
                            }

    
                            // RRA - 939 delete icon attach and comment if document visibility don't exists
                            if (lstDocVisBroReins.size() == 0){
                                newVersionRequest.Utility_Icon_Attachment__c= ''; //RRA - 939
                            }
                            if (lstDocVisReins.size() == 0){
                                newVersionRequest.Utility_Icon_Attachment__c= ''; //RRA - 939
                            }
    
                            if (newVersionRequest.Broker__c!= null && newVersionRequest.Reinsurer__c != null ){
                                if (newVersionRequest.CommentsResponse__c == null){
                                    newVersionRequest.Utility_Icon_Comment__c= ''; //RRA - 939
                                }
                            }
                            if (newVersionRequest.Broker__c == null && newVersionRequest.Reinsurer__c != null ){
                                if (newVersionRequest.CommentsResponse__c == null){
                                    newVersionRequest.Utility_Icon_Comment__c= ''; //RRA - 939
                                }
                            }
    
                            newVersionRequest.LastVersionSent__c = true;
                            newVersionRequest.LastVersionAnswered__c = true;
                            newVersionRequest.isFirstSending__c = false; //RRA - VERSIONING
                            newVersionRequest.isUpdateRequest__c = false; //RRA - VERSIONING
                            //newVersionRequest.LastSentDate__c = System.today();
                            newVersionRequest.UpdateRequestDate__c = System.today(); //RRA - VERSIONING
                            newVersionRequest.UpdateRequestByUser__c = connectedUser.Id; //RRA - VERSIONING
                            if(newVersionRequest.ExpectedResponseDate__c < Date.today()){
                                newVersionRequest.ReinsurerStatus__c = AP_Constant.statusTimeout;
                            }
                            System.debug(' expectedAnsDate == ' +  expectedAnsDate);
                            //newVersionRequest.ExpectedResponseDate__c = expectedAnsDate;
                            newVersionRequest.TECH_Actor2Id__c = null;
                            lstRequestNewVersion.add(newVersionRequest);
    
                        }
    
                        if(request.OriginalRequest__c == null){
                            mapRequestSentByOriginalReqId.put(request.Id, request);
                        }
                        else{
                            mapRequestSentByOriginalReqId.put(request.OriginalRequest__c, request);
                        }
    
                        mapRequestToUpdateById.put(request.Id, request);
                    }
                    /*if(lstRequestOriginal.size() > 0){
                        update lstRequestOriginal;
                    }*/

                    System.debug('lstRequestOriginal == ' + lstRequestOriginal);
                    if(lstRequestNewVersion.size() > 0){
                        insert lstRequestNewVersion;
                        mapRequestNewVersionById = new Map<Id, Request__c>(lstRequestNewVersion);
                        //RRA VERSIONING
                        for (Request__c req : lstRequestNewVersion){
                            if (req.VersionMajor__c == 1 && req.VersionMinor__c == 0 && req.isUpdateRequest__c == false){
                                req.isFirstSending__c = true;
                                //req.UpdateRequestDate__c = (stageType == 'Quote' || stageType == 'Placement') ? null : req.UpdateRequestDate__c;
                                req.UpdateRequestDate__c = null;
                                //req.UpdateRequestByUser__c = (stageType == 'Quote' || stageType == 'Placement') ? null : req.UpdateRequestByUser__c;
                                req.UpdateRequestByUser__c = null;
                                
                            }
                            if (req.ResponseDate__c != null && req.ReinsurerStatus__c == AP_Constant.statusSent){
                                req.ResponseDate__c = null;
                                req.ResponseByUser__c = null;
                            }
                            mapIdReqLastRequest.put(req.OriginalRequest__c, req);
                        }
                      
                        update lstRequestNewVersion;
                    }
                    System.debug('mapRequestNewVersionById__Quote == ' + mapRequestNewVersionById);
    
                    if(lstDocumentVisibilityToInsert.size() > 0){
                        insert lstDocumentVisibilityToInsert;
                    }
    
                    System.enqueueJob(new LWC18_SendEmailForQuotePlaceSign(lstRequest, lstSigningRequestSignedShare0, lstAccountContact, btnNameSendUpdateRemind, stageType, lstCCEmailsToSend, strLstCCEmailDisplay, programName, cedingCompanyName, lstContractDoc, lstRenewDoc, mapListOfCompanyByContentVersionId, setSigningRequestSignedShare0Id, requestCommentExpectedAnsDate));
                }
                else if(stageType == 'Lead'){
                    Set<Id> setLeadChildRequestId = new Set<Id>();
                    Map<Id, List<Id>> mapChildLeadReqIdByParentLeadReq = new Map<Id, List<Id>>();
    
                    String queryLeadRequest = 'select Id, Program__r.Name, Program__r.PrincipalCedingCompany__r.Name, Program__r.TECH_StageName__c, Reinsurer__r.Name, TECH_TreatyName__c, TECH_SectionName__c, TECH_ReinsurerName__c,'
                            + strRequestFields
                            + ' from Request__c where (Id IN :lstRequestId) ';
    
                    List<Request__c> lstLeadRequestParent = Database.query(queryLeadRequest);
    
                    List<LeadRequestSelection__c> lstLeadRequestSelection = [SELECT Id, LeadRequestChild__r.Section__c, LeadRequestChild__r.Section__r.TECH_TreatyName__c
                                                                                    , LeadRequestChild__r.Section__r.Name, LeadRequestChild__c, LeadRequestParent__r.TECH_ReinsurerName__c
                                                                             FROM LeadRequestSelection__c
                                                                             WHERE LeadRequestParent__c IN :lstRequestId];
    
                    for(LeadRequestSelection__c leadRequestSelection : lstLeadRequestSelection){
                        setLeadChildRequestId.add(leadRequestSelection.LeadRequestChild__c);
                    }
    
                    String queryChildLeadRequest = 'select Id, Program__r.Name, Program__r.PrincipalCedingCompany__r.Name, Program__r.TECH_StageName__c, Reinsurer__r.Name, TECH_TreatyName__c, TECH_SectionName__c, TECH_ReinsurerName__c,'
                            + strRequestFields
                            + ' from Request__c where (Id IN :setLeadChildRequestId) ';
    
                    List<Request__c> lstLeadRequestChild = Database.query(queryChildLeadRequest);
    
                    String programName = null;
                    String cedingCompanyName = null;
    
                    if(lstLeadRequestChild.size() > 0){
                        programName = lstLeadRequestChild[0].Program__r.Name;
                        cedingCompanyName = lstLeadRequestChild[0].Program__r.PrincipalCedingCompany__r.Name;
                    }
    
                    List<Request__c> lstLeadRequestToInsert = new List<Request__c>();
                    List<LeadRequestSelection__c> lstLeadRequestSelectionNewVersion = new List<LeadRequestSelection__c>();
                    List<Id> lstOriginalRequestId = new List<Id>();
    
                    for(Request__c childRequest : lstLeadRequestChild){                       
                        if(requestCommentExpectedAnsDate.Comments__c != null){
                            childRequest.Comments__c = requestCommentExpectedAnsDate.Comments__c;
                        }

                        //****** */
                        // RRA 01/06/2022 - 1104 this line is to deactivated because it's overwrites all the values ​​of the intermediate request of the field ExpectedResponseDate__c of ChildtLead.
                        //*******

                       /*if(requestCommentExpectedAnsDate.ExpectedResponseDate__c != null){
                            childRequest.ExpectedResponseDate__c = requestCommentExpectedAnsDate.ExpectedResponseDate__c;
                        }*/

                        // RRA - 1104 - 02/06/2022
                        if ( btnNameSendUpdateRemind == 'Update'){
                            if (childRequest.LastVersionAnswered__c && childRequest.LastVersionSent__c){
                                childRequest.ExpectedResponseDate__c = dateEntryExpectedDate;
                                childRequest.TECH_ExpectedAnsweredDate__c = dateEntryExpectedDate;
                                childRequest.UpdateRequestDate__c = System.today();//RRA - VERSIONING
                                childRequest.UpdateRequestByUser__c = connectedUser.Id; //RRA - VERSIONING
                                childRequest.isUpdateRequest__c = true; //RRA - VERSIONING
                            }
                        }

                        if(expectedAnsDate >= Date.today() && childRequest.ReinsurerStatus__c == AP_Constant.statusTimeout){
                            childRequest.ReinsurerStatus__c = (btnNameSendUpdateRemind == 'Update' || btnNameSendUpdateRemind == 'Send') ? AP_Constant.statusSent :  childRequest.ReinsurerStatus__c;
                            childRequest.isUpdateRequest__c = (btnNameSendUpdateRemind == 'Update') ? true : childRequest.isUpdateRequest__c; //RRA - VERSIONING
                        }else if(btnNameSendUpdateRemind == 'Send'){
                            //childRequest.ReinsurerStatus__c = AP_Constant.statusSent;
                            //childRequest.ReinsurerStatus__c = (childRequest.ReinsurerStatus__c == AP_Constant.statusAnswered) ? AP_Constant.statusAnswered : AP_Constant.statusSent; //RRA -  ticket 1528 - 23052023    
                        }
    
                        childRequest.TECH_LastSendUpdRemDate__c = System.today();
                        //childRequest.LastSentDate__c = System.today();
                        
                        //RRA VERSIONING
                        if(btnNameSendUpdateRemind == 'Send'){

                            valueMajor = childRequest.VersionMajor__c + 1;// RRA - 1104 (Initialize value of VersionMajor__c in config)
                            valueReinsurerStatus = childRequest.ReinsurerStatus__c; //RRA VERSIONING
                            valueDateNextSending = childRequest.UpdateRequestDate__c;
                            valueIdUser = childRequest.UpdateRequestByUser__c;//RRA VERSIONING
                            
                            //RRA - VERSIONING
                            if (childRequest.OriginalRequest__c == null){
                                childRequest.isFirstSending__c = false;                           
                            }
                            else {
                                if (childRequest.LastSentDate__c != null){
                                    if (childRequest.UpdateRequestDate__c != null){
                                        childRequest.UpdateRequestDate__c = valueDateNextSending;
                                        childRequest.UpdateRequestByUser__c = valueIdUser; //RRA VERSIONING
                                    }else{
                                        childRequest.UpdateRequestDate__c = System.today();
                                        childRequest.UpdateRequestByUser__c = connectedUser.Id;//RRA VERSIONING
                                    }
                                }else {
                                    childRequest.LastSentDate__c = System.today();
                                    childRequest.isFirstSending__c = true;
                                    childRequest.SentBy__c = connectedUser.Id;
                                    childRequest.UpdateRequestDate__c = null;
                                    childRequest.UpdateRequestByUser__c = null;
                                }
                            }
                            
                            //RRA VERSIONING
                            /*if (childRequest.LastSentDate__c != null){
                                if (childRequest.UpdateRequestDate__c != null){
                                    childRequest.UpdateRequestDate__c = valueDateNextSending;
                                }else{
                                    childRequest.UpdateRequestDate__c = System.today();
                                }
                                childRequest.isFirstSending__c = false;
                                childRequest.ResponseDate__c = null;
                            }else {
                                childRequest.LastSentDate__c = System.today();
                                childRequest.isFirstSending__c = true;
                                childRequest.ResponseDate__c = null;
                            }*/

                              //RRA - 1104
                              if(childRequest.VersionMajor__c == 0){
                                childRequest.VersionMajor__c = 1;
                                childRequest.LastSentDate__c = System.today();//RRA VERSIONING
                                childRequest.SentBy__c = connectedUser.Id;
                                childRequest.ExpectedResponseDate__c = dateEntryExpectedDate;
                                childRequest.TECH_ExpectedAnsweredDate__c = dateEntryExpectedDate;
                            } 
                            //childRequest.isUpdateRequest__c = false; //RRA - VERSIONING
                            childRequest.LastVersionSent__c = false;
                            childRequest.LastVersionAnswered__c = false;
                            if (childRequest.ReinsurerStatus__c == AP_Constant.statusAnswered){
                                childRequest.ReinsurerStatus__c = AP_Constant.statusAnswered;
                            }else if (childRequest.ReinsurerStatus__c == AP_Constant.statusRefused){
                                childRequest.ReinsurerStatus__c = AP_Constant.statusRefused;
                            }else {
                                childRequest.ReinsurerStatus__c = AP_Constant.statusSent; 
                            }
                            //childRequest.ReinsurerStatus__c = (childRequest.ReinsurerStatus__c == AP_Constant.statusAnswered) ? AP_Constant.statusAnswered : AP_Constant.statusSent; //RRA -  ticket 1528 - 23052023    
                            Request__c newChildVersionRequest = childRequest.clone(false, false, false, false);
                            newChildVersionRequest.VersionMajor__c = valueMajor; // RRA - 1104
                            newChildVersionRequest.ExpectedResponseDate__c = dateEntryExpectedDate; // RRA 01/06/2022 - 1104
                            newChildVersionRequest.TECH_ExpectedAnsweredDate__c = dateEntryExpectedDate;
                            //need to set Original Parent Request Id
                            //hence create a map of parentId by childId
                            if(childRequest.OriginalRequest__c == null){
                                newChildVersionRequest.OriginalRequest__c = childRequest.Id;
                                childRequest.ExpectedResponseDate__c = dateEntryExpectedDate; // RRA 01/06/2022 - 1104
                                childRequest.TECH_ExpectedAnsweredDate__c = dateEntryExpectedDate;
                            }
                            else{
                                newChildVersionRequest.OriginalRequest__c = childRequest.OriginalRequest__c;
                                lstOriginalRequestId.add(childRequest.OriginalRequest__c);
                            }
    
                            if(newChildVersionRequest.ExpectedResponseDate__c < Date.today()){
                                newChildVersionRequest.ReinsurerStatus__c = AP_Constant.statusTimeout;
                            }
    
                            // RRA - 939 delete icon attach and comment if document visibility don't exists
                            if (lstDocVisBroReins.size() == 0){
                                newChildVersionRequest.Utility_Icon_Attachment__c= ''; //RRA - 939
                            }
                            if (lstDocVisReins.size() == 0){
                                newChildVersionRequest.Utility_Icon_Attachment__c= ''; //RRA - 939
                            }
    
                            if (newChildVersionRequest.Broker__c!= null && newChildVersionRequest.Reinsurer__c != null ){
                                if (newChildVersionRequest.CommentsResponse__c == null){
                                    newChildVersionRequest.Utility_Icon_Comment__c= ''; //RRA - 939
                                }
                            }
                            if (newChildVersionRequest.Broker__c == null && newChildVersionRequest.Reinsurer__c != null ){
                                if (newChildVersionRequest.CommentsResponse__c == null){
                                    newChildVersionRequest.Utility_Icon_Comment__c= ''; //RRA - 939
                                }
                            }
                            newChildVersionRequest.isUpdateRequest__c = false; //RRA - VERSIONING
                            newChildVersionRequest.LastVersionSent__c = true;
                            newChildVersionRequest.LastVersionAnswered__c = true;
                            newChildVersionRequest.TECH_OldRequestId__c = childRequest.Id;
                            newChildVersionRequest.TECH_Actor2Id__c = null;
                            newChildVersionRequest.ReinsurerStatus__c = AP_Constant.statusSent; //RRA - VERSIONING
                            newChildVersionRequest.UpdateRequestDate__c = System.today();//RRA VERSIONING
                            newChildVersionRequest.UpdateRequestByUser__c = connectedUser.Id;//RRA VERSIONING
                            newChildVersionRequest.isFirstSending__c = false; //RRA - VERSIONING
                            lstLeadRequestToInsert.add(newChildVersionRequest);
                        }
                    
                        if(childRequest.OriginalRequest__c == null){
                            mapRequestSentByOriginalReqId.put(childRequest.Id, childRequest);
                        }
                        else{
                            mapRequestSentByOriginalReqId.put(childRequest.OriginalRequest__c, childRequest);
                        }
                        
    
                        mapRequestToUpdateById.put(childRequest.Id, childRequest);
                    }
            
                    for(Request__c parentRequest : lstLeadRequestParent){
                        if(requestCommentExpectedAnsDate.Comments__c != null){
                            parentRequest.Comments__c = requestCommentExpectedAnsDate.Comments__c;
                        }
                        
                        System.debug ('requestCommentExpectedAnsDate.ExpectedResponseDate__c == ' + requestCommentExpectedAnsDate.ExpectedResponseDate__c);
                        
                         //****** */
                        // RRA 01/06/2022 - 1104 this line is to deactivated because it's overwrites all the values ​​of the intermediate request of the field ExpectedResponseDate__c of ParentLead.
                        //*******

                        /*if(requestCommentExpectedAnsDate.ExpectedResponseDate__c != null){
                            parentRequest.ExpectedResponseDate__c = requestCommentExpectedAnsDate.ExpectedResponseDate__c;
                        }*/

                        // RRA - 1104 - 02/06/2022
                        if (btnNameSendUpdateRemind == 'Update'){
                            if (parentRequest.LastVersionAnswered__c && parentRequest.LastVersionSent__c){
                                parentRequest.ExpectedResponseDate__c = dateEntryExpectedDate;
                                parentRequest.TECH_ExpectedAnsweredDate__c = dateEntryExpectedDate;
                                parentRequest.UpdateRequestDate__c = System.today();//RRA - VERSIONING
                                parentRequest.UpdateRequestByUser__c = connectedUser.Id;
                                parentRequest.isUpdateRequest__c = true; //RRA - VERSIONING
                            }
                        }
    
                        if(expectedAnsDate >=  Date.today() && btnNameSendUpdateRemind == 'Update' && parentRequest.ReinsurerStatus__c == AP_Constant.statusTimeout){
                            parentRequest.ReinsurerStatus__c = AP_Constant.statusSent;
                            parentRequest.isUpdateRequest__c = true; //RRA - VERSIONING
                        }
                        else if(btnNameSendUpdateRemind == 'Send'){
                            //parentRequest.ReinsurerStatus__c = AP_Constant.statusSent;
                            //parentRequest.ReinsurerStatus__c = (parentRequest.ReinsurerStatus__c == AP_Constant.statusAnswered) ? AP_Constant.statusAnswered : AP_Constant.statusSent; //RRA -  ticket 1528 - 23052023    
                        }

                        parentRequest.TECH_LastSendUpdRemDate__c = System.today();
                        //parentRequest.LastSentDate__c = System.today();
                        
                        if(btnNameSendUpdateRemind == 'Send'){
                            valueMajor =  parentRequest.VersionMajor__c + 1; // RRA - 1104
                            valueReinsurerStatus = parentRequest.ReinsurerStatus__c; //RRA VERSIONING
                            valueDateNextSending = parentRequest.UpdateRequestDate__c;
                            valueIdUser = parentRequest.UpdateRequestByUser__c;//RRA VERSIONING

                            //RRA - VERSIONING
                            if (parentRequest.OriginalRequest__c == null){
                                parentRequest.isFirstSending__c = false;                           
                            }
                            else {
                                if (parentRequest.LastSentDate__c != null){
                                    if (parentRequest.UpdateRequestDate__c != null){
                                        parentRequest.UpdateRequestDate__c = valueDateNextSending;
                                        parentRequest.UpdateRequestByUser__c = valueIdUser;//RRA VERSIONING
                                    }else{
                                        parentRequest.UpdateRequestDate__c = System.today();
                                        parentRequest.UpdateRequestByUser__c = connectedUser.Id;//RRA VERSIONING
                                    }
                                }else {
                                    parentRequest.LastSentDate__c = System.today();
                                    parentRequest.isFirstSending__c = true;
                                    parentRequest.SentBy__c = connectedUser.Id; 
                                    parentRequest.UpdateRequestDate__c = null;
                                    parentRequest.UpdateRequestByUser__c = null;
                                }
                            }
                            
                            
                            //RRA VERSIONING
                            /*if (parentRequest.LastSentDate__c != null){
                                if (parentRequest.UpdateRequestDate__c != null){
                                    parentRequest.UpdateRequestDate__c = valueDateNextSending;
                                }else{
                                    parentRequest.UpdateRequestDate__c = System.today();
                                }
                                parentRequest.isFirstSending__c = false;
                                parentRequest.ResponseDate__c = null;
                            }else {
                                parentRequest.LastSentDate__c = System.today();
                                parentRequest.isFirstSending__c = true;
                                parentRequest.ResponseDate__c = null;
                            }*/

                            //RRA - 1104
                            if(parentRequest.VersionMajor__c == 0){
                                parentRequest.VersionMajor__c = 1;
                                parentRequest.LastSentDate__c = System.today();//RRA VERSIONING
                                parentRequest.SentBy__c = connectedUser.Id;
                                //parentRequest.ExpectedResponseDate__c = dateEntryExpectedDate;
                            }

                            System.debug ('valueMajor== '+ valueMajor); 
                            //parentRequest.isUpdateRequest__c = false; //RRA - VERSIONING                           
                            parentRequest.LastVersionSent__c = false;
                            parentRequest.LastVersionAnswered__c = false;
                            if (parentRequest.ReinsurerStatus__c == AP_Constant.statusAnswered){
                                parentRequest.ReinsurerStatus__c = AP_Constant.statusAnswered;
                            }else if (parentRequest.ReinsurerStatus__c == AP_Constant.statusRefused){
                                parentRequest.ReinsurerStatus__c = AP_Constant.statusRefused;
                            }else {
                                parentRequest.ReinsurerStatus__c = AP_Constant.statusSent; 
                            }
                            //parentRequest.ReinsurerStatus__c = (parentRequest.ReinsurerStatus__c == AP_Constant.statusAnswered) ? AP_Constant.statusAnswered : AP_Constant.statusSent; //RRA -  ticket 1528 - 23052023    
                            Request__c newParentVersionRequest = parentRequest.clone(false, false, false, false);
                            newParentVersionRequest.VersionMajor__c = valueMajor;  // RRA - 1104
                            newParentVersionRequest.ExpectedResponseDate__c = dateEntryExpectedDate; // RRA 01/06/2022 - 1104
                            newParentVersionRequest.TECH_ExpectedAnsweredDate__c = dateEntryExpectedDate;
                            newParentVersionRequest.UpdateRequestDate__c = System.today();//RRA VERSIONING
                            newParentVersionRequest.UpdateRequestByUser__c = connectedUser.Id;//RRA VERSIONING
                            if(parentRequest.OriginalRequest__c == null){
                                newParentVersionRequest.OriginalRequest__c = parentRequest.Id;
                                parentRequest.ExpectedResponseDate__c = dateEntryExpectedDate; // RRA 01/06/2022 - 1104
                                parentRequest.TECH_ExpectedAnsweredDate__c = dateEntryExpectedDate;
                            }
                            else{
                                newParentVersionRequest.OriginalRequest__c = parentRequest.OriginalRequest__c;
                                lstOriginalRequestId.add(parentRequest.OriginalRequest__c);
                            }
    
                            if(newParentVersionRequest.ExpectedResponseDate__c < Date.today()){
                                newParentVersionRequest.ReinsurerStatus__c = AP_Constant.statusTimeout;
                            }
    
                            // RRA - 939 delete icon attach and comment if document visibility don't exists
                            if (lstDocVisBroReins.size() == 0){
                                newParentVersionRequest.Utility_Icon_Attachment__c= ''; //RRA - 939
                            }
                            if (lstDocVisReins.size() == 0){
                                newParentVersionRequest.Utility_Icon_Attachment__c= ''; //RRA - 939
                            }
    
                            if (newParentVersionRequest.Broker__c!= null && newParentVersionRequest.Reinsurer__c != null ){
                                if (newParentVersionRequest.CommentsResponse__c == null){
                                    newParentVersionRequest.Utility_Icon_Comment__c= ''; //RRA - 939
                                }
                            }
                            if (newParentVersionRequest.Broker__c == null && newParentVersionRequest.Reinsurer__c != null ){
                                if (newParentVersionRequest.CommentsResponse__c == null){
                                    newParentVersionRequest.Utility_Icon_Comment__c= ''; //RRA - 939
                                }
                            }
                            newParentVersionRequest.isUpdateRequest__c = false; //RRA - VERSIONING
                            newParentVersionRequest.LastVersionSent__c = true;
                            newParentVersionRequest.LastVersionAnswered__c = true;
                            newParentVersionRequest.TECH_OldRequestId__c = parentRequest.Id;
                            newParentVersionRequest.TECH_Actor2Id__c = null;
                            //newParentVersionRequest.ReinsurerStatus__c = AP_Constant.statusSent; //RRA - VERSIONING
                            newParentVersionRequest.isFirstSending__c = false; //RRA - VERSIONING

                            lstLeadRequestToInsert.add(newParentVersionRequest);
                        }
    
                        if(parentRequest.OriginalRequest__c == null){
                            mapRequestSentByOriginalReqId.put(parentRequest.Id, parentRequest);
                        }
                        else{
                            mapRequestSentByOriginalReqId.put(parentRequest.OriginalRequest__c, parentRequest);
                        }
    
                        mapRequestToUpdateById.put(parentRequest.Id, parentRequest);

                        System.debug ('parentRequest.ExpectedResponseDate__c == ' + mapRequestToUpdateById.get(parentRequest.Id).ExpectedResponseDate__c);
                    }
                    
                    System.debug ('mapRequestSentByOriginalReqId == ' + mapRequestSentByOriginalReqId);
                    
                    System.debug ('mapRequestToUpdateById == ' + mapRequestToUpdateById);

                    if(btnNameSendUpdateRemind == 'Send'){
                        if(lstLeadRequestToInsert.size() > 0) {
                            insert lstLeadRequestToInsert;
                            /*for (Request__c reqLead : lstLeadRequestToInsert){
                                if (reqLead.VersionMajor__c == 1 && reqLead.VersionMinor__c == 0){
                                    if(btnNameSendUpdateRemind == 'Send'){
                                        reqLead.isFirstSending__c = true;
                                        reqLead.UpdateRequestDate__c = null;
                                        reqLead.UpdateRequestByUser__c = null;
                                    }else if(btnNameSendUpdateRemind == 'Update'){
                                        reqLead.UpdateRequestDate__c =  reqLead.UpdateRequestDate__c;
                                        reqLead.UpdateRequestByUser__c =  reqLead.UpdateRequestByUser__c;
                                        reqLead.isUpdateRequest__c = true; //RRA - VERSIONING
                                    }
                                    
                                }if (reqLead.ResponseDate__c != null && reqLead.ReinsurerStatus__c == AP_Constant.statusSent){
                                    reqLead.ResponseDate__c = null;
                                    reqLead.ResponseByUser__c = null;
                                }
                            }
                            update lstLeadRequestToInsert;*/
                        }
    
                        mapRequestNewVersionById = new Map<Id, Request__c>(lstLeadRequestToInsert);
    
                        Map<Id, Id> mapNewRequestIdByOldRequestLead = new Map<Id, Id>();
    
                        for(Request__c newLeadRequest : lstLeadRequestToInsert){
                            mapNewRequestIdByOldRequestLead.put(newLeadRequest.TECH_OldRequestId__c, newLeadRequest.Id);
                        }
    
                        for(LeadRequestSelection__c leadRequestSelection: lstLeadRequestSelection){
                            if(mapNewRequestIdByOldRequestLead.containsKey(leadRequestSelection.LeadRequestParent__c) && mapNewRequestIdByOldRequestLead.containsKey(leadRequestSelection.LeadRequestChild__c)){
                                LeadRequestSelection__c newLeadRequestSelection = leadRequestSelection.clone(false,false,false,false);
                                newLeadRequestSelection.LeadRequestChild__c = mapNewRequestIdByOldRequestLead.get(leadRequestSelection.LeadRequestChild__c);
                                newLeadRequestSelection.LeadRequestParent__c = mapNewRequestIdByOldRequestLead.get(leadRequestSelection.LeadRequestParent__c);
                                lstLeadRequestSelectionNewVersion.add(newLeadRequestSelection);
                            }
                        }
    
                        if(lstLeadRequestSelectionNewVersion.size() > 0){
                            insert lstLeadRequestSelectionNewVersion;
                        }
                    }
                    
                    //RRA VERSIONING
                    if(lstLeadRequestToInsert.size() > 0) {
                        for (Request__c reqLead : lstLeadRequestToInsert){
                            mapIdReqLastRequest.put(reqLead.OriginalRequest__c, reqLead);
                            if (reqLead.VersionMajor__c == 1 && reqLead.VersionMinor__c == 0 && reqLead.isUpdateRequest__c == false){
                                if(btnNameSendUpdateRemind == 'Send'){
                                    reqLead.isFirstSending__c = true;
                                    reqLead.UpdateRequestDate__c = null;
                                    reqLead.UpdateRequestByUser__c = null;
                                    reqLead.isUpdateRequest__c = false; //RRA - VERSIONING
                                }else if(btnNameSendUpdateRemind == 'Update'){
                                    reqLead.UpdateRequestDate__c =  reqLead.UpdateRequestDate__c;
                                    reqLead.UpdateRequestByUser__c =  reqLead.UpdateRequestByUser__c;
                                    reqLead.isUpdateRequest__c = true; //RRA - VERSIONING
                                }
                                
                            }if (reqLead.ResponseDate__c != null && reqLead.ReinsurerStatus__c == AP_Constant.statusSent){
                                reqLead.ResponseDate__c = null;
                                reqLead.ResponseByUser__c = null;
                            }
                        }
                        update lstLeadRequestToInsert;
                    }
    
                    if(lstDocumentVisibilityToInsert.size() > 0){
                        insert lstDocumentVisibilityToInsert;
                    }
                    
                    //update lstLeadRequestParent; //RRA VERSIONING
    
                    System.enqueueJob(new LWC18_SendEmailForLead(lstLeadRequestParent, lstAccountContact, programId, btnNameSendUpdateRemind, lstCCEmailsToSend, strLstCCEmailDisplay, lstContractDoc, lstRenewDoc, mapListOfCompanyByContentVersionId, programName, cedingCompanyName, expectedAnsDate, comment));
                }

                //RRA - VERSIONING
                List<Request__c> lstRequestVersionReinsurerStatus = [SELECT Id, ReinsurerStatus__c, QuoteOnBehalf__c, LeadOnBehalf__c, PlacementOnBehalf__c, TECH_ExpectedAnsweredDate__c, ResponseDate__c, VersionMinor__c, QuoteType__c, isUpdateRequest__c,  UpdateRequestByUser__c, isFirstSending__c, ResponseByUser__c, UpdateRequestDate__c, OriginalRequest__c, ExpectedResponseDate__c, TECH_LastSendUpdRemDate__c, LastSentDate__c, SentBy__c, CommentsResponse__c, Broker__c,Reinsurer__c, VersionMajor__c, LastVersionSent__c, LastVersionAnswered__c
                                                                     FROM Request__c 
                                                                     WHERE (Id IN :mapRequestSentByOriginalReqId.keySet() OR OriginalRequest__c IN :mapRequestSentByOriginalReqId.keySet())
                                                                     AND (Id NOT IN :mapRequestToUpdateById.keySet() AND OriginalRequest__c NOT IN :mapRequestToUpdateById.keySet())
                                                                     AND (Id NOT IN :mapRequestNewVersionById.keySet() AND OriginalRequest__c NOT IN :mapRequestNewVersionById.keySet())];

                 // RRA - 18/05/2022 - 1104
                Request__c  lastVersionReq = new Request__c();
                if(btnNameSendUpdateRemind == 'Send'){
                    lastVersionReq = mapRequestNewVersionById.values().get(0); //get the last request updated
                }else{
                    lastVersionReq = mapRequestSentByOriginalReqId.values().get(0);
                }
                System.debug('lastVersionReq' + lastVersionReq);
                System.debug('lastVersionReq.ReinsurerStatus__c : ' + lastVersionReq.ReinsurerStatus__c);
                
                System.debug('mapIdReqLastRequest : ' + mapIdReqLastRequest);
                
                
                //System.debug('lastVersionReq.VersionMajor__c : ' + lastVersionReq.VersionMajor__c);

                System.debug('lstRequestVersionReinsurerStatus == ' + lstRequestVersionReinsurerStatus);
                
                /*if (lastVersionReq != null){
                    for (Request__c reqlastV : mapRequestNewVersionById.values()){
                        setIdLastV.add(reqlastV.OriginalRequest__c);
                    }
                    if (setIdLastV != null){
                        for (Request__c req : [SELECT Id, isFirstSending__c,OriginalRequest__c,RecordType.Name, ResponseDate__c, ReinsurerStatus__c, Quote__c, PlacementParticipation__c, ReasonRefusal__c, ResponseByUser__c, LastVersionAnswered__c,LastVersionSent__c  FROM Request__c WHERE Program__c =:programId AND Id IN: setIdLastV]){
                            if (req.OriginalRequest__c == null ){

                            }
                        }
                    }
                }*/

                for(Request__c request : lstRequestVersionReinsurerStatus){
                    Id originalReqId;
                    if(request.OriginalRequest__c == null){
                        originalReqId = request.Id;
                    }
                    else{
                        originalReqId = request.OriginalRequest__c;
                    }
    
                    //Request__c requestSent = mapRequestSentByOriginalReqId.get(originalReqId); // mapRequestSentByOriginalReqId (key : IdOriginalReequest , Values : requestSent) because mapRequestSentByOriginalReqId do not contain the last request
    
                    //request.ReinsurerStatus__c = lastVersionReq.ReinsurerStatus__c;
                
                    if(request.OriginalRequest__c == null) {
                        //RRA - VERSIONING
                        //if(btnNameSendUpdateRemind == 'Send' || btnNameSendUpdateRemind == 'Update'){
		                    /*request.ReinsurerStatus__c = lastVersionReq != null ?  lastVersionReq.ReinsurerStatus__c : valueReinsurerStatus; //RRA - VERSIONING
                            request.LastSentDate__c = (lastVersionReq != null && btnNameSendUpdateRemind == 'Send' ) ?  lastVersionReq.LastSentDate__c : request.LastSentDate__c; //RRA - VERSIONING
                            request.SentBy__c = (lastVersionReq != null && btnNameSendUpdateRemind == 'Send' ) ?  lastVersionReq.SentBy__c : request.SentBy__c; //RRA - VERSIONING
                            request.ResponseDate__c = lastVersionReq != null ? lastVersionReq.ResponseDate__c : request.ResponseDate__c; //RRA - VERSIONING
                            request.ResponseByUser__c = lastVersionReq != null ? lastVersionReq.ResponseByUser__c : request.ResponseByUser__c; //RRA - VERSIONING
                            request.UpdateRequestDate__c = lastVersionReq != null ?  lastVersionReq.UpdateRequestDate__c : request.UpdateRequestDate__c; //RRA - VERSIONING
                            request.UpdateRequestByUser__c = lastVersionReq != null ?  lastVersionReq.UpdateRequestByUser__c : request.UpdateRequestByUser__c; //RRA - VERSIONING
                            request.VersionMajor__c = valueMajor != null ? lastVersionReq.VersionMajor__c : request.VersionMajor__c; // RRA - 1104 - 02/06/2022*/
                            
                            request.VersionMajor__c = (btnNameSendUpdateRemind == 'Send' ) ? mapIdReqLastRequest.get(request.Id).VersionMajor__c : request.VersionMajor__c;
                            request.VersionMinor__c = (btnNameSendUpdateRemind == 'Send' ) ? mapIdReqLastRequest.get(request.Id).VersionMinor__c : request.VersionMinor__c;
                            request.ReinsurerStatus__c = (btnNameSendUpdateRemind == 'Send') ? mapIdReqLastRequest.get(request.Id).ReinsurerStatus__c : (btnNameSendUpdateRemind == 'Update') ? mapRequestSentByOriginalReqId.get(request.Id).ReinsurerStatus__c : valueReinsurerStatus;
                            request.LastSentDate__c = (btnNameSendUpdateRemind == 'Send' ) ?  mapIdReqLastRequest.get(request.Id).LastSentDate__c : request.LastSentDate__c; //RRA - VERSIONING
                            request.SentBy__c = (btnNameSendUpdateRemind == 'Send' ) ?  mapIdReqLastRequest.get(request.Id).SentBy__c : request.SentBy__c; //RRA - VERSIONING
                            request.ResponseDate__c = (request.ResponseDate__c != null && btnNameSendUpdateRemind == 'Send') ? mapIdReqLastRequest.get(request.Id).ResponseDate__c : request.ResponseDate__c;
                            request.ResponseByUser__c = (request.ResponseByUser__c != null && btnNameSendUpdateRemind == 'Send') ? mapIdReqLastRequest.get(request.Id).ResponseByUser__c : request.ResponseByUser__c;
                            request.QuoteOnBehalf__c = (btnNameSendUpdateRemind == 'Send' ) ? mapIdReqLastRequest.get(request.Id).QuoteOnBehalf__c : request.QuoteOnBehalf__c;
                            request.LeadOnBehalf__c = (btnNameSendUpdateRemind == 'Send' ) ? mapIdReqLastRequest.get(request.Id).LeadOnBehalf__c : request.LeadOnBehalf__c;
                            request.PlacementOnBehalf__c = (btnNameSendUpdateRemind == 'Send' ) ? mapIdReqLastRequest.get(request.Id).PlacementOnBehalf__c : request.PlacementOnBehalf__c;
                            request.UpdateRequestDate__c = (btnNameSendUpdateRemind == 'Send') ? mapIdReqLastRequest.get(request.Id).UpdateRequestDate__c : (btnNameSendUpdateRemind == 'Update') ? System.today() : request.UpdateRequestDate__c;
                            request.UpdateRequestByUser__c = (btnNameSendUpdateRemind == 'Send') ? mapIdReqLastRequest.get(request.Id).UpdateRequestByUser__c : (btnNameSendUpdateRemind == 'Update') ? connectedUser.Id : request.UpdateRequestByUser__c;
                            //request.ExpectedResponseDate__c = request.ReinsurerStatus__c != 'Informed' ? dateEntryExpectedDate : null;
                            request.ExpectedResponseDate__c = (btnNameSendUpdateRemind == 'Send' && request.ReinsurerStatus__c != 'Informed') ? mapIdReqLastRequest.get(request.Id).ExpectedResponseDate__c :  (btnNameSendUpdateRemind == 'Send' && request.ReinsurerStatus__c == 'Informed') ? null : (btnNameSendUpdateRemind == 'Update') ? mapRequestSentByOriginalReqId.get(request.Id).ExpectedResponseDate__c : request.ExpectedResponseDate__c;
                            request.TECH_ExpectedAnsweredDate__c = (btnNameSendUpdateRemind == 'Send' && request.ReinsurerStatus__c != 'Informed') ? mapIdReqLastRequest.get(request.Id).TECH_ExpectedAnsweredDate__c : (btnNameSendUpdateRemind == 'Update') ? mapRequestSentByOriginalReqId.get(request.Id).TECH_ExpectedAnsweredDate__c : request.TECH_ExpectedAnsweredDate__c;
                            request.isUpdateRequest__c = (btnNameSendUpdateRemind == 'Send') ? mapIdReqLastRequest.get(request.Id).isUpdateRequest__c : (btnNameSendUpdateRemind == 'Update') ? mapRequestSentByOriginalReqId.get(request.Id).isUpdateRequest__c : request.isUpdateRequest__c;
                            
                             //request.ResponseDate__c =  mapIdReqLastRequest.get(request.Id).ResponseDate__c != null ? mapIdReqLastRequest.get(request.Id).ResponseDate__c : request.ResponseDate__c; //RRA - VERSIONING
                            //request.ResponseByUser__c = mapIdReqLastRequest.get(request.Id).ResponseByUser__c != null ? mapIdReqLastRequest.get(request.Id).ResponseByUser__c : request.ResponseByUser__c; //RRA - VERSIONING
                            //request.UpdateRequestDate__c =  (btnNameSendUpdateRemind == 'Update' ) ? System.today() : request.ResponseDate__c;//RRA - VERSIONING
                            //request.UpdateRequestByUser__c = (btnNameSendUpdateRemind == 'Update' ) ? connectedUser.Id : request.ResponseByUser__c;
                            //RRA - ticket 1393 - 15052023
                        //}
                    //RRA - VERSIONING
                    }else if (btnNameSendUpdateRemind == 'Send' && request.OriginalRequest__c != null && request.LastVersionSent__c && request.LastVersionAnswered__c &&  (request.ReinsurerStatus__c == AP_Constant.statusAnswered) || (request.ReinsurerStatus__c == AP_Constant.statusRefused)){
                        request.LastVersionSent__c = false;
                        request.LastVersionAnswered__c = false;
                        request.isFirstSending__c = false;
                    }else if (btnNameSendUpdateRemind == 'Send' && request.OriginalRequest__c != null && request.ResponseDate__c == null && request.ResponseByUser__c != null){
                        request.ResponseByUser__c = null;
                    }

                    request.TECH_LastSendUpdRemDate__c = System.today();
                    //request.LastSentDate__c = System.today();//RRA - VERSIONING
    
                    // RRA - 939 delete icon attach and comment if document visibility don't exists
                    if (lstDocVisBroReins.size() == 0){
                        request.Utility_Icon_Attachment__c= ''; //RRA - 939
                    }
                    if (lstDocVisReins.size() == 0){
                        request.Utility_Icon_Attachment__c= ''; //RRA - 939
                    }
    
                    if (request.Broker__c!= null && request.Reinsurer__c != null ){
                        if (request.CommentsResponse__c == null){
                            request.Utility_Icon_Comment__c= ''; //RRA - 939
                        }
                    }
                    if (request.Broker__c == null && request.Reinsurer__c != null ){
                        if (request.CommentsResponse__c == null){
                            request.Utility_Icon_Comment__c= ''; //RRA - 939
                        }
                    }
    
                    if(!mapRequestToUpdateById.containsKey(request.Id) && !mapRequestNewVersionById.containsKey(request.Id)){
                        mapRequestToUpdateById.put(request.Id, request);
                    }
                }
    
                

                if(lstReinsurerToEmpty.size()>0 && btnNameSendUpdateRemind == 'Send' && stageType == 'Signing'){
                    deleteCollateralSignatories(lstReinsurerToEmpty,programId) ;
                }
                
                
                if(mapRequestToUpdateById.size() > 0){
                    lstAllRequestToUpdate = mapRequestToUpdateById.values();
                    List<Request__c> lstUdapeReqQuote = new List<Request__c>();
                    if(lstAllRequestToUpdate.size() > 0){
                        System.debug('## lstAllRequestToUpdate.size()'+lstAllRequestToUpdate.size());
                        update lstAllRequestToUpdate;
                    }
                    
                    for (Request__c request : lstAllRequestToUpdate){
                        if (btnNameSendUpdateRemind == 'Send' && request.OriginalRequest__c == null && request.QuoteType__c == '2' && (request.ReinsurerStatus__c == AP_Constant.statusAnswered || request.ReinsurerStatus__c == AP_Constant.statusSent || request.ReinsurerStatus__c == AP_Constant.statusTimeout || request.ReinsurerStatus__c == AP_Constant.statusRefused)){
                            request.ExpectedResponseDate__c = null;
                            request.ReinsurerStatus__c = 'Informed';
                        }
                        lstUdapeReqQuote.add(request);
                    }
                    if (lstUdapeReqQuote.size()>0){
                        update lstUdapeReqQuote;
                    }
                }
                //RRA VERSIONING
                List<Request__c> lstReq = [SELECT Id, OriginalRequest__c, UpdateRequestByUser__c, UpdateRequestDate__c, ExpectedResponseDate__c FROM Request__c WHERE RecordType.Name = 'Signing Request' AND OriginalRequest__c =  null AND Id IN :mapRequestSentByOriginalReqId.keySet()];
                if (lstReq.size()>0){
                    for (Request__c req : lstReq){
                        req.UpdateRequestDate__c = lastVersionReq.UpdateRequestDate__c;
                        req.UpdateRequestByUser__c = lastVersionReq.UpdateRequestByUser__c;
                        req.ExpectedResponseDate__c = lastVersionReq.ExpectedResponseDate__c;
                        lstReqUpdateSigning.add(req);
                    }
                }
                update lstReqUpdateSigning;
                 
                //RRA VERSIONING
                for (Request__c request : mapRequestSentByOriginalReqId.values()){
                    /*if (btnNameSendUpdateRemind == 'Send' && request.OriginalRequest__c != null && request.ResponseDate__c != null && (request.ReinsurerStatus__c == AP_Constant.statusAnswered) || (request.ReinsurerStatus__c == AP_Constant.statusRefused)){
                        request.UpdateRequestDate__c = null;
                        request.UpdateRequestByUser__c = null;
                    }/*else if (request.OriginalRequest__c != null && request.ResponseDate__c != null){
                        request.UpdateRequestByUser__c = null;
                        
                    }*/
                    if (btnNameSendUpdateRemind == 'Send' && request.OriginalRequest__c != null && request.ResponseDate__c != null && request.ReinsurerStatus__c == AP_Constant.statusSent){
                        request.ResponseDate__c = null;
                        request.ResponseByUser__c = null;
                    }else if (btnNameSendUpdateRemind == 'Send' && request.OriginalRequest__c != null && request.ResponseByUser__c != null && request.ReinsurerStatus__c == AP_Constant.statusSent){
                        request.ResponseByUser__c = null;
                    }else if (btnNameSendUpdateRemind == 'Send' && request.OriginalRequest__c != null && request.isFirstSending__c && request.UpdateRequestDate__c != null && request.UpdateRequestByUser__c != null && request.isUpdateRequest__c == false){
                        request.UpdateRequestDate__c = (stageType == 'Quote' || stageType == 'Placement' || stageType == 'Lead') ? null : request.UpdateRequestDate__c;
                        request.UpdateRequestByUser__c = (stageType == 'Quote' || stageType == 'Placement' || stageType == 'Lead') ? null : request.UpdateRequestByUser__c;
                    }else if (btnNameSendUpdateRemind == 'Send' && request.OriginalRequest__c != null && request.isFirstSending__c && request.UpdateRequestDate__c != null && request.UpdateRequestByUser__c != null && request.isUpdateRequest__c){
                        request.UpdateRequestDate__c = request.UpdateRequestDate__c;
                        request.UpdateRequestByUser__c = request.UpdateRequestByUser__c;
                        request.isUpdateRequest__c = true;
                    }else if (btnNameSendUpdateRemind == 'Send' && request.OriginalRequest__c != null && request.UpdateRequestDate__c != null && request.UpdateRequestByUser__c != null && request.isUpdateRequest__c){
                        request.isUpdateRequest__c = true;
                    }
                
                    
                    lstUpdateAllRequest.add(request);
                }
                
                update lstUpdateAllRequest;
                mapResults.put('Success', 'Success');
            }
            catch (Exception ex){
                mapResults.put('Error', ex.getMessage());
                Database.rollback(sp);
            }
            return mapResults;
        }
        //MRA W-1233 15/09/2022 Market Sub - pas de reprise des infos si réassureur signé à 0% : START 
        @AuraEnabled
        public static Map<String, String> deleteCollateralSignatories(List<Id> lstReinsurerToEmpty,Id programId){
            Map<String, String> mapResults = new Map<String,String>();
            Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
            String recordTypeIdSigning = mapRecTypeId.get(AP_Constant.reqRTSigning);
            List<Request__c> lstRequestToUpdate = new List<Request__c>() ;
            String statusSetup = AP_Constant.statusSetup;
            String querySigning = 'SELECT Id,Claims_contact__c,Collateral_provider_Name__c,Collateral_Provider_City__c,Collateral_provider_Code__c,Type_of_Code__c,DescriptionReinsurerLimitColl__c,Program__c,Reinsurer__c,RecordTypeId,LastVersionSent__c,LastVersionAnswered__c,ReinsurerStatus__c'
                                + ' FROM Request__c WHERE (Program__c = \''+programId+ '\' AND Reinsurer__c IN :lstReinsurerToEmpty AND RecordTypeId = :recordTypeIdSigning) AND ((LastVersionSent__c = TRUE AND LastVersionAnswered__c = TRUE) OR (ReinsurerStatus__c = :statusSetup)) ';
            for(Request__c request :Database.query(querySigning)){
                request.Claims_contact__c = '' ;
                request.Collateral_provider_Name__c = '' ;
                request.Collateral_Provider_City__c= '' ;
                request.Collateral_provider_Code__c= '' ;
                request.Type_of_Code__c = null ;
                request.DescriptionReinsurerLimitColl__c = null ;
                lstRequestToUpdate.add(request) ;
            }
            /*List<Contact> lstSignatoriesToDelete = [SELECT Id,
                                                    AccountId,
                                                    Salutation,
                                                    FirstName,
                                                    LastName,
                                                    Email,
                                                    MobilePhone,
                                                    TECH_ProgramId__c,
                                                    Order_of_signatories__c,
                                                    RecordTypeId
                                            FROM Contact
                                            WHERE AccountId IN :lstReinsurerToEmpty
                                            AND RecordType.DeveloperName =: AP_Constant.contactSignatory
                                            AND TECH_ProgramId__c =: programId
                                            ORDER BY Order_of_signatories__c
                                            ];*/
            List<ContactReinsurerProgramRelation__c> lstSignatoriesToDelete = [SELECT Id,Name, ContactId__c,ContactId__r.Salutation,ContactId__r.LastName,ContactId__r.FirstName,ContactId__r.Email,ContactId__r.Name,ContactId__r.MobilePhone,ProgramId__r.Name,ReinsurerId__r.Name,OrderOfSignatory__c
                                                                               FROM ContactReinsurerProgramRelation__c 
                                                                               WHERE ReinsurerId__c IN :lstReinsurerToEmpty
                                                                               AND ProgramId__c =: programId
                                                                               ORDER BY OrderOfSignatory__c
                                                                                ] ;//MRA 19/05/23 - Contact Signatory Rebuild
            if(lstRequestToUpdate.size()>0){
                update lstRequestToUpdate ;
            }

            if (lstSignatoriesToDelete.size()>0) {
                delete lstSignatoriesToDelete ;
            }

            mapResults.put('Success','Sucesss');
            return mapResults;
        }
        //MRA W-1233 15/09/2022 Market Sub - pas de reprise des infos si réassureur signé à 0% : END
    
        /**
        * @description Method to Share PCC with Custom Internal User PCC
        * @param Id pccId
        * @return void
        */
        @Future
        public static void sharePCCWithCustomIntUser(Id pccId){
            Map<String, Object> mapResults = new Map<String, Object>();
            Savepoint sp = Database.setSavepoint();
    
            try{
                //Share PCC with Group - Custom All Internal User
                List<AccountShare> lstAccShare = new List<AccountShare>();
                List<GroupMember> lstGroupMember = new List<GroupMember>();
                String strReferentialId;
                Id pccGroupId;
    
                if(pccId != null){
                    for(Account account : [SELECT Id, Name, TECH_ReferentialId__c FROM Account WHERE Id = :pccId LIMIT 1]){
                        strReferentialId = account.TECH_ReferentialId__c;
                    }
    
                    for(Group groupRecord : [SELECT Id, DeveloperName FROM Group WHERE DeveloperName = :strReferentialId LIMIT 1]){
                        pccGroupId = groupRecord.Id;
                    }
    
                    List<Group> lstCustomAllIntUserPCC = [SELECT Id, name FROM Group WHERE Name = :AP_Constant.groupCustomAllInternalUsersPCC LIMIT 1];
    
                    //Add Group CustomAllInternalUsersPCC as Group Member in PCC
                    if(pccGroupId != null && lstCustomAllIntUserPCC.size() > 0){
                        GroupMember groupMemberCustom = new GroupMember();
                        groupMemberCustom.GroupId = pccGroupId;
                        groupMemberCustom.UserOrGroupId = lstCustomAllIntUserPCC[0].Id;
                        lstGroupMember.add(groupMemberCustom);
                    }
    
                    if(lstGroupMember.size() > 0){
                        insert lstGroupMember;
                    }
                }
                mapResults.put('Success', 'Success');
            }catch (Exception ex) {
                mapResults.put('Error', ex.getMessage());
                Database.rollback(sp);
            }
        }
    
        /**
        * @description Method to send Remind Email for Request(s)
        * @param List<AccountContactRelation> lstAccountContact, List<Id> lstApplyToRequestId, Id selectedProgramId, String stageName, List <String> lstPoolIdToTreatyId, List<String> lstPoolIdToEmail, List<Request__c> lstRequestData
        * @return Map<String, Object>
        */
        @AuraEnabled
        public static Map<String, Object> sendReminderForRequest(List<AccountContactRelation> lstAccountContact, List<Id> lstApplyToRequestId, Id selectedProgramId, String stageName, List <String> lstPoolIdToTreatyId, List<String> lstPoolIdToEmail, List<Request__c> lstRequestData){
            Map<String, Object> mapResults = new Map<String, Object>();
            List<Request__c> lstUpdateRequestDate =  new List<Request__c>();
            List<String> lstCCEmailsToSend = new List<String>();
            Set<Id> setAllVersionRequestId = new Set<Id>();
            Savepoint sp = Database.setSavepoint();
            String strLstCCEmail = null;
            String strLstCCEmailDisplay = null;
    
            try{
                User connectedUser = [SELECT Id, Name, Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
    
                Program__c program = [SELECT Id, Macro_L_O_B__c, Name, PrincipalCedingCompany__r.Name, PrincipalCedingCompany__r.EmailPCLife__c
                                      FROM Program__c 
                                      WHERE Id = :selectedProgramId];
    
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
    
                Map<Id,String> mapPoolIdToEmail = new Map<Id,String>();
                Map<Id, List<String>> mapPoolIdToTreatyIds = new Map<Id,List<String>>();
                Map<Id, List<String>> mapPoolIdToRequestIds = new Map<Id,List<String>>();
    
                for(Integer i = 0; i < lstPoolIdToEmail.size(); i++){
                    List <String> poolArr = lstPoolIdToEmail[i].split('\\|');
                    mapPoolIdToEmail.put(poolArr[0], poolArr[1]);
                }
    
                for(Integer x = 0; x < lstPoolIdToTreatyId.size(); x++){
                    List <String> poolArr = lstPoolIdToTreatyId[x].split('\\|');
                    List<String> lstTreatyNames = new List<String>();
                    if(mapPoolIdToTreatyIds.containsKey(poolArr[0])){
                        lstTreatyNames = mapPoolIdToTreatyIds.get(poolArr[0]);
                        lstTreatyNames.add(poolArr[1]);
                        mapPoolIdToTreatyIds.put(poolArr[0], lstTreatyNames);
                    }
                    else{
                        lstTreatyNames.add(poolArr[1]);
                        mapPoolIdToTreatyIds.put(poolArr[0], lstTreatyNames);
                    }              
                }
    
                Id emailTempSignForPoolId;
                String emailTempSignPoolName = AP_Constant.emailTemplateSignForPoolRemind;
                List<Messaging.SingleEmailMessage> lstMailsToRemind =  new List<Messaging.SingleEmailMessage>();
                Set<String> setPoolTrackingNo = new Set<String>(); //BBH W- 1873 - ticket 1873 - using PoolTrackNumber__c to send one mail
                List<EmailTemplate> lstEmailTempSignPool= [SELECT Id, Name FROM EmailTemplate WHERE Name = :emailTempSignPoolName];
                emailTempSignForPoolId = lstEmailTempSignPool[0].Id;
                Id userId = UserInfo.getUserId();
                Id pccIdOfProgram;
    
                Messaging.SingleEmailMessage mPoolRemind = new Messaging.SingleEmailMessage();       
                mPoolRemind = Messaging.renderStoredEmailTemplate(emailTempSignForPoolId, userId, lstRequestData[0].Id);
    
                for(Request__c request : lstRequestData){
                    if(request.Pool__c != null ){
                        Pool__c pool = request.Pool__r;
                        pccIdOfProgram = request.Program__r.Principalcedingcompany__c;
    
                        if(!setPoolTrackingNo.contains(pool.PoolTrackNumber__c)) {//BBH W- 1873 - ticket 1873 - using PoolTrackNumber__c to send one mail
                            setPoolTrackingNo.add(pool.PoolTrackNumber__c);//BBH W- 1873 - ticket 1873 - using PoolTrackNumber__c to send one mail
                            Id requestId = request.Id;
                            Messaging.SingleEmailMessage m = new Messaging.SingleEmailMessage();
                            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                            List<String> lstEmailsToSend = new List<String>();
                            m.setTemplateId(emailTempSignForPoolId);
                            m.setTargetObjectId(userId);
                            m.setWhatId(requestId);
                            m.setSaveAsActivity(false);
                            lstEmailsToSend.add(mapPoolIdToEmail.get(pool.Id));
                            mail.setToAddresses(lstEmailsToSend);
                            mail.setReplyTo(UserInfo.getUserEmail());
                            mail.setSenderDisplayName(UserInfo.getFirstName() + ' ' + UserInfo.getLastName());
    
                            if(lstCCEmailsToSend.size() > 0){
                                mail.setCcAddresses(lstCCEmailsToSend);
                            }
                            
                            mail.setSubject(mPoolRemind.getSubject());
                            String htmlBody = mPoolRemind.htmlBody;
                            String htmlTreatysListReinsurers = '<br/>';
                            String linkToPool = '/lightning/n/SignForPool?c__program=' + request.Program__c + '-' + request.Program__r.Principalcedingcompany__c + '-' + request.TECH_UWyear__c + '-' + request.Pool__c;
                            String domainURL = URL.getSalesforceBaseUrl().toExternalForm();
                            String htmlInternetLink = '<a href="' + domainURL + '/lightning/page/home">ACTOR NewGen Page</a>';
                            String signForPoolLink = '<a href="' + domainURL + linkToPool + '">link</a>';
                        
                            if(htmlBody != null && htmlBody != 'null'){
                                htmlBody = htmlBody.replace('{InternetLink}', htmlInternetLink);
                                htmlBody = htmlBody.replace('{HomePageLink}', htmlInternetLink);
                                htmlBody = htmlBody.replace('{SignforPoolLink}', signForPoolLink);
    
                                String strLstCCEmailDisplayPool = strLstCCEmailDisplay != null ? strLstCCEmailDisplay : '';
                                htmlBody = htmlBody.replace('{contactEmail}', strLstCCEmailDisplayPool);
    
                                mail.setHtmlBody(htmlBody);
                                lstMailsToRemind.add(mail);
                            }  
                        }
                    }
                }
    
                if(lstMailsToRemind.size() > 0){
                    Messaging.SendEmailResult[] results = Messaging.sendEmail((List<Messaging.Email>) lstMailsToRemind);
    
                    if(pccIdOfProgram != null){
                        sharePCCWithCustomIntUser(pccIdOfProgram);
                    }
                }
    
                String macroLob = program.Macro_L_O_B__c;
                Set<Id> lstAccountId = new Set<Id>();
                List<Request__c> lstRequest = [SELECT Id, TECH_LastSendUpdRemDate__c, ExpectedResponseDate__c, Comments__c, Broker__c, Reinsurer__c
                                                      , TECH_ReinsurerName__c, TECH_SectionName__c, TECH_TreatyName__c, Program__c, Program__r.TECH_StageName__c
                                                      , Pool__r.Name, Pool__r.AssignedTo__r.Email, OriginalRequest__c
                                               FROM Request__c WHERE Id IN :lstApplyToRequestId];
    
                Id emailTemplateRemind;
                String emailTemplateRemindName = AP_Constant.emailTemplateRemindReq;
                Map<Id, List<Request__c>> mapLstRequestByAccID = new Map<Id, List<Request__c>>();
                Map<Id, List<AccountContactRelation>> mapLstAccountContactByAccID = new Map<Id, List<AccountContactRelation>>();
                List<Messaging.SingleEmailMessage> lstMails =  new List<Messaging.SingleEmailMessage>();
               
                List<EmailTemplate> lstEmailTemplateRemind = [SELECT Id, Name FROM EmailTemplate WHERE Name = :emailTemplateRemindName];
                emailTemplateRemind = lstEmailTemplateRemind[0].Id;
    
                Messaging.SingleEmailMessage mRemind = new Messaging.SingleEmailMessage();       
                mRemind = Messaging.renderStoredEmailTemplate(emailTemplateRemind, userId, lstRequest[0].Id);
    
                for(Request__c request : lstRequest){
                    if(request.OriginalRequest__c == null){
                        setAllVersionRequestId.add(request.Id);
                    }
                    else{
                        setAllVersionRequestId.add(request.OriginalRequest__c);
                    }
    
                    List<Request__c> lstUpdRequest = new List<Request__c>();
                    request.TECH_LastSendUpdRemDate__c = System.today();
                    //request.LastSentDate__c = System.today(); //RRA - VERSIONING -11102024
                    lstUpdateRequestDate.add(request);
                    if(request.Broker__c != null){
                        lstAccountId.add(request.Broker__c);
                        if(mapLstRequestByAccID.containsKey(request.Broker__c)){
                            lstUpdRequest = mapLstRequestByAccID.get(request.Broker__c);
                            lstUpdRequest.add(request);
                            mapLstRequestByAccID.put(request.Broker__c, lstUpdRequest);
                        }
                        else{
                            lstUpdRequest.add(request);
                            mapLstRequestByAccID.put(request.Broker__c, lstUpdRequest);
                        }
                    }
                    else{
                        lstAccountId.add(request.Reinsurer__c);
                        if(mapLstRequestByAccID.containsKey(request.Reinsurer__c)){
                            lstUpdRequest = mapLstRequestByAccID.get(request.Reinsurer__c);
                            lstUpdRequest.add(request);
                            mapLstRequestByAccID.put(request.Reinsurer__c, lstUpdRequest);
                        }
                        else{
                            lstUpdRequest.add(request);
                            mapLstRequestByAccID.put(request.Reinsurer__c, lstUpdRequest);
                        }
                    }
                       
                }
                for(AccountContactRelation accountContact : lstAccountContact){
                    List<AccountContactRelation> lstUpdAccountContact = new List<AccountContactRelation>();
                    if(mapLstAccountContactByAccID.containsKey(accountContact.AccountId)){
                        lstUpdAccountContact = mapLstAccountContactByAccID.get(accountContact.AccountId);
                        lstUpdAccountContact.add(accountContact);
                        mapLstAccountContactByAccID.put(accountContact.AccountId, lstUpdAccountContact);
                    }
                    else{
                        lstUpdAccountContact.add(accountContact);
                        mapLstAccountContactByAccID.put(accountContact.AccountId, lstUpdAccountContact);
                    }
                }
                Network networkObj = [SELECT Id
                                      FROM Network
                                      WHERE Name =: System.Label.Actor_portal_name];
                String url = Network.getLoginUrl(networkObj.Id);
    
                for(Id accountId : mapLstAccountContactByAccID.keySet()){
                    List<AccountContactRelation> lstAccountContactByAccId = mapLstAccountContactByAccID.get(accountId);
                    for(AccountContactRelation accountContact : lstAccountContactByAccId){
                        List<Request__c> lstRequestByAccId = mapLstRequestByAccID.get(accountContact.AccountId);
                        Id requestId;
                        for(Request__c request : lstRequestByAccId){
                            requestId = request.Id;
                            Messaging.SingleEmailMessage m = new Messaging.SingleEmailMessage();
                            m.setTemplateId(emailTemplateRemind);
                            m.setTargetObjectId(userId);
                            m.setWhatId(requestId);
                            m.setSaveAsActivity(false);
    
                            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                            List<String> sendTo = new List<String>();
                            sendTo.add(accountContact.Contact.Email);
                            mail.setToAddresses(sendTo);
                            mail.setReplyTo(UserInfo.getUserEmail());
                            mail.setSenderDisplayName(UserInfo.getFirstName() + ' ' + UserInfo.getLastName());
    
                            if(lstCCEmailsToSend.size() > 0){
                                mail.setCcAddresses(lstCCEmailsToSend);
                            }
    
                            mail.setSubject(mRemind.getSubject());
                            String htmlBody = mRemind.htmlBody;
                            String htmlTreatysListReinsurers = '<br/>';
                            List <String> urlArr1 = url.split('login');
                            String htmlInternetLink = '<a href="' + urlArr1[0] + 'homepage">ACTOR New Gen HomePage</a>';
                            String reinsurerLink = urlArr1[0] + 'request?c__details=';
    
                            if(accountContact.Contact.AccountType__c == AP_Constant.contactBroker) {
                                if(stageName == 'Signing'){
                                    reinsurerLink += request.Program__c + '-' + request.Id + '-Signing';
                                }
                                else{
                                    reinsurerLink += request.Program__c + '-' + request.Reinsurer__c + '-' + request.Broker__c + '-' + request.Program__r.TECH_StageName__c + '-'+request.Id; //RRA - 1045;;
                                }
                            }
                            else if(accountContact.Contact.AccountType__c == AP_Constant.contactReinsurer) {
                                if(stageName == 'Signing'){
                                    reinsurerLink += request.Program__c + '-' + request.Id + '-Signing';
                                }
                                else{
                                    reinsurerLink += request.Program__c + '-' + request.Reinsurer__c + '-null-' + request.Program__r.TECH_StageName__c + '-'+request.Id; //RRA - 1045;
                                }
                            }
    
                            if(htmlBody != null && htmlBody != 'null'){
                                htmlBody = htmlBody.replace('{InternetLink}', htmlInternetLink);
                                htmlBody = htmlBody.replace('{ProgramName}', program.Name);
                                htmlBody = htmlBody.replace('{CedingCompanyName}', program.PrincipalCedingCompany__r.Name);
    
                                String strLstCCEmailDisplayEmails = strLstCCEmailDisplay != null ? strLstCCEmailDisplay : '';
                                htmlBody = htmlBody.replace('{emailP_C_LIFE}', strLstCCEmailDisplayEmails);
                                htmlBody = htmlBody.replace('{ReinsurerPageLink}', '<a href="'+ reinsurerLink + '">this link </a>');
    
                                if(String.valueOf(request.ExpectedResponseDate__c) != null){
                                    htmlBody = htmlBody.replace('{ExpectedResponseDate}',String.valueOf(request.ExpectedResponseDate__c));
                                }
    
                                mail.setHtmlBody(htmlBody);
                                lstMails.add(mail);
                            }   
                        }
                    }
                }
    
                if(lstMails.size() > 0){
                    Messaging.sendEmail((List<Messaging.Email>) lstMails);
                }
    
                if(lstUpdateRequestDate.size() > 0){
                    update lstUpdateRequestDate;
                }
    
                if(stageName == 'Lead'){
                    for(LeadRequestSelection__c leadRequestSelection : [SELECT Id, LeadRequestParent__c, LeadRequestChild__c FROM LeadRequestSelection__c WHERE LeadRequestParent__c IN :setAllVersionRequestId]) {
                        setAllVersionRequestId.add(leadRequestSelection.LeadRequestChild__c);
                    }
                }
    
                List<Request__c> lstAllRequestVersion = [SELECT Id, ReinsurerStatus__c, OriginalRequest__c, ExpectedResponseDate__c, TECH_LastSendUpdRemDate__c, LastSentDate__c, SentBy__c FROM Request__c WHERE Id IN :setAllVersionRequestId OR OriginalRequest__c IN :setAllVersionRequestId];
    
                for(Request__c request : lstAllRequestVersion){
                    request.TECH_LastSendUpdRemDate__c = System.today();
                    //request.LastSentDate__c = System.today(); //RRA - VERSIONING -11102024
                }
    
                if(lstAllRequestVersion.size() > 0){
                    update lstAllRequestVersion;
                }
    
                mapResults.put('Success', 'Success');
            }
            catch (Exception ex) {
                mapResults.put('Error', ex.getMessage());
                Database.rollback(sp);
            }
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
        /**
        * @description Method to get Users assigned to each Pool
        * @param null
        * @return List <User>
        */
        @AuraEnabled
        public static List <User> getPoolAssignedTo(){
            List <User> lstPoolAssignedUsers = [SELECT Id, 
                                                       Email 
                                             FROM User
                                             WHERE UserRole.DeveloperName =: AP_Constant.HeadUGP
                                             ORDER BY UserRole.DeveloperName DESC];  //RRA - ticket 2225 - 19122024 
            return lstPoolAssignedUsers;    
        }
    
        /**
        * @description Method to get Email Templates for preview
        * @param String btnNameSendUpdateRemind, String reqId, String stageType
        * @return Map<String, Object>
        */
        @AuraEnabled
        public static Map<String, Object> getEmailTemplate(String btnNameSendUpdateRemind, String reqId, String stageType){
            Map<String, Object> mapResults = new Map<String, Object>();
            Map<String, String> mapBodyByEmailTemplateName= new Map<String, String>();
            List<String> lstEmailTemplateName;
            List<EmailTemplate> lstEmailTemplate = new List<EmailTemplate>();
            List<Request__c> lstRequest = new List<Request__c>();
            String emailTemp1;
            String emailTemp2;
            String emailTemp3;
            String emailTemp4;
            String emailTemp5;
            String updateRemindTempForBrokRein;
            String updateRemindTempForSignForPool;
            String domainURL = URL.getSalesforceBaseUrl().toExternalForm();
            String emailPCLife = null;
    
            try{
                lstEmailTemplateName = new List<String>{AP_Constant.emailTemplateSendQuoteReqBrokerForInformation
                                                        ,AP_Constant.emailTemplateSendRQuoteReqReinsurerForInformation
                                                        ,AP_Constant.emailTemplateSendQuoteReqBrokerForQuote
                                                        ,AP_Constant.emailTemplateSendQuoteReqReinsurerForQuote
                                                        ,AP_Constant.emailTemplateSendRetainedBroker
                                                        ,AP_Constant.emailTemplateSendRetainedReinsurer
                                                        ,AP_Constant.emailTemplateSendNonRetainedBroker
                                                        ,AP_Constant.emailTemplateSendNonRetainedReinsurer
                                                        ,AP_Constant.emailTemplateSendPlacementReqBroker
                                                        ,AP_Constant.emailTemplateSendPlacementReqReinsurer
                                                        ,AP_Constant.emailTemplateSendSigningReqBroker
                                                        ,AP_Constant.emailTemplateSendSigningReqReinsurer
                                                        ,AP_Constant.emailTemplateSendSigningBrokerSignedShare
                                                        ,AP_Constant.emailTemplateSendSigningReinsurerSignedShare
                                                        ,AP_Constant.emailTemplateSignForPoolSend
                                                        ,AP_Constant.emailTemplateUpdateReq
                                                        ,AP_Constant.emailTemplateSignForPoolUpdate
                                                        ,AP_Constant.emailTemplateRemindReq
                                                        ,AP_Constant.emailTemplateSignForPoolRemind};
                
                lstRequest = [SELECT Id, Name, TECH_ProgramName__c, ExpectedResponseDate__c, Program__r.UwYear__c, Program__r.PrincipalCedingCompany__r.Name, Program__r.PrincipalCedingCompany__r.EmailPCLife__c FROM Request__c WHERE Id = : reqId LIMIT 1];
    
                lstEmailTemplate = [SELECT Id, Name FROM EmailTemplate WHERE Name IN : lstEmailTemplateName];
    
                Network networkObj = [SELECT Id FROM Network WHERE Name = :System.Label.Actor_portal_name];
                String url = Network.getLoginUrl(networkObj.Id);
                List<String> urlArr = url.split('login');
    
                for(EmailTemplate emailTemplate : lstEmailTemplate){
                    //to build map emailTemplateName - emailBody
                    Messaging.SingleEmailMessage m = Messaging.renderStoredEmailTemplate(emailTemplate.Id, UserInfo.getUserId(), reqId);
                    m.setSaveAsActivity(false);
                    String body = m.htmlBody;
    
                    if(lstRequest.size() > 0){
                        emailPCLife = lstRequest[0].Program__r.PrincipalCedingCompany__r.EmailPCLife__c;
    
                        List<String> lstPCCEmailsToSend = new List<String>();
                        String emailPCLifeDisplay = null;
    
                        if(emailPCLife != null ){
                            if(emailPCLife.contains(';')){
                                lstPCCEmailsToSend = emailPCLife.split(';');
                            }else{
                                lstPCCEmailsToSend.add(emailPCLife);
                            }
                        }
    
                        for(String pccEmail : lstPCCEmailsToSend){
                            if(emailPCLifeDisplay == null){
                                emailPCLifeDisplay = pccEmail;
                            }else{
                                emailPCLifeDisplay = emailPCLifeDisplay + ' ' + pccEmail;   
                            }
                        }
    
                        if(body != null){
                            body = body.replace('{ProgramName}', lstRequest[0].TECH_ProgramName__c);
                            body = body.replace('{CedingCompanyName}', lstRequest[0].Program__r.PrincipalCedingCompany__r.Name);
                            body = body.replace('{phase}', stageType);
    
                            if(emailPCLifeDisplay != null){
                                body = body.replace('{emailP_C_LIFE}', emailPCLifeDisplay);
                                body = body.replace('{contactEmail}', emailPCLifeDisplay);
                            }else{
                                body = body.replace('{emailP_C_LIFE}', '');
                                body = body.replace('{contactEmail}', '');
                            }
    
                            String htmlInternetLink = '<a href="' + urlArr[0] + 'homepage">ACTOR New Gen HomePage</a>';
                            body = body.replace('{InternetLink}', htmlInternetLink);
    
                            String homePageLink = '<a href="' + domainURL + '/lightning/page/home">ACTOR NewGen Page</a>';
                            body = body.replace('{HomePageLink}', homePageLink);
    
                            if(btnNameSendUpdateRemind == 'Remind'){
                                body = body.replace('{ExpectedResponseDate}', String.valueOf(lstRequest[0].ExpectedResponseDate__c));
                            }
                        }      
                    }
                    
                    mapBodyByEmailTemplateName.put(emailTemplate.Name, body);
                }
    
                if(btnNameSendUpdateRemind == 'Send'){
                    if(stageType == 'Quote'){
                        //to get the 4 email template for send quote request
                        emailTemp1 = mapBodyByEmailTemplateName.get(AP_Constant.emailTemplateSendQuoteReqBrokerForInformation);
                        emailTemp2 = mapBodyByEmailTemplateName.get(AP_Constant.emailTemplateSendRQuoteReqReinsurerForInformation);
                        emailTemp3 = mapBodyByEmailTemplateName.get(AP_Constant.emailTemplateSendQuoteReqBrokerForQuote);
                        emailTemp4 = mapBodyByEmailTemplateName.get(AP_Constant.emailTemplateSendQuoteReqReinsurerForQuote);
                    } 
                    else if(stageType == 'Lead'){
                        //to get the 4 email template for send lead request
                        emailTemp1 = mapBodyByEmailTemplateName.get(AP_Constant.emailTemplateSendRetainedBroker);
                        emailTemp2 = mapBodyByEmailTemplateName.get(AP_Constant.emailTemplateSendRetainedReinsurer);
                        emailTemp3 = mapBodyByEmailTemplateName.get(AP_Constant.emailTemplateSendNonRetainedBroker);
                        emailTemp4 = mapBodyByEmailTemplateName.get(AP_Constant.emailTemplateSendNonRetainedReinsurer);
                    }       
                    else if(stageType == 'Placement'){
                        //to get the 2 email template for send placement request
                        emailTemp1 = mapBodyByEmailTemplateName.get(AP_Constant.emailTemplateSendPlacementReqBroker);
                        emailTemp2 = mapBodyByEmailTemplateName.get(AP_Constant.emailTemplateSendPlacementReqReinsurer);
                    }   
                    else if(stageType == 'Signing'){
                        //to get the 5 email template for send signing request
                        emailTemp1 = mapBodyByEmailTemplateName.get(AP_Constant.emailTemplateSendSigningReqBroker);
                        emailTemp2 = mapBodyByEmailTemplateName.get(AP_Constant.emailTemplateSendSigningReqReinsurer);
                        emailTemp3 = mapBodyByEmailTemplateName.get(AP_Constant.emailTemplateSendSigningBrokerSignedShare);
                        emailTemp4 = mapBodyByEmailTemplateName.get(AP_Constant.emailTemplateSendSigningReinsurerSignedShare);
                        emailTemp5 = mapBodyByEmailTemplateName.get(AP_Constant.emailTemplateSignForPoolSend);
                    }
                }
                else if(btnNameSendUpdateRemind == 'Update'){
                    if(stageType == 'Quote' || stageType == 'Lead' || stageType == 'Placement'){
                        //to display only 1 email template
                        updateRemindTempForBrokRein = mapBodyByEmailTemplateName.get(AP_Constant.emailTemplateUpdateReq);
                    }
                    else if(stageType == 'Signing'){
                        //to display 2 email - update email for broker/reinsurer + update email for pool
                        updateRemindTempForBrokRein = mapBodyByEmailTemplateName.get(AP_Constant.emailTemplateUpdateReq);
                        updateRemindTempForSignForPool = mapBodyByEmailTemplateName.get(AP_Constant.emailTemplateSignForPoolUpdate);
                    }
                }
                else if(btnNameSendUpdateRemind == 'Remind'){
                    if(stageType == 'Quote' || stageType == 'Lead' || stageType == 'Placement'){
                        //to display only 1 email template
                        updateRemindTempForBrokRein = mapBodyByEmailTemplateName.get(AP_Constant.emailTemplateRemindReq);
                    }
                    else if(stageType == 'Signing'){
                        //to display 2 email - update email for broker/reinsurer + update email for pool
                        updateRemindTempForBrokRein = mapBodyByEmailTemplateName.get(AP_Constant.emailTemplateRemindReq);
                        updateRemindTempForSignForPool = mapBodyByEmailTemplateName.get(AP_Constant.emailTemplateSignForPoolRemind);
                    }
                }
    
                mapResults.put('emailTemp1', emailTemp1);
                mapResults.put('emailTemp2', emailTemp2);
                mapResults.put('emailTemp3', emailTemp3);
                mapResults.put('emailTemp4', emailTemp4);
                mapResults.put('emailTemp5', emailTemp5);
                mapResults.put('updateRemindTempForBrokRein', updateRemindTempForBrokRein);
                mapResults.put('updateRemindTempForSignForPool', updateRemindTempForSignForPool);
                mapResults.put('Success', 'Success');
    
            } catch (Exception ex) {mapResults.put('Error', ex.getMessage());}
            return mapResults;
        }
    }