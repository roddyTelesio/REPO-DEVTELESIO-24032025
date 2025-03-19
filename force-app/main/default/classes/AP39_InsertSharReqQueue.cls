public with sharing class AP39_InsertSharReqQueue implements Queueable{
        /**************************************************************************************
        -- - Author        : Telesio 
        -- - Description   : insert Request Share Big Quantity from Queue
        --
        -- Maintenance History:
        --
        -- Date         Name  Version  Remarks
        -- -----------  ----  -------  -------------------------------------------------------
        --23-MAY-2024   RRA   1.0      Initial version
        --------------------------------------------------------------------------------------
        **************************************************************************************/
    public List<Request__Share> lstReqShare = new List<Request__Share>();

    public AP39_InsertSharReqQueue( List<Request__Share>  lstReqShare){
        this.lstReqShare = lstReqShare;
    }
    
    public void execute(QueueableContext context){
        Database.executeBatch(new BAT001_InsertSharingBigQuantity(lstReqShare), 500);
        System.debug('batch BAT001 started');
    }
}