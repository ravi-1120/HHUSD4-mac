public class MSD_CORE_VE_Trigger_Factory {
/* Copyright, 2016 MERCK & CO, INC., Kevin Brace ALL RIGHTS RESERVED */

    
/* 
 * 
 * KRB - 3/14/2014 - REL 5.0 
 * Class MRK_TriggerFactory
 * 
 * Used to instantiate and execute Trigger Handlers associated with sObjects.
 */

	
	/**
	 * Public static method to create and execute a trigger handler
	 *
	 * Arguments:	Schema.sObjectType soType - Object type to process (SObject.sObjectType)
	 *
	 * Throws a TriggerException if no handler has been coded.
	 */
	public static void process(Schema.sObjectType soType)
	{
		// Get a handler appropriate to the object being processed
		MRK_ITrigger handler = getHandler(soType);
		
		// Make sure we have a handler registered, new handlers must be registered in the getHandler method.
		if (handler == null)
		{
			throw new MRK_TriggerException('No Trigger Handler registered for Object Type: ' + soType);
		}
		
		// Execute the handler to fulfil the trigger
		execute(handler);
	}
	
	/**
	 * private static method to control the execution of the handler
	 *
	 * Arguments:	ITrigger handler - A Trigger Handler to execute
	 */	
	private static void execute(MRK_ITrigger handler)
	{
		// Before Trigger
		if (Trigger.isBefore)
		{
			// Call the bulk before to handle any caching of data and enable bulkification
			handler.bulkBefore();
			
			// Iterate through the records to be deleted passing them to the handler.
			if (Trigger.isDelete)
			{
				for (SObject so : Trigger.old)
				{
					handler.beforeDelete(so);
				}
			}
			// Iterate through the records to be inserted passing them to the handler.
			else if (Trigger.isInsert)
			{
				for (SObject so : Trigger.new)
				{
					handler.beforeInsert(so);
				}
			}
			// Iterate through the records to be updated passing them to the handler.
			else if (Trigger.isUpdate)
			{
				for (SObject so : Trigger.old)
				{
					handler.beforeUpdate(so, Trigger.newMap.get(so.Id));
				}
			}
		}
		else
		{
			// Call the bulk after to handle any caching of data and enable bulkification
			handler.bulkAfter();
			
			// Iterate through the records deleted passing them to the handler.
			if (Trigger.isDelete)
			{
				for (SObject so : Trigger.old)
				{
					handler.afterDelete(so);
				}
			}
			// Iterate through the records inserted passing them to the handler.
			else if (Trigger.isInsert)
			{
				for (SObject so : Trigger.new)
				{
					handler.afterInsert(so);
				}
			}
			// Iterate through the records updated passing them to the handler.
			else if (Trigger.isUpdate)
			{
				for (SObject so : Trigger.old)
				{
					handler.afterUpdate(so, Trigger.newMap.get(so.Id));
				}
			}
		}
		
		// Perform any post processing
		handler.andFinally();
	}
	
	/**
	 * private static method to get the appropriate handler for the object type.
	 * Modify this method to add any additional handlers.
	 *
	 * Arguments:	Schema.sObjectType soType - Object type tolocate (SObject.sObjectType)
	 *
	 * Returns:		ITrigger - A trigger handler if one exists or null.
	 */
	private static MRK_ITrigger getHandler(Schema.sObjectType soType)
	{
       
        if (soType == Visibility_Rule_Record_MRK__c.sObjectType)
		{
			return new MRK_VisibilityRuleRecordGenericHandler(); //completed OA
		}

        if (soType == Visibility_Rule_MRK__c.sObjectType)
		{
			return new MRK_VisibilityRuleHandler();
		}

        if (soType == Visibility_Rule_Sales_Team_MRK__c.sObjectType)
		{
			return new MRK_VisibilityRuleSlsTeamGenericHandler(); //completed OA
		}

        //US ONLY METHOD:
        if ((soType == User_Sales_Team_MRK__c.sObjectType))
		{
			return new MRK_UserSalesTeamGenericHandler(); //completed OA
		}

        //GLOBAL METHOD:
        /*
        if ((soType == MSD_CORE_User_Sales_Team__c.sObjectType))
		{
			return new MRK_UserSalesTeamGenericHandler(); //completed OA
		}
        */
		return null;
	}
}