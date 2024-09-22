/* KRB 9/17/2020 21R1.0 Veeva Lightning Conversion Project
 * Account Request Alignment Removal Quick Action
 */

public class MSD_CORE_Request_Alignment_Removal_QA {
     
    @AuraEnabled
    public static void processAlignmentRemoval(String accountId, String removalReason) 
    {
        
        List<Account> accountList = [SELECT Id, 
                                            Request_Alignment_Removal_MRK__c, 
                                            Requestors_Reasons_Notes_MRK__c FROM Account 
                                     WHERE id =: accountId];
        
        if(accountList.size() > 0)
        {
            accountList[0].Request_Alignment_Removal_MRK__c = true;
            
            if (String.isNotBlank(removalReason)){
               accountList[0].Requestors_Reasons_Notes_MRK__c = removalReason;
            }
            
            try{
                update accountList;
             } catch(System.DmlException e) {
                 CustomExceptionData data = new CustomExceptionData('Update Failed!', 'The Alignment Removal Request was not Processed: ' + e.getMessage(), 0);
               throw new AuraHandledException(JSON.serialize(data));
             } catch(Exception e){
                 CustomExceptionData data = new CustomExceptionData('Update Failed!', 'The Alignment Removal Request was not Processed: ' + e.getMessage(), 0);
                 throw new AuraHandledException(JSON.serialize(data));
             }
            
        }
        
    }
    

    public class CustomExceptionData {
      public String name;
      public String message;
      public Integer code;

       public CustomExceptionData(String name, String message, Integer code) {
         this.name = name;
         this.message = message;
         this.code = code;
       }
    }
   
}