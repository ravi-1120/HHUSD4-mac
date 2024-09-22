global class MRK_CTIHelper{

    global static final String ANI_INVALID= 'ANI_INVALID';
    global static final String SAP_INVALID= 'SAP_INVALID';

     global MRK_CTIHelper() {
        
    }
    public List<Communication_Mechanism_MRK__c> findAccountByANI(String ANI){
      List<List<SObject>>searchList=[FIND :ANI 
                                     IN PHONE FIELDS 
                                     RETURNING Communication_Mechanism_MRK__c
                                               (Id, Account_MRK__r.HVD_MRK__c,Account_MRK__c 
                                                       where Account_MRK__r.isPersonAccount= false 
                                                    and Do_Not_Use_Inbound_Routing_MRK__c =false) ];
             
      List<Communication_Mechanism_MRK__c> comMechList= ((List<Communication_Mechanism_MRK__c>)searchList[0]);
      return comMechList;
    }
    
    
     public List<Alternate_Identifier_MRK__c> findAccountBySAPID(String SAPID){
      List<List<SObject>>searchList=[FIND :SAPID
                                     IN ALL FIELDS 
                                     RETURNING Alternate_Identifier_MRK__c(Id, Account_MRK__r.HVD_MRK__c,Account_MRK__c,Alternate_Identifier_Value_MRK__c 
                                                       where Account_MRK__r.isPersonAccount= false and Type_MRK__c='SAPID'
                                                    ) ];
             
      List<Alternate_Identifier_MRK__c> alternateIDList= ((List<Alternate_Identifier_MRK__c>)searchList[0]);
      return alternateIDList;
    }

    
    public List<String> listSalesTeamNamesByCode(String salesTeamCodes){
    
         String [] salesTeamCodesList = salesTeamCodes.split(';');
          List<String> salesTeamNames = new List<String>();
          
          List<Sales_Team_MRK__c > salesTeams = new List<Sales_Team_MRK__c >([
          SELECT Name FROM Sales_Team_MRK__c where Sales_Team_Code_MRK__c IN : salesTeamCodesList]);
          
          for(Sales_Team_MRK__c salesTeam :salesTeams ){
           salesTeamNames.add(salesTeam.Name);
          }
          
          return salesTeamNames;
    }
    
    
    public List<CFE_Coverage_MRK__c> listCFECoverage(Set<String> accountIds,List<String>salesTeamNames){
    
         
         List<CFE_Coverage_MRK__c> CFECoverageList =  new List<CFE_Coverage_MRK__c>([select Account_MRK__c,User_MRK__r.Alias, User_MRK__c
                                                                         from CFE_Coverage_MRK__c
                                                                          where Sales_Team_MRK__c IN :salesTeamNames
                                                                          and Account_MRK__c IN : accountIds 
                                                                          and Alignment_End_Date_MRK__c >=TODAY
                                                                          ]);
          
          return CFECoverageList;     
    
    }
    
    public String findScenarioCode(String scenarioInputType, String scenarioHVD,String scenarioRepISID, String scenarioSFDCID){
    
       String scenarioCode ='INVALID';
       List<CTI_Scenario_Matrix_MRK__c> scenarios = new List<CTI_Scenario_Matrix_MRK__c>(
                                                  [ SELECT Scenario_Code_MRK__c FROM 
                                                    CTI_Scenario_Matrix_MRK__c 
                                                    WHERE Input_Type_MRK__c= :scenarioInputType
                                                    AND HVD_Flag_MRK__c = :scenarioHVD
                                                    AND Rep_ISID_MRK__c = :scenarioRepISID
                                                    AND Account_SFDC_ID_MRK__c  =:scenarioSFDCID
                                                   ]);
          
          if(scenarios.size() ==1){
              scenarioCode=scenarios[0].Scenario_Code_MRK__c ;
          }else if(scenarioInputType=='ANI') {
              scenarioCode = ANI_INVALID;   
          }else{
              scenarioCode = SAP_INVALID;             
          }
        return scenarioCode;
    }
}