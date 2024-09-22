public class VeevaTeamMemberStubs {
    private static Map<String, Schema.RecordTypeInfo> eaRTMap = Event_Attendee_vod__c.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName();
    private static Map<ID, Schema.RecordTypeInfo> tmRTMap = EM_Event_Team_Member_vod__c.sObjectType.getDescribe().getRecordTypeInfosById();

    public static void insertTeamMemberStubs(Set<Id> newTeamMemberIds) {
        if (System.isFuture() || System.isBatch()) {
            insertTeamMemberStubsSync(newTeamMemberIds);
        } else {
            insertTeamMemberStubsFuture(newTeamMemberIds);
        }
    }

    @future
    private static void insertTeamMemberStubsFuture(Set<Id> newTeamMemberIds) {
        insertTeamMemberStubsSync(newTeamMemberIds);
    }

    private static void insertTeamMemberStubsSync(Set<Id> newTeamMemberIds) {
        VOD_Utils.setTriggerEmTeamMember(true);

        List<EM_Event_Team_Member_vod__c> newEMEventTeamMembers = [
            SELECT
                Id,
                Team_Member_vod__c,
                Name,
                First_Name_vod__c,
                Last_Name_vod__c,
                Group_Name_vod__c,
                Role_vod__c,
                Stub_Mobile_Id_vod__c,
                Event_vod__c,
                RecordTypeId
            FROM EM_Event_Team_Member_vod__c
            WHERE Id IN :newTeamMemberIds
        ];

        List<String> emEventIds = new List<String>();
        for (EM_Event_Team_Member_vod__c member : newEMEventTeamMembers) {
            emEventIds.add(member.Event_vod__c);
        }

        Map<String, String> emEventsToMedEvents = new Map<String, String>();
        for (Medical_Event_vod__c eventStub : [SELECT Id, EM_Event_vod__c FROM Medical_Event_vod__c WHERE EM_Event_vod__c IN :emEventIds]) {
            emEventsToMedEvents.put(eventStub.EM_Event_vod__c, eventStub.Id);
        }

        List<Event_Attendee_vod__c> stubsToInsert = new List<Event_Attendee_vod__c>();
        for (EM_Event_Team_Member_vod__c member : newEMEventTeamMembers) {
            Event_Attendee_vod__c newStub = new Event_Attendee_vod__c(
                User_vod__c = member.Team_Member_vod__c,
                Attendee_vod__c = member.Name,
                First_Name_vod__c = member.First_Name_vod__c,
                Last_Name_vod__c = member.Last_Name_vod__c,
                Group_Name_vod__c = member.Group_Name_vod__c,
                Role_vod__c = member.Role_vod__c,
                EM_Event_Team_Member_vod__c = member.Id,
                Mobile_Id_vod__c = member.Stub_Mobile_Id_vod__c,
                Medical_Event_vod__c = emEventsToMedEvents.get(member.Event_vod__c),
                Override_Lock_vod__c = true
            );
            if (member.RecordTypeId != null && tmRTMap.get(member.RecordTypeId) != null) {
                RecordTypeInfo eaRTInfo = eaRTMap.get(tmRTMap.get(member.RecordTypeId).getDeveloperName());
                if (eaRTInfo != null && eaRTInfo.isAvailable()) {
                    newStub.RecordTypeId = eaRTInfo.getRecordTypeId();
                }
            }

            stubsToInsert.add(newStub);
        }

        Map<String, String> idToStubMap = new Map<String, String>();
        Database.SaveResult[] insertResults = Database.insert(stubsToInsert, false);

        for (Integer i = 0; i < insertResults.size(); i++) {
            Database.SaveResult result = insertResults[i];
            if (result.isSuccess()) {
                idToStubMap.put(stubsToInsert[i].EM_Event_Team_Member_vod__c, result.getId());
            }
        }

        VOD_EVENT_UTILS.updateTeamMemberStub(idToStubMap);
    }

    public static void updateTeamMemberStubs(Set<Id> changedTeamMemberIds) {
        if (System.isFuture() || System.isBatch()) {
            updateTeamMemberStubsSync(changedTeamMemberIds);
        } else {
            updateTeamMemberStubsFuture(changedTeamMemberIds);
        }
    }

    @future
    public static void updateTeamMemberStubsFuture(Set<Id> changedTeamMemberIds) {
        updateTeamMemberStubsSync(changedTeamMemberIds);
    }

    public static void updateTeamMemberStubsSync(Set<Id> changedTeamMemberIds) {
        VOD_Utils.setTriggerEmTeamMember(true);

        List<Event_Attendee_vod__c> stubsToUpdate = new List<Event_Attendee_vod__c>();
        Map<Id, EM_Event_Team_Member_vod__c> changedTeamMemberMap = new Map<Id, EM_Event_Team_Member_vod__c>(
            [
                SELECT Id, Team_Member_vod__c, Name, First_Name_vod__c, Last_Name_vod__c, Group_Name_vod__c, Role_vod__c, RecordTypeId
                FROM EM_Event_Team_Member_vod__c
                WHERE Id IN :changedTeamMemberIds
            ]
        );

        for (Event_Attendee_vod__c stub : [
            SELECT User_vod__c, Attendee_vod__c, First_Name_vod__c, Last_Name_vod__c, Group_Name_vod__c, Role_vod__c, EM_Event_Team_Member_vod__c
            FROM Event_Attendee_vod__c
            WHERE EM_Event_Team_Member_vod__c IN :changedTeamMemberMap.keySet()
        ]) {
            EM_Event_Team_Member_vod__c member = changedTeamMemberMap.get(stub.EM_Event_Team_Member_vod__c);
            stub.User_vod__c = member.Team_Member_vod__c;
            stub.Attendee_vod__c = member.Name;
            stub.First_Name_vod__c = member.First_Name_vod__c;
            stub.Last_Name_vod__c = member.Last_Name_vod__c;
            stub.Group_Name_vod__c = member.Group_Name_vod__c;
            stub.Role_vod__c = member.Role_vod__c;
            stub.Override_Lock_vod__c = true;
            if (member.RecordTypeId != null && tmRTMap.get(member.RecordTypeId) != null) {
                RecordTypeInfo eaRTInfo = eaRTMap.get(tmRTMap.get(member.RecordTypeId).getDeveloperName());
                if (eaRTInfo != null && eaRTInfo.isAvailable()) {
                    stub.RecordTypeId = eaRTInfo.getRecordTypeId();
                }
            }
            stubsToUpdate.add(stub);
        }

        if (stubsToUpdate.size() > 0) {
            Database.update(stubsToUpdate, false);
        }
    }
}