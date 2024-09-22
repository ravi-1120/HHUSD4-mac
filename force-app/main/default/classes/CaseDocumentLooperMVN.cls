/*
* CaseDocumentLooperMVN
* Created By: Kai Amundsen
* Created Date: May 14, 2014
* Description: This class is a helper class for Drawloop to be able to inlcude Veeva Vault documents in the merge
*     *** NOTE:  Only works for Vault.  Case_Document_MVN__c records refering to Knowledge caseDocuments will cause an error ********
*
*     *** NOTE: Currently not used for the Merck implementation. ***
*/

public with sharing class CaseDocumentLooperMVN implements Loop.AdHoc.IAttachmentManager
{

    public List<Loop.AdHoc.Attachment> getAttachments(Id ddpId, Id eid, Set<Id> topLevelIds, Set<Id> parentIds)
    {
        List<Loop.AdHoc.Attachment> vaultAttachments = new List<Loop.AdHoc.Attachment>();

        if (topLevelIds == null)
        {
            topLevelIds = new Set<Id>();
        }

        if (parentIds != null)
        {
            topLevelids.addAll(parentIds);
        }

        for (Case_Document_MVN__c caseDocument : [select Id, Document_ID_MVN__c, Document_Type_MVN__c, Case_MVN__c,
                                                    Document_Title_MVN__c, Document_File_Extension_MVN__c,
                                                    Document_Major_Version_MVN__c, Document_Minor_Version_MVN__c
                                                    from Case_Document_MVN__c
                                                    where Case_MVN__c in :topLevelids])
        {
            String vaultLink = VaultSearchUtilityMVN.buildDownloadURL(caseDocument);
            vaultAttachments.add( new Loop.AdHoc.VeevaVaultAttachment(
                                                        caseDocument.Id,
                                                        caseDocument.Case_MVN__c,
                                                        caseDocument.Document_ID_MVN__c,
                                                        caseDocument.Document_Title_MVN__c,
                                                        caseDocument.Document_File_Extension_MVN__c,
                                                        caseDocument.Document_Type_MVN__c,
                                                        caseDocument.Document_Title_MVN__c,
                                                        vaultLink
                                                    )
                                     );
        }

        return vaultAttachments;
    }
}