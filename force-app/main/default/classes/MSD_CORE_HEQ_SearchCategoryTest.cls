/**
 * Component Name:      MSD_CORE_HEQ_SearchCategoryTest
 * Created By:          Ravi Modi (Focal CXM)
 * Created Date:        23th July 2024
 * @description:        Test class of MSD_CORE_HEQ_SearchCategoryController
 */

@isTest
public class MSD_CORE_HEQ_SearchCategoryTest {

    /**
     * @description: Cover getSearchCategory method
     * @return: void
    */
    @isTest
    static void testGetSearchCategory() {
        
        Test.startTest();
        List<MSD_CORE_HEQ_SearchCategoryController.SearchCategoryWrapper> result = MSD_CORE_HEQ_SearchCategoryController.getSearchCategory('System Administrator');
        Test.stopTest();

        // Perform assertions to verify the results
        System.assertEquals(true, result.size()>0, 'Expected more than one root category');
    }
}