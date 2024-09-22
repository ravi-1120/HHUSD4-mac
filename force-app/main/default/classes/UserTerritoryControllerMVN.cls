/*
 * UserTerritoryControllerMVN
 * Modified by: Kai Amundsen
 * Last Modified Date: June 9, 2014
 * Description: Controller for User territory component that is optional on account page layouts.
 *
 * *** NOTE: Currently not used for the Merck implementation. ***
 */

 public with sharing class UserTerritoryControllerMVN {
	private final Account acct;
    public List<UserTerritoryRow> userTerritories {get;private set;}

    public UserTerritoryControllerMVN(ApexPages.StandardController controller) {
        this.acct = (Account)controller.getRecord();
    }

    public List<UserTerritoryRow> getUserTerritories() {
        if(userTerritories == null) {
            userTerritories = new List<UserTerritoryRow>();

            String acctId = acct.id;
            if ((acctId == null) || (acctId == '')) {
                return null;
            }

            Set<String> groupIds = new Set<String>();
            for (AccountShare acctShare : [Select UserOrGroupId From AccountShare Where AccountId=:acctId And RowCause In ('Territory','TerritoryManual')]) {
                groupIds.add(acctShare.UserOrGroupId);
            }

            if (groupIds.size() <= 0) {
                return null;
            }

            Set<String> territoryIds = new Set<String>();
            for (Group gr : [Select RelatedId From Group Where Id In :groupIds]) {
                territoryIds.add(gr.RelatedId);
            }

            if (territoryIds.size() <= 0) {
                return null;
            }

            List<UserTerritory> userTerritoryList = [Select Id,UserId,TerritoryId From UserTerritory Where TerritoryId In :territoryIds And IsActive=true];

            Set<String> userIds = new Set<String>();
            for (UserTerritory ut : userTerritoryList) {
                userIds.add(ut.UserId);
            }

            Map<Id,User> users = null;
            if (userIds.size() > 0) {
                users = new Map<Id,User>([Select Id,Name,Phone,Email From User Where Id In :userIds]);
            } else {
                return null;
            }

            Map<Id,Territory> territories = new Map<Id,Territory>([Select Id,Name,Description From Territory Where Id In :territoryIds]);

            for (UserTerritory ut : userTerritoryList) {
                Territory tempTerr = territories.get(ut.TerritoryId);
                if (tempTerr == null) {
                    continue;
                }

                UserTerritoryRow userTerrRow = new UserTerritoryRow();

                User usr = users.get(ut.UserId);

                userTerrRow.Territory = tempTerr.Name;
                if (tempTerr.Description != null) {
                    userTerrRow.Description = tempTerr.Description;
                } else {
                    userTerrRow.Description = '';
                }
                userTerrRow.User = usr.Name;
                userTerrRow.Phone = usr.Phone;
                userTerrRow.Email = usr.Email;
                userTerritories.add(userTerrRow);
            }
        }

        return userTerritories;
    }

    public class UserTerritoryRow {
        public String territory{get; set;}
        public String user{get; set;}
        public String description{get; set;}
        public String Phone{get; set;}
        public String Email{get; set;}
    }
}