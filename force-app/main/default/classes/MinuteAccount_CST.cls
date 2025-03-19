public with sharing class MinuteAccount_CST {

    // Constants for trigger bypass


        // #####################################################################
    // Custom settings to bypass certain Content Version logic
    // #####################################################################
    /***
    * @description Custom Setting to dynamically influence Account Business Logic
    *              (mainly Trigger feature bypasses).
    ***/
    static final public MinuteAccountSettings__C	 SETTING = MinuteAccountSettings__C.getInstance();

    // #####################################################################    
    // Dynamic trigger bypasses (may be set by other triggers or methods)
    // #####################################################################

    /***
    * @description Flag to dynamically bypass the After update trigger.
    ***/
    static public Boolean DoAfterDelete  = true;


    
}