/* KRB - 3/14/2014 - REL 5.0
 * Class MRK_TriggerFactory
 *
 * Used to instantiate and execute Trigger Handlers associated with sObjects.
 *
 * BMP - 4/14/2015 - global port.  naming standard changes only
 */
public class MSD_CORE_TriggerFactory
{

    /**
     * Public static method to create and execute a trigger handler
     *
     * Arguments:   Schema.sObjectType soType - Object type to process (SObject.sObjectType)
     *
     * Throws a TriggerException if no handler has been coded.
     */
    public static void process(Schema.sObjectType soType)
    {
        // Get a handler appropriate to the object being processed
        MSD_CORE_ITrigger handler = getHandler(soType);

        // Make sure we have a handler registered, new handlers must be registered in the getHandler method.
        if (handler == null)
        {
            throw new MSD_CORE_TriggerException('No Trigger Handler registered for Object Type: ' + soType);
        }

        // Execute the handler to fulfil the trigger
        execute(handler);
    }

    /**
     * private static method to control the execution of the handler
     *
     * Arguments:   ITrigger handler - A Trigger Handler to execute
     */
    private static void execute(MSD_CORE_ITrigger handler)
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
     * Arguments:   Schema.sObjectType soType - Object type tolocate (SObject.sObjectType)
     *
     * Returns:     ITrigger - A trigger handler if one exists or null.
     */
    private static MSD_CORE_ITrigger getHandler(Schema.sObjectType soType)
    {

        if (soType == Attachment.sObjectType)
        {
            return new MSD_CORE_AttachmentHandler();
        }

        if (soType == MSD_CORE_List__c.sObjectType)
        {
            return new MSD_CORE_ListHandler();
        }

        if (soType == MSD_CORE_List_Product__c.sObjectType)
        {
            return new MSD_CORE_ListProductHandler();
        }

        if (soType == MSD_CORE_List_Sales_Team__c.sObjectType)
        {
            return new MSD_CORE_ListSalesTeamHandler();
        }

        if (soType == MSD_CORE_List_Attribute__c.sObjectType)
        {
            return new MSD_CORE_ListAttributeHandler();
        }

        if (soType == MSD_CORE_List_Application__c.sObjectType)
        {
            return new MSD_CORE_ListApplicationHandler();
        }

        if (soType == MSD_CORE_Job_Queue_Group__c.sObjectType)
        {
            return new MSD_CORE_JobQueueGroupHandler();
        }

        /* handlers for US specific objects will be ported over as needed */

       /*
        if (soType == Visibility_Rule_Record_MRK__c.sObjectType)
        {
            return new MRK_VisibilityRuleRecordHandler();
        }

        if (soType == Visibility_Rule_MRK__c.sObjectType)
        {
            return new MRK_VisibilityRuleHandler();
        }

        if (soType == Visibility_Rule_Sales_Team_MRK__c.sObjectType)
        {
            return new MRK_VisibilityRuleSalesTeamHandler();
        }

        if (soType == User_Sales_Team_MRK__c.sObjectType)
        {
            return new MRK_UserSalesTeamHandler();
        }

        if (soType == Sales_Team_MRK__c.sObjectType)
        {
            return new MRK_SalesTeamHandler();
        }

        if (soType == User.sObjectType)
        {
            return new MRK_UserHandler();
        }

        if (soType == Rule_MRK__c.sObjectType)
        {
            return new MRK_RuleHandler();
        }

        if (soType == Account_Plan_vod__c.sObjectType)
        {
            return new MRK_AccountPlanHandler();
        }

        if (soType == Goal_Opportunity_MRK__c.sObjectType)
        {
            return new MRK_GoalOpportunityHandler();
        }

        if (soType == Objective_MRK__c.sObjectType)
        {
            return new MRK_ObjectiveHandler();
        }

        if (soType == Territory.sObjectType)
        {
            return new MRK_TerritoryHandler();
        }

        if (soType == Communication_Target_MRK__c.sObjectType)
        {
            return new MRK_CommunicationTargetHandler();
        }

        if (soType == Communication_Event_Target_MRK__c.sObjectType)
        {
            return new MRK_CommunicationEventTargetHandler();
        }
        
        if(soType == ContentVersion.sObjectType){
            return new MSD_CORE_HEQ_CVTriggerHandler();
        }
        */

        if(soType == MSD_CORE_HEQ_Template_File_Metadata__c.sObjectType)
        {
            return new MSD_CORE_HEQ_TemplateFileMDTHandler();
        }

        return null;
    }
}