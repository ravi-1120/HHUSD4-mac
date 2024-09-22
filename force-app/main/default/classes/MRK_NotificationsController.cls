public class MRK_NotificationsController {
   private Map<string,string> pageParams = ApexPages.currentPage().getParameters();	
	public Boolean functionalityEnabled {
		get {
			return MRK_UserInfo.communicationFunctionalityEnabledForUser( UserInfo.getUserId() );
		}
	}

	public MRK_NotificationsController() {

	}

	public Map<String, Object> getSettings() {
		return MRK_Setting.getValues(MRK_CommunicationServices.SETTING_NAME);
	}

	public String getBaseResourceURL() {
		return MRK_CommunicationServices.getResourceURL();
	}

}