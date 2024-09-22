/**
 * Component Name:      HEQ_SearchCategoryControllerTest
 * Created By:          Ravi Modi (Focal CXM)
 * Created Date:        23th July 2024
 * @description:        Test class of HEQ_SearchCategoryController
 */

@isTest
public class HEQ_SearchCategoryControllerTest {

    /**
     * @description: Cover getSearchCategory method
     * @return: void
    */
    @isTest
    static void testGetSearchCategory() {
        
        Test.startTest();
        List<HEQ_SearchCategoryController.SearchCategoryWrapper> result = HEQ_SearchCategoryController.getSearchCategory('System Administrator');
        Test.stopTest();

        // Perform assertions to verify the results
        System.assertEquals(true, result.size()>0, 'Expected more than one root category');
    }
}