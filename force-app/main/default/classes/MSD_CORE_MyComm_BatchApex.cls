public class MSD_CORE_MyComm_BatchApex{
    public List<String> ids; 
    
    //MSD_CORE_MyComm_BatchApex.MSD_CORE_MyComm_BatchApex(ApexPages.StandardController controller)'
    
    public MSD_CORE_MyComm_BatchApex(ApexPages.StandardController controller) {
      /*  this.ids = new List<String>();
        List<sObject> records = (List<sObject>) controller.getSelected();
        for (sObject record_i : records) {
            this.ids.add(record_i.Id);
        }*/
    } 
    
    public void runQRBatch() {
        //run your batch here with set of ids you have
      /*  String query = 'SELECT Description, Id FROM Account WHERE Id IN (\'' + String.join(this.ids, '\',\'') + '\')';
        Database.executeBatch(new TestBatch(query), 20);
      */
    MRK_Comm_DryRun_UTL b = new MRK_Comm_DryRun_UTL();
    database.executeBatch(b);
    }
        
    public void runProcessBatch() {
          MRK_Comm_Processing_Update b = new MRK_Comm_Processing_Update(); 
          database.executeBatch(b);
    }
    
    public void runDeleBatch() {
       MRK_Comm_Processing_DeleteAll b = new MRK_Comm_Processing_DeleteAll();
       database.executeBatch(b);
    }
    
   public PageReference cont() {  
    PageReference NAWPage = new PageReference('/apex/MRK_BatchProcessing');
    NAWPage.setRedirect(true);
    return NAWPage;
   }
     
}