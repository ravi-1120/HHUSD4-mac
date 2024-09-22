public class MRK_VisibilityUtility{
    
     /* KRB - 12/12//2013 REL 5.0 
        Method used to log Errors caught in try/catch Blocks..
     */ 
    
     @future
     public static void createErrorRecord(String message){

            Error_Log_MRK__c errLog = New Error_Log_MRK__c();
            errLog.Error_Message_MRK__c = message;
            Database.insert(errLog,false);
            //insert errLog;
     }
    
    /* KRB - 12/11/2013 REL 5.0 
       inserts CLM_Presentation_vod_share records
       IN: JSON Serialized LIST of CLM_Presentation_vod__share Objects

    */

    @future
    public static void insertCLMPresentationSharingRules(String shareRecords){
        
        try{
            list<CLM_Presentation_vod__share> insertCLMPresentationShareRecords =  (list<CLM_Presentation_vod__share>)JSON.deserializeStrict(shareRecords, list<CLM_Presentation_vod__share>.class);
        
            insert insertCLMPresentationShareRecords;
            
        }catch(DmlException e){
            System.debug('Error in insertCLMPresentationSharingRules: ' + e.getMessage());
            Error_Log_MRK__c errLog = New Error_Log_MRK__c();
            errLog.DmlMessage_MRK__c = e.getMessage();
            errLog.LineNumber_MRK__c = e.getLineNumber();
            //errLog.DmlFieldNames_MRK__c = e.DmlFieldNames_MRK__c();
            insert errLog;
        }
    }
    
    


    /* KRB - 12/11/2013 REL 5.0 
       Helper Methods (TODO: move to an external "SHARED" Class)... 
       Converts a Set to a Properly comma, single quoted string 
       IN: a Set of Strings
       OUT: comma, single quoted string
    */
    
    public static String convertStringSetToCommaQuotedString(Set<String> aSet){
       Integer x = aSet.size();
       Boolean firstTimeIn = true;
       String newString = '';
       Integer i = 0;
       
       for (String s: aSet){
          i = i + 1;
        
          if (firstTimeIn == true){
             newString = '\'' + s + '\',';
             firstTimeIn = false;
          }else{
             if (i == x){
                newString = newString + '\'' + s + '\'';
             }else{
                newString = newString + '\'' + s + '\',';
             }
        }
       }
        return newString;
    }

    public static String convertStringToCommaQuotedString(String s){
       String newString = '';
       newString = '\'' + s + '\'';
       return newString;
    }
 
}