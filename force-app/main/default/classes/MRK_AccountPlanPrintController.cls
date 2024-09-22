/*
 *  Developer:          Abu Bakar Aziz
 *  Created Date:       3/12/2014
 *  Description:        This is a Controller Extension class for the Printable PDF Account Plan Report
 *
 */
public class MRK_AccountPlanPrintController {
        
    public Account_Plan_vod__c accountPlan{get; set;}
    public static final Integer queryLimit = 1000;
    public List<Goal_Opportunity_MRK__c> goalList{get;set;}
    public List<Objective_MRK__c> objectiveList{get;set;}
    public List<Account_Tactic_vod__c> tacticList{get;set;}
    public List<GoalWrapper> goalObjectiveList = new List<GoalWrapper>();
    public List<Map<String, String>> approvalHistoryList{get;set;}
    public Boolean existsApprovalHistory{get;set;}

  /**
   * MRK_AccountPlanPrintController
   *
   * Constructor for the Controller Extension
   * 
   */
    public MRK_AccountPlanPrintController(ApexPages.StandardController controller){       
        accountPlan = (Account_Plan_vod__c) controller.getRecord();
    }
    
   /**
   * queryData
   * This method is used to fetch the Goals, Objectives and Tactis using the SOQL query
   */
    public void queryData()
    {
       // Query to fetch Goals
       goalList = new List<Goal_Opportunity_MRK__c>([select Id, 
                                         Name, 
                                         Organization_Priority_MRK__c,
                                         Area_of_Collaboration_MRK__c,
                                         Merck_Priority_MRK__c
                                         from Goal_Opportunity_MRK__c 
                                        where Account_Plan_MRK__c = :accountPlan.Id
                                        order by Merck_Priority_MRK__c asc
                                        limit :queryLimit]);
                                        
        Set<Id> goalIds = new Set<Id>();
        for(Goal_Opportunity_MRK__c goal:goalList){
            goalIds.add(goal.Id);
        }

        //Query to fetch Objectives                                          
        objectiveList = new List<Objective_MRK__c>([select Id, 
                                                            Name, Goal_Opportunity_MRK__c,
                                                            Period_MRK__c,
                                                            Contact_MRK__r.Name,
                                                            Opportunity_Category_MRK__c,
                                                            Account_Name_MRK__c
                                                         from Objective_MRK__c
                                                      where Goal_Opportunity_MRK__c = :goalIds 
                                                      order by Goal_Opportunity_MRK__c asc
                                                      limit :queryLimit]);
                                                      
        Set<Id> objectiveIds = new Set<Id>();
        for(Objective_MRK__c objective:objectiveList){
            objectiveIds.add(objective.Id);
        }
        
        // Query to fetch Tactics in the order 1) Completed Status (unchecked, then checked), 2) Start Date, 3) End Date                                            
        tacticList = new List<Account_Tactic_vod__c>([select Id, 
                                                   Objective_MRK__c,
                                                   Name,
                                                   Description_vod__c,
                                                   Start_Date_MRK__c,
                                                   End_Date_MRK__c,
                                                   Tactic_Owner_MRK__c,
                                                   Priority_MRK__c,
                                                   Complete_vod__c,
                                                   Key_Contact_MRK__r.Name,
                                                   Tactic_Owner_MRK__r.Name,
                                                   Category_MRK__c
                                                   from Account_Tactic_vod__c
                                                    where Objective_MRK__c = :objectiveIds 
                                                    order by Complete_vod__c asc,Start_Date_MRK__c asc, End_Date_MRK__c asc
                                                    limit :queryLimit]);
            
    }

  /**
   * getApprovalHistory
   * This method is used to get the Approval History for the Account Plan
   */
     
   public List<Map<String, String>> getApprovalHistory(){
    approvalHistoryList = MRK_ApprovalProcessServices.getInstance().getApprovalHistoryRecordList(accountPlan.Id);                                                    
     return approvalHistoryList;
   }

    
  /**
   * getGOTList
   * This method is used to get the hierarchical Goals,Objectives, Tactics List
   */
     public List<GoalWrapper> getGOTList()
    {           
           // Call method to fetch Goals, Objectives and Tacitcs
           queryData(); 
           
           
           // Iterate over the data set and create a Hierarchy List of Goals, Objectives and Tactics
           if(goalList.size()>0){
                for(integer g=0;g<goalList.size();g++){
                        //Create Goal Wrappers
                        GoalWrapper gWrap = new GoalWrapper();
                        gWrap.goal       = goalList[g];
                List<objectiveWrapper> storedObjectives = new List<objectiveWrapper>();
                List<TacticWrapper> storedTactics = new List<TacticWrapper>();
                
                 for(Objective_MRK__c objective:objectiveList) {
                    objectiveWrapper objWrap = new objectiveWrapper();
                    if(objective.Goal_Opportunity_MRK__c == goalList[g].Id)
                    {   // Create Objective Wrapper
                        objWrap.objective = objective;
                        storedObjectives.add(objWrap);
                        storedTactics = new List<TacticWrapper>();

                        for(Account_Tactic_vod__c tactic:tacticList){
                                
                                    if(tactic.Objective_MRK__c == objective.Id)
                                    {   // Create Tactic Wrapper
                                        TacticWrapper tacticWrap = new TacticWrapper();
                                        tacticWrap.tactic = tactic;
                                        tacticWrap.objective = objective;
                                        storedTactics.add(tacticWrap);
                                    }
                        }
                    }
                   objWrap.tactics = storedTactics;
                    
                }
                gWrap.objectives= storedObjectives;
                goalObjectiveList.add(gWrap);
                }
                
           } 
        goalObjectiveList.sort();    
        return goalObjectiveList;             
    }

  /**
   * getExistsApprovalHistory
   * This method is used to check if approval history is available
   */
    public Boolean getExistsApprovalHistory(){
        
        if(approvalHistoryList.size()>0)return true; else return false;
    }

  /**
   * getPDFPrintReport
   * This method is used to get the printable PDF format
   */    
     public PageReference getPDFPrintReport() {
        PageReference pg = Page.MRKAccountPlanPrintableView;       
        pg.getParameters().put('Id',accountPlan.Id);
        pg.setRedirect(true);
        return pg;
     }
    

/**
******SECTION FOR WRAPPER CLASSES **************
*
*/
  
/*
 *  Developer:          Abu Bakar Aziz
 *  Created Date:       3/12/2014
 *  Description:        This is a Wrapper class for Account_Tactic_vod__c object
 *
 */
    public class TacticWrapper{
        public Account_Tactic_vod__c tactic{get; set;}
        public Objective_MRK__c objective{get; set;}
        public TacticWrapper(){
        }
    }

/*
 *  Developer:          Abu Bakar Aziz
 *  Created Date:       3/12/2014
 *  Description:        This is a Wrapper class for Objective_MRK__c  object
 *
 */
     
    public class ObjectiveWrapper{
      public Objective_MRK__c objective{get; set;}
      public List<TacticWrapper> tactics{get; set;}
      public ObjectiveWrapper(){}

    } 

/*
 *  Developer:          Abu Bakar Aziz
 *  Created Date:       3/12/2014
 *  Description:        This is a Wrapper class for Goal_Opportunity_MRK__c   object. 
 *It implements Comparator class to allow for Custom Sorting
 *
 */

public class GoalWrapper implements Comparable{
      public Goal_Opportunity_MRK__c goal{get; set;}
      public List<ObjectiveWrapper> objectives{get; set;}
      public GoalWrapper(){}
     
      /**
       * compareTo
       * Override the Comparator methor to sort the Goals in the order of: 1)Merck Priority (High to Low), 2) Org Priority
       */
     public Integer compareTo(Object compareTo) {
        GoalWrapper compareToGoal = (GoalWrapper)compareTo;
        // The return value of 0 indicates that both elements are equal.
        Integer returnValue = 0;
        
        //Lesser the value of the Org Priority, Higher it should be in the sort order
       if(goal.Organization_Priority_MRK__c > compareToGoal.goal.Organization_Priority_MRK__c){
            returnValue = 1;
        }else if(goal.Organization_Priority_MRK__c < compareToGoal.goal.Organization_Priority_MRK__c){
            returnValue = -1;
        }
        
        System.debug('1 - Goal Name: -'+goal.Name+ ' Org Priority: '+goal.Organization_Priority_MRK__c + 'Compare 2 Goal Name : '+compareToGoal.goal.Name+ ' Compare 2 Org priority:  '+compareToGoal.goal.Organization_Priority_MRK__c +'Return value '+ returnValue);
        
        if(goal.Merck_Priority_MRK__c==null && compareToGoal.goal.Merck_Priority_MRK__c!=null){
            returnValue  = 1;
        }else if(goal.Merck_Priority_MRK__c!=null && compareToGoal.goal.Merck_Priority_MRK__c==null){
            returnValue = -1;
        }
        
        // Merck Priority from High to Low
        //System.debug('!goal.Merck_Priority_MRK__c.equals(compareToGoal.goal.Merck_Priority_MRK__c) : '+goal.Merck_Priority_MRK__c.equals(compareToGoal.goal.Merck_Priority_MRK__c));
        if(goal.Merck_Priority_MRK__c!=null &&  
           compareToGoal.goal.Merck_Priority_MRK__c !=null && 
           !goal.Merck_Priority_MRK__c.equals(compareToGoal.goal.Merck_Priority_MRK__c)){
           System.debug('Entering Main If');
            if('High'.equalsIgnoreCase(goal.Merck_Priority_MRK__c)){
                returnValue = -1;
            }else if(('Low').equalsIgnoreCase(goal.Merck_Priority_MRK__c)){
                returnValue= 1;
            }else if(('Med').equalsIgnoreCase(goal.Merck_Priority_MRK__c)){
                if(compareToGoal.goal.Merck_Priority_MRK__c.equalsIgnoreCase('High'))
                   returnValue = 1;
                 else
                   returnValue = -1;
            }
        }
        //System.debug('2 - Goal Name: -'+goal.Name+ ' Merck Priority: '+goal.Merck_Priority_MRK__c+ 'Compare 2 Goal Name : '+compareToGoal.goal.Name+ ' Compare 2 Merck priority:  '+compareToGoal.goal.Merck_Priority_MRK__c+'Return value '+ returnValue);

             
        return returnValue;       
    }



}


}