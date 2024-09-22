public without sharing class VeevaTimeOffTerritoryTriggerHandler extends VeevaTriggerHandler {
    private List<Time_Off_Territory_vod__c> newTimeOffTerritories;
    private List<Time_Off_Territory_vod__c> oldTimeOffTerritories;
    private Map<ID, Time_Off_Territory_vod__c> newTimeOffTerritoriesMap;
    private Map<ID, Time_Off_Territory_vod__c> oldTimeOffTerritoriesMap;
        
    protected override void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld, Map<ID, SObject> triggerNewMap, Map<ID, SObject> triggerOldMap) {
        this.newTimeOffTerritories = (List<Time_Off_Territory_vod__c>) triggerNew;
        this.oldTimeOffTerritories = (List<Time_Off_Territory_vod__c>) triggerOld;
        this.newTimeOffTerritoriesMap = (Map<ID, Time_Off_Territory_vod__c>) triggerNewMap;
        this.oldTimeOffTerritoriesMap = (Map<ID, Time_Off_Territory_vod__c>) triggerOldMap;
    }
    
    protected override String sObjectType() {
        return 'Time_Off_Territory_vod__c';
    }
    
    protected override void beforeInsert() {
        handleBeforeInsertUpdate();
    }
    
    protected override void beforeUpdate() {
        handleBeforeInsertUpdate();
    }

    protected override void beforeDelete() {
        List<Unavailable_Time_vod__c> toDelete = new List<Unavailable_Time_vod__c>();
        List<ID> totIdsForUtDeletion = new List<ID>();

        for (Time_Off_Territory_vod__c oldTot : this.oldTimeOffTerritories) {
            if (oldTot.Unavailable_for_Engage_Scheduling_vod__c) {
                totIdsForUtDeletion.add(oldTot.Id);
            }
        }

        if (!totIdsForUtDeletion.isEmpty()) {
            toDelete.addAll([SELECT Id FROM Unavailable_Time_vod__c WHERE Time_Off_Territory_vod__c IN :totIdsForUtDeletion]);
            handleUnavailableTimeDeletion(toDelete);
        }
    }
    
    protected override void afterInsert() {
        Map<ID, String> userIdToLocale = getUserIdToLocale();
        Boolean disableTotWeekends = disableTotWeekends();
        List<Unavailable_Time_vod__c> toCreate = new List<Unavailable_Time_vod__c>();
        
        for (Time_Off_Territory_vod__c tot : this.newTimeOffTerritories) {
            if (tot.Unavailable_for_Engage_Scheduling_vod__c) {
                String locale = userIdToLocale.get(tot.OwnerId);
                Unavailable_Time_vod__c ut = (new VeevaUnavailableTimeBuilder())
                    .setOwnerId(tot.OwnerId)
                    .setTimeOffTerritory(tot.Id)
                    .setStartAndEndDates(locale, disableTotWeekends, tot.Date_vod__c, tot.Time_vod__c, tot.Start_Time_vod__c, tot.Hours_vod__c.intValue())
                    .build();
                toCreate.add(ut);
            }
        }
        
        handleUnavailableTimeUpsert(toCreate);
    }
    
    protected override void afterUpdate() {
        Map<ID, String> userIdToLocale = getUserIdToLocale();
        Boolean disableTotWeekends = disableTotWeekends();

        List<Unavailable_Time_vod__c> toUpsert = new List<Unavailable_Time_vod__c>();
        List<Unavailable_Time_vod__c> toDelete = new List<Unavailable_Time_vod__c>();
        List<ID> totIdsForUtUpdate = new List<ID>();
        List<ID> totIdsForUtDeletion = new List<ID>();

        for (Time_Off_Territory_vod__c currentTot : this.newTimeOffTerritories) {
            Time_Off_Territory_vod__c prevTot = this.oldTimeOffTerritoriesMap.get(currentTot.Id);

            if (prevTot.Unavailable_for_Engage_Scheduling_vod__c != currentTot.Unavailable_for_Engage_Scheduling_vod__c) {
                if (currentTot.Unavailable_for_Engage_Scheduling_vod__c) {
                    VeevaUnavailableTimeBuilder builder = new VeevaUnavailableTimeBuilder();
                    String locale = userIdToLocale.get(currentTot.OwnerId);

                    Unavailable_Time_vod__c ut = 
                        builder.setOwnerId(currentTot.OwnerId)
                        .setTimeOffTerritory(currentTot.Id)
                        .setStartAndEndDates(locale, disableTotWeekends, currentTot.Date_vod__c, currentTot.Time_vod__c, currentTot.Start_Time_vod__c, currentTot.Hours_vod__c.intValue())
                        .build();
                    toUpsert.add(ut);
                } else {
                    totIdsForUtDeletion.add(currentTot.Id);
                }
            } else if (currentTot.Unavailable_for_Engage_Scheduling_vod__c && (prevTot.OwnerId != currentTot.OwnerId || dateOrTimeValuesHaveChanged(prevTot, currentTot))) {
                totIdsForUtUpdate.add(currentTot.Id);
            }
        }

        // Query all UTs to be deleted
        if (!totIdsForUtDeletion.isEmpty()) {
            toDelete.addAll([SELECT Id FROM Unavailable_Time_vod__c WHERE Time_Off_Territory_vod__c IN :totIdsForUtDeletion]);
            handleUnavailableTimeDeletion(toDelete);
        }

        // Query all the UTs to be updated and determine what has changed in the source TOT record
        if (!totIdsForUtUpdate.isEmpty()) {
            List<Unavailable_Time_vod__c> filteredUtsToUpdate = [SELECT Id, Time_Off_Territory_vod__c FROM Unavailable_Time_vod__c WHERE Time_Off_Territory_vod__c IN :totIdsForUtUpdate];
            for (Unavailable_Time_vod__c ut : filteredUtsToUpdate) {
                Id sourceTotId = ut.Time_Off_Territory_vod__c;
                Time_Off_Territory_vod__c prevTot = this.oldTimeOffTerritoriesMap.get(sourceTotId);
                Time_Off_Territory_vod__c currentTot = this.newTimeOffTerritoriesMap.get(sourceTotId);

                VeevaUnavailableTimeBuilder builder = new VeevaUnavailableTimeBuilder();
                builder.setId(ut.Id);
                builder.setTimeOffTerritory(ut.Time_Off_Territory_vod__c);

                if (prevTot.OwnerId != currentTot.OwnerId) {
                    builder.setOwnerId(currentTot.OwnerId);
                }

                if (dateOrTimeValuesHaveChanged(prevTot, currentTot)) {
                    String locale = userIdToLocale.get(currentTot.OwnerId);
                    builder.setStartAndEndDates(locale, disableTotWeekends, currentTot.Date_vod__c, currentTot.Time_vod__c, currentTot.Start_Time_vod__c, currentTot.Hours_vod__c.intValue());
                }

                toUpsert.add(builder.build());
            }
        }

        handleUnavailableTimeUpsert(toUpsert);
    }
    
    private void handleBeforeInsertUpdate() {
        if (VEEVA_PROCESS_FLAGS.getUpdateTOT() == true) {
            return;
        }

        // Retrieve the set of TOT owners from those being created/updated
        Set<Id> ownerList = new Set<Id>();
        for (Integer o = 0; o < this.newTimeOffTerritories.size(); o++) {
            ownerList.add(this.newTimeOffTerritories[o].OwnerId);      
        }

        Map <String, List <String>> mTerr = new Map <String, List <String>>();
        Map<Id, Map<String, String>> userTerrs = new Map<Id, Map<String, String>>();
        Map<Id, Map<String, String>> territoryMap = new Map<Id, Map<String, String>>();
        Set<Id> territoryIds = new Set<Id>();

        userTerrs = TerritoryManagementFactory.getInstance().getUserTerritories(ownerList, null);
        for(Map<String, String> ut : userTerrs.values()){
            //TERRITORY_MAP in TerritoryManagement handles TerritoryId & Territory2Id mapping
            territoryIds.add(ut.get('territoryId'));
        }

        territoryMap = TerritoryManagementFactory.getInstance().getTerritories(territoryIds);
        for(Map<String, String> userTerr : userTerrs.values()) {
            String UserId = userTerr.get('UserId');
            List <String> sTerr = mTerr.get(UserId);
            if (sTerr == null) {
                sTerr = new List <String> ();
            }
            Map<String, String> terr = territoryMap.get(userTerr.get('territoryId'));
            if (terr != null) {
                sTerr.add(terr.get('Name'));
                mTerr.put(UserId, sTerr);
            }
        }
     
        for (Integer l = 0; l < this.newTimeOffTerritories.size(); l++) {
    
            String ownerInRow = this.newTimeOffTerritories[l].OwnerId;
            List <String> thisSet = mTerr.get(ownerInRow);
            String terrString = ';';
    
            if (thisSet != null) {
                for (String terrName : thisSet) {
                    terrString += terrName + ';';
                }
            }

            this.newTimeOffTerritories[l].Territory_vod__c = terrString;
            if(this.newTimeOffTerritories[l].Time_vod__c == 'Hourly') {
                if(this.newTimeOffTerritories[l].Hours_off_vod__c == null) {
                    this.newTimeOffTerritories[l].Hours_off_vod__c = '1'; 
                }
                if(this.newTimeOffTerritories[l].Start_Time_vod__c == null) {
                    this.newTimeOffTerritories[l].Start_Time_vod__c = '8:00 AM';
                }                    
            }
        }

        checkForTotOverlap();
    }

    private void checkForTotOverlap() {
        Boolean disableTotWeekends = disableTotWeekends();
        Integer preventTotOverlap = preventTotOverlap();

        if (preventTotOverlap != 2 || this.newTimeOffTerritories.size() > 1) { // iPad ignores PREVENT_TOT_OVERLAP when multiple records inserted simultaneously
            return;
        }

        String totOverlapError = VeevaMessageController.getVeevaMessages(new List<String>{'TOT'}).get('TOT;;TOT_OVERLAP_ERROR');

        Time_Off_Territory_vod__c newTot = this.newTimeOffTerritories.get(0);
        List<Time_Off_Territory_vod__c> existingTots = [SELECT Id, Date_vod__c, Time_vod__c, Start_Time_vod__c, Reason_vod__c, Hours_vod__c, OwnerId FROM Time_Off_Territory_vod__c WHERE OwnerId = :newTot.OwnerId AND Id != :newTot.Id AND Date_vod__c > :newTot.Date_vod__c.addDays(-10) AND Date_vod__c < :newTot.Date_vod__c.addDays(10)];
        Map<ID, String> userIdToLocale = getUserIdToLocale(existingTots);

        List<Datetime> adjustedDatesNewTot = VeevaUnavailableTimeBuilder.calculateStartAndEndDates(
                                                userIdToLocale.get(newTot.OwnerId), disableTotWeekends, newTot.Date_vod__c, newTot.Time_vod__c, newTot.Start_Time_vod__c, 
                                                newTot.Hours_vod__c != null ? newTot.Hours_vod__c.intValue() : null);
        Datetime adjustedStartDate = adjustedDatesNewTot.get(0);
        Datetime adjustedEndDate = adjustedDatesNewTot.get(1);
        
        Set<String> nonAllDays = new Set<String>{'AM Off', 'PM Off', 'Hourly'};
        for (Time_Off_Territory_vod__c existingTot : existingTots) {
            List<Datetime> adjustedDatesExistingTot = VeevaUnavailableTimeBuilder.calculateStartAndEndDates(
                                                        userIdToLocale.get(existingTot.OwnerId), disableTotWeekends, existingTot.Date_vod__c, existingTot.Time_vod__c, existingTot.Start_Time_vod__c, 
                                                        existingTot.Hours_vod__c != null ? existingTot.Hours_vod__c.intValue() : null);
            Datetime adjustedStartDateExistingTot = adjustedDatesExistingTot.get(0);
            Datetime adjustedEndDateExistingTot = adjustedDatesExistingTot.get(1);
            
            if(nonAllDays.contains(newTot.Time_vod__c) || nonAllDays.contains(existingTot.Time_vod__c)) {
                if (eventsOverlap(adjustedStartDate, adjustedEndDate, adjustedStartDateExistingTot, adjustedEndDateExistingTot)) {
                    newTot.addError(totOverlapError);
                    break;
                }
            } else {
                if (eventsDateOverlap(adjustedStartDate.date(), adjustedEndDate.date(), adjustedStartDateExistingTot.date(), adjustedEndDateExistingTot.date())) {
                    newTot.addError(totOverlapError);
                    break;
                }
            }
        }
    }

    @TestVisible
    private static Boolean eventsDateOverlap(Date start1, Date end1, Date start2, Date end2) {
        return (start1 < end2 && start2 < end1);
    }

    @TestVisible
    private static Boolean eventsOverlap(Datetime start1, Datetime end1, Datetime start2, Datetime end2) {
        return (start1 < start2 && start2 < end1) ||
                (start2 < end1 && start1 < end2) ||
                (start1 < start2 && end1 > end2) ||
                (start2 < start1 && end2 > end1);
    }

    private void handleUnavailableTimeDeletion(List<Unavailable_Time_vod__c> toDelete) {
        if (!toDelete.isEmpty()) {
            Database.DeleteResult[] deletionResults = Database.delete(toDelete, false);
            for (Integer i = 0; i < deletionResults.size(); i++) {
                Database.DeleteResult result = deletionResults.get(i);
                if (!result.isSuccess()){
                    Id targetTotRecord = toDelete.get(i).Time_Off_Territory_vod__c;
                    Database.Error[] errors = result.getErrors();
                    
                    String msg = '';
                    for (Database.Error e : errors) {
                        msg += e.getStatusCode() + ': ' + e.getMessage() + ' ';                 
                    }
                    this.oldTimeOffTerritoriesMap.get(targetTotRecord).addError(msg);
                }
            }
        }
    }

    private void handleUnavailableTimeUpsert(List<Unavailable_Time_vod__c> toUpsert) {
        if (!toUpsert.isEmpty()) {
            Database.UpsertResult[] upsertResults = Database.upsert(toUpsert, false);
            for (Integer i = 0; i < upsertResults.size(); i++) {
                Database.UpsertResult result = upsertResults.get(i);
                if (!result.isSuccess()){
                    Id targetTotRecord = toUpsert.get(i).Time_Off_Territory_vod__c;
                    Database.Error[] errors = result.getErrors();
                    
                    String msg = '';
                    for (Database.Error e : errors) {
                        msg += e.getStatusCode() + ': ' + e.getMessage() + ' ';                 
                    }
                    this.newTimeOffTerritoriesMap.get(targetTotRecord).addError(msg);
                }
            }
        }
    }

    private Map<ID, String> getUserIdToLocale() {
        return getUserIdToLocale(null);
    }

    private Map<ID, String> getUserIdToLocale(List<Time_Off_Territory_vod__c> existingTots) {
        Set<ID> userIds = new Set<Id>();
        for (Time_Off_Territory_vod__c tot : this.newTimeOffTerritories) {
            userIds.add(tot.OwnerId);
        }
        
        if (existingTots != null) {
            for (Time_Off_Territory_vod__c tot : existingTots) {
                userIds.add(tot.OwnerId);
            }
        }

        Map<ID, String> userIdToLocale = new Map<ID, String>();
        if (!userIds.isEmpty()) {
            List<User> users = [SELECT Id, LocaleSidKey FROM User WHERE Id IN :userIds];
            for (User u : users) {
                userIdToLocale.put(u.Id, u.LocaleSidKey);
            }
        }
        return userIdToLocale;
    }

    private Boolean disableTotWeekends() {
        Veeva_Settings_vod__c vsc = Veeva_Settings_vod__c.getInstance();
        return vsc != null ? vsc.DISABLE_TOT_WEEKENDS_vod__c : true;
    }

    private Integer preventTotOverlap() {
        Veeva_Settings_vod__c vsc = Veeva_Settings_vod__c.getInstance();
        return (vsc != null && vsc.PREVENT_TOT_OVERLAP_vod__c != null) ? vsc.PREVENT_TOT_OVERLAP_vod__c.intValue() : 0;
    }

    private Boolean dateOrTimeValuesHaveChanged(Time_Off_Territory_vod__c prevRecord, Time_Off_Territory_vod__c currentRecord) {
        return (prevRecord.Date_vod__c != currentRecord.Date_vod__c || prevRecord.Time_vod__c != currentRecord.Time_vod__c 
        || (currentRecord.Time_vod__c == 'Hourly' && (prevRecord.Start_Time_vod__c != currentRecord.Start_Time_vod__c || prevRecord.Hours_off_vod__c != currentRecord.Hours_off_vod__c)));
    }
}