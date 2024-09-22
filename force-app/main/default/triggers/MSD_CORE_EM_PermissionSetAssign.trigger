trigger MSD_CORE_EM_PermissionSetAssign on User (after insert) {

String Profiles = Label.MSD_CORE_EM_PROFILES;
Set<ID> usersId = new Set<Id>();
Id PermissionSetId1;
Id PermissionSetId2;

List<PermissionSet> PS = [select Id from PermissionSet where name in ('MSD_CORE_EM_FIELD_USER','MSD_CORE_EM_MERCK_MEDICAL_FORUM')];
PermissionSetId1 = PS.get(0).Id;
PermissionSetId2 = PS.get(1).Id;

for(User usr: Trigger.new){
if(usr.IsActive == true){ //If user is active
  if(Profiles.contains(usr.Profile_Name_vod__c)){ //If Profile of the user is part of the custom label profiles list.
    usersId.add(usr.Id); //Populate the user set
  }
}
}
  //AssignPermissionSet.AssignPermissionSetToUsers(usersId);
  List<PermissionSetAssignment> permissionSetList = new List<PermissionSetAssignment>();
       for (User u : [Select Id, Name FROM User Where Id IN : usersId]){ 
       PermissionSetAssignment psa1 = new PermissionSetAssignment (PermissionSetId = PermissionSetId1, AssigneeId = u.Id);
       PermissionSetAssignment psa2 = new PermissionSetAssignment (PermissionSetId = PermissionSetId2, AssigneeId = u.Id);
       permissionSetList.add(psa1);
       permissionSetList.add(psa2);
       
        PreferencesUtil.createPreferences(u.Id); //class to insert preferences class
    }
    upsert permissionSetList;
}