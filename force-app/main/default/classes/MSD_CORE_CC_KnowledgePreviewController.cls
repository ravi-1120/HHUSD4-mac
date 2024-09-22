public class MSD_CORE_CC_KnowledgePreviewController {    
    @AuraEnabled
    public static KnowledgeReviewWrapper getKnowledge(String kavId)    
    { 
        List<Knowledge__kav> lstKav = [SELECT Title, 
                                       UrlName,
                                       MSD_CORE_Approvals_Required__c,
                                       MSD_CORE_Product_ID__c,
                                       MSD_CORE_Audience__c,
                                       MSD_CORE_DemoReqd__c,
                                       MSD_CORE_Urgent__c,
                                       MSD_CORE_ExpiryDate__c,
                                       MSD_CORE_General_Cmnt__c,
                                       MSD_CORE_General_Cmnt_Conversation__c,
                                       MSD_CORE_Preview__c,
                                       MSD_CORE_Preview_Cmnt__c,
                                       MSD_CORE_Preview_Cmnt_Conversation__c,
                                       MSD_CORE_InstrBckgnd__c,
                                       MSD_CORE_Instruction_Comment__c,
                                       MSD_CORE_Instruct_Cmnt_Conversation__c,
                                       MSD_CORE_Inform__c,
                                       MSD_CORE_Information_Cmnt__c,
                                       MSD_CORE_Information_Cmnt_Conversation__c,
                                       MSD_CORE_Questions__c,
                                       MSD_CORE_Questions_Comment__c,
                                       MSD_CORE_Qstn_Cmnt_Convo__c,
                                       MSD_CORE_AftCllWork__c,
                                       MSD_CORE_After_Call_Work_Cmnt__c,
                                       MSD_CORE_AfterCallWork_Cmnt_Conversation__c,
                                       MSD_CORE_KnwlArtCat__c,
                                       toLabel(Language),
                                       MSD_CORE_GenCntry__c,
                                       MSD_CORE_Channels__c,
                                       MSD_CORE_Subtype__c,
                                       MSD_CORE_GenCatgry__c,
                                       MSD_CORE_Case_Type__c,
                                       MSD_CORE_Case_Category__c,
                                       MSD_CORE_GenAssArtcle__c,
                                       MSD_CORE_FormerReviewArticle__c,
                                       PublishStatus,
                                       IsLatestVersion,
                                       VersionNumber,
                                       LastPublishedDate,
                                       LastModifiedDate,
                                       LastModifiedBy.Name,
                                       ArticleNumber,
                                       MSD_CORE_Assigned_To__r.Name,
                                       Owner.Name,
                                       ArticleCreatedBy.Name,
                                       ArticleCreatedDate,
                                       MSD_CORE_Disclaimer__c,
                                       MSD_CORE_Parent_Article__c,
                                       RecordType.DeveloperName
                                      FROM Knowledge__kav WHERE KnowledgeArticleId = :kavId LIMIT 1];        
        KnowledgeReviewWrapper wrap = new KnowledgeReviewWrapper();
        wrap.kav = lstKav[0];
        wrap.profileName =  [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()].Name;
        return wrap;
    }
    
    public class KnowledgeReviewWrapper{
        @AuraEnabled
        public String profileName;
        @AuraEnabled
        public Knowledge__kav kav;
    }
 }