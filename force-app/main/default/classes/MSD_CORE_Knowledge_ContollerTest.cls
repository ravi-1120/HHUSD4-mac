@isTest
public class MSD_CORE_Knowledge_ContollerTest {
    @isTest
    public  static void Test() {
        List<String> names = new List<string>();
        Test.startTest();
        names = MSD_CORE_Knowledge_Contoller.GetAvailableRecordTypeNamesForSObject(Knowledge__kav.SObjectType);
        Test.stopTest();  
        
    }
}