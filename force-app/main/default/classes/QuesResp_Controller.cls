public  class QuesResp_Controller
{
    public Id SurveyTgtId {get;set;}
    public List<Question_response_vod__c> getQuesResp()
    {
        List<Question_response_vod__c> QuesResp;
        QuesResp = [SELECT Name,Question_Text_vod__c,Answer_Choice_vod__c,MRK_Answer__c,Number_vod__c,Order_vod__c,Date_vod__c,Datetime_vod__c,Text_vod__c FROM Question_response_vod__c WHERE Survey_Target_vod__c =: SurveyTgtId order by Order_vod__c ASC];
        return QuesResp;
    }
}