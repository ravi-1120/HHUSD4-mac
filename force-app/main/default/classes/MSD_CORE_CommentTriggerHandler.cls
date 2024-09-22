public class MSD_CORE_CommentTriggerHandler {
   public static void UpdateConverstions (List<MSD_CORE_Comments__c> newList)
    {
        For (MSD_CORE_Comments__c k : newList){
            If(k.MSD_CORE_Type__c == 'Generic Comment'){
                MSD_CORE_Comments__c com = [SELECT CreatedBy.Name FROM MSD_CORE_Comments__c WHERE Id = :k.Id ];
                List<Knowledge__kav> KRecordlist  = new List<Knowledge__kav>();
                KRecordlist = [SELECT MSD_CORE_General_Cmnt_Conversation__c FROM Knowledge__kav WHERE Id = :k.MSD_CORE_Knowledge__c];
                for (Knowledge__kav KRecord : KRecordlist ){
                    String createddate = k.CreatedDate.month()+ ' / ' + k.CreatedDate.day() + ' / ' + k.CreatedDate.year();
                    KRecord.MSD_CORE_General_Cmnt_Conversation__c = KRecord.MSD_CORE_General_Cmnt_Conversation__c + '<br/>' + com.CreatedBy.Name +' - '+ k.MSD_CORE_Comment__c +' - '+ createddate ; 
                }
                update KRecordlist;
            }       
            If(k.MSD_CORE_Type__c == 'After Call Work'){
                MSD_CORE_Comments__c com = [SELECT CreatedBy.Name FROM MSD_CORE_Comments__c WHERE Id = :k.Id ];
                List<Knowledge__kav> KRecordlist  = new List<Knowledge__kav>();
                KRecordlist = [SELECT MSD_CORE_AfterCallWork_Cmnt_Conversation__c FROM Knowledge__kav WHERE Id = :k.MSD_CORE_Knowledge__c];
                for (Knowledge__kav KRecord : KRecordlist ){
                    String createddate = k.CreatedDate.month()+ ' / ' + k.CreatedDate.day() + ' / ' + k.CreatedDate.year();
                    KRecord.MSD_CORE_AfterCallWork_Cmnt_Conversation__c = KRecord.MSD_CORE_AfterCallWork_Cmnt_Conversation__c + '<br/>' + com.CreatedBy.Name + ' - ' + k.MSD_CORE_Comment__c + ' - ' + createddate;
                }
                update KRecordlist;
            }
           
            If(k.MSD_CORE_Type__c == 'Inform'){
                MSD_CORE_Comments__c com = [SELECT CreatedBy.Name FROM MSD_CORE_Comments__c WHERE Id = :k.Id ];
                List<Knowledge__kav> KRecordlist  = new List<Knowledge__kav>();
                KRecordlist = [SELECT MSD_CORE_Information_Cmnt_Conversation__c FROM Knowledge__kav WHERE Id = :k.MSD_CORE_Knowledge__c];
                for (Knowledge__kav KRecord : KRecordlist ){
                    String createddate = k.CreatedDate.month()+ ' / ' + k.CreatedDate.day() + ' / ' + k.CreatedDate.year();
                    KRecord.MSD_CORE_Information_Cmnt_Conversation__c = KRecord.MSD_CORE_Information_Cmnt_Conversation__c + '<br/>'+ com.CreatedBy.Name + ' - ' + k.MSD_CORE_Comment__c+' - ' + createddate ;
                }
                update KRecordlist;
            }
            If(k.MSD_CORE_Type__c == 'Preview'){
                MSD_CORE_Comments__c com = [SELECT CreatedBy.Name FROM MSD_CORE_Comments__c WHERE Id = :k.Id ];
                List<Knowledge__kav> KRecordlist  = new List<Knowledge__kav>();
                KRecordlist = [SELECT MSD_CORE_Preview_Cmnt_Conversation__c FROM Knowledge__kav WHERE Id = :k.MSD_CORE_Knowledge__c];
                for (Knowledge__kav KRecord : KRecordlist ){
                    String createddate = k.CreatedDate.month()+ ' / ' + k.CreatedDate.day() + ' / ' + k.CreatedDate.year();
                    KRecord.MSD_CORE_Preview_Cmnt_Conversation__c = KRecord.MSD_CORE_Preview_Cmnt_Conversation__c + '<br/>' +com.CreatedBy.Name + ' - ' + k.MSD_CORE_Comment__c + ' - ' +createddate ;
                }
                update KRecordlist;
            }
            
             If(k.MSD_CORE_Type__c == 'Instruction/Background'){
                MSD_CORE_Comments__c com = [SELECT CreatedBy.Name FROM MSD_CORE_Comments__c WHERE Id = :k.Id ];
                List<Knowledge__kav> KRecordlist  = new List<Knowledge__kav>();
                KRecordlist = [SELECT MSD_CORE_Instruct_Cmnt_Conversation__c FROM Knowledge__kav WHERE Id = :k.MSD_CORE_Knowledge__c];
                for (Knowledge__kav KRecord : KRecordlist ){
                    String createddate = k.CreatedDate.month()+ ' / ' + k.CreatedDate.day() + ' / ' + k.CreatedDate.year();
                    KRecord.MSD_CORE_Instruct_Cmnt_Conversation__c = KRecord.MSD_CORE_Instruct_Cmnt_Conversation__c + '<br/>' + com.CreatedBy.Name + ' - ' + k.MSD_CORE_Comment__c + ' - ' +createddate ;
                }
                update KRecordlist;
            }
             If(k.MSD_CORE_Type__c == 'Questions'){
                MSD_CORE_Comments__c com = [SELECT CreatedBy.Name FROM MSD_CORE_Comments__c WHERE Id = :k.Id ];
                List<Knowledge__kav> KRecordlist  = new List<Knowledge__kav>();
                KRecordlist = [SELECT MSD_CORE_Qstn_Cmnt_Convo__c FROM Knowledge__kav WHERE Id = :k.MSD_CORE_Knowledge__c];
                for (Knowledge__kav KRecord : KRecordlist ){
                    String createddate = k.CreatedDate.month()+ ' / ' + k.CreatedDate.day() + ' / ' + k.CreatedDate.year();
                    KRecord.MSD_CORE_Qstn_Cmnt_Convo__c = KRecord.MSD_CORE_Qstn_Cmnt_Convo__c + '<br/>' + com.CreatedBy.Name + ' - ' + k.MSD_CORE_Comment__c + ' - ' + createddate ;
                }
                update KRecordlist;
            }
        }
}
}