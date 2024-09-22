///-----------------------------------------------------------------
///   Namespace:      <Class Namespace>
///   Class:          Pw_Event_Team_Members_Manipulation
///   Description:    This class will receive the event team members from Tp and update the same in veeva
///   Author:         Snehal Asare                   
///   Notes:          Conatins methods which will add and delete team members
///   Date: 25-9-2016
///   Revision History:
///-----------------------------------------------------------------
public class Pw_Event_Team_Members_Manipulation {
    
       /// <summary>
       ///     Update veeva team members
       /// </summary>
       /// <param name="eve">
       ///      'event which will get send from TP
       /// </param>             
       /// </param>   
       public static void UpsertTeamMemberInVeevaEvent(PW_Event_Model eve){
            
               set<string> setOfTeamMembers = new set<string>(); 
            
               setOfTeamMembers = AddTeamMembersToVeevaEvent(eve.ListOfEventTeamMember ,eve.Id,eve.Owner_Emp_number,setOfTeamMembers);
              
               DeleteTeamMembersToVeevaEvent(eve.Id,setOfTeamMembers);                                            
        }
       
        /// <summary>
        ///     Add veeva team members
        /// </summary>
        /// <param name="teamMembersOfTp">
        ///     'teamMembersOfTp' contains team members employee number which will get send from TP
        /// </param> 
        // <param name="setOfTeamMembers">
        ///     'setOfTeamMembers' contains team member id
        /// </param>
       /* static set<string> AddTeamMembersToVeevaEvent(list<PW_Event_Team_Member_Model> teamMembersOfTp, id eventId,string ownerEmployeeNumber,set<string> setOfTeamMembers){ 
                                      
                for(PW_Event_Team_Member_Model member :teamMembersOfTp)
                 {      
                        setOfTeamMembers.add(member.Employee_number);
                        list<user> userExist =[select id, name from user where EmployeeNumber=:member.Employee_number limit 1];
                        if(userExist.size()>0){ 
                          
                            list<EM_Event_Team_Member_vod__c> VeevaMemberList =[select id,Role_vod__c from EM_Event_Team_Member_vod__c
                                                                          where Team_Member_vod__c=:userExist[0].id and Event_vod__c =: eventId limit 1];
                            //check whether the team member exists already or not
                            if(VeevaMemberList.size()==0){
                                EM_Event_Team_Member_vod__c eveTeamMember = new EM_Event_Team_Member_vod__c(); 
                                eveTeamMember.Event_vod__c=eventId;
                                eveTeamMember.Team_Member_vod__c = userExist[0].id;
                                //setting role for new team memeber which comes from TP
                                //eveTeamMember.Role_vod__c=SetRoles(member.Employee_number,ownerEmployeeNumber); 
                                eveTeamMember.Role_vod__c=member.Role;                                                                                                                             
                                // eveTeamMember.Team_Member_vod__r.userName= member.User_Name;                         
                                insert eveTeamMember;
                           }else{
                                EM_Event_Team_Member_vod__c existEveTeamMember = VeevaMemberList[0];
                               //Updating role for existing team memeber 
                               //existEveTeamMember.Role_vod__c=SetRoles(member.Employee_number,ownerEmployeeNumber);        
                                existEveTeamMember.Role_vod__c=member.Role;                                                                                                                                                                                      
                                update existEveTeamMember;                                                              
                           }
                        }
                    
                      System.debug('inserted successfully Team Member');                          
                 }  
             return setOfTeamMembers;
         } */
     static set<string> AddTeamMembersToVeevaEvent(list<PW_Event_Team_Member_Model> teamMembersOfTp, id eventId,string ownerEmployeeNumber,set<string> setOfTeamMembers)
     { 
            Map<String, Id> mapofEmpNoNUserID = new Map<String, Id>();
            Map<Id, EM_Event_Team_Member_vod__c> mapofUserIDnEventTeamMember = new Map<Id, EM_Event_Team_Member_vod__c>();
            List<String> lstEmployeeNumber = new List<string>();
            List<Id> lstUser = new List<Id>();
            List<EM_Event_Team_Member_vod__c> lstEventTeamMemberInsert = new List<EM_Event_Team_Member_vod__c>(); // optimised
            List<EM_Event_Team_Member_vod__c> lstEventTeamMemberUpdate = new List<EM_Event_Team_Member_vod__c>(); // optimised
            
            for(PW_Event_Team_Member_Model member :teamMembersOfTp)
           {                       
                  lstEmployeeNumber.add( member.Employee_number);
           }
             for(User userobj : [select id, name,EmployeeNumber from User where EmployeeNumber IN:lstEmployeeNumber ])
             {
                        mapofEmpNoNUserID.put(userobj.EmployeeNumber, userobj.id);
                        lstUser.add(userobj.id);
            }
            for(EM_Event_Team_Member_vod__c member : [select id,Role_vod__c, Team_Member_vod__c from EM_Event_Team_Member_vod__c
                                                                          where Team_Member_vod__c in :lstUser and Event_vod__c =: eventId ])
             {
                        mapofUserIDnEventTeamMember.put(member.Team_Member_vod__c, member)  ;
                        
                     
            }
             for(PW_Event_Team_Member_Model member :teamMembersOfTp)
                 {      
                        setOfTeamMembers.add(member.Employee_number);
                        //list<user> userExist =[select id, name from user where EmployeeNumber=:member.Employee_number limit 1];
                        //if(userExist.size()>0){ 
                        if(mapofEmpNoNUserID.get(member.Employee_number)!=null){
                          
                            //list<EM_Event_Team_Member_vod__c> VeevaMemberList =[select id,Role_vod__c from EM_Event_Team_Member_vod__c
                             //                                            where Team_Member_vod__c=:userExist[0].id and Event_vod__c =: eventId limit 1];
                             Id userId =mapofEmpNoNUserID.get(member.Employee_number);
                             if(mapofUserIDnEventTeamMember.get(userId)==null)
                             {
                            //check whether the team member exists already or not
                           
                                EM_Event_Team_Member_vod__c eveTeamMember = new EM_Event_Team_Member_vod__c(); 
                                eveTeamMember.Event_vod__c=eventId;
                                eveTeamMember.Team_Member_vod__c = userId;
                                //setting role for new team memeber which comes from TP
                                //eveTeamMember.Role_vod__c=SetRoles(member.Employee_number,ownerEmployeeNumber); 
                                eveTeamMember.Role_vod__c=member.Role;                                                                                                                             
                                // eveTeamMember.Team_Member_vod__r.userName= member.User_Name;  
                                lstEventTeamMemberInsert.add(eveTeamMember);    // optimised                            
                                //insert eveTeamMember;                         // optimised
                           }else{
                                //EM_Event_Team_Member_vod__c existEveTeamMember = VeevaMemberList[0];
                               //Updating role for existing team memeber 
                               //existEveTeamMember.Role_vod__c=SetRoles(member.Employee_number,ownerEmployeeNumber);  
                                EM_Event_Team_Member_vod__c existEveTeamMember = mapofUserIDnEventTeamMember.get(userId);                              
                                existEveTeamMember.Role_vod__c=member.Role;                                                                                      lstEventTeamMemberUpdate.add(existEveTeamMember);  // optimised
                                //update existEveTeamMember;                       // optimised                                         
                           }
                        }
                    
                      System.debug('inserted successfully Team Member');                          
                 }  
                  if(lstEventTeamMemberInsert!=null && lstEventTeamMemberInsert.size()>0)   // optimised
                        insert lstEventTeamMemberInsert;                                    // optimised    
                        
                if(lstEventTeamMemberUpdate!=null && lstEventTeamMemberUpdate.size()>0)     // optimised 
                        update lstEventTeamMemberUpdate;                                    // optimised    
                 
 return setOfTeamMembers;
 } //End Function
    
        /// <summary>
        ///     Delete extra veeva team members
        /// </summary>
        /// <param name="eventId">
        ///     'eventId' contains event id
        /// </param> 
        /// <param name="setOfTeamMembers">
        ///     'setOfTeamMembers' contains team members employee number
        /// </param>  
        static void DeleteTeamMembersToVeevaEvent(id eventId,set<string> setOfTeamMembers){ 
           
                 list<EM_Event_Team_Member_vod__c> AllVeevaTeamMemberList =[select id ,Team_Member_vod__c,Team_Member_vod__r.EmployeeNumber from EM_Event_Team_Member_vod__c
                                                             where Event_vod__c =: eventId and (Role_vod__c like '%Organizer%' or Role_vod__c  like '%Cohost%') ];
           
             List<EM_Event_Team_Member_vod__c> lstEventTeamMemberDelete = new List<EM_Event_Team_Member_vod__c>(); // optimised 
            for(EM_Event_Team_Member_vod__c existedMember :AllVeevaTeamMemberList){
                            
                          if(!setOfTeamMembers.contains(existedMember.Team_Member_vod__r.EmployeeNumber)){
                                       
                              // delete existedMember ;   // optimised
                              lstEventTeamMemberDelete.add(existedMember); // optimised
                              System.debug('delete successfully ');
                           }
                } 
                if(lstEventTeamMemberDelete!=null && lstEventTeamMemberDelete.size()>0)  // optimised
                        delete lstEventTeamMemberDelete;                                 // optimised  
                
         }
    
    
        static string SetRoles(String teamMember,String eventOwner){ 
            string role;
            if(teamMember!= eventOwner){
                role='Cohost';   
              }else{
                 role='Event Owner';
            }
            return role;
        }

}