/*
* MSD_CORE_ManageVeevaCaseTrigger
* Created By:    Kevin Brace
*

* Created Date:  6/30/2017
* Description:   REL 10.0 - This class clears out all Not Applicable values in an AE Case when a User 
*                changes the AE Case Type from a Non Null value to another Non Null Value.
* Change Log:
* Updated Date: 7/7/2021
* Updated By:   Vamshi Bashyakarla
* Description: Commented the oldCaseMap and directly used oldCases map from the trigger 
			   and change the condtion the if condition logic for blank value check on Type.
*/
public without sharing class MSD_CORE_Clear_NotApplicable_AE_Values implements TriggersMVN.HandlerInterface {
    public void execute(Map<Id, Case> newCases, Map<Id, Case> oldCases){
        Service_Cloud_Settings_MVN__c settings = Service_Cloud_Settings_MVN__c.getInstance();
        Set<ID> aECaseIDs = new Set<ID>();
        /*Map<Id, Case> oldCaseMap = new Map<Id, Case>([select  TypeFROM Case WHERE Id in :oldCases.values()]);*/
        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Combo Case').getRecordTypeId();
        
        for(Case newCase : newCases.values())
        {
            if((newCase.MSD_CORE_Event_Case_Type__c == 'PQC Only' || newCase.MSD_CORE_Event_Case_Type__c == 'AE and PQC'))
            {
                aECaseIDs.add(newCase.Id);   
            }
            //Case oldCase = oldCaseMap.get(newCase.Id);
            Case oldCase = oldCases.get(newCase.Id);
            //Only if AE Type Cases...AND
            //the user switched the values of the Type from non null to non null
            
            /*if( 
                newCase.Type != oldCase.Type &&
                newCase.Type != '' &&
                oldCase.Type != '' &&
                ((UtilitiesMVN.matchCaseRecordTypeIdToName(newCase.RecordTypeId, settings.Adverse_Event_Record_Type_MVN__c)) ||
                 newCase.RecordTypeId == recordTypeId)
             )*/
            if( 
                newCase.Type != oldCase.Type && !String.isBlank(newCase.Type) && !String.isBlank(oldCase.Type) &&
                ((UtilitiesMVN.matchCaseRecordTypeIdToName(newCase.RecordTypeId, settings.Adverse_Event_Record_Type_MVN__c)) ||
                 newCase.RecordTypeId == recordTypeId)
            ){ 
                if(newCase.Patient_First_Name_MVN__c == 'Not Applicable'){
                    newCase.Patient_First_Name_MVN__c = '';
                }
                if(newCase.MSD_CORE_AE_Patient_Height__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Patient_Height__c = '';
                } 
                if(newCase.Patient_Last_Name_MVN__c == 'Not Applicable'){
                    newCase.Patient_Last_Name_MVN__c = '';
                } 
                if(newCase.MSD_CORE_AE_Patient_Weight__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Patient_Weight__c = '';
                }                   
                if(newCase.MSD_CORE_AE_Patient_Date_of_Birth__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Patient_Date_of_Birth__c = '';
                }                   
                if(newCase.MSD_CORE_AE_Is_Patient_Pregnant__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Is_Patient_Pregnant__c = '';
                }                   
                if(newCase.MSD_CORE_AE_Patient_Age__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Patient_Age__c = '';
                }                   
                if(newCase.MSD_CORE_AE_Pregnancy_Gestation_or_LMP__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Pregnancy_Gestation_or_LMP__c = '';
                }                   
                if(newCase.MSD_CORE_AE_Patient_Gender__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Patient_Gender__c = '';
                }  
                if(newCase.MSD_CORE_AE_Sought_Medical_Attention__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Sought_Medical_Attention__c = '';
                } 
                if(newCase.MSD_CORE_PSP_Program_Name__c == 'Not Applicable'){
                    newCase.MSD_CORE_PSP_Program_Name__c = '';
                }
                if(newCase.MSD_CORE_PSP_Number__c == 'Not Applicable'){
                    newCase.MSD_CORE_PSP_Number__c = '';
                }                   
                if(newCase.MSD_CORE_PSP_Program_Name_Other__c == 'Not Applicable'){
                    newCase.MSD_CORE_PSP_Program_Name_Other__c = '';
                }                   
                if(newCase.MSD_CORE_PSP_Number_Other__c == 'Not Applicable'){
                    newCase.MSD_CORE_PSP_Number_Other__c = '';
                }                   
                if(newCase.MSD_CORE_PSP_Company__c == 'Not Applicable'){
                    newCase.MSD_CORE_PSP_Company__c = '';
                } 
                if(newCase.MSD_CORE_PSP_Agent_Name__c == 'Not Applicable'){
                    newCase.MSD_CORE_PSP_Agent_Name__c = '';
                }                   
                if(newCase.MSD_CORE_PSP_Company_Other__c == 'Not Applicable'){
                    newCase.MSD_CORE_PSP_Company_Other__c = '';
                }                   
                if(newCase.MSD_CORE_AE_Description__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Description__c = '';
                }                   
                if(newCase.MSD_CORE_AE_Route_of_Administration__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Route_of_Administration__c = '';
                }  
                if(newCase.MSD_CORE_AE_Therapy_Start_Date__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Therapy_Start_Date__c = '';
                }                   
                if(newCase.MSD_CORE_AE_Was_Therapy_Discontinued__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Was_Therapy_Discontinued__c = '';
                }                   
                if(newCase.MSD_CORE_AE_Therapy_End_Date__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Therapy_End_Date__c = '';
                } 
                //if(newCase.AE_Start_Date_MVN__c == 'Not Applicable'){
                //  newCase.AE_Start_Date_MVN__c = '';
                //}                   
                if(newCase.MSD_CORE_AE_Recovery_Date__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Recovery_Date__c = '';
                }                   
                if(newCase.MSD_CORE_AE_Hospitalization_or_Prolonged__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Hospitalization_or_Prolonged__c = '';
                }    
                if(newCase.MSD_CORE_AE_Indication__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Indication__c = '';
                }                   
                if(newCase.MSD_CORE_AE_Life_Threatening__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Life_Threatening__c = '';
                }                   
                if(newCase.MSD_CORE_AE_Was_Treatment_Given_for_AE__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Was_Treatment_Given_for_AE__c = '';
                }                   
                if(newCase.MSD_CORE_AE_Sig_Disability_or_Incapacity__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Sig_Disability_or_Incapacity__c = '';
                }
                if(newCase.MSD_CORE_AE_Treatment_Provided__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Treatment_Provided__c = '';
                }
                if(newCase.MSD_CORE_AE_Is_Was_AE_Congenital_Anomaly__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Is_Was_AE_Congenital_Anomaly__c = '';
                }
                if(newCase.MSD_CORE_AE_Concomitant_Medication__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Concomitant_Medication__c = '';
                }
                if(newCase.MSD_CORE_AE_Did_the_Patient_Die__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Did_the_Patient_Die__c = '';
                }
                if(newCase.MSD_CORE_AE_Pertinent_Medical_History__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Pertinent_Medical_History__c = '';
                }
                if(newCase.MSD_CORE_AE_Cause_of_Death__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Cause_of_Death__c = '';
                }
                if(newCase.MSD_CORE_AE_Drug_Reactions_Allergies__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Drug_Reactions_Allergies__c = '';
                }
                if(newCase.MSD_CORE_AE_Date_of_Death__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Date_of_Death__c = '';
                }
                if(newCase.MSD_CORE_AE_Lab_Diagnostics_Studies__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Lab_Diagnostics_Studies__c = '';
                }
                if(newCase.MSD_CORE_AE_Intervention_Prevent_Serious__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Intervention_Prevent_Serious__c = '';
                }
                if(newCase.MSD_CORE_AE_Dechallenge__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Dechallenge__c = '';
                } 
                if(newCase.MSD_CORE_AE_Is_Was_the_AE_Cancer__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Is_Was_the_AE_Cancer__c = '';
                }
                if(newCase.MSD_CORE_AE_Rechallenge__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Rechallenge__c = '';
                }
                if(newCase.MSD_CORE_AE_Patient_Overdose__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Patient_Overdose__c = '';
                } 
                if(newCase.MSD_CORE_AE_Present_Status__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Present_Status__c = '';
                }                   
                if(newCase.MSD_CORE_AE_IRRE_Reported__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_IRRE_Reported__c = '';
                }                   
                if(newCase.MSD_CORE_AE_Implant_Insertion_Date__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Implant_Insertion_Date__c = '';
                }  
                if(newCase.MSD_CORE_AE_IRRE_Onset_Date__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_IRRE_Onset_Date__c = '';
                }                   
                if(newCase.MSD_CORE_AE_Implant_Removal_Date__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Implant_Removal_Date__c = '';
                }  
                if(newCase.MSD_CORE_AE_Insertion_Difficulty__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Insertion_Difficulty__c = '';
                }                   
                if(newCase.MSD_CORE_AE_Insertion_Difficulty_Details__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Insertion_Difficulty_Details__c = '';
                }  
                if(newCase.MSD_CORE_AE_Localization_Problem__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Localization_Problem__c = '';
                }                   
                if(newCase.MSD_CORE_AE_Multiple_Insertion__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Multiple_Insertion__c = '';
                } 
                if(newCase.MSD_CORE_AE_Migration__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Migration__c = '';
                }                   
                if(newCase.MSD_CORE_AE_Multiple_Insertion_Details__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Multiple_Insertion_Details__c = '';
                }                   
                if(newCase.MSD_CORE_AE_Migration_Details__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Migration_Details__c = '';
                }                   
                if(newCase.MSD_CORE_AE_Deep_Insertion__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Deep_Insertion__c = '';
                }                   
                if(newCase.MSD_CORE_AE_Removal_Problem__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Removal_Problem__c = '';
                }                   
                if(newCase.MSD_CORE_AE_Deep_Insertion_Details__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Deep_Insertion_Details__c = '';
                }
                if(newCase.MSD_CORE_AE_Removal_Problem_Details__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Removal_Problem_Details__c = '';
                }
                if(newCase.MSD_CORE_AE_Incorrect_Insertion__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Incorrect_Insertion__c = '';
                }
                if(newCase.MSD_CORE_AE_Procedure_Used_for_Removal__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Procedure_Used_for_Removal__c = '';
                }
                if(newCase.MSD_CORE_AE_Insertion_Location__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Insertion_Location__c = '';
                }                   
                if(newCase.MSD_CORE_AE_Removal_Under_Anesthesia__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Removal_Under_Anesthesia__c = '';
                } 
                if(newCase.MSD_CORE_AE_Implant_Broken_Cut__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Implant_Broken_Cut__c = '';
                }                   
                if(newCase.MSD_CORE_AE_Anesthesia_Removal_Details__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Anesthesia_Removal_Details__c = '';
                }                   
                if(newCase.MSD_CORE_AE_Implant_Bent__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Implant_Bent__c = '';
                } 
                if(newCase.MSD_CORE_AE_Partial_Complete_Expulsion__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Partial_Complete_Expulsion__c = '';
                }                   
                if(newCase.MSD_CORE_AE_Implant_Palpable_At_Any_Time__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Implant_Palpable_At_Any_Time__c = '';
                }  
                if(newCase.MSD_CORE_AE_Expulsion_Details__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Expulsion_Details__c = '';
                } 
                if(newCase.MSD_CORE_AE_Doubt_About_Presence__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Doubt_About_Presence__c = '';
                }   
                if(newCase.MSD_CORE_AE_Significant_Fibrosis__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Significant_Fibrosis__c = '';
                }                   
                if(newCase.MSD_CORE_AE_Doubt_Details__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Doubt_Details__c = '';
                } 
                if(newCase.MSD_CORE_AE_Incision_Enlarged__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Incision_Enlarged__c = '';
                } 
                if(newCase.MSD_CORE_AE_Implant_Located_Ultrasound__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Implant_Located_Ultrasound__c = '';
                } 
                if(newCase.MSD_CORE_AE_Other_IRRE_Details__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Other_IRRE_Details__c = '';
                } 
                if(newCase.MSD_CORE_AE_Implant_Located_by_MRI__c == 'Not Applicable'){
                    newCase.MSD_CORE_AE_Implant_Located_by_MRI__c = '';
                }                   
            }
        }
        
        Set<String> caseSet = new Set<String>();
        if(aECaseIDs.size() > 0)
        {
        for(MSD_CORE_AE_Product__c product : [select id, MSD_CORE_Adverse_Event__c 
                                              from MSD_CORE_AE_Product__c 
                                              where MSD_CORE_Primary_Product__c = true
                                              and MSD_CORE_Adverse_Event__c =: aECaseIDs
                                              and (MSD_CORE_Related_to__c = 'PQC'
                                                   or MSD_CORE_Related_to__c = 'AE and PQC')])
        {
            caseSet.add(product.MSD_CORE_Adverse_Event__c);
        }
        
        for(Case newCase : newCases.values())
        {
            if(!caseSet.contains(newCase.Id))
            {
                newCase.Product_MVN__c = null;
            }
        }
        }
    }
    
    
    public void handle() {
        execute((Map<Id, Case>) trigger.newMap, (Map<Id, Case>) trigger.oldMap);
    }
}