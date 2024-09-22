public class MSD_CORE_CM_FieldValidator {

    /* KRB REL 6.0 6/25/2015 - Class contains methods 
     * that will help enforce the rules implemented
     * by Customer Master. Using these Methods will ensure 
     * that information passed to Customer Master is Valid. 
     */
    
    Public static String DCRServiceLayerSettingsInstance = 'Main';
    
    //Validates string is at least 2 characters in Length
    public static Boolean containsAtLeast2Characters(String str){
        Boolean isValid = true;
        if(str.length() <= 1){
            isValid = false;
        }
        return isValid;
    }

    
    //Validates that the String contains no numbers and 
    //Special Characters other than (<space>,.'-)
    public static Boolean isNameValid(String str){

        Boolean isvalidNm = False;
        
        //Pull the Regular Expression for Name Validation
        MSD_CORE_DCR_Service_Layer_Settings__c dcrServiceLayerSettings = MSD_CORE_DCR_Service_Layer_Settings__c.getInstance(DCRServiceLayerSettingsInstance);
        String Name_RegEx_Validation = '';
        Name_RegEx_Validation = dcrServiceLayerSettings.Name_RegEx_Validation__c;  
 
        //If value in Setting is blank or null =  no validation necessary:
        if(Name_RegEx_Validation == ''){
            return True;
        }
        
        Pattern MyPattern = Pattern.compile(Name_RegEx_Validation);
        Matcher MyMatcher = MyPattern.matcher(str);

        if (MyMatcher.matches()) {
           System.Debug('We found a Match! ');
           isvalidNm = True;
        }        
        
        return isvalidNm;
    }
       
}