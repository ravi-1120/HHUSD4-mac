/**
* @author - Brian Pfeil, Merck & Co.,Inc.
* @className - MRK_UserInfo.cls
* @description - Convienence class that provides additional user information attributes
*                to help with targeting
* @createdate - July 8th, 2013
*
*/

public class MRK_UserInfo {

	private static Map<String, MRK_UserInfo> cache = new Map<String, MRK_UserInfo>();
	public String userid;
	public String profileName;
	public Set<Id> assignedProductIds = new Set<Id>();
	public Set<String> assignedProductNames = new Set<String>();
	public Set<String> assignedProductExternalIds = new Set<String>();

	public Set<String> salesTeamCodes = new Set<String>();

	public List<Id> territoryPathIdList = new List<Id>();
	public List<String> territoryPathDescriptionList = new List<String>();
	public Set<String> territoryPathDescriptionSet = new Set<String>();

	public MRK_UserInfo() {
		
	}

	public static MRK_UserInfo getByUserid(String userid) {

		// check for cache hit
		MRK_UserInfo ui = cache.get(userid);
		if (ui != null) {
			return ui;
		}

		ui = new MRK_UserInfo();

		ui.userid = userid;
		ui.profileName = [select Profile.Name from user where Id = :userid].Profile.Name;


		// assigned products
		for (My_Setup_Products_vod__c sp : [SELECT Product_vod__c, Product_vod__r.Name, Product_vod__r.External_ID_vod__c FROM My_Setup_Products_vod__c WHERE OwnerId = :userid and Product_vod__r.Product_Type_vod__c = 'Detail']) {
			ui.assignedProductIds.add(sp.Product_vod__c);
			ui.assignedProductNames.add(sp.Product_vod__r.Name);
			ui.assignedProductExternalIds.add(sp.Product_vod__r.External_ID_vod__c);
		}

		// sales team(s)
		for (User_Sales_Team_MRK__c ust : [select Id, Name, Sales_Team_MRK__c, Sales_Team_MRK__r.Sales_Team_Code_MRK__c from User_Sales_Team_MRK__c where User_MRK__c = :userid]) {
			ui.salesTeamCodes.add(ust.Sales_Team_MRK__r.Sales_Team_Code_MRK__c);
		}

		// all users are members of the *virtual* "MERCK & CO." (000) team
		ui.salesTeamCodes.add('000');
		
		// get *my* territory
		String territoryId = null;
		//KRB 2/11/2020 - Out for TM2.0
        //List<UserTerritory> utList = [select TerritoryId from UserTerritory where UserId = :userid and IsActive = true];
		//KRB 2/11/2020 - In for TM2.0
        List<UserTerritory2Association> utList = [SELECT Territory2Id 
                                                  FROM   UserTerritory2Association 
                                                  WHERE  UserId = :userid 
                                                  AND    IsActive = true
                                                  AND    Territory2.Territory2Model.state = 'Active'];
        
		if (utList.size() > 0) {
			//KRB 2/11/2020 - Out for TM2.0
            //territoryId = utList[0].TerritoryId;
            //KRB 2/11/2020 - In for TM2.0
            territoryId = utList[0].Territory2Id;
            System.debug('TM2.0 Test: territoryId: ' + territoryId);
		}


		// walk up the hierarchy
		while (territoryId != null) {
		/* KRB 2/11/2020 - Out for TM2.0
            Territory t = [select ParentTerritoryId, Name, Description from Territory where Id = :territoryId];
			territoryId = t.ParentTerritoryId;
		   ui.territoryPathIdList.add(t.ParentTerritoryId);
		   ui.territoryPathDescriptionList.add(t.Description);
		   ui.territoryPathDescriptionSet.add(t.Description);
        */
           //KRB 2/11/2020 - In for TM2.0
           Territory2 t = [select ParentTerritory2Id, Name, Description from Territory2 where Id = :territoryId];
		   System.debug('TM2.0 Test: ParentTerritory2Id: ' + t.ParentTerritory2Id);

           territoryId = t.ParentTerritory2Id;
		   ui.territoryPathIdList.add(t.ParentTerritory2Id);
		   ui.territoryPathDescriptionList.add(t.Description);
		   ui.territoryPathDescriptionSet.add(t.Description);
		}

		// limit territory targeting to the first N levels
		Integer levels = MRK_Setting.getInteger(MRK_CommunicationServices.SETTING_NAME, 'territory targeting levels');

		// if levels isn't a valid value, don't set any limits, and all levels will be used
		if ( (levels != null) && (levels > 0) ) {

			Set<String> levelLimitedTerritoryPathDescriptionsSet = new Set<String>();		

			// walk the territory list backwards since the top most territory in the hierarchy
			// is last in the list			
			Integer counter = 0;
			for (Integer i = (ui.territoryPathDescriptionList.size() - 1); i >=0; i--) {
				if (counter++ < levels) {
					levelLimitedTerritoryPathDescriptionsSet.add(ui.territoryPathDescriptionList[i]);	
				}
			}

			// clear set with all levels
			ui.territoryPathDescriptionSet.clear();

			// add limited levels
			ui.territoryPathDescriptionSet.addAll(levelLimitedTerritoryPathDescriptionsSet);

		}

		return ui;	

	}

	public static Boolean communicationFunctionalityEnabledForUser(String userid) {
		Boolean globalPilotMode = MRK_Setting.getBoolean(MRK_CommunicationServices.SETTING_NAME, 'pilot mode');
		if (!globalPilotMode) {
			return true;
		} else {
			String fieldName = MRK_Setting.getString(MRK_CommunicationServices.SETTING_NAME, 'pilot user field api name');
			User u = (User)Database.query('select ' + fieldName + ' from user where id = \'' + userid + '\'' )[0];
			return (Boolean)u.get(fieldName);
		}
	}


}