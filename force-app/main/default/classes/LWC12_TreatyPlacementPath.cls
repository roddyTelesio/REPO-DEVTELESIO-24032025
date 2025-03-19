public with sharing class LWC12_TreatyPlacementPath {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Class for lwc12TreatyPlacementPath
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 07-JAN-2020  NBI    1.0     Initial Version
--------------------------------------------------------------------------------------
**************************************************************************************/

    /**
    * @description Method to update Stage of Program
    * @param String stageName
    * @param Id programId
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static Map<String, Object> updateStage(String stageName, Id programId) {
        Map<String, Object> mapResults = new Map<String, Object>();

        try{ 
            LWC65_GenericReadOnlyCmp.readOnlyApexRollbackInit('TP_Path','updateStage'); //BBH 30.10.2024 - Dev ReadOnly W-2163:AUDIT - Create a Read only profile for all platform except Works tab
            Program__c program = new Program__c();
            program.Id = programId;
            program.TECH_StageName__c = stageName;
//            program.TECH_ShowClosePreviousPhaseBtn__c = '1';
            update program;
            LWC65_GenericReadOnlyCmp.readOnlyApexCheckRollback(); //BBH 30.10.2024 - Dev ReadOnly W-2163:AUDIT - Create a Read only profile for all platform except Works tab
            mapResults.put('Success', 'Updated successfully');
            system.debug('success rollback');
        }
        catch (Exception exp){
            mapResults.put('Error', exp.getMessage());
        }

        return mapResults;
    }
    
    /**
    * @description Method to get previous stage of Program
    * @param String stageName, Id programId
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static Map<String, Object> getPreviousStageName(String stageName, Id programId) {
        Map<String, Object> mapResults = new Map<String, Object>();
        Boolean isReadOnly = LWC65_GenericReadOnlyCmp.isReadOnlyConfig('GenericBypass');//BBH 19.12.2024 W-2226

        try{
            mapResults.put('isReadOnly',isReadOnly);//BBH 19.12.2024 W-2226
            Program__c program = [SELECT Id, TECH_StageName__c FROM Program__c WHERE Id = :programId];
            String previousStageName = program.TECH_StageName__c;
            mapResults.put('previousStageName', previousStageName);
        }
        catch (Exception exp){
            mapResults.put('Error', exp.getMessage());
        }

        return mapResults;
    }
}