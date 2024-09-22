@isTest
public class RecordTypeIdByRecordTypeNameTest {
    static testMethod void validateTriggerBeforeInsertUpdateIndex() {
        
        String recordTypeName;
        Index_vod__c index;
        
        // Test KOL_Activity_Index_vod
        recordTypeName = 'KOL_Activity_Index_vod';
        index = new Index_vod__c(Record_Type_Name_vod__c = recordTypeName);
        insert index;
        
        index = [SELECT RecordTypeId FROM Index_vod__c WHERE Id = :index.Id];
        
        System.assert(index.RecordTypeId != null);
        System.debug('index.RecordTypeId for ' + recordTypeName + ' is [' + index.RecordTypeId + ']');
        
        // Test KOL_Scientific_Index_vod
        recordTypeName = 'KOL_Scientific_Index_vod';
        index = new Index_vod__c(Record_Type_Name_vod__c = recordTypeName);
        insert index;
        
        index = [SELECT RecordTypeId FROM Index_vod__c WHERE Id = :index.Id];
        
        System.assert(index.RecordTypeId != null);
        System.debug('index.RecordTypeId for ' + recordTypeName + ' is [' + index.RecordTypeId + ']');
    }

    static testMethod void validateTriggerBeforeInsertUpdateCompanyCollaboration() {
        
        String recordTypeName;
        Company_Collaboration_vod__c companyCollaboration;

        // Test KOL_Activity_Index_vod
        recordTypeName = 'KOL_Company_Collaboration_vod';
        companyCollaboration = new Company_Collaboration_vod__c(Record_Type_Name_vod__c = recordTypeName);
        insert companyCollaboration;
        
        companyCollaboration = [SELECT RecordTypeId FROM Company_Collaboration_vod__c WHERE Id = :companyCollaboration.Id];
        
        System.assert(companyCollaboration.RecordTypeId != null);
        System.debug('companyCollaboration.RecordTypeId for ' + recordTypeName + ' is [' + companyCollaboration.RecordTypeId + ']');
    }

    static testMethod void validateTriggerBeforeInsertUpdateFocusArea() {
        
        String recordTypeName;
        Focus_Area_vod__c focusArea;

        // Test KOL_Focus_Area_vod
        recordTypeName = 'KOL_Focus_Area_vod';
        focusArea = new Focus_Area_vod__c(Record_Type_Name_vod__c = recordTypeName);
        insert focusArea;
        
        focusArea = [SELECT RecordTypeId FROM Focus_Area_vod__c WHERE Id = :focusArea.Id];
        
        System.assert(focusArea.RecordTypeId != null);
        System.debug('focusArea.RecordTypeId for ' + recordTypeName + ' is [' + focusArea.RecordTypeId + ']');
    }

    static testMethod void validateTriggerBeforeInsertUpdatePosition() {

        String recordTypeName;
        Position_vod__c position;

        // Test KOL_Position_vod
        recordTypeName = 'KOL_Position_vod';
        position = new Position_vod__c(Record_Type_Name_vod__c = recordTypeName);
        insert position;
        
        position = [SELECT RecordTypeId FROM Position_vod__c WHERE Id = :position.Id];
        
        System.assert(position.RecordTypeId != null);
        System.debug('position.RecordTypeId for ' + recordTypeName + ' is [' + position.RecordTypeId + ']');
    }
}