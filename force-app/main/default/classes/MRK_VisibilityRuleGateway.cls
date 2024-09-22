/* Copyright, 2016 MERCK & CO, INC., Kevin Brace ALL RIGHTS RESERVED */

/**
 * Class MRK_VisibilityRuleGateway
 *
 * Provides finder methods for accessing data in the Visibility_Rule_MRK__c object.
 */

public class MRK_VisibilityRuleGateway
{
                                            
   public static Map<Id, Visibility_Rule_MRK__c> retrieveGenericVisiblityRuleMapbyVisibilityRuleId(Id visibilityRuleId){
        
        Map<Id, Visibility_Rule_MRK__c> visibilityRuleMap = new Map<Id, Visibility_Rule_MRK__c>(
           [SELECT Visibility_Rule_MRK__c.Name, 
                   Visibility_Rule_MRK__c.Id,
                   (SELECT Sales_Team_MRK__c 
                    FROM   Visibility_Rule_Sales_Teams__r),
                   (SELECT Object_Id__c, RecordTypeId
                    FROM   Visibility_Rule_Records_MRK__r)
            FROM   Visibility_Rule_MRK__c 
            WHERE  Id = : visibilityRuleId]
        );
        
        return visibilityRuleMap;
        
    }
                                                  
                               
    public static Map<Id, Visibility_Rule_MRK__c> retrieveGenericVisiblityRuleMapbyVisibilityRuleIdsList(List<Id> visibilityRuleIdList){
        
        Map<Id, Visibility_Rule_MRK__c> visibilityRuleMap = new Map<Id, Visibility_Rule_MRK__c>(
           [SELECT Visibility_Rule_MRK__c.Name, 
                   Visibility_Rule_MRK__c.Id,
                   (SELECT Sales_Team_MRK__c 
                    FROM   Visibility_Rule_Sales_Teams__r),
                   (SELECT Object_Id__c, RecordTypeId, Object_Name__c//, MSD_CORE_Access_Level__c
                    FROM   Visibility_Rule_Records_MRK__r)
            FROM   Visibility_Rule_MRK__c 
            WHERE  Id in : visibilityRuleIdList]
        );
        
        return visibilityRuleMap;
        
    }
    
                                                 
    public static List<Visibility_Rule_MRK__c> findVisibilityRulesAssociatedtoVRRObjectIds(List<Id> objectIds){
      
        List <Visibility_Rule_MRK__c> visibilityRuleList = new List<Visibility_Rule_MRK__c>();
        List <Visibility_Rule_Record_MRK__c> visibilityRuleRecordList = new List<Visibility_Rule_Record_MRK__c>();
        List <Id> visibilityRuleIdList = new List<Id>();
       
       try{ 
       
        //Get list of all Visibility Rule Records that have that CLM Presentation Assigned to it...
        visibilityRuleRecordList = new List<Visibility_Rule_Record_MRK__c>(
              [SELECT Id,
                      Object_Id__c,
                      Visibility_Rule_MRK__c
               FROM   Visibility_Rule_Record_MRK__c 
               WHERE  Object_Id__c IN : objectIds]);
        
        for (Visibility_Rule_Record_MRK__c vrr : visibilityRuleRecordList){
            visibilityRuleIdList.add(vrr.Visibility_Rule_MRK__c);
        }
       
        
        visibilityRuleList = new List<Visibility_Rule_MRK__c>( 
                  [SELECT Visibility_Rule_MRK__c.Name, 
                          Visibility_Rule_MRK__c.Id,
                          (SELECT Sales_Team_MRK__c 
                           FROM   Visibility_Rule_Sales_Teams__r),
                          (SELECT Object_Id__c,Object_Name__c//,MSD_CORE_Access_Level__c 
                           FROM   Visibility_Rule_Records_MRK__r)
                  FROM   Visibility_Rule_MRK__c 
                  WHERE  Id in : visibilityRuleIdList]);
        
        
        
        }catch(DmlException e){
            System.debug('Error in findVisibilityRuleRecordsAssociatedtoCLMPresentationIds: ' + e.getMessage());
            MRK_VisibilityUtility.createErrorRecord( e.getMessage());     
        }catch(Exception e){
            System.debug('Error in findVisibilityRuleRecordsAssociatedtoCLMPresentationIds: ' + e.getMessage());
            MRK_VisibilityUtility.createErrorRecord( e.getMessage()); 
        
        }
        
        return visibilityRuleList;
    }

    
    
    

    /**
	 * Returns a subset of id's where there are any records in use.
	 *
	 * Arguments:	String - String of propearly single quoted, comma separated salesteams
	 *
	 * Returns:		List<Visibility_Rule_MRK__c> - List of Visibility_Rule_MRK__c Objects
	 */
	
    public static List<Visibility_Rule_MRK__c> findVisibilityRulesAssociatedToSalesTeams(String salesTeamString)
	{
        List<Visibility_Rule_MRK__c> tmp = new List<Visibility_Rule_MRK__c>();
      
        try{ 
		  tmp =  Database.query('select Id, Sales_Team_MRK__c from Visibility_Rule_MRK__c where Sales_Team_MRK__c includes (' + salesTeamString + ')');
	    
        }catch(DmlException e){
            System.debug('Error in findVisibilityRulesAssoicatedToSalesTeams: ' + e.getMessage());
            MRK_VisibilityUtility.createErrorRecord( e.getMessage());     
        }catch(Exception e){
            System.debug('Error in findVisibilityRulesAssoicatedToSalesTeams: ' + e.getMessage());
            MRK_VisibilityUtility.createErrorRecord( e.getMessage()); 
        
        }
        
        return tmp;
        
    }
 
}