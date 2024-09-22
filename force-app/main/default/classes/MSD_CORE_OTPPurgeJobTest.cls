/**
* Component Name:      MSD_CORE_OTPPurgeJobTest
* Created By:          Focal CXM
* Description:         Test class for MSD_CORE_OTPPurgeJob
*/
@isTest
public class MSD_CORE_OTPPurgeJobTest {
    @isTest static void testSchedule(){
        list<MSD_CORE_OTP__c> otpList = new list<MSD_CORE_OTP__c>();
        for(integer i = 0 ; i < 10 ; i++){
            MSD_CORE_OTP__c otp = new MSD_CORE_OTP__c();
            otp.Name = 'test'+i;
            otp.MSD_CORE_Status__c = 'New';
            otp.MSD_CORE_Token__c = '11111'+i;
            otp.MSD_CORE_Expiration_DateTime__c = System.today().addDays(-10);
            otpList.add(otp);
        }
        insert otpList;
           
        Test.startTest();
	        MSD_CORE_OTPPurgeJob sh1 = new MSD_CORE_OTPPurgeJob();
			String sch = '0 0 23 * * ?'; 
        	system.schedule('MSD_CORE_OTPPurgeJob Test', sch, sh1); 
        Test.stopTest();
    }
    
    @isTest static void testExecute(){
        list<MSD_CORE_OTP__c> otpList = new list<MSD_CORE_OTP__c>();
        for(integer i = 0 ; i < 10 ; i++){
            MSD_CORE_OTP__c otp = new MSD_CORE_OTP__c();
            otp.Name = 'test'+i;
            otp.MSD_CORE_Status__c = 'New';
            otp.MSD_CORE_Token__c = '11111'+i;
            otp.MSD_CORE_Expiration_DateTime__c = System.today().addDays(-10);
            otpList.add(otp);
        }
        insert otpList;
           
        Test.startTest();
	        MSD_CORE_OTPPurgeJob b = new MSD_CORE_OTPPurgeJob();
			database.executeBatch(b);
        Test.stopTest();
        list<MSD_CORE_OTP__c> result = [SELECT Id FROM MSD_CORE_OTP__c];
        System.assertEquals(0,result.size());
    }
}