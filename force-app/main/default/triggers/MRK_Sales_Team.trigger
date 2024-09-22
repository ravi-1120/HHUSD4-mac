/*
 * KRB 3/14/2014 - REL 5.0 Entry point for all Sales Team processing Logic. 
 */

trigger MRK_Sales_Team on Sales_Team_MRK__c (after delete, after insert, after update, before delete, before insert, before update) {
    MRK_TriggerFactory.process(Sales_Team_MRK__c.sObjectType);
}