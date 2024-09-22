public class MSD_CORE_NAW_RecordType_Controller{

/** Apex Class controls  
*   VisualForce : MSD_Core_NAW_RecordType_Selection_VF
*   
*/

/************** Variable Definitions *********************/
Set<String> recordTypes = new Set<String>(); //Distinct Record Types in MSD_CORE_NAW_Field_Types__c Object.
public String selRT {get; set;} //Account Record Type Selected by the Rep - MSD_Core_NAW_RecordType_Selection_VF 
public String sRT {get; set;} //Account Record Type Selected by the Rep - MSD_Core_NAW_VF

public List<SelectOption> getRT(){
   List<SelectOption> options = new List<SelectOption>();
   for(String s : recordTypes){
    options.add(new SelectOption(s, s.replace('_vod','')));
   }
   return options;
}
Public List<New_Account_Wizard__c> NAW_Settings {get; set;} //Custom Settings to display Account Record Type Descriptions

/************** Controller for MSD_Core_NAW_RecordType_Selection_VF Page  *********************/
public MSD_CORE_NAW_RecordType_Controller(){

Id profileId=userinfo.getProfileId();  //Not using it in the code
String profileName=[Select Id,Name from Profile where Id=:profileId].Name;  //Not using it in the code

for(MSD_CORE_NAW_Field_Types__c r : [Select Record_Type__c from MSD_CORE_NAW_Field_Types__c where Active__c = true AND Profile__c = 'All Sales User Profiles' order by Record_Type__c ])  //Populating Map. Distinct Record Types
    recordTypes.add(r.Record_Type__c );
    
NAW_Settings  = [SELECT Instructions__c,Description__c,Name FROM New_Account_Wizard__c]; //Populating List

}

/************** Functions/Methods used in MSD_Core_NAW_RecordType_Selection_VF Page  *********************/

public PageReference cont() {  //Code to call the Next NAW VF Page & passing selected RecordType
    //System.debug('Selected Record Type...' + selRT);
    PageReference NAWPage = new PageReference('/apex/MSD_Core_NAW_VF_New?recType='+selRT);
    NAWPage.setRedirect(true);
    return NAWPage;
}
      
public PageReference Cancel() { //Code to call the Home Page
  //  PageReference HomePage = new PageReference('/home/home.jsp'); 
    PageReference HomePage = new PageReference('/apex/searchAccts');    
    HomePage.setRedirect(true);
    return HomePage;
}


}