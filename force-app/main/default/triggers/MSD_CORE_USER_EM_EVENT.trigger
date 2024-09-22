/* 
 * Trigger: MSD_CORE_USER_EM_EVENT
 * 
 * Trigger created to handle EM Events Logic on User
 * 
 * Author: Kevin Brace
 * 
 * Change Log: 
 * KRB 6/22/2019 - Initial Version - added Logic to process EmployeeNumber Field Updates needed for PW  
*/
trigger MSD_CORE_USER_EM_EVENT on User (before insert, before update) {

 if (Trigger.isBefore){
       
      if(Trigger.isUpdate){
         
         for(User usr: Trigger.new){

            //If the Alias Changes from one value to another...
            if((!String.isBlank(Trigger.oldMap.get(usr.ID).Alias)) 
               && (!String.isBlank(usr.Alias)) 
               && (Trigger.oldMap.get(usr.ID).Alias != usr.Alias)){
              
               usr.EmployeeNumber = usr.Alias;
            }
            
            //If the Alias was Blank but now has Value... 
            if((String.isBlank(Trigger.oldMap.get(usr.ID).Alias)) && 
               (!String.isBlank(usr.Alias) )){

               usr.EmployeeNumber = usr.Alias;    
            }
         }
      }
    
      if(Trigger.isInsert){
      
         for(User usr: Trigger.new){
            if (!String.isBlank(usr.Alias)){
               usr.EmployeeNumber = usr.Alias;
            }
         }
      }
       
   }

}