/**
 * MRK_Account_Before
 * When an Account is updated with “Request Alignment Removal” checked, 
 * a UAR record is created to request removal from the territory.
 * The checkbox and comments on account are also set to null.
 * If a pending UAR already exists, a new one is not created.
 * KRB 2/5/2020 - Updated to support TM2.0
 * 
 *
 * @version        1.0 
 * @author         Jeff Kelso, Veeva Technical Services
 *
 * @update          1/7/2014 - jkelso - Check for temporary alignments and prevent creating a UAR
 */

trigger MRK_Account_Before on Account (before update) { 
    List<Account> removeAlignmentsAccts = new List<Account>();
    List<Id> acctIds = new List<Id>();
    //Get any Account IDs where alignment removal is requested
    for (Account a : trigger.new) {
        if (a.Request_Alignment_Removal_MRK__c) {
            removeAlignmentsAccts.add(a);
            acctIds.add(a.Id);
        }   
    }
    
    if (!removeAlignmentsAccts.IsEmpty()) {
        system.debug(Logginglevel.INFO,'jk - remove alignment count :' + removeAlignmentsAccts.size() + ' ' + removeAlignmentsAccts);
        //Get user's territory
        String userTerritoryName = '';
        List<Territory2> territory = [SELECT Name 
                                      FROM Territory2 
                                      WHERE Territory2Model.state = 'Active'
                                      AND ID IN (SELECT Territory2Id 
                                                 FROM UserTerritory2Association 
                                                 WHERE UserId = :UserInfo.getUserId() 
                                                 AND IsActive = true
                                                 AND Territory2.Territory2Model.state = 'Active')
                                     LIMIT 1];
        
        for(Territory2 t : territory){
           System.debug('KRB TM2.0 2/5/2020: ' + t.Name);
        }
              
        Boolean nullTerritory = false;
        if (!territory.isEmpty()) {
            userTerritoryName = territory.get(0).Name;
        } else {
            nullTerritory = true;
        }                                                                                                   
        
        //Get record type ID for UAR
        RecordType rt = [SELECT ID, Name, DeveloperName 
                         FROM RecordType 
                         WHERE SObjectType = 'Update_Account_Request_MRK__c' AND 
                               DeveloperName = 'MRK_UAR_AR' LIMIT 1];
        system.debug(Logginglevel.INFO,'jk - UAR RecordTypeId :' + rt);                    
        
        //check for any existing UARs
        List<Update_Account_Request_MRK__c> existingUars = new List<Update_Account_Request_MRK__c>();
        existingUars = [SELECT Account_MRK__c, Alignment_Territory_Name_MRK__c
                        FROM Update_Account_Request_MRK__c
                        WHERE Account_MRK__c IN :acctIds AND
                              Alignment_Territory_Name_MRK__c = :userTerritoryName AND
                              Change_Type_MRK__c = 'Remove from territory' AND
                              Approval_Status_MRK__c = 'Pending'];
                              
        //check for temporary alignments
        List<Update_Account_Request_MRK__c> tempUars = new List<Update_Account_Request_MRK__c>();
        tempUars = [SELECT Account_MRK__c,Alignment_End_Date_MRK__c,Alignment_Request_Type_MRK__c,
                            Approval_Status_MRK__c,Change_Type_MRK__c, Alignment_Territory_Name_MRK__c 
                    FROM Update_Account_Request_MRK__c
                    WHERE Account_MRK__c IN :acctIds AND
                          Alignment_Territory_Name_MRK__c = :userTerritoryName AND
                          Change_Type_MRK__c = 'Alignment Request' AND
                          Alignment_Request_Type_MRK__c IN ('One Day','Temporary') AND
                          Approval_Status_MRK__c IN ('Pending','Approved','Auto-Approved') AND
                          Alignment_End_Date_MRK__c >= TODAY];
                          
        //check permanent requests
        List<Update_Account_Request_MRK__c> pendingRequests = new List<Update_Account_Request_MRK__c>();
        pendingRequests = [SELECT Account_MRK__c,Alignment_End_Date_MRK__c,Alignment_Request_Type_MRK__c,
                            Approval_Status_MRK__c,Change_Type_MRK__c, Alignment_Territory_Name_MRK__c 
                           FROM Update_Account_Request_MRK__c
                           WHERE Account_MRK__c IN :acctIds AND
                                 Alignment_Territory_Name_MRK__c = :userTerritoryName AND
                                 Change_Type_MRK__c = 'Alignment Request' AND
                                 Alignment_Request_Type_MRK__c IN ('Permanent') AND
                                 Approval_Status_MRK__c IN ('Pending') AND
                                 Alignment_End_Date_MRK__c >= TODAY];
        
        List<Update_Account_Request_MRK__c> uars = new List<Update_Account_Request_MRK__c>();
        Update_Account_Request_MRK__c uar;
        
        //get TSFs
        List<TSF_vod__c> tsfs = new List<TSF_vod__c>();
        tsfs = [SELECT Account_vod__c,Alignment_End_Date_MRK__c,Alignment_Start_Date_MRK__c,Alignment_Type_MRK__c,External_Id_vod__c,
                       Name,ODA_MRK__c,RecordTypeId,Sales_Team_MRK__c,Territory_vod__c,UAR_ID_MRK__c,Call_Deck_Status_MRK__c  
                FROM TSF_vod__c
                WHERE Account_vod__c IN :acctIds];
                       
                       
                       
        
        //Create new UAR
        for (Account a : removeAlignmentsAccts) {
            if (nullTerritory) {
                a.addError('Current user must be assigned to a territory');
                continue;
            } 
            
            Boolean foundDuplicateUar = false;
            Boolean foundTempUar = false;
            
            //check for existing UARs
            if (!existingUars.IsEmpty()) {
                for (Update_Account_Request_MRK__c euar : existingUars) {
                    if (euar.Account_MRK__c == a.Id && euar.Alignment_Territory_Name_MRK__c == userTerritoryName) {
                        system.debug(Logginglevel.INFO,'jk - found duplicate UAR for :' + a);
                        foundDuplicateUar = true;
                        a.addError('A removal request already exists for this account');
                    }
                }
            }
            
            //check for temporary alignment
            if (!tempUars.IsEmpty()) {
                for (Update_Account_Request_MRK__c tuar : tempUars) {
                    if (tuar.Account_MRK__c == a.Id && tuar.Alignment_Territory_Name_MRK__c == userTerritoryName) {
                        system.debug(Logginglevel.INFO,'jk - found temporary aligned UAR for: ' + a);
                        foundTempUar = true;
                        a.addError('Temporary or One Day alignments cannot be removed');
                    }
                }
            }
            
            //check for pending permanent requets
            if (!pendingRequests.IsEmpty()) {
                for (Update_Account_Request_MRK__c tuar : pendingRequests) {
                    if (tuar.Account_MRK__c == a.Id && tuar.Alignment_Territory_Name_MRK__c == userTerritoryName) {
                        system.debug(Logginglevel.INFO,'jk - found permanent request that is pending for: ' + a);
                        foundTempUar = true;
                        a.addError('You can not request a removal while an open permanent request is still pending');
                    }
                
                }
            }
            
            if (!foundDuplicateUar && !foundTempUar) {
            
                //get start and end date from TSF
                Date startDate;
                Date endDate;
         
                for (TSF_vod__c tsf : tsfs) {
                    if (tsf.Account_vod__c == a.Id && tsf.Territory_vod__c == userTerritoryName) {
                        if (tsf.Call_Deck_Status_MRK__c == 'Temporary' || tsf.Call_Deck_Status_MRK__c == 'One Day') {
                            a.addError('Temporary or One Day alignments cannot be removed');
                            return;
                        }
                        startDate = tsf.Alignment_Start_Date_MRK__c;
                        endDate = tsf.Alignment_End_Date_MRK__c;
                    }
                }            
            
            
                uar = new Update_Account_Request_MRK__c();
                uar.Account_MRK__c = a.Id;
                uar.Change_Type_MRK__c = 'Remove from territory';
                uar.Approval_Status_MRK__c = 'Pending';
                system.debug(Logginglevel.INFO,'jk - Requestors_Reasons_Notes_MRK__c :' + a.Requestors_Reasons_Notes_MRK__c);
                uar.Requestors_Reasons_Notes_MRK__c = a.Requestors_Reasons_Notes_MRK__c;
                uar.RecordTypeId = rt.Id;
                uar.Alignment_Territory_Name_MRK__c = userTerritoryName;
                uar.Requestor_MRK__c = UserInfo.getUserId();
                uar.Alignment_Request_Type_MRK__c = 'Permanent';
                if (startDate != null) {
                    uar.Alignment_Start_Date_MRK__c = startDate;
                }
                if (endDate != null) {
                    uar.Alignment_End_Date_MRK__c = endDate;
                }
                
                uars.add(uar);              
            }
            
            //set Account fields for requests back to null
            a.Requestors_Reasons_Notes_MRK__c = '';
            a.Request_Alignment_Removal_MRK__c = false;
            //a.addError('Jeff - just testing');
        }
        system.debug(Logginglevel.INFO,'jk - UARs to insert count :' + uars.size() + ' ' + uars);
        insert uars;
    }
}