trigger ContentDocumentLinkTrigger on contentDocumentLink (after insert) {
    /**************************************************************************************
-- - Author        : Telesio
-- - Description   : Trigger on contentDocumentLink
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 13-FEB-2024  RRA   1.0      Initial version - ticekt 1780 20032024
--------------------------------------------------------------------------------------*/
CntDocLinkTriggerHandler handler = new CntDocLinkTriggerHandler();
    if(Trigger.isAfter && Trigger.isInsert) {
        handler.handleAfterInsert(Trigger.new);
    }
}