/**
* @author - Brian Pfeil, Merck & Co.,Inc.
* @className - MRK_LinksController.cls
* @description - Controller class for MRK_Links.page
* @createdate - July 8th, 2013
*
*/

public class MRK_LinksController {

	public Boolean functionalityEnabled {
		get {
			return MRK_UserInfo.communicationFunctionalityEnabledForUser( UserInfo.getUserId() );
		}
	}

	public MRK_LinksController() {
		
	}

	public Map<String, Object> getSettings() {
		return MRK_Setting.getValues(MRK_CommunicationServices.SETTING_NAME);
	}

	/*
	* @methodDescription: returns links for user
	*/
	public List<Resource_Link_MRK__c> getLinks() {
		String soql = MRK_Setting.getString(MRK_CommunicationServices.SETTING_NAME, 'links soql');
		return Database.query(soql);
	}

	/*
	* @methodDescription: returns links as JSON.  rendering is done on client
	*/
	public String getLinksAsJSON() {
		
		return JSON.serializePretty( getLinks() );
	}
}