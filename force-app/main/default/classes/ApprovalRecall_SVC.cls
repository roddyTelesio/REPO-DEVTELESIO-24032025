/**
 * @description       : 
 * @author            : Patrick Randrianarisoa
 * @group             : 
 * @last modified on  : 11-22-2024
 * @last modified by  : Bhavesh Bhuckory
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   14-09-2023   Patrick Randrianarisoa   Initial Version
 * 1.1   10-11-2024   Bhavesh Bhuckory   W-1970 CLM - Legal profile + clause approval - bulkify code
**/
global class ApprovalRecall_SVC
{
   @InvocableMethod
    public static void recallApproval(List<Id> recId)   
    {       
        List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest> ();

        for (ProcessInstanceWorkitem workItem: [SELECT Id, ProcessInstanceId, ProcessInstance.TargetObjectId FROM ProcessInstanceWorkitem WHERE Id IN :recId]) {
            Approval.ProcessWorkitemRequest pwr = new Approval.ProcessWorkitemRequest();  
            pwr.setAction('Removed');
                pwr.setWorkItemId(workItem.id);
            requests.add(pwr);
        }

        Approval.ProcessResult[] processResults = null;
        try {
            processResults = Approval.process(requests, false);
        }catch (System.DmlException e) {
            AP_CreateLogUtility.createLog(recId[0],'CLM_ApprovalReminder','ApprovalRecall_SVC','500',e.getMessage());
            System.debug('Exception Is ' + e.getMessage());

        }
    }
}