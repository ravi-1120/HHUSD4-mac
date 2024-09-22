public class searchAcctsAccountController {

    public String alignmentType {get; set;}
    public String AcctId {get; set;}
    private final Account acct;
    
    public searchAcctsAccountController(ApexPages.StandardController stdController) { 
        acct = (Account) stdController.getRecord();
    } 
    
    public PageReference processPermAlignmentRequest(){
        processAlignmentRequest('Permanent');
        return null;
    }
    
    public PageReference processTempAlignmentRequest(){
        processAlignmentRequest('Temporary');
        return null;
    }
    
    private void processAlignmentRequest (String alignmentType){ 
  
        AcctId = ApexPages.currentPage().getParameters().get('id'); 
        
        
        Boolean requestAlignmentSuccess = true;
        if (AcctId == null) { 
           ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Your Alignment Request Failed. Account Id Missing.');
           ApexPages.addMessage(myMsg);
           requestAlignmentSuccess = false;
        } 
        
        
        if(requestAlignmentSuccess){
           try{
              searchAccts sa = new searchAccts();
              if(alignmentType == 'Temporary'){               
                requestAlignmentSuccess = sa.processRequestedAlignment(AcctId, 'Temporary');
              }else if(alignmentType == 'Permanent'){
                requestAlignmentSuccess = sa.processRequestedAlignment(AcctId, 'Permanent');
              }else{
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Your Alignment Request Failed. Cannot determine Alignment Type.');
                ApexPages.addMessage(myMsg);
                requestAlignmentSuccess = false;
              }
          }catch(Exception ex){
              //ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Your Alignment Request Failed for the following reason. ' + ex);
              //ApexPages.addMessage(myMsg);
              
              //requestAlignmentSuccess = false;
  
          }
        
        }
        /*for (Account account:[select id, name from Account where id =:AcctId]) { 
            System.Debug ('The account id and name are as follows: ' + account.id + ' ' + account.name );
        } */
        
        //if (requestAlignmentSuccess){
        //   ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'Your Alignment Request was successful.');
        //   ApexPages.addMessage(myMsg);
        //}
     
    } 
   
       public PageReference back(){
          return new PageReference('/' + AcctId);
       }
  
}