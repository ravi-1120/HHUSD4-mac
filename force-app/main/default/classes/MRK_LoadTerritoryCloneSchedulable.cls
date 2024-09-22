global class MRK_LoadTerritoryCloneSchedulable implements Schedulable{
    
       global void execute(SchedulableContext sc) {
      
       
       String soql = 'SELECT Id, Name, ParentTerritory2Id FROM Territory2 WHERE Territory2Model.state =\'Active\'';
        
        
       MRK_LoadTerritoryCloneBatchable ltcb = 
          new MRK_LoadTerritoryCloneBatchable (soql); 
      
       database.executebatch(ltcb);
       
   }


}