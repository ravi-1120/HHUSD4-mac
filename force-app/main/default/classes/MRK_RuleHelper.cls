public class MRK_RuleHelper{

    /* KRB - REL 5.0 - Validation exists in the MRK_RuleHandler that ensures
     * that the User can only update the Active 
     * indicator on a Rule if it is a Parent Territory Record on the 
     * Rule_MRK__c Object. A process in the MRK_RuleHandler then cascades
     * the update to all the Child Territories related to the Parent. 
     * This action fires the Trigger again, at which point we need 
     * to bypass the validation mentioned above. 
     * This Helper Class will be used to enable the process to bypass the 
     * validation when it enters into the Trigger for the Child Territory Updates. 
    */
    
    // Static variables are local to the context of a Web request  
    // (or testMethod during a runTests call)  
    // Therefore, this variable will be initialized as false  
    // at the beginning of each Web request which accesses it.  

    private static boolean bypassValidation = false;


    public static boolean shouldBypassValidation() {
        return bypassValidation;
    }

    // By setting the variable to true, it maintains this  
    // new value throughout the duration of the request  
    // (or testMethod)  
    
    public static void setBypassValidation() {
        bypassValidation = true;
    }
    
    public static void deactivateBypassValidation() {
        bypassValidation = false;
    }

   
}