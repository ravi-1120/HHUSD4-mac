public class MSD_Core_RTI_Switch_Utility {
    
    String countryCode;
    //String switchStatus = 'OFF';  **US version will not use this class to look up on and off per country.  
    String switchStatus = 'ON';  //Hard code the switch to ON for the US.
    String systemName;
    
    public string getSwitchValue(String countryCode, String systemName){
    return switchStatus;
    }
    
    
/*  Commenting out code to lookup in a custom object that is not in the US org  
    public string getSwitchValue(String countryCode, String systemName){
        
        this.countryCode = countryCode;
        this.systemName = systemName;
        
        MSD_Core_RTI_Switch__c[] switchvalue = [Select MSD_Core_Swtich__c from MSD_Core_RTI_Switch__c where 
                                               MSD_Core_Country_code__c =:countryCode and MSD_Core_External_System__c =:systemName];
        
        if(switchvalue.size()>0){
            return switchvalue[0].MSD_Core_Swtich__c;
        }
        
        else
            return switchStatus;
    }
*/
}