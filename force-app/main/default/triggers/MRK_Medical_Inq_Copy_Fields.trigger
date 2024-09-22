trigger MRK_Medical_Inq_Copy_Fields on Medical_Inquiry_vod__c (Before Insert, Before Update) {
//3/4/2013 bjd When a PIR is inserted or updated, perform the following logic
//             - for standard request, copy the PIR concept name & product onto the request in "common" fields
//             - for custom request, copy the selected product and free form inquiry into the "common" fields
//If the PIR has been submitted, change the record type (an alternate Page Layout will be used that displays the text fields RO)
//             - change the record type to Submitted_Request 
//

String flag = 'N';
String Medical= 'Medical';
Profile ProfileName = [select Name from profile where id = :userinfo.getProfileId()];
if(ProfileName.Name.contains(Medical)){
flag = 'Y';
}



for (Integer i = 0; i < Trigger.new.size(); i++) {
       Medical_Inquiry_vod__c newPIR = Trigger.new[i];
        //Please note that PIR_Concept_Product__C is the field referenced by integration.  It is referenced here for consistency. 
        newPIR.PIR_Product_MRK__c = newPIR.PIR_Concept_Product_MRK__c;
        RecordType RT = [Select r.DeveloperName from RecordType r where r.Id = :newPIR.RecordTypeId limit 1];
        string currRecType = RT.DeveloperName;
        if (currRecType == 'Uncoded_Request_MRK') {
            newPIR.PIR_Text_MRK__c = newPIR.Inquiry_Text__c;
            }
        else {
            newPIR.PIR_Text_MRK__c = newPIR.PIR_Concept_Name_MRK__c;
        }
        If (newPIR.Status_vod__c == 'Submitted_vod' && flag == 'N') {
            string modRecType = 'Submitted_Request_MRK';
            RecordType NT = [Select n.Id from RecordType n where n.DeveloperName = :modRecType 
                                                        and sObjectType='Medical_Inquiry_vod__c' 
                                                        and isActive=true LIMIT 1];
            newPIR.RecordTypeId = NT.Id;
            }
}
}