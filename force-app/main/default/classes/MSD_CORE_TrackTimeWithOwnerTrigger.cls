/*
* MSD_CORE_TrackTimeWithOwnerTrigger
* Created By:    Roman Lerman
* Created Date:  7/14/2015
* Description:   This class tracks the time a Case spends with an owner 
*                (the owner can be a person or a queue).
*                The contact center business hours must be set up in order for the time to be recorded.
*/
public with sharing class MSD_CORE_TrackTimeWithOwnerTrigger implements TriggersMVN.HandlerInterface {
    public void execute(Map<Id, Case> newCases, Map<Id, Case> oldCases){
        Schema.DescribeSObjectResult usr = User.sObjectType.getDescribe();
        String userIdPrefix = usr.getKeyPrefix();

        Service_Cloud_Settings_MVN__c settings = Service_Cloud_Settings_MVN__c.getInstance();

        List<BusinessHours> businessHoursList = [select Id from BusinessHours 
                                                    where isActive = true 
                                                    and Name =: settings.MSD_CORE_Business_Hours_Name__c];

        if(businessHoursList == null || businessHoursList.size() == 0){
            return;
        }

        Id businessHoursId = businessHoursList[0].Id;

        Map<Id, Case> oldCaseMap = new Map<Id, Case>([select Id, Status, CreatedDate, OwnerId, Owner.Name, MSD_CORE_Owner_Role__c,
                                                        (select Id, CreatedDate from Time_With_Owner__r order by CreatedDate desc) 
                                                        from Case where Id in :oldCases.values()]);

        List<MSD_CORE_Time_with_Owner__c> timeWithOwnerList = new List<MSD_CORE_Time_with_Owner__c>();
        for(Case newCase : newCases.values()){
            Case oldCase = oldCaseMap.get(newCase.Id);

            if(oldCase != null && (newCase.OwnerId != oldCase.OwnerId 
                || (newCase.Status != oldCase.Status 
                    && (newCase.Status == settings.Closed_Status_MVN__c
                        || newCase.Status == settings.Cancelled_Status_MVN__c)))){

                MSD_CORE_Time_with_Owner__c timeWithOwner = new MSD_CORE_Time_with_Owner__c();
                
                if(((String) oldCase.OwnerId).startsWith(userIdPrefix)){
                    timeWithOwner.MSD_CORE_User__c = oldCase.OwnerId;
                }else{
                    timeWithOwner.MSD_CORE_Queue_Name__c = oldCase.Owner.Name;
                }

                Datetime startDate = newCase.CreatedDate;
                if(oldCase.Time_With_Owner__r != null && oldCase.Time_With_Owner__r.size() > 0){
                    startDate = oldCase.Time_With_Owner__r[0].CreatedDate;
                }
                timeWithOwner.MSD_CORE_Time_in_Hours__c = Decimal.valueOf(BusinessHours.diff(businessHoursId, 
                                                                            startDate,
                                                                            Datetime.now()))/(1000*60*60);
                timeWithOwner.MSD_CORE_Case__c = newCase.Id;

                timeWithOwner.MSD_CORE_Owner_Role__c = oldCase.MSD_CORE_Owner_Role__c;

                timeWithOwnerList.add(timeWithOwner);
            }
        }

        if(timeWithOwnerList != null && timeWithOwnerList.size() > 0){
            insert timeWithOwnerList;
        }
    }

    public void handle() {
        execute((Map<Id, Case>) trigger.newMap, (Map<Id, Case>) trigger.oldMap);
    }
}