public class VPS_Object_Selector_Cont {
    public VPS_VR_Extension cont{get;set;}
    public String sObjName{get;set;}
    public String search{get;set;}
    
    public VPS_Object_Selector_Cont(){
        
    }
    
    public List<Wrapper> getObjList(){
        return cont.retWrapper;
    }
    
    
    public void runQuery(){
    
        //if(String.isNotBlank(sObjName)){
          
        
        cont.retWrapper = new List<Wrapper>();
        Set<String> curr = cont.current;
        
        //KRB 4/2016
        
        //String fieldsToDisplay = sObjName + '_Display_Fields'; 
        //List<MSD_CORE_Visibility_Engine_Properties__c> VEpropertiesList = Database.query('SELECT MSD_CORE_Name__c, MSD_CORE_Value__c FROM MSD_CORE_Visibility_Engine_Properties__c WHERE MSD_CORE_Name__c = \'' + fieldsToDisplay + '\''); 

        
        //String fields = getLabelString(labelName);
        String q; 
        
        //if(!VEpropertiesList.isEmpty()){
        //   q = 'SELECT Id,Name,' + VEpropertiesList[0].MSD_CORE_Value__c  +  ' FROM ' + sObjName + ' WHERE Name Like \'%' + search + '%\' AND Id NOT IN :curr LIMIT 20';
         
        
       // }else{
           q = 'SELECT Id,Name FROM ' + sObjName + ' WHERE Name Like \'%' + search + '%\' AND Id NOT IN :curr LIMIT 20';
       // }
        
        System.debug(q);
        
        
        
        //String listType = 'List<' + sObjName + '>';
        //List<SObject> castRecords = (List<SObject>)Type.forName(listType).newInstance();
        //castRecords.addAll(Database.query(q));

        
        
        //for(SObject obj : castRecords){
        
        try{
        for(SObject obj : Database.query(q)){
            cont.retWrapper.add(new Wrapper(obj));
        }
        }catch(Exception e){
        return;
        }
    
    
    //}
    
    }
    
    public class Wrapper{
        public SObject obj{get;set;}
        public boolean include{get;set;}
        public String accessLevel{get;set;}
        
        public Wrapper(SObject objIn){
            obj = objIn;
        }
    }
        
}