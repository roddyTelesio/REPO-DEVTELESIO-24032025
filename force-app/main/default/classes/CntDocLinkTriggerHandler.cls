public with sharing class CntDocLinkTriggerHandler {
 /**************************************************************************************
-- - Author        : Telesio
-- - Description   : apex contentDocumentLinkTriggerHandler
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 13-FEB-2024  RRA   1.0      Initial version - ticket 1780 - 20032024
--------------------------------------------------------------------------------------*/
public CntDocLinkTriggerHandler() {}

public void handleAfterInsert(List<ContentDocumentLink> lstNewContentDocumentLink){
    String strObjPrefix; // to check parent record prefix value like for Work__c object: 001, for Opportunity: 006 
    Set<Id> setCntDocIds = new set<Id>();
    Set<Id> setCntIdsDoc = new set<Id>();
    set<Id> setAgmtIds = new set<Id>();//Store Parent record i.e. Agreement Ids
    map<Id, SObject> mapAgmt;
    Id recordTypeIdCurrent;
    String objectName;
    String query;
    List <String> lstExtensionFileActorCEAXAXL = System.Label.ExtensionNotAuthorizedActorCEAXAXL.Split(','); 
    List <String> lstExtensionFileAGRESystemAdmin = System.Label.ExtensionNotAuthorizedAGRESystemAdmin.Split(','); 
    List <String> lstExtensionFileAGREActorBasicSalesforceAccess = System.Label.ExtensionNotAuthorizedAGRE_ActorBasicSalesforceAccess.Split(','); 
    List <String> lstExtensionFileAGREActorBasicSFPlatformAccess = System.Label.ExtensionNotAuthorizedAGRE_ActorBasicSFPlatformAccess.Split(','); 
    List <String> lstExtensionFileAGRECommunityExternalUser = System.Label.ExtensionNotAuthorizedAGRECommunityExternalUser.Split(','); 
    List <String> lstExtensionFileAGRECommunityInternalUser = System.Label.ExtensionNotAuthorizedAGRECommunityInternalUser.Split(','); 
    List <String> lstExtensionFileAGREActorCE = System.Label.ExtensionNotAuthorizedAGRE_Actor_C_E.Split(','); 
    List <String> lstExtensionFileSystemAdministrator = System.Label.ExtensionNotAuthorizedSystemAdministrator.Split(','); 
    List<String> lstExtensionAuthorizedForCLM = System.Label.ExtensionAuthorizedCLM.Split(','); 

  

    

    
    Profile profileObj = [SELECT Id, Name FROM Profile WHERE Id =: UserInfo.getProfileId()];
    System.debug('lstNewContentDocumentLink == ' + lstNewContentDocumentLink);
    System.debug('profileObj == ' + profileObj);
    
    try{
        for(ContentDocumentLink clIterator : lstNewContentDocumentLink) {
            //BBH 30.10.2024 - Dev ReadOnly W-2163:AUDIT - Create a Read only profile for all platform except Works tab
            String sObjectType = SObjectTypeIdentifier.getSObjectTypeById(clIterator.LinkedEntityId);
            LWC65_GenericReadOnlyCmp.readOnlyApexError('ContentDocumentLink',clIterator,sObjectType);

            strObjPrefix = String.valueOf(clIterator.LinkedEntityId).substring(0, 3); // Return first letters of record id like a0L for Work__c 
            System.debug('strObjPrefix == ' + strObjPrefix);
            if(strObjPrefix == Work__c.sObjectType.getDescribe().getKeyPrefix()) {
                objectName = 'Work__c';
            }else if (strObjPrefix == Account.sObjectType.getDescribe().getKeyPrefix()){
                objectName = 'Account';
            }else if (strObjPrefix == Campaign.sObjectType.getDescribe().getKeyPrefix()){
                objectName = 'Campaign';
            }else if (strObjPrefix == Minute__c.sObjectType.getDescribe().getKeyPrefix()){
                objectName = 'Minute__c';
            }else if (strObjPrefix == Apttus__APTS_Agreement__c.sObjectType.getDescribe().getKeyPrefix()){
                objectName = 'Apttus__APTS_Agreement__c';
            }else if (strObjPrefix == Universign_Transaction__c.sObjectType.getDescribe().getKeyPrefix()){
                objectName = 'Universign_Transaction__c';
            }
            
            if (objectName == 'Work__c' || objectName == 'Account' || objectName == 'Campaign' || objectName == 'Minute__c' || objectName == 'Apttus__APTS_Agreement__c' || objectName == 'Universign_Transaction__c') {
                setCntDocIds.add(clIterator.ContentDocumentId);// Content Document Id
                setAgmtIds.add(clIterator.LinkedEntityId);// Agreement Id - Parent record Id
            }else {
                setCntDocIds.add(clIterator.ContentDocumentId);// Content Document Id
            }
            
        }
        System.debug('setCntDocIds == ' + setCntDocIds);
        System.debug('setAgmtIds == ' + setAgmtIds);
        
        System.debug('lstExtensionFileAGRESystemAdmin == ' + lstExtensionFileAGRESystemAdmin);
            
        // Not Access Files for only Work /Account / Campaign / Minute__c
        if(setCntDocIds.size() > 0 && setAgmtIds.size() > 0 ) { 
            System.debug('ok ');
            if (objectName == 'Work__c' || objectName == 'Account' || objectName == 'Campaign' || objectName == 'Minute__c' || objectName == 'Apttus__APTS_Agreement__c' || objectName == 'Universign_Transaction__c'){
                query = 'SELECT Id, Name FROM ' + objectName + ' WHERE Id IN :setAgmtIds';
            }
            
            if (String.isNotBlank(query) && String.isNotEmpty(query)){
                mapAgmt = new map<Id, SObject>(Database.query(query));       
            }

            System.debug('mapAgmt == ' + mapAgmt);
            //Fetching parent record details and restricting only if Record type is Work__c 
            if(mapAgmt.size() > 0){
                System.debug('ok parent exists ');
                map<Id, ContentDocument> mapContentDocuments = new map<Id, ContentDocument>([SELECT Id, Title, FileExtension FROM ContentDocument WHERE Id IN :setCntDocIds]);
                list<ContentDocument> lstCntDocsToUpdate = new list<ContentDocument>();   
                for(ContentDocumentLink cdlIterator : lstNewContentDocumentLink) {
                    ContentDocument objCntDoc = mapContentDocuments.get(cdlIterator.ContentDocumentId);
                        // Restrict upload files 
                        if (objectName == 'Apttus__APTS_Agreement__c' || objectName == 'Universign_Transaction__c'){
                            if (profileObj.Name == 'AGRE_Actor C.E' || profileObj.Name =='AGRE_System Admin' || profileObj.Name =='System Administrator'){
                                if (!lstExtensionAuthorizedForCLM.contains(objCntDoc.FileExtension)){
                                    cdlIterator.addError('You can not upload files with extension ' + objCntDoc.FileExtension);//Showing error   
                                }
                            }else{
                                cdlIterator.addError('You can not upload files ');//Showing error  
                            }
                            
                        } else{
                            if (profileObj.Name == 'AGRE_Actor C.E'){
                                if (!lstExtensionFileAGREActorCE.contains(objCntDoc.FileExtension)){
                                    //cdlIterator.addError('You can not upload files with extension ' + objCntDoc.FileExtension);//Showing error   
                                }
                            }else if (profileObj.Name == 'AGRE_C.E_AXA XL'){
                                if (!lstExtensionFileActorCEAXAXL.contains(objCntDoc.FileExtension)){
                                    cdlIterator.addError('You can not upload files with extension ' + objCntDoc.FileExtension);//Showing error   
                                }
                            }else if (profileObj.Name == 'AGRE_System Admin'){
                                if (!lstExtensionFileAGRESystemAdmin.contains(objCntDoc.FileExtension)){
                                    cdlIterator.addError('You can not upload files with extension ' + objCntDoc.FileExtension);//Showing error   
                                }
                            }else if (profileObj.Name == 'AGRE_Actor Basic Salesforce Access'){
                                if (!lstExtensionFileAGREActorBasicSalesforceAccess.contains(objCntDoc.FileExtension)){
                                    cdlIterator.addError('You can not upload files with extension ' + objCntDoc.FileExtension);//Showing error   
                                }
                            }else if (profileObj.Name == 'AGRE_Actor Basic SF Platform Access'){
                                if (!lstExtensionFileAGREActorBasicSFPlatformAccess.contains(objCntDoc.FileExtension)){
                                    cdlIterator.addError('You can not upload files with extension ' + objCntDoc.FileExtension);//Showing error   
                                }
                            }else if (profileObj.Name == 'AGRE_Community External User'){
                                if (!lstExtensionFileAGRECommunityExternalUser.contains(objCntDoc.FileExtension)){
                                    cdlIterator.addError('You can not upload files with extension ' + objCntDoc.FileExtension);//Showing error   
                                }
                            }else if (profileObj.Name == 'AGRE_Community Internal User'){
                                if (!lstExtensionFileAGRECommunityInternalUser.contains(objCntDoc.FileExtension)){
                                    cdlIterator.addError('You can not upload files with extension ' + objCntDoc.FileExtension);//Showing error   
                                }
                            }else if (profileObj.Name == 'System Administrator'){
                                if (!lstExtensionFileSystemAdministrator.contains(objCntDoc.FileExtension)){
                                    cdlIterator.addError('You can not upload files with extension ' + objCntDoc.FileExtension);//Showing error   
                                }
                            }else if (profileObj.Name == 'Salesforce Platform_read only'){
                                 cdlIterator.addError('You can not upload files ');//Showing error   
                            }
                            // This line will abort file upload option. 
                            // Error message will be displayed only when 'ContentDocumentLink' object has some RecordType created (any other than Master)
                            // else Generic message will be dispayed - 'Can not add 1 file to Account'.
                        }                  
                }  
            }
        }
        
        //Not Access Files for Chatter, Files, Libraries => Other that Work
        if (setCntDocIds.size() > 0 && setAgmtIds.size() == 0){
            System.debug('ok parent don\'t exists');
            map<Id, ContentDocument> mapContentDocuments = new map<Id, ContentDocument>([SELECT Id, Title, FileExtension FROM ContentDocument WHERE Id IN :setCntDocIds]);
                list<ContentDocument> lstCntDocsToUpdate = new list<ContentDocument>();        
                for(ContentDocumentLink cdlIterator : lstNewContentDocumentLink) {
                    ContentDocument objCntDoc = mapContentDocuments.get(cdlIterator.ContentDocumentId);
                    
                    if (objectName == 'Apttus__APTS_Agreement__c' || objectName == 'Universign_Transaction__c'){
                        if (profileObj.Name == 'AGRE_Actor C.E' || profileObj.Name =='AGRE_System Admin' || profileObj.Name =='System Administrator'){
                            if (!lstExtensionAuthorizedForCLM.contains(objCntDoc.FileExtension)){
                                cdlIterator.addError('You can not upload files with extension ' + objCntDoc.FileExtension);//Showing error   
                            }
                        }else{
                            cdlIterator.addError('You can not upload files ');//Showing error  
                        }
                    }else{
                        // Restrict upload files 
                        if (profileObj.Name == 'AGRE_Actor C.E'){
                            if (!lstExtensionFileAGREActorCE.contains(objCntDoc.FileExtension)){
                                cdlIterator.addError('You can not upload files with extension ' + objCntDoc.FileExtension);//Showing error   
                            }
                        }else if (profileObj.Name == 'AGRE_C.E_AXA XL'){
                            if (!lstExtensionFileActorCEAXAXL.contains(objCntDoc.FileExtension)){
                                cdlIterator.addError('You can not upload files with extension ' + objCntDoc.FileExtension);//Showing error   
                            }
                        }else if (profileObj.Name == 'AGRE_System Admin'){
                            if (!lstExtensionFileAGRESystemAdmin.contains(objCntDoc.FileExtension)){
                                cdlIterator.addError('You can not upload files with extension ' + objCntDoc.FileExtension);//Showing error   
                            }
                        }else if (profileObj.Name == 'AGRE_Actor Basic Salesforce Access'){
                            if (!lstExtensionFileAGREActorBasicSalesforceAccess.contains(objCntDoc.FileExtension)){
                                cdlIterator.addError('You can not upload files with extension ' + objCntDoc.FileExtension);//Showing error   
                            }
                        }else if (profileObj.Name == 'AGRE_Actor Basic SF Platform Access'){
                            if (!lstExtensionFileAGREActorBasicSFPlatformAccess.contains(objCntDoc.FileExtension)){
                                cdlIterator.addError('You can not upload files with extension ' + objCntDoc.FileExtension);//Showing error   
                            }
                        }else if (profileObj.Name == 'AGRE_Community External User'){
                            if (!lstExtensionFileAGRECommunityExternalUser.contains(objCntDoc.FileExtension)){
                                cdlIterator.addError('You can not upload files with extension ' + objCntDoc.FileExtension);//Showing error   
                            }
                        }else if (profileObj.Name == 'AGRE_Community Internal User'){
                            if (!lstExtensionFileAGRECommunityInternalUser.contains(objCntDoc.FileExtension)){
                                cdlIterator.addError('You can not upload files with extension ' + objCntDoc.FileExtension);//Showing error   
                            }
                        }else if (profileObj.Name == 'System Administrator'){
                            if (!lstExtensionFileSystemAdministrator.contains(objCntDoc.FileExtension)){
                                cdlIterator.addError('You can not upload files with extension ' + objCntDoc.FileExtension);//Showing error   
                            }
                        }else if (profileObj.Name == 'Salesforce Platform_read only'){
                            cdlIterator.addError('You can not upload files ');//Showing error   
                        }
                        // This line will abort file upload option. 
                        // Error message will be displayed only when 'ContentDocumentLink' object has some RecordType created (any other than Master)
                        // else Generic message will be dispayed - 'Can not add 1 file to Account'.
                    }
                }
        }
    }
    catch (Exception ex){
        system.debug('Exception in TW_ContentDocumentLink_Handler class :' + ex.getMessage());
    }
 }
}