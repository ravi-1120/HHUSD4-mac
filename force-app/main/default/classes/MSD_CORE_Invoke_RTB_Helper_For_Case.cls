/*
* Company		: Merck Co.
* Date			: 07-02-2018	
* Author		: Ramesh Elapakurthi
* Description	: Helper class to invoke AWS API from a Process builder, for example.
* History		: First version
*/

public class MSD_CORE_Invoke_RTB_Helper_For_Case {

    @InvocableMethod(label='Invoke Aws Api For Case' description='Helper method to invoke Aws Api from a process buider.')
    public static void invokeAwsApiForCase(List<String> pirCases){
        system.debug('calling submitCaseToBus from AWS Api Integration'+ pirCases.get(0));
    	//callAwsApi(pirData.Id,pirData.Account_vod__c,pirData.Status_vod__c , pirData.Inquiry_Text__c, pirData.Salutation_MRK__c);
		MSD_CORE_AwsApiIntegration.submitCaseToBus(pirCases);
        system.debug('Done calling SubmitPirToBus from AWS Api Integration');
    }
    
}