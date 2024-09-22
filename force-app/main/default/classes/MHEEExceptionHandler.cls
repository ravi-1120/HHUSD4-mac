/**
 * Component Name:      MHEEExceptionHandler
 * Created By:          Focal CXM
 * Description:         Exception Handler class for MHEE
 */
Public Class MHEEExceptionHandler implements FoundaryExceptionHandler{
    public static string cLASS_NAME = 'MHEEPortalExceptionHandler';
    public static void logException(Exception ex){
    }
    
    /**
        * @description futureLogException
        * @return void
        * @param exstr, className, methodName, feature
    */
    @future    
    public static void futureLogException(String exstr, String className, String methodName, String feature){
        // GMSA_MMPortal_Exception__c portalException;
        try{
           System.debug(LoggingLevel.WARN, className + '' + methodName + '' + feature);
        }catch(Exception lex){
            MHEEExceptionHandler.logException(lex, cLASS_NAME, 'futureLogException', feature);
        }
    }
     
    public static void logException(Exception ex, String className, String methodName){
    }

    /**
        * @description logException
        * @return GenericException
        * @param Exception, className, methodName, feature
    */
    public static GenericException logException(Exception ex, String className, String methodName, String feature){
        
        return new GenericException(null, null);
    }
}