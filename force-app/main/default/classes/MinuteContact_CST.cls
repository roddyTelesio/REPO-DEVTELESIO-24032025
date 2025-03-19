public with sharing class MinuteContact_CST {

    // Constants for trigger bypass


        // #####################################################################
    // Custom settings to bypass certain Minute Contact logic
    // #####################################################################
    /***
    * @description Custom Setting to dynamically influence Minute Contact Business Logic
    *              (mainly Trigger feature bypasses).
    ***/
    static final public MinuteContactSettings__C	 SETTING = MinuteContactSettings__C.getInstance();

    // #####################################################################    
    // Dynamic trigger bypasses (may be set by other triggers or methods)
    // #####################################################################

    /***
    * @description Flag to dynamically bypass the After update trigger.
    ***/
    static public Boolean DoAfterDelete  = true;


    
}