/*
 *  Developer:          Abu Bakar Aziz
 *  Created Date:       08/05/2014
 *  Description:        CTI Data Lookup APEX Class. This class is called from LiveOps to perform data lookup based on SAP ID or ANI(PHONE)
 *                      This class finds out the Account and the Call Center Rep aligned to the account which is then used in Live Ops Call Routing flows
 *                      to pop out the account as well as assign the call to the correct call center rep
 */

@RestResource(urlMapping='/MRK_CTI_DataLookup/*')
global class MRK_CTI_DataLookup{
    
    // constants Declaration
    global static final String NONE = 'NONE';
    global static final String MULTIPLE= 'MULTIPLE';
    global static final String SFDCID= 'SFDCID';
    global static final String ISID= 'ISID';
    global static final String INVALID= 'INVALID';   
  /**
   * doGet
   *
   * This method is called from LiveOps to perform the account and rep Data Lookup
   * 
   */
    @HttpGet
    global static MRK_CTI_ReturnPayLoad doGet() {

    
        //Variable Declaration
        String scenarioInputType;
        String scenarioHVD ='N'; 
        String scenarioRepISID=NONE;
        String scenarioSFDCID=NONE;
        String accountID;
        String repISID;
        Boolean HVD = false;
        String scenarioCode;
        
        // Retreive Request Parameters
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String ANI= RestContext.request.params.get('ANI');
        String SAP_ID= RestContext.request.params.get('SAP_ID');        
        String salesTeamCodes= RestContext.request.params.get('ST');
        String LK_TYPE= RestContext.request.params.get('LK_TYPE');


        //Variable Initialization
        MRK_CTI_ReturnPayLoad returnPayLoad= new MRK_CTI_ReturnPayLoad();
        MRK_CTIHelper CTIHelper =  new MRK_CTIHelper ();
        Set<String> accountIds = new Set<String>();
        List<String> salesTeamNames =  new List<String>();
        List<CFE_Coverage_MRK__c> CFECoverageList= new List<CFE_Coverage_MRK__c>();
        
        
        scenarioInputType =LK_TYPE;
        
       if(LK_TYPE=='ANI'){
               
           //Step 1 -  SOSL Query using ANI, do a lookup against Communication_Mechanism_MRK__c object to retur Account(ID, HVD)
           List<Communication_Mechanism_MRK__c> comMechList= CTIHelper.findAccountByANI(ANI);
           Map <String, Communication_Mechanism_MRK__c> commMap = new Map<String, Communication_Mechanism_MRK__c>();

              if(comMechList.size()>0) {
                  for(Communication_Mechanism_MRK__c comm: comMechList){
                      commMap.put(comm.Account_MRK__c,comm);
                      if(!HVD)HVD= comm.Account_MRK__r.HVD_MRK__c;
                      accountID =comm.Account_MRK__c;
                  }
                  accountIds = commMap.keySet();
              }

        }else if(LK_TYPE=='SAP_ID'){
        
           //Step 1 -  SOSL Query using SAP ID, do a Lookup against Alternate Identifier Object to return Account(ID, HVD)
           List<Alternate_Identifier_MRK__c> alternateIDList= CTIHelper.findAccountBySAPID(SAP_ID);
           Map <String, Alternate_Identifier_MRK__c> alternateIDMap= new Map<String, Alternate_Identifier_MRK__c>();
              if(alternateIDList.size()>0) {
                  for(Alternate_Identifier_MRK__c alternateID: alternateIDList){
                     if(alternateID.Alternate_Identifier_Value_MRK__c.contains(SAP_ID)){
                      alternateIDMap.put(alternateID.Account_MRK__c,alternateID);
                      if(!HVD)HVD= alternateID.Account_MRK__r.HVD_MRK__c;
                      accountID =alternateID.Account_MRK__c;
                     }
                  }
                  accountIds = alternateIDMap.keySet();
              }

        }else{
            // INVALID Codes
             returnPayLoad =  new MRK_CTI_ReturnPayLoad();
             returnPayLoad.scenarioCode=INVALID;
             returnPayLoad.accountID=NONE;
             returnPayLoad.HVD='N';
             returnPayLoad.repISID=NONE;
        }
        

          Integer accountSize= accountIds .size();
          
          if(accountSize ==1){
               scenarioSFDCID =SFDCID;
           }else if(accountSize >1){
              scenarioSFDCID = MULTIPLE;
              accountID  = MULTIPLE;
          }else{
               scenarioSFDCID = NONE;
               accountID  = NONE;
          }
          

       if(accountID !=NONE ){
          salesTeamNames = CTIHelper.listSalesTeamNamesByCode(salesTeamCodes);
          
                     Map<ID, CFE_Coverage_MRK__c> CFEMap = new Map<ID, CFE_Coverage_MRK__c>();

          //Query to fetch CFE Coverage Object                                          
           CFECoverageList= CTIHelper.listCFECoverage(accountIds,salesTeamNames);
           if(CFECoverageList.size()==0){
               repISID =NONE;
               scenarioRepISID =NONE;
           }else if(CFECoverageList.size()==1) {
               repISID =CFECoverageList[0].User_MRK__r.Alias;    
               scenarioRepISID = ISID;      
           }else if(CFECoverageList.size() >1){
                for(CFE_Coverage_MRK__c coverage : CFECoverageList){
                      CFEMap.put(coverage .User_MRK__c, coverage);
                 }                                                                              
                if(CFEMap.keySet().size()==1){
                   repISID =CFECoverageList[0].User_MRK__r.Alias;  
                   scenarioRepISID =ISID; 
                 }else{
                   repISID =MULTIPLE;  
                   scenarioRepISID =MULTIPLE; 
            
                 }                   
            }

       }else{
        
            repISID =NONE;
            scenarioRepISID  = NONE;
            
             
        }
        
         if(HVD)scenarioHVD='Y';  else scenarioHVD='N';
          
    
          
          //Strep 3 - Lookup for Scenario Code from Scenario Matrix Object
         scenarioCode = CTIHelper.findScenarioCode(scenarioInputType,scenarioHVD,scenarioRepISID,scenarioSFDCID);
         returnPayLoad =  new MRK_CTI_ReturnPayLoad();
         returnPayLoad.scenarioCode=scenarioCode;
         returnPayLoad.accountID=accountID;
         returnPayLoad.HVD=scenarioHVD;
         returnPayLoad.repISID=repISID;
         returnPayLoad.inputValues='INPUT TYPE : '+scenarioInputType+' ST Codes : '+salesTeamCodes+' ST Names : '+salesTeamNames+' ANI : '+ANI+' SAP ID : ' +SAP_ID;  
         
         
         return returnPayLoad; 
    }
    

    global class MRK_CTI_ReturnPayLoad{
        global String scenarioCode{ get; set; }
        global String accountID{ get; set; }
        global String HVD{ get; set; }
        global String repISID{ get; set; }
        global String inputValues{ get; set; }

    }    
  
}