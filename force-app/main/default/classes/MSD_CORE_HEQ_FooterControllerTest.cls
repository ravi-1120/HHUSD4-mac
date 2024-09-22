/**
 * Component Name:      MSD_CORE_HEQ_FooterControllerTest
 * Created By:          Shravan (Focal CXM)
 * Created Date:        9/6/2024
 * @description:        Test class of MSD_CORE_HEQ_FooterController
 */

@isTest
public class MSD_CORE_HEQ_FooterControllerTest {
    
    @isTest
    static void testGetFooterConfig() {
        Test.startTest();
        MSD_CORE_HEQ_FooterController.FooterDataWrapper result = MSD_CORE_HEQ_FooterController.getFooterConfig();
        Test.stopTest();
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.additionalMerckSites.size() > 1, 'Expected more than 1 record in additionalMerckSites');
        System.assert(result.footerLinks.size() > 1, 'Expected more than 1 record in additionalMerckSites');
    }
}