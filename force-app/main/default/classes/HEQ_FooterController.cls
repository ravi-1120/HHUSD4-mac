/**
 * Component Name:      HEQ_FooterController
 * Created By:          Ravi Modi (Focal CXM)
 * Created Date:        4th July 2024
 * @description:        Server side controller for HEQ_Footer LWC component
 * Test Class:          HEQ_FooterControllerTest
 */

 public without sharing class HEQ_FooterController {
    

    /**
     * Method Name  :   getPortalSetting
     * @description :   Use to get HEQ Portal Setting Metadata 
     * @return      :   List<Map<String, Object>>
     * Created By   :   Ravi Modi (Focal CXM)
     * Created Date :   4th July 2024
     */
    @AuraEnabled
    public static List<Map<String, Object>> getPortalSetting(){
        List<Map<String, Object>> returnfootervalue = new List<Map<String, Object>>();
        try {
            returnfootervalue = HEQ_Utility.getAllFieldValues('HEQ_Portal_Setting__mdt', 'WHERE DeveloperName LIKE \'HEQ_Footer%\'');
        } catch (Exception e) {
            System.debug('Error>>'+ e.getMessage() + '----' +e.getLineNumber());
        }
        return returnfootervalue;
    }
}