public class MRK_TerritoryCloneTreeUtil{
    
    
    /*
       KRB - 4/25/2014 REL 5.1 - Utility Methods for the Territory_Clone_MRK__c Object
    */

    
    // private static variable referencing the class
    private static MRK_TerritoryCloneTreeUtil instance = null;
    
    //Map that will store the Territory Hierachy
    public map<id, list<id>> parentToChildrenMap {get;private set;} 
    
    //List that will store all Children Nodes for a given Parent Node
    private List<id> allChildNodes = new List<id>();

    /*
     * The constructor is private and initializes the Territory Map in the MRK_TerritoryTreeUtil
     */
     
    private MRK_TerritoryCloneTreeUtil(){
        
        parentToChildrenMap = loadTerritoryCloneTreeMap();
        
        //Spooling out Limits
        System.debug('Total Number of script statements allowed in this apex code context: ' +  Limits.getLimitScriptStatements());
        System.debug('Total Number of script statements Executed to Load Map: ' +  Limits.getScriptStatements());
        System.debug('Total Allocated Heap Size for the Given Context: ' +  Limits.getLimitHeapSize());
        System.debug('Heap Size After Territory Map Load: ' + Limits.getHeapSize());

    }

    /*
     * static method that returns the instance of the MRK_TerritoryTreeUtil
     */
    
    public static MRK_TerritoryCloneTreeUtil getInstance(){
        // lazy load the MRK_TerritoryTreeUtil - only initialize if it doesn't already exist
        if(instance == null) instance = new MRK_TerritoryCloneTreeUtil();
        return instance;
    }
    
    /*
     * Private Method called by the Constructor to load up the Parent
     * to Child Territory Map
     */
    
    private map<id, list<id>> loadTerritoryCloneTreeMap(){
        
       map<id, list<id>> tempMap = new map<id, list<id>>(); 
       integer iRecCt = 0; 
        
       for(Territory_Clone_MRK__c [] terrRecArr : [Select Territory_SFID_MRK__c, Parent_Territory_SFID_MRK__c 
                                      FROM   Territory_Clone_MRK__c]){
           for(Territory_Clone_MRK__c terr : terrRecArr){
               
              iRecCt++;
   
              if(tempMap.get(terr.Parent_Territory_SFID_MRK__c) == null){
                tempMap.put(terr.Parent_Territory_SFID_MRK__c, new list<id>{terr.Territory_SFID_MRK__c});
              }else{
                tempMap.get(terr.Parent_Territory_SFID_MRK__c).add(terr.Territory_SFID_MRK__c);
              }
           }
       }
        
       System.debug('Number of Records Processed for the Map: ' + iRecCt);
       return tempMap;
    }
    
    
   /*
    * Public Method to retrieve ALL Children for a Given Parent Node
    */ 
   public List<id> getAllChildrenGivenParentNodeId(id parentNodeId){
      List<id> tempList = new List<id>();
       
      allChildNodes.clear();
      getAllChildren(parentNodeId);
      
       if(allChildNodes.size() >0){
          tempList= allChildNodes.clone();
       }else{
          System.debug('No Child Nodes found for Parent Node: ' + parentNodeId);
       }
       
       //spooling out for testing only
       for(id childId: tempList){
           system.debug('Child Id = ' + childId);
       }
       
       return tempList;
      
   }

   /*
    * Private Method to retrieve ALL Children for a Given Parent Node
    */ 
   private void getAllChildren(id parentNodeId){
      
      System.debug('Kevin: in MRK_TerritoryCloneTreeUtil.getAllChildren: parentNodeId = ' + parentNodeId);
       
      if(parentToChildrenMap.get(parentNodeId) != null){
        for(id idChild : parentToChildrenMap.get(parentNodeId)){
            allChildNodes.add(idChild);
            getAllChildren(idChild);
        }
      }else{
          System.debug('Kevin: Parent Node for this Id does not exist.');
      }
   }
 
    /*
     * User to display the Tree Structure for a given Node
     * to the Debug Log.
     */
    
    public void displayTheTree(id nodeId, integer iLevel){
    
      string strLevel = '*';

      for(integer i = 0; i < iLevel; i++){
        strLevel += '*';
      }

      System.Debug(strLevel + nodeId);

      if(parentToChildrenMap.get(nodeId) != null){
        for(id idChild : parentToChildrenMap.get(nodeId)){
            displayTheTree(idChild, iLevel + 1);
        }
     }
   }

    
}