public class MRK_PermSet_AutoAssign Implements Schedulable{
	
    public void execute(SchedulableContext sc) {
        
	Sales_PermsetAssgn();
    Med_PermsetAssgn();
        
    }
    
    public void Sales_PermsetAssgn()
    {
                  System.debug('Starteddddddd');
        Set<String> Sales_Profile = new Set<String>();
        String salesprof = System.Label.MRK_Sales_Profiles;
        List<String> Splitted_Sales_profiles =salesprof.Split(',');
       Sales_Profile.addAll(Splitted_Sales_profiles);
         System.debug('Sales_Profile'+Sales_Profile);
        
    Set<String> Sales_PermissionSets = new Set<String>();
        String SalesPermissionSet = System.Label.MRK_Sales_PermissionSets;
        List<String> Splitted_Sales_permSet =SalesPermissionSet.Split(',');
       Sales_PermissionSets.addAll(Splitted_Sales_permSet);
        System.debug('Sales_PermissionSets'+Sales_PermissionSets);
        
    List<User> usersToAssignPermissionSets = new List<User>();
List<User> AllUserwithSalesProfile = new List<User>();
    List<PermissionSet> PermSetListInfo = new List<PermissionSet>();
Map<String,PermissionSet> PermissionSetMap = new Map<String,PermissionSet>();
        
        Map<Id,Set<String>> UserPermissionsetMap = new  Map<Id,Set<String>>();
        Map<Id,Set<String>> missingPermissionSetsMap = new  Map<Id,Set<String>>();
        Set<String> missingPermissionSets = new Set<String>();
        Set<String> missingPermissionSetstoadd = new Set<String>();
        
        for(PermissionSetAssignment userPsa : [SELECT AssigneeId, Assignee.Profile_Name_vod__c, PermissionSet.Name FROM PermissionSetAssignment WHERE Assignee.IsActive =true and Assignee.Profile_Name_vod__c IN:Sales_Profile])
        {
            if (!UserPermissionsetMap.containsKey(userPsa.AssigneeId)) {
        UserPermissionsetMap.put(userPsa.AssigneeId, new Set<String>());
        }
            UserPermissionsetMap.get(userPsa.AssigneeId).add(userPsa.PermissionSet.Name);
        }
         System.debug('UserPermissionsetMap ' + UserPermissionsetMap);
      //  AllUserwithSalesProfile = [SELECT Id,Name,Profile_Name_vod__c, IsActive from User where IsActive =true and Profile_Name_vod__c IN:Sales_Profile];
   	//	System.debug('User ' + AllUserwithSalesProfile);
        
		for(Id userId : UserPermissionsetMap.keySet()) 
        {
            Set<String> UserPermissionsSet = UserPermissionsetMap.get(userId);
            missingPermissionSets = Sales_PermissionSets.clone();
        	missingPermissionSets.removeAll(UserPermissionsSet);
            missingPermissionSetsMap.put(userId,missingPermissionSets);
        }
        
        System.debug('missingPermissionSets ' + missingPermissionSets);
          System.debug('missingPermissionSetsMap-----> ' + missingPermissionSetsMap);
      
     PermSetListInfo = [SELECT Id,Name FROM PermissionSet WHERE Name IN:missingPermissionSets];
            for(PermissionSet ps :PermSetListInfo){
                System.debug('ps Name ' + ps.Name);
                System.debug('ps ' + ps);
            	PermissionSetMap.put(ps.Name,ps);
             }
            System.debug('PermissionSetMap ' + PermissionSetMap);
   // System.debug('usersToAssignPermissionSets ' + usersToAssignPermissionSets);
        if (!missingPermissionSetsMap.isEmpty()) {
        List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
            try{
        for (Id user : missingPermissionSetsMap.keySet()) {
           missingPermissionSetstoadd = missingPermissionSetsMap.get(user);
        for (String permissionSetName : missingPermissionSetstoadd) {
            PermissionSet permset = PermissionSetMap.get(permissionSetName);
            System.debug('permset ' + permset);
            if(permset!=null){
        PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = user, PermissionSetId = permset.Id);
            System.debug('PSA*** ' + psa);
            assignments.add(psa);
        }else{
            System.debug('Permission not found'+permissionSetName);
        }
        }
        }}
            Catch(Exception e){
         
        System.Debug('^^^^^^^^^^ Error^^^^^'+e.getMessage());
        System.Debug('^^^^^^^^^^ Error^^^^^'+e.getLinenumber());
     
        }
         System.debug('assignments ' + assignments);
         
        if (!assignments.isEmpty()) {
        
        //Insert Results and Handle Errors
        List<String> failedRecords = new List<String>();
                Database.SaveResult[] srList = Database.insert(assignments, false); 
                system.debug('after DB result');
                for (Database.SaveResult sr : srList) {
                    if (sr.isSuccess()) {
                        System.debug('Permission set assignments Successfully Created : ' + sr.getId());
                    } else {
                        for(Database.Error err : sr.getErrors()) {
                            String failedRecord ='Record ID: '+sr.getId() +',Error: '+err.getMessage();
                            failedRecords.add(failedRecord);
                            System.debug('The following error has occurred.');
                            System.debug(err.getStatusCode() + ': ' + err.getMessage());
                            System.debug('User fields that affected this error: ' + err.getFields());
                        }
                    }
                }
            string emailtable = '';
                 Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                String allEmail = System.Label.Email_FailedRecords;
                List<String> toAddressList = allEmail.Split(',');
                   if (!failedRecords.isEmpty()) {
                 String tableContent = '<p>Hi</p><p>The Permission Set assignemnt for the below records failed.<br/><br/></p><table style ="border-collapse:collapse; border: 1px solid black;"><tr><th style ="border: 1px solid black;padding:4px;">Record ID</th> <th style ="border: 1px solid black;padding:4px;">Error Message</th></tr>';
                for (String failedRecord : failedRecords) {
                    List<String> recordDetails = failedRecord.split(',');
                    tableContent += '<tr><td style ="border: 1px solid black; padding: 8px;">' + recordDetails[0].substring(recordDetails[0].indexOf(':') + 2) + '</td><td style ="border: 1px solid black; padding: 8px;">' + recordDetails[1].substring(recordDetails[1].indexOf(':') + 2) + '</td></tr>';
                }
                tableContent += '</table>';
                for(String toAddress :toAddressList)
                {
                String[] toAddresses = new String[]{toAddress}; // Add recipient email address
                email.setToAddresses(toAddresses);
                email.setSubject('Permission Set Assignment for Sales Users - Failed Records Report');
                email.setHtmlBody(tableContent);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
                
               }
            }
        }
        }
    
    }   
        

    
    public void Med_PermsetAssgn()
    {
        System.Debug('^^^^^^^^^^Medical^^^^^');
     Set<String> Med_Profiles = new Set<String>();
        String CustomeLabelValuesMed_Profile = System.Label.MRK_Med_Profiles;
        List<String> Splitted_MEd_profiles =CustomeLabelValuesMed_Profile.Split(',');
       Med_Profiles.addAll(Splitted_MEd_profiles);
        System.debug('Medical_Profile'+Med_Profiles);
        
    Set<String> Med_PermissionSets = new Set<String>();
        String MedPermissionSet = System.Label.MRK_Med_PermissionSets; //custom label
        List<String> Splitted_Med_permSet =MedPermissionSet.Split(',');
       Med_PermissionSets.addAll(Splitted_Med_permSet);
        System.debug('Medical_Permissions'+Med_PermissionSets);
        
        
    List<User> usersToAssignPermissionSets = new List<User>();
    List<User> AllUserwithMedProfile = new List<User>();
	List<PermissionSet> PermSetListInfo = new List<PermissionSet>();
Map<String,PermissionSet> PermissionSetMap = new Map<String,PermissionSet>();

		Map<Id,Set<String>> UserPermissionsetMap = new  Map<Id,Set<String>>();
        Map<Id,Set<String>> missingPermissionSetsMap = new  Map<Id,Set<String>>();
        Set<String> missingPermissionSets = new Set<String>();
        Set<String> missingPermissionSetstoadd = new Set<String>();
        
        for(PermissionSetAssignment userPsa : [SELECT AssigneeId, Assignee.Profile_Name_vod__c, PermissionSet.Name FROM PermissionSetAssignment WHERE Assignee.IsActive =true and Assignee.Profile_Name_vod__c IN:Med_Profiles])
        {
            if (!UserPermissionsetMap.containsKey(userPsa.AssigneeId)) {
        UserPermissionsetMap.put(userPsa.AssigneeId, new Set<String>());
        }
            UserPermissionsetMap.get(userPsa.AssigneeId).add(userPsa.PermissionSet.Name);
        }
         System.debug('UserPermissionsetMap ' + UserPermissionsetMap);
      //  AllUserwithSalesProfile = [SELECT Id,Name,Profile_Name_vod__c, IsActive from User where IsActive =true and Profile_Name_vod__c IN:Sales_Profile];
   	//	System.debug('User ' + AllUserwithSalesProfile);
         
       for(Id userId : UserPermissionsetMap.keySet()) 
        {
            Set<String> UserPermissionsSet = UserPermissionsetMap.get(userId);
            missingPermissionSets = Med_PermissionSets.clone();
        	missingPermissionSets.removeAll(UserPermissionsSet);
            missingPermissionSetsMap.put(userId,missingPermissionSets);
        }
        
        System.debug('missingPermissionSets ' + missingPermissionSets);
          System.debug('missingPermissionSetsMap-----> ' + missingPermissionSetsMap);
      
     PermSetListInfo = [SELECT Id,Name FROM PermissionSet WHERE Name IN:missingPermissionSets];
            for(PermissionSet ps :PermSetListInfo){
                System.debug('ps Name ' + ps.Name);
                System.debug('ps ' + ps);
            	PermissionSetMap.put(ps.Name,ps);
             }
            System.debug('PermissionSetMap ' + PermissionSetMap);
   // System.debug('usersToAssignPermissionSets ' + usersToAssignPermissionSets);
        if (!missingPermissionSetsMap.isEmpty()) {
        List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
            try{
        for (Id user : missingPermissionSetsMap.keySet()) {
           missingPermissionSetstoadd = missingPermissionSetsMap.get(user);
        for (String permissionSetName : missingPermissionSetstoadd) {
            PermissionSet permset = PermissionSetMap.get(permissionSetName);
            System.debug('permset ' + permset);
            if(permset!=null){
        PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = user, PermissionSetId = permset.Id);
            System.debug('PSA*** ' + psa);
            assignments.add(psa);
        }else{
            System.debug('Permission not found'+permissionSetName);
        }
        }
        }}
            Catch(Exception e){
         
        System.Debug('^^^^^^^^^^ Error^^^^^'+e.getMessage());
        System.Debug('^^^^^^^^^^ Error^^^^^'+e.getLinenumber());
     
        }
         
        if (!assignments.isEmpty()) {
        
        //Insert Results and Handle Errors
        List<String> failedRecords = new List<String>();
                Database.SaveResult[] srList = Database.insert(assignments, false); 
                system.debug('after DB result');
                for (Database.SaveResult sr : srList) {
                    if (sr.isSuccess()) {
                        System.debug('Permission set assignments Successfully Created : ' + sr.getId());
                    } else {
                        for(Database.Error err : sr.getErrors()) {
                            String failedRecord ='Record ID: '+sr.getId() +',Error: '+err.getMessage();
                            failedRecords.add(failedRecord);
                            System.debug('The following error has occurred.');
                            System.debug(err.getStatusCode() + ': ' + err.getMessage());
                            System.debug('User fields that affected this error: ' + err.getFields());
                        }
                    }
                }
            string emailtable = '';
                 Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                String allEmail = System.Label.Email_FailedRecords;
                List<String> toAddressList = allEmail.Split(',');
                   if (!failedRecords.isEmpty()) {
                 String tableContent = '<p>Hi</p><p>The Permission Set assignemnt for the below records failed.<br/><br/></p><table style ="border-collapse:collapse; border: 1px solid black;"><tr><th style ="border: 1px solid black;padding:4px;">Record ID</th> <th style ="border: 1px solid black;padding:4px;">Error Message</th></tr>';
                for (String failedRecord : failedRecords) {
                    List<String> recordDetails = failedRecord.split(',');
                    tableContent += '<tr><td style ="border: 1px solid black; padding: 8px;">' + recordDetails[0].substring(recordDetails[0].indexOf(':') + 2) + '</td><td style ="border: 1px solid black; padding: 8px;">' + recordDetails[1].substring(recordDetails[1].indexOf(':') + 2) + '</td></tr>';
                }
                tableContent += '</table>';
                for(String toAddress :toAddressList)
                {
                String[] toAddresses = new String[]{toAddress}; // Add recipient email address
                email.setToAddresses(toAddresses);
                email.setSubject('Permission Set Assignment for Medical Users - Failed Records Report');
                email.setHtmlBody(tableContent);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
                
               }
            }
        }
        }
    
    }   
}