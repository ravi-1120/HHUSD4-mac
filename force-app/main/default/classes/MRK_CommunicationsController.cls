/**
* @author - Brian Pfeil, Merck & Co.,Inc.
* @className - MRK_CommunicationsController.cls
* @description - Controller class for MRK_Communications.page
* @createdate - July 8th, 2013
*
*/

public class MRK_CommunicationsController {

	public Boolean functionalityEnabled {
		get {
			return MRK_UserInfo.communicationFunctionalityEnabledForUser( UserInfo.getUserId() );
		}
	}

	public MRK_CommunicationsController() {
		
	}

	public Map<String, Object> getSettings() {
		return MRK_Setting.getValues(MRK_CommunicationServices.SETTING_NAME);
	}

	public String getBaseResourceURL() {
		return MRK_CommunicationServices.getResourceURL();
	}	

}