/**
 * @description MSD_CORE_Notification
 */

public without sharing class MSD_CORE_Notification {
    public static string className = 'MSD_CORE_Notification';
    
    /**
     * @description getProductList
     * @return Map
     * @param userId
    */
    @AuraEnabled
    public static Map<Id,prodlst> getProductList(String userId){
        try {
            Set<Id> proId = new Set<Id>();
            List<MSD_CORE_Product_Payor__c> prodlist = [SELECT Id, Name, MSD_CORE_Product_Description__c, MSD_CORE_Generic_Name__c, MSD_CORE_Dosage_Form_and_Strength__c FROM MSD_CORE_Product_Payor__c WHERE Related_System__c = 'MFR'  ];
            //Modified by Sabari - : [MFRUS-117] Prescribing Information link update
            Map<Id,MSD_CORE_Product_Payor__c> prodmap = new Map<Id,MSD_CORE_Product_Payor__c>([SELECT Id,Name,MSD_CORE_Product_Description__c, MSD_CORE_Generic_Name__c, MSD_CORE_Dosage_Form_and_Strength__c,MSD_CORE_Prescribing_Information__c FROM MSD_CORE_Product_Payor__c WHERE Related_System__c = 'MFR']); 

            for(MSD_CORE_Product_Payor__c pr: prodlist){
                proId.add(pr.Id);
            }

            Map<Id,prodlst> mapval = new Map<Id,prodlst>();
            
            List<AggregateResult> agglst = [SELECT COUNT(Id), MSD_CORE_Label__c lb ,MSD_CORE_Product_Payor__c pp FROM MSD_CORE_Notification__c 
                                            WHERE MSD_CORE_Product_Payor__c =: proId AND MSD_CORE_Payor__c =: userId AND MSD_CORE_Read__C != true AND MSD_CORE_LabeL__c != null 
                                            AND MSD_CORE_Meeting_Request__r.MSD_CORE_Source__c = 'MFR'  
                                            GROUP BY MSD_CORE_LabeL__c,MSD_CORE_Product_Payor__c ];

            for(AggregateResult agg: agglst){
                String pro = String.valueOf(agg.get('pp'));
                Integer counttotal = [SELECT Id, Name, MSD_CORE_Payor__c, MSD_CORE_Product_Payor__c, MSD_CORE_Read__c FROM MSD_CORE_Notification__c 
                                      WHERE MSD_CORE_Product_Payor__c =: pro AND MSD_CORE_Payor__c =: userid AND MSD_CORE_Read__c != true AND MSD_CORE_LabeL__c != null 
                                      AND MSD_CORE_Meeting_Request__r.MSD_CORE_Source__c = 'MFR' ].size();
                if(mapval.containsKey(String.valueOf(agg.get('pp')))){
                    List<AggregateResult> lsagg = mapval.get(pro).aggresult;
                    lsagg.add(agg);
                    mapval.get(pro).aggresult = lsagg;
                }else{
                    prodlst newwrapper = new prodlst();
                    newwrapper.prodid = pro;
                    newwrapper.total = counttotal;
                    newwrapper.prodname = prodmap.get(pro).Name;
                    newwrapper.proddesc = prodmap.get(pro).MSD_CORE_Product_Description__c;
                    newwrapper.prodgen = prodmap.get(pro).MSD_CORE_Generic_Name__c;
                    newwrapper.proddos = prodmap.get(pro).MSD_CORE_Dosage_Form_and_Strength__c;
                    newwrapper.aggresult = new List<AggregateResult> {agg};
                    //Added by Sabari - : [MFRUS-117] Prescribing Information link update
                    newwrapper.prodpilink = prodmap.get(pro).MSD_CORE_Prescribing_Information__c;                    
                    newwrapper.notifi_id = agg.Id+'tt';
                    mapval.put(pro,newwrapper);
                }
            }
            return mapval;

        } catch (Exception e) {
            MHEEExceptionHandler.logException(e, className, 'getproductlist', 'Get Productlist');
            return null;
        }
    }
    
    /**
     * @description getNotificationCount
     * @return noticount
     * @param userid
    */
    @AuraEnabled
    public static noticount getNotificationCount(String userid){
        try {
            Integer totalcount = [SELECT Id, Name, MSD_CORE_Payor__c, MSD_CORE_Product_Payor__c, MSD_CORE_Label__c, MSD_CORE_Meeting_Request__c, MSD_CORE_Read__c, MSD_CORE_Resource__c 
                                  FROM MSD_CORE_Notification__c WHERE MSD_CORE_Payor__c =: userid AND MSD_CORE_Read__c != true AND MSD_CORE_Label__c != null AND MSD_CORE_Meeting_Request__r.MSD_CORE_Source__c = 'MFR'].size();
            Integer closedcount = [SELECT Id, Name, MSD_CORE_Payor__c, MSD_CORE_Product_Payor__c, MSD_CORE_Label__c, MSD_CORE_Meeting_Request__c, MSD_CORE_Read__c, MSD_CORE_Resource__c 
                                   FROM MSD_CORE_Notification__c WHERE MSD_CORE_Label__c = 'Closed' AND MSD_CORE_Payor__c =: userid AND MSD_CORE_Read__c != true AND MSD_CORE_Label__c != null AND MSD_CORE_Meeting_Request__r.MSD_CORE_Source__c = 'MFR'].size();
            Integer appcount = [SELECT Id, Name, MSD_CORE_Payor__c, MSD_CORE_Product_Payor__c, MSD_CORE_Label__c, MSD_CORE_Meeting_Request__c, MSD_CORE_Read__c, MSD_CORE_Resource__c 
                                FROM MSD_CORE_Notification__c WHERE MSD_CORE_Label__c = 'Appointments' AND MSD_CORE_Payor__c =: userid AND MSD_CORE_Read__c != true AND MSD_CORE_Label__c != null AND MSD_CORE_Meeting_Request__r.MSD_CORE_Source__c = 'MFR'].size();
            Integer actcount = [SELECT Id, Name, MSD_CORE_Payor__c, MSD_CORE_Product_Payor__c, MSD_CORE_Label__c, MSD_CORE_Meeting_Request__c, MSD_CORE_Read__c, MSD_CORE_Resource__c
                                FROM MSD_CORE_Notification__c WHERE MSD_CORE_Label__c = 'Activity' AND MSD_CORE_Payor__c =: userid AND MSD_CORE_Read__c != true AND MSD_CORE_Label__c != null AND MSD_CORE_Meeting_Request__r.MSD_CORE_Source__c = 'MFR'].size();
            Integer savedcount = [SELECT Id, Name, MSD_CORE_Payor__c, MSD_CORE_Product_Payor__c, MSD_CORE_Label__c, MSD_CORE_Meeting_Request__c, MSD_CORE_Read__c, MSD_CORE_Resource__c 
                                  FROM MSD_CORE_Notification__c WHERE MSD_CORE_Label__c = 'Saved' AND MSD_CORE_Payor__c =: userid AND MSD_CORE_Read__c != true AND MSD_CORE_Label__c != null AND MSD_CORE_Meeting_Request__r.MSD_CORE_Source__c = 'MFR'].size();

            noticount notic = new noticount();
            notic.appointment = appcount;
            notic.closed = closedcount;
            notic.total = totalcount;
            notic.activity = actcount;
            notic.saved = savedcount;
            return notic;

        } catch (Exception e) {
            MHEEExceptionHandler.logException(e, className, 'getnotificationcount', 'Get Notification Count');
            return null;
        }
    }

    /**
     * @description updateNotification
     * @return noticount
     * @param userid
     * @param label
     * @param prodId
    */
    @AuraEnabled
    public static noticount updateNotification(String userid, String label, String prodId){
        try {
            List<MSD_CORE_Notification__c> notilst = [SELECT Id, Name, MSD_CORE_Label__c, MSD_CORE_Read__c, MSD_CORE_Payor__c, MSD_CORE_Product_Payor__c 
                                                      FROM MSD_CORE_Notification__c WHERE MSD_CORE_Payor__c =: userid AND MSD_CORE_Product_Payor__c =: prodId 
                                                      AND MSD_CORE_Label__c =: label AND MSD_CORE_Meeting_Request__r.MSD_CORE_Source__c = 'MFR'  
                                                      ORDER BY CreatedDate Desc];
            List<MSD_CORE_Notification__c> newlst = new List<MSD_CORE_Notification__c>();
            for (MSD_CORE_Notification__c noti : notilst) {
                noti.MSD_CORE_Read__c = true;
                newlst.add(noti);
            }
            update newlst;

            Integer totalcount = [SELECT Id, Name, MSD_CORE_Payor__c, MSD_CORE_Product_Payor__c, MSD_CORE_Label__c, MSD_CORE_Meeting_Request__c, MSD_CORE_Read__c, MSD_CORE_Resource__c 
                                    FROM MSD_CORE_Notification__c WHERE MSD_CORE_Payor__c =: userid AND MSD_CORE_Read__c != true AND MSD_CORE_Label__c != null  AND MSD_CORE_Meeting_Request__r.MSD_CORE_Source__c = 'MFR'].size();
            Integer closedcount = [SELECT Id, Name, MSD_CORE_Payor__c, MSD_CORE_Product_Payor__c, MSD_CORE_Label__c, MSD_CORE_Meeting_Request__c, MSD_CORE_Read__c, MSD_CORE_Resource__c 
                                    FROM MSD_CORE_Notification__c WHERE MSD_CORE_Label__c = 'Closed' AND MSD_CORE_Payor__c =: userid AND MSD_CORE_Read__c != true AND MSD_CORE_Label__c != null AND MSD_CORE_Meeting_Request__r.MSD_CORE_Source__c = 'MFR'].size();
            Integer appcount = [SELECT Id, Name, MSD_CORE_Payor__c, MSD_CORE_Product_Payor__c, MSD_CORE_Label__c, MSD_CORE_Meeting_Request__c, MSD_CORE_Read__c, MSD_CORE_Resource__c 
                                FROM MSD_CORE_Notification__c WHERE MSD_CORE_Label__c = 'Appointments' AND MSD_CORE_Payor__c =: userid AND MSD_CORE_Read__c != true AND MSD_CORE_Label__c != null AND MSD_CORE_Meeting_Request__r.MSD_CORE_Source__c = 'MFR'].size();
            Integer actcount = [SELECT Id, Name, MSD_CORE_Payor__c, MSD_CORE_Product_Payor__c, MSD_CORE_Label__c, MSD_CORE_Meeting_Request__c, MSD_CORE_Read__c, MSD_CORE_Resource__c 
                                FROM MSD_CORE_Notification__c WHERE MSD_CORE_Label__c = 'Activity' AND MSD_CORE_Payor__c =: userid AND MSD_CORE_Read__c != true AND MSD_CORE_Label__c != null AND MSD_CORE_Meeting_Request__r.MSD_CORE_Source__c = 'MFR'].size();
            Integer savedcount = [SELECT Id, Name, MSD_CORE_Payor__c, MSD_CORE_Product_Payor__c, MSD_CORE_Label__c, MSD_CORE_Meeting_Request__c, MSD_CORE_Read__c, MSD_CORE_Resource__c 
                                  FROM MSD_CORE_Notification__c WHERE MSD_CORE_Label__c = 'Saved' AND MSD_CORE_Payor__c =: userid AND MSD_CORE_Read__c != true AND MSD_CORE_Label__c != null AND MSD_CORE_Meeting_Request__r.MSD_CORE_Source__c = 'MFR'].size();

            noticount notic = new noticount();
            notic.appointment = appcount;
            notic.closed = closedcount;
            notic.total = totalcount;
            notic.activity = actcount;
            notic.saved = savedcount;

            return notic;
        } catch (Exception e) {
            MHEEExceptionHandler.logException(e, className, 'updatenotification', 'Update Notification');
            return null;
        }
    }

    /**
     * @description getActivity
     * @return NotificationWrapper
     * @param userid
     * @param prodID
     * @param pageSize
     * @param pageNumber
    */
    @AuraEnabled
    public static NotificationWrapper getActivity(String userid,String prodID,String pageSize,String pageNumber){
        try {
            System.debug(LoggingLevel.WARN,'Get Activity Data');
            NotificationWrapper objNotificationWrapper = new NotificationWrapper();
            Integer ps = Integer.valueOf(pageSize);
            Integer pn = Integer.valueOf(pageNumber) - 1;
            Integer offsetValue = ps * pn;
            objNotificationWrapper.totalNotificationRecord = [SELECT COUNT() FROM MSD_CORE_Notification__c WHERE MSD_CORE_Payor__c =: userid AND CreatedDate != null AND CreatedDate = THIS_YEAR AND MSD_CORE_Product_Payor__c =:prodID  AND MSD_CORE_Notification__c = NULL ];

            List<MSD_CORE_Notification__c> parentNotificationResult = [SELECT Id, Name, MSD_CORE_Label__c, MSD_CORE_Product_Payor__c, MSD_CORE_Activity__c, MSD_CORE_Activity_Label__c, MSD_CORE_Meeting_Request__c, MSD_CORE_Payor__c, CreatedDate, MSD_CORE_Read__c, MSD_CORE_Meeting_Request__r.Assignee_vod__r.FirstName, MSD_CORE_Meeting_Request__r.Assignee_vod__r.LastName, MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c, MSD_CORE_Meeting_Request__r.MSD_CORE_Resource__r.Name, MSD_CORE_Meeting_Request__r.MSD_CORE_Resource__r.MSD_CORE_Resource_Title__c, MSD_CORE_Meeting_Request__r.Name,MSD_CORE_Product_Payor__r.Name,MSD_CORE_Product_Payor__r.MSD_CORE_Remove_Title_Description__c FROM MSD_CORE_Notification__c WHERE MSD_CORE_Payor__c =: userid AND CreatedDate != null AND CreatedDate = THIS_YEAR AND MSD_CORE_Product_Payor__c =:prodID  AND MSD_CORE_Notification__c = NULL  ORDER BY CreatedDate DESC LIMIT :ps OFFSET :offsetValue];
            Set<Id> parentNotificationIDs = new Set<Id>();
            for(MSD_CORE_Notification__c result:parentNotificationResult){
                parentNotificationIDs.add(result.id);
            }
        
            Map<String, List<notificationwrap>> returnmap = mapInitalization();
            List<MSD_CORE_Notification__C> childNotification = [SELECT Id, Name, MSD_CORE_Activity__c,MSD_CORE_Product_Payor__c, MSD_CORE_Activity_Label__c, MSD_CORE_Meeting_Request__c, MSD_CORE_Payor__c, CreatedDate, MSD_CORE_Read__c,MSD_CORE_Notification__c FROM MSD_CORE_Notification__c WHERE MSD_CORE_Payor__c =: userid AND CreatedDate != null AND CreatedDate = THIS_YEAR AND MSD_CORE_Product_Payor__c =:prodID  AND MSD_CORE_Notification__c != NULL AND MSD_CORE_Notification__c IN : ParentNotificationIDs   ORDER BY CreatedDate DESC];
            System.debug(LoggingLevel.WARN,'notilst===>'+childNotification);
            for(MSD_CORE_Notification__c result:parentNotificationResult){
                String meetingRequest=result.MSD_CORE_Meeting_Request__c;
                integer notificaionCounter=getChildNotificationCount(childNotification,result.Id);
                String notificationMonth='';
                notificationwrap nw = new notificationwrap();
                DateTime dt = result.CreatedDate;

                System.debug('System.today()-->'+System.today());
                System.debug('result.CreatedDate-->'+result.CreatedDate);
                System.debug('result.CreatedDate.date()-->'+result.CreatedDate.date());

                String catalogUrl = '';
                if (result.MSD_CORE_Activity__c.contains(Label.MerckPortalLibrary)) {
                    catalogUrl = Label.MerckPortalLibrary + result.MSD_CORE_Product_Payor__c;
                } else if (result.MSD_CORE_Activity__c.contains(Label.MerckProductDetail)) {
                    catalogUrl = Label.MerckProductDetail + result.MSD_CORE_Product_Payor__c;
                }
                System.debug('===>catalogUrl-->'+catalogUrl);

                if(result.CreatedDate.date() == System.today()){
                    NotificationMonth='Today';
                    // nw.activity = result.MSD_CORE_Activity__c;
                    DateTime dtm = System.Now();
                    dtm = dtm.addHours(-dt.hourGmt());
                    String timeval;
                    if (Integer.valueOf(dtm.hourGmt()) == 0) {
                        DateTime gtmv = System.now();
                        gtmv = gtmv.addMinutes(-dt.minuteGmt());
                        if (Integer.valueOf(gtmv.minuteGmt()) == 0) {
                            timeval = 'Just Now';
                        }else{
                            timeval = String.valueOf(gtmv.minuteGmt());
                            timeval += ' Minutes ago';
                        }
                    } else if (Integer.valueOf(dtm.hourGmt()) == 1) {
                        timeval = String.valueOf(dtm.hourGmt());
                        timeval += ' hour ago';
                    } else {
                        timeval = String.valueOf(dtm.hourGmt());
                        timeval += ' hours ago';
                    }
                    nw.dateval = timeval;
                    // E2ESE-1280
                    // 03 July 2023
                    // For Fixing Timezone issue on Schedule appointment Notification text
                    if (result.MSD_CORE_LabeL__c == 'Appointments') {
                        String meetingrequrl = Label.MerckPortal + result.MSD_CORE_Meeting_Request__c+'&GAnotification=true';
                        if (result.MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c != null) {
                            String startdateval = result.MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c.format('EEEE') +', '+result.MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c.format('MMMM')+' '+result.MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c.format('dd')+', '+result.MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c.format('YYYY')+' at '+result.MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c.format('hh')+':'+result.MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c.format('mm')+' '+result.MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c.format('aa'); 
                            if(result.MSD_CORE_Product_Payor__r.MSD_CORE_Remove_Title_Description__c){
                                result.MSD_CORE_Activity__c = '<p style="font-size: 18px; color:#333333;font-weight: 700; line-height: 27px;font-style: normal;">'+result.MSD_CORE_Meeting_Request__r.Assignee_vod__r.FirstName+ ' '+result.MSD_CORE_Meeting_Request__r.Assignee_vod__r.LastName+' scheduled an appointment for <style="font-size: 18px;font-weight: 700; line-height: 27px;font-style: normal;"><a href="'+meetingrequrl+'" onclick={handleredirect}  target="_self" style="font-size: 18px; color: rgb(0, 133, 124);font-weight: 700; line-height: 27px;font-style: normal;"><u>Request: '+result.MSD_CORE_Meeting_Request__r.Name+'</u></a><style="font-size: 18px;font-weight: 700; line-height: 27px;font-style: normal;"><style="font-size: 14px;font-style: normal;font-weight: 700;line-height: 27px;color:#333333;"> <style="font-size: 14px; color:#333333;font-style: normal;font-weight: 700;line-height: 27px;">on '+startdateval+'</p>';   
                            }else{
                                result.MSD_CORE_Activity__c = '<p style="font-size: 18px; color:#333333;font-weight: 700; line-height: 27px;font-style: normal;">'+result.MSD_CORE_Meeting_Request__r.Assignee_vod__r.FirstName+ ' '+result.MSD_CORE_Meeting_Request__r.Assignee_vod__r.LastName+' scheduled an appointment for <style="font-size: 18px;font-weight: 700; line-height: 27px;font-style: normal;"><a href="'+meetingrequrl+'" onclick={handleredirect}  target="_self" style="font-size: 18px; color: rgb(0, 133, 124);font-weight: 700; line-height: 27px;font-style: normal;"><u>Request: '+result.MSD_CORE_Meeting_Request__r.Name+'</u></a><style="font-size: 18px;font-weight: 700; line-height: 27px;font-style: normal;"> for <a href="'+catalogUrl+'" target="_self" style="font-size: 18px; color: rgb(0, 133, 124); font-family: Invention;font-weight: 700; line-height: 27px;font-style: normal;"><u>'+result.MSD_CORE_Meeting_Request__r.MSD_CORE_Resource__r.MSD_CORE_Resource_Title__c+'</u></a><style="font-size: 14px;font-style: normal;font-weight: 700;line-height: 27px;color:#333333;"> <style="font-size: 14px; color:#333333;font-style: normal;font-weight: 700;line-height: 27px;">on '+startdateval+'</p>';   
                            }
                        }
                        nw.activity = result.MSD_CORE_Activity__c;
                    } else {
                        if(result.MSD_CORE_Product_Payor__r.MSD_CORE_Remove_Title_Description__c){
                            if(result.MSD_CORE_Activity__c.toLowerCase().contains('in your library') || result.MSD_CORE_Activity__c.toLowerCase().contains('for your library')){
                                result.MSD_CORE_Activity__c = result.MSD_CORE_Activity__c.substring(0,result.MSD_CORE_Activity__c.indexOf('">',result.MSD_CORE_Activity__c.indexOf('">')+1)+2)+'resource'+result.MSD_CORE_Activity__c.substring(result.MSD_CORE_Activity__c.indexOf('</a>'),result.MSD_CORE_Activity__c.length()-1);
                                if(result.MSD_CORE_Activity__c.contains('saved')){
                                    result.MSD_CORE_Activity__c = result.MSD_CORE_Activity__c.replace('saved','saved a');
                                }
                            }else if(result.MSD_CORE_Activity__c.toLowerCase().contains('you have created')){
                                //result.MSD_CORE_Activity__c = result.MSD_CORE_Activity__c.substring(0,findWordIndices(result.MSD_CORE_Activity__c, '<u>')[findWordIndices(result.MSD_CORE_Activity__c, '<u>').size()-1]+3)+'resource'+result.MSD_CORE_Activity__c.substring(findWordIndices(result.MSD_CORE_Activity__c, '</u>')[findWordIndices(result.MSD_CORE_Activity__c, '</u>').size()-1],result.MSD_CORE_Activity__c.length()-1);
                                result.MSD_CORE_Activity__c = result.MSD_CORE_Activity__c.substring(0,result.MSD_CORE_Activity__c.indexOf(' for <a'))+result.MSD_CORE_Activity__c.substring(result.MSD_CORE_Activity__c.indexOf('<span'),result.MSD_CORE_Activity__c.length()-1);
                                result.MSD_CORE_Activity__c = result.MSD_CORE_Activity__c.replace('You have created','You have created Request:');
                            }else if(result.MSD_CORE_Activity__c.toLowerCase().contains('you have cancelled')){
                                //result.MSD_CORE_Activity__c = result.MSD_CORE_Activity__c.substring(0,findWordIndices(result.MSD_CORE_Activity__c, '<u>')[findWordIndices(result.MSD_CORE_Activity__c, '<u>').size()-1]+3)+'resource'+result.MSD_CORE_Activity__c.substring(findWordIndices(result.MSD_CORE_Activity__c, '</u>')[findWordIndices(result.MSD_CORE_Activity__c, '</u>').size()-1],result.MSD_CORE_Activity__c.length()-1);
                                result.MSD_CORE_Activity__c = result.MSD_CORE_Activity__c.substring(0,result.MSD_CORE_Activity__c.indexOf('<strong> for'))+result.MSD_CORE_Activity__c.substring(result.MSD_CORE_Activity__c.indexOf('</a></p>')+4,result.MSD_CORE_Activity__c.length()-1)+'.';
                                result.MSD_CORE_Activity__c = result.MSD_CORE_Activity__c.replace('You have cancelled','You have cancelled Request:');
                            }else if(result.MSD_CORE_Activity_Label__c == 'Meeting_Request__c' && result.MSD_CORE_Activity__c.contains('for') && result.MSD_CORE_Activity__c.contains('on')){
                                result.MSD_CORE_Activity__c = result.MSD_CORE_Activity__c.substring(0,findWordIndices(result.MSD_CORE_Activity__c, 'for')[findWordIndices(result.MSD_CORE_Activity__c, 'for').size()-1])+result.MSD_CORE_Activity__c.substring(findWordIndices(result.MSD_CORE_Activity__c, 'on')[findWordIndices(result.MSD_CORE_Activity__c, 'on').size()-1],result.MSD_CORE_Activity__c.length()-1);
                            }
                        }
                        
                         nw.activity = result.MSD_CORE_Activity__c;
                    }
                    nw.resid = result.MSD_CORE_Meeting_Request__c;
                    nw.read = result.MSD_CORE_Read__c;
                    nw.groupact = result.MSD_CORE_Activity_Label__c;
                    nw.activityID=result.Id;
                }else if(result.CreatedDate != Date.today()){
                    NotificationMonth=dt.format('MMMM');
                    // nw.activity = result.MSD_CORE_Activity__c;
                    // E2ESE-1280
                    // 03 July 2023
                    // For Fixing Timezone issue on Schedule appointment Notification text
                    if (result.MSD_CORE_LabeL__c == 'Appointments') {
                        String meetingrequrl = Label.MerckPortal + result.MSD_CORE_Meeting_Request__c+'&GAnotification=true';
                        if (result.MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c != null) {
                            String startdateval = result.MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c.format('EEEE') +', '+result.MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c.format('MMMM')+' '+result.MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c.format('dd')+', '+result.MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c.format('YYYY')+' at '+result.MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c.format('hh')+':'+result.MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c.format('mm')+' '+result.MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c.format('aa'); 
                            if(result.MSD_CORE_Product_Payor__r.MSD_CORE_Remove_Title_Description__c){
                                result.MSD_CORE_Activity__c = '<p style="font-size: 18px; color:#333333;font-weight: 700; line-height: 27px;font-style: normal;">'+result.MSD_CORE_Meeting_Request__r.Assignee_vod__r.FirstName+ ' '+result.MSD_CORE_Meeting_Request__r.Assignee_vod__r.LastName+' scheduled an appointment for <style="font-size: 18px;font-weight: 700; line-height: 27px;font-style: normal;"><a href="'+meetingrequrl+'" onclick={handleredirect}  target="_self" style="font-size: 18px; color: rgb(0, 133, 124);font-weight: 700; line-height: 27px;font-style: normal;"><u>Request: '+result.MSD_CORE_Meeting_Request__r.Name+'</u></a><style="font-size: 18px;font-weight: 700; line-height: 27px;font-style: normal;"><style="font-size: 14px;font-style: normal;font-weight: 700;line-height: 27px;color:#333333;"> <style="font-size: 14px; color:#333333;font-style: normal;font-weight: 700;line-height: 27px;">on '+startdateval+'</p>';   
                            }else{
                                result.MSD_CORE_Activity__c = '<p style="font-size: 18px; color:#333333;font-weight: 700; line-height: 27px;font-style: normal;">'+result.MSD_CORE_Meeting_Request__r.Assignee_vod__r.FirstName+ ' '+result.MSD_CORE_Meeting_Request__r.Assignee_vod__r.LastName+' scheduled an appointment for <style="font-size: 18px;font-weight: 700; line-height: 27px;font-style: normal;"><a href="'+meetingrequrl+'" onclick={handleredirect}  target="_self" style="font-size: 18px; color: rgb(0, 133, 124);font-weight: 700; line-height: 27px;font-style: normal;"><u>Request: '+result.MSD_CORE_Meeting_Request__r.Name+'</u></a><style="font-size: 18px;font-weight: 700; line-height: 27px;font-style: normal;"> for <a href="'+catalogUrl+'" target="_self" style="font-size: 18px; color: rgb(0, 133, 124); font-family: Invention;font-weight: 700; line-height: 27px;font-style: normal;"><u>'+result.MSD_CORE_Meeting_Request__r.MSD_CORE_Resource__r.MSD_CORE_Resource_Title__c+'</u></a><style="font-size: 14px;font-style: normal;font-weight: 700;line-height: 27px;color:#333333;"> <style="font-size: 14px; color:#333333;font-style: normal;font-weight: 700;line-height: 27px;">on '+startdateval+'</p>';   
                            }
                        }
                        nw.activity = result.MSD_CORE_Activity__c;
                    } else {
                        if(result.MSD_CORE_Product_Payor__r.MSD_CORE_Remove_Title_Description__c){
                            if(result.MSD_CORE_Activity__c.toLowerCase().contains('in your library') || result.MSD_CORE_Activity__c.toLowerCase().contains('for your library')){
                                result.MSD_CORE_Activity__c = result.MSD_CORE_Activity__c.substring(0,result.MSD_CORE_Activity__c.indexOf('">',result.MSD_CORE_Activity__c.indexOf('">')+1)+2)+'resource'+result.MSD_CORE_Activity__c.substring(result.MSD_CORE_Activity__c.indexOf('</a>'),result.MSD_CORE_Activity__c.length()-1);
                                if(result.MSD_CORE_Activity__c.contains('saved')){
                                    result.MSD_CORE_Activity__c = result.MSD_CORE_Activity__c.replace('saved','saved a');
                                }
                            }else if(result.MSD_CORE_Activity__c.toLowerCase().contains('you have created')){
                                result.MSD_CORE_Activity__c = result.MSD_CORE_Activity__c.substring(0,result.MSD_CORE_Activity__c.indexOf(' for <a'))+result.MSD_CORE_Activity__c.substring(result.MSD_CORE_Activity__c.indexOf('<span'),result.MSD_CORE_Activity__c.length()-1);
                                result.MSD_CORE_Activity__c = result.MSD_CORE_Activity__c.replace('You have created','You have created Request:');
                            }else if(result.MSD_CORE_Activity__c.toLowerCase().contains('you have cancelled')){
                                result.MSD_CORE_Activity__c = result.MSD_CORE_Activity__c.substring(0,result.MSD_CORE_Activity__c.indexOf('<strong> for'))+result.MSD_CORE_Activity__c.substring(result.MSD_CORE_Activity__c.indexOf('</a></p>')+4,result.MSD_CORE_Activity__c.length()-1)+'.';
                                result.MSD_CORE_Activity__c = result.MSD_CORE_Activity__c.replace('You have cancelled','You have cancelled Request:');
                            }else if(result.MSD_CORE_Activity_Label__c == 'Meeting_Request__c' && result.MSD_CORE_Activity__c.contains('for') && result.MSD_CORE_Activity__c.contains('on')){
                                result.MSD_CORE_Activity__c = result.MSD_CORE_Activity__c.substring(0,findWordIndices(result.MSD_CORE_Activity__c, 'for')[findWordIndices(result.MSD_CORE_Activity__c, 'for').size()-1])+result.MSD_CORE_Activity__c.substring(findWordIndices(result.MSD_CORE_Activity__c, 'on')[findWordIndices(result.MSD_CORE_Activity__c, 'on').size()-1],result.MSD_CORE_Activity__c.length()-1);
                            }
                        }
                        nw.activity = result.MSD_CORE_Activity__c;
                    }
                    nw.dateval = dt.format('EEEE') +', '+dt.format('MMMM')+' '+dt.format('dd')+','+dt.format('YYYY')+' at '+dt.format('hh')+':'+dt.format('mm')+' '+dt.format('aa'); 
                    nw.resid = result.MSD_CORE_Meeting_Request__c;
                    nw.read = result.MSD_CORE_Read__c;
                    nw.groupact = result.MSD_CORE_Activity_Label__c;
                    nw.activityID=result.Id;    
                    nw.createddate=result.CreatedDate;
                }
                    
                List<notificationwrap> nwlist = returnmap.get(NotificationMonth);
                Integer i = NotificaionCounter;
                if(i == 1){
                    nw.MultipleMeetingCount = NotificaionCounter +' more event';
                }else{
                    nw.MultipleMeetingCount = NotificaionCounter +' more events';
                }
                if(NotificaionCounter>0){
                    nw.isMultipleMeeting= true;
                }else{
                    nw.isMultipleMeeting= false;
                }
                nwlist.add(nw);
                returnmap.put(NotificationMonth,nwlist);
            }
            objNotificationWrapper.notificationList=returnmap;
            System.debug('objNotificationWrapper-->'+objNotificationWrapper);
            return objNotificationWrapper;
        } catch (Exception e) {
            MHEEExceptionHandler.logException(e, className, 'getActivity', 'get Activity');
            System.debug('Error----===>'+e.getMessage()+'---'+e.getLineNumber());
            return null;
        }

    }
    
     public static List<Integer> findWordIndices(String inputString, String targetWord) {
        List<Integer> indices = new List<Integer>();
        Integer currentIndex = -1;
        
        // Loop until there are no more occurrences of the targetWord
        while ((currentIndex = inputString.indexOf(targetWord, currentIndex + 1)) != -1) {
            // Add the index of the found occurrence to the list
            indices.add(currentIndex);
        }
        
        return indices;
    }

    /**
     * @description getChildNotificationCount
     * @return integer
     * @param childNotificationList
     * @param parentNotificationID
    */
    private static integer getChildNotificationCount(List<MSD_CORE_Notification__C> childNotificationList,String parentNotificationID){
        integer childNotificationCount=0;
        for(MSD_CORE_Notification__C notification:childNotificationList){
            if(notification.MSD_CORE_Notification__c==parentNotificationID){
                ChildNotificationCount++;
            }
        }
        return ChildNotificationCount;
    }

    /**
     * @description getActivityDetail
     * @return List<notificationwrap>
     * @param userid
     * @param prodID
     * @param parentNotificationID
    */
    @AuraEnabled(cacheable=true)
    public static List<notificationwrap> getActivityDetail(String userid,String prodID,String parentNotificationID){
        try {
            List<MSD_CORE_Notification__C> notilst = [SELECT Id, Name, MSD_CORE_Activity__c,MSD_CORE_Product_Payor__r.Name, MSD_CORE_Product_Payor__c, MSD_CORE_Activity_Label__c,MSD_CORE_LabeL__c, MSD_CORE_Meeting_Request__c, MSD_CORE_Meeting_Request__r.Name, MSD_CORE_Payor__c, CreatedDate, MSD_CORE_Read__c, MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c, MSD_CORE_Meeting_Request__r.Assignee_vod__r.FirstName, MSD_CORE_Meeting_Request__r.Assignee_vod__r.LastName, MSD_CORE_Meeting_Request__r.MSD_CORE_Resource__r.Name, MSD_CORE_Meeting_Request__r.MSD_CORE_Resource__r.MSD_CORE_Resource_Title__c,MSD_CORE_Product_Payor__r.MSD_CORE_Remove_Title_Description__c FROM MSD_CORE_Notification__c WHERE MSD_CORE_Payor__c =: userid AND CreatedDate != null AND CreatedDate = THIS_YEAR AND MSD_CORE_Product_Payor__c =:prodID AND MSD_CORE_Notification__c=:parentNotificationID ORDER BY CreatedDate DESC ];
            List<notificationwrap> activityDetailList = new List<notificationwrap> ();

            for(MSD_CORE_Notification__C n: notilst){
                DateTime dt = n.CreatedDate;

                String catalogUrl = '';
                if (n.MSD_CORE_Activity__c.contains(Label.MerckPortalLibrary)) {
                    catalogUrl = Label.MerckPortalLibrary + n.MSD_CORE_Product_Payor__c;
                } else if (n.MSD_CORE_Activity__c.contains(Label.MerckProductDetail)) {
                    catalogUrl = Label.MerckProductDetail + n.MSD_CORE_Product_Payor__c;
                }
                System.debug('catalogUrl-->'+catalogUrl);

                if(n.CreatedDate.date() == System.today()){
                    notificationwrap nw = new notificationwrap();
                    // nw.activity = n.MSD_CORE_Activity__c;

                    DateTime dtm = System.Now();
                    dtm = dtm.addHours(-dt.hourGmt());
                    String timeval;
                    if (Integer.valueOf(dtm.hourGmt()) == 0) {
                        DateTime gtmv = System.now();
                        gtmv = gtmv.addMinutes(-dt.minuteGmt());
                        if (Integer.valueOf(gtmv.minuteGmt()) == 0) {
                            timeval = 'Just Now';
                        }else{
                            timeval = String.valueOf(gtmv.minuteGmt());
                            timeval += ' Minutes ago';
                        }

                    } else if (Integer.valueOf(dtm.hourGmt()) == 1) {
                        timeval = String.valueOf(dtm.hourGmt());
                        timeval += ' hour ago';
                    } else{
                        timeval = String.valueOf(dtm.hourGmt());
                        timeval += ' hours ago';
                    }

                    // E2ESE-1280
                    // 03 July 2023
                    // For Fixing Timezone issue on Schedule appointment Notification text
                    if (n.MSD_CORE_LabeL__c == 'Appointments') {
                        String meetingrequrl = Label.MerckPortal + n.MSD_CORE_Meeting_Request__c+'&GAnotification=true';
                        if (n.MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c != null) {
                            String startdateval = n.MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c.format('EEEE') +', '+n.MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c.format('MMMM')+' '+n.MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c.format('dd')+', '+n.MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c.format('YYYY')+' at '+n.MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c.format('hh')+':'+n.MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c.format('mm')+' '+n.MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c.format('aa'); 
                            n.MSD_CORE_Activity__c = '<p style="font-size: 18px; color:#333333;font-weight: 700; line-height: 27px;font-style: normal;">'+n.MSD_CORE_Meeting_Request__r.Assignee_vod__r.FirstName+ ' '+n.MSD_CORE_Meeting_Request__r.Assignee_vod__r.LastName+' scheduled an appointment for <style="font-size: 18px;font-weight: 700; line-height: 27px;font-style: normal;"><a href="'+meetingrequrl+'" onclick={handleredirect}  target="_self" style="font-size: 18px; color: rgb(0, 133, 124);font-weight: 700; line-height: 27px;font-style: normal;"><u>Request: '+n.MSD_CORE_Meeting_Request__r.Name+'</u></a><style="font-size: 18px;font-weight: 700; line-height: 27px;font-style: normal;"> for <a href="'+catalogUrl+'" target="_self" style="font-size: 18px; color: rgb(0, 133, 124); font-family: Invention;font-weight: 700; line-height: 27px;font-style: normal;"><u>'+n.MSD_CORE_Meeting_Request__r.MSD_CORE_Resource__r.MSD_CORE_Resource_Title__c+'</u></a><style="font-size: 14px;font-style: normal;font-weight: 700;line-height: 27px;color:#333333;"> <style="font-size: 14px; color:#333333;font-style: normal;font-weight: 700;line-height: 27px;">on '+startdateval+' </p>';
                        }
                        nw.activity = n.MSD_CORE_Activity__c;
                    } else {
                        if(n.MSD_CORE_Product_Payor__r.MSD_CORE_Remove_Title_Description__c){
                            if(n.MSD_CORE_Activity__c.toLowerCase().contains('in your library') || n.MSD_CORE_Activity__c.toLowerCase().contains('for your library')){
                                n.MSD_CORE_Activity__c = n.MSD_CORE_Activity__c.substring(0,n.MSD_CORE_Activity__c.indexOf('">',n.MSD_CORE_Activity__c.indexOf('">')+1)+2)+'resource'+n.MSD_CORE_Activity__c.substring(n.MSD_CORE_Activity__c.indexOf('</a>'),n.MSD_CORE_Activity__c.length()-1);
                                if(n.MSD_CORE_Activity__c.contains('saved')){
                                    n.MSD_CORE_Activity__c = n.MSD_CORE_Activity__c.replace('saved','saved a');
                                }
                            }else if(n.MSD_CORE_Activity__c.toLowerCase().contains('you have created')){
                                n.MSD_CORE_Activity__c = n.MSD_CORE_Activity__c.substring(0,n.MSD_CORE_Activity__c.indexOf(' for <a'))+n.MSD_CORE_Activity__c.substring(n.MSD_CORE_Activity__c.indexOf('<span'),n.MSD_CORE_Activity__c.length()-1);
                                n.MSD_CORE_Activity__c = n.MSD_CORE_Activity__c.replace('You have created','You have created Request:');
                            }else if(n.MSD_CORE_Activity_Label__c == 'Meeting_Request__c' && n.MSD_CORE_Activity__c.contains('for') && n.MSD_CORE_Activity__c.contains('on')){
                                try{
	                                n.MSD_CORE_Activity__c = n.MSD_CORE_Activity__c.substring(0,findWordIndices(n.MSD_CORE_Activity__c, 'for')[findWordIndices(n.MSD_CORE_Activity__c, 'for').size()-1])+n.MSD_CORE_Activity__c.substring(findWordIndices(n.MSD_CORE_Activity__c, 'on')[findWordIndices(n.MSD_CORE_Activity__c, 'on').size()-1],n.MSD_CORE_Activity__c.length()-1);                                    
                                }catch(exception e){System.debug(e.getMessage());}

                            }
                        }
                        nw.activity = n.MSD_CORE_Activity__c;
                    }

                    nw.dateval = timeval;
                    nw.resid = n.MSD_CORE_Meeting_Request__c;
                    nw.read = n.MSD_CORE_Read__c;
                    nw.groupact = n.MSD_CORE_Activity_Label__c;
                    nw.MultipleMeetingCount='1';
                    nw.isMultipleMeeting= false;
                    activityDetailList.add(nw);
                    system.debug('createdDate>>'+ n.CreatedDate);
                    system.debug('todaysdate>>'+ Date.today());
                    system.debug('pastdate>>'+ Date.today().addDays(-2));
                }else if(n.CreatedDate != Date.today()){
                    notificationwrap nw = new notificationwrap();
                    // nw.activity = n.MSD_CORE_Activity__c;
                    // E2ESE-1280
                    // 03 July 2023
                    // For Fixing Timezone issue on Schedule appointment Notification text
                    if (n.MSD_CORE_LabeL__c == 'Appointments') {
                        String meetingrequrl = Label.MerckPortal + n.MSD_CORE_Meeting_Request__c+'&GAnotification=true';
                        if (n.MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c != null) {
                            String startdateval = n.MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c.format('EEEE') +', '+n.MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c.format('MMMM')+' '+n.MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c.format('dd')+', '+n.MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c.format('YYYY')+' at '+n.MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c.format('hh')+':'+n.MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c.format('mm')+' '+n.MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c.format('aa'); 
                            n.MSD_CORE_Activity__c = '<p style="font-size: 18px; color:#333333;font-weight: 700; line-height: 27px;font-style: normal;">'+n.MSD_CORE_Meeting_Request__r.Assignee_vod__r.FirstName+ ' '+n.MSD_CORE_Meeting_Request__r.Assignee_vod__r.LastName+' scheduled an appointment for <style="font-size: 18px;font-weight: 700; line-height: 27px;font-style: normal;"><a href="'+meetingrequrl+'" onclick={handleredirect}  target="_self" style="font-size: 18px; color: rgb(0, 133, 124);font-weight: 700; line-height: 27px;font-style: normal;"><u>Request: '+n.MSD_CORE_Meeting_Request__r.Name+'</u></a><style="font-size: 18px;font-weight: 700; line-height: 27px;font-style: normal;"> for <a href="'+catalogUrl+'" target="_self" style="font-size: 18px; color: rgb(0, 133, 124); font-family: Invention;font-weight: 700; line-height: 27px;font-style: normal;"><u>'+n.MSD_CORE_Meeting_Request__r.MSD_CORE_Resource__r.MSD_CORE_Resource_Title__c+'</u></a><style="font-size: 14px;font-style: normal;font-weight: 700;line-height: 27px;color:#333333;"> <style="font-size: 14px; color:#333333;font-style: normal;font-weight: 700;line-height: 27px;">on '+startdateval+' </p>';
                        }
                        nw.activity = n.MSD_CORE_Activity__c;
                    } else {
                        if(n.MSD_CORE_Product_Payor__r.MSD_CORE_Remove_Title_Description__c){
                            if(n.MSD_CORE_Activity__c.toLowerCase().contains('in your library') || n.MSD_CORE_Activity__c.toLowerCase().contains('for your library')){
                                n.MSD_CORE_Activity__c = n.MSD_CORE_Activity__c.substring(0,n.MSD_CORE_Activity__c.indexOf('">',n.MSD_CORE_Activity__c.indexOf('">')+1)+2)+'resource'+n.MSD_CORE_Activity__c.substring(n.MSD_CORE_Activity__c.indexOf('</a>'),n.MSD_CORE_Activity__c.length()-1);
                                if(n.MSD_CORE_Activity__c.contains('saved')){
                                    n.MSD_CORE_Activity__c = n.MSD_CORE_Activity__c.replace('saved','saved a');
                                }
                            }else if(n.MSD_CORE_Activity__c.toLowerCase().contains('you have created')){
                                n.MSD_CORE_Activity__c = n.MSD_CORE_Activity__c.substring(0,n.MSD_CORE_Activity__c.indexOf(' for <a'))+n.MSD_CORE_Activity__c.substring(n.MSD_CORE_Activity__c.indexOf('<span'),n.MSD_CORE_Activity__c.length()-1);
                                n.MSD_CORE_Activity__c = n.MSD_CORE_Activity__c.replace('You have created','You have created Request:');
                            }else if(n.MSD_CORE_Activity_Label__c == 'Meeting_Request__c'){
                                n.MSD_CORE_Activity__c = n.MSD_CORE_Activity__c.substring(0,findWordIndices(n.MSD_CORE_Activity__c, '<u>')[findWordIndices(n.MSD_CORE_Activity__c, '<u>').size()-1]+3)+'resource'+n.MSD_CORE_Activity__c.substring(findWordIndices(n.MSD_CORE_Activity__c, '</u>')[findWordIndices(n.MSD_CORE_Activity__c, '</u>').size()-1],n.MSD_CORE_Activity__c.length()-1);
                            }
                        }
                        nw.activity = n.MSD_CORE_Activity__c;
                    }
                    nw.dateval = dt.format('EEEE') +', '+dt.format('MMMM')+' '+dt.format('dd')+','+dt.format('YYYY')+' at '+dt.format('hh')+':'+dt.format('mm')+' '+dt.format('aa'); 
                    nw.resid = n.MSD_CORE_Meeting_Request__c;
                    nw.read = n.MSD_CORE_Read__c;
                    nw.groupact = n.MSD_CORE_Activity_Label__c;
                    nw.MultipleMeetingCount='1';
                    nw.isMultipleMeeting= false;
                    activityDetailList.add(nw);
                }         
            }
            return activityDetailList;
        } catch (Exception e) {
            MHEEExceptionHandler.logException(e, className, 'getActivityDetail', 'get Activity Detail');
            return null;
        }
    }

    /**
     * @description updateReadCheck
     * @return string
     * @param meetid
    */
    @AuraEnabled
    public static string updateReadCheck(String meetid){
        String returnval = '';
        try {
            MSD_CORE_Notification__c msdno = [SELECT Id, MSD_CORE_Read__c FROM MSD_CORE_Notification__c WHERE Id =: meetid  LIMIT 1];
            msdno.MSD_CORE_Read__c = true;
            update msdno;
            returnval = 'Success!';
        } catch (Exception e) {
            returnval = e.getMessage();
        }
        return returnval;
    }    

    /**
     * @description mapInitalization
     * @return Map<String,List<notificationwrap>>
    */
    public static Map<String,List<notificationwrap>> mapInitalization(){
        Map<String,List<notificationwrap>> newMap = new Map<String,List<notificationwrap>>();
        List<String> monthdetails = new List<String>{'Today','January','February','March','April','May','June','July','August','September','October','November','December'};
        for(String s: monthdetails){
            newMap.put(s,new List<notificationwrap>());
        }
        return newMap;
    }

     /**
     * owner: Tausif
     * @description getMHEEUnreadNotificationCount
     * @return Integer
     * @param userid
    */
    @AuraEnabled(cacheable=false)
    public static Integer getMHEEUnreadNotificationCount(String userid){
            return [SELECT ID  FROM MSD_CORE_Notification__c WHERE MSD_CORE_Payor__c =: userid AND MSD_CORE_Read__c != true  AND MSD_CORE_Meeting_Request__r.MSD_CORE_Source__c = 'MHEE'].size();
    }

     /**
    * owner: Ravi/Tausif
    * @description getMHEEUnreadNotificationCount
    * @return Integer
    * @param userid
    * @param pageSize
    * @param pageNumber
    */
    @AuraEnabled(cacheable=true)
    public static MheeNotificationWrapper getMHEENotification(String userid,String pageSize,String pageNumber){
        Integer ps = Integer.valueOf(pageSize);
        Integer pn = Integer.valueOf(pageNumber) - 1;
        Integer offsetValue = ps * pn;
        List<MSD_CORE_Notification__C> mheenotilst = [SELECT Id, Name, MSD_CORE_Notification__c, MSD_CORE_Label__c, MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c , MSD_CORE_Meeting_Request__r.ScheduleFilter__c, MSD_CORE_Meeting_Request__r.Assignee_vod__r.FirstName, MSD_CORE_Meeting_Request__r.Assignee_vod__r.LastName, MSD_CORE_Activity__c, MSD_CORE_Notification__r.Name, Related_Notification__c,msd_core_read__c,createdDate FROM MSD_CORE_Notification__C WHERE MSD_CORE_Meeting_Request__r.MSD_CORE_Source__c = 'MHEE' AND MSD_CORE_Payor__c =: userid   ORDER BY CreatedDate DESC LIMIT :ps OFFSET :offsetValue];

        MheeNotificationWrapper mheeNotWrapperObj= new MheeNotificationWrapper();
        mheeNotWrapperObj.totalParentNotificationCount = [SELECT Count() FROM MSD_CORE_Notification__C WHERE MSD_CORE_Meeting_Request__r.MSD_CORE_Source__c = 'MHEE' AND MSD_CORE_Payor__c =: userid];
        
        Map<String, List<MheeNotifParenticationWrapper>> parentNotificationList =new Map<String, List<MheeNotifParenticationWrapper>>();
        List<MheeNotifParenticationWrapper> mheeNotifParenticationlst= new List<MheeNotifParenticationWrapper>();

        List<String> childNotiIds = new List<String>();
        for(MSD_CORE_Notification__C childnotificationRelated:mheenotilst){
            if (childnotificationRelated.Related_Notification__c != null) {
                childNotiIds.addAll(childnotificationRelated.Related_Notification__c.split('\\,'));
            }
        }
        List<MSD_CORE_Notification__c> childnotificationlist = [SELECT Id, Name, MSD_CORE_Notification__c, MSD_CORE_Label__c, MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c , MSD_CORE_Meeting_Request__r.ScheduleFilter__c, MSD_CORE_Meeting_Request__r.Assignee_vod__r.FirstName, MSD_CORE_Meeting_Request__r.Assignee_vod__r.LastName, MSD_CORE_Activity__c, MSD_CORE_Notification__r.Name, Related_Notification__c,msd_core_read__c,createdDate FROM MSD_CORE_Notification__C WHERE MSD_CORE_Meeting_Request__r.MSD_CORE_Source__c = 'MHEE' AND MSD_CORE_Payor__c =: userid AND Id IN: childNotiIds ORDER BY CreatedDate DESC];

        for(MSD_CORE_Notification__C meetingNotification:mheenotilst){
            
            String strMonth ='';
            
            Datetime dtvar1 = meetingNotification.createdDate;
            Date createdDate = date.newinstance(dtvar1.year(), dtvar1.month(), dtvar1.day());

            DateTime dtvar2 = System.Now();
            Date todaysDate = date.newinstance(dtvar2.year(), dtvar2.month(), dtvar2.day());

            if(createdDate == todaysDate){
                strMonth ='Today';
            }else{
                strMonth = dtvar1.format('MMMM');
            }
            if(parentNotificationList.get(strMonth)==null){
                mheeNotifParenticationlst = new List<MheeNotifParenticationWrapper>();
            }
            List<MheeChildNotifictionWrapper> childNotList = new List<MheeChildNotifictionWrapper>();
            MheeNotifParenticationWrapper mheeNotifParenticationObj= new MheeNotifParenticationWrapper();

            if(!String.isEmpty(meetingNotification.Related_Notification__c)) {
                string[] childNotiArray;
                childNotiArray = meetingNotification.Related_Notification__c.split('\\,');

                if(childNotiArray!=null && childNotiArray.size()>0){
                    mheeNotifParenticationObj.isChild = true;
                    if(childNotiArray.size()==1){
                        mheeNotifParenticationObj.childCount = childNotiArray.size() +' more event';
                    } else {
                        mheeNotifParenticationObj.childCount = childNotiArray.size() +' more events';
                    }

                    for(Integer counter =0; counter<childNotiArray.size(); counter ++){
                        MheeChildNotifictionWrapper childNotificationWrap = new MheeChildNotifictionWrapper();
                        for(MSD_CORE_Notification__C notiobj : childnotificationlist){
                            if (notiobj.Id==childNotiArray[counter]) {
                                childNotificationWrap.duration = getDuration(notiobj.createdDate);
                                if (notiobj.MSD_CORE_Label__c == 'Appointments') {
                                    String navchildurl = Label.MheePortal + notiobj.MSD_CORE_Meeting_Request__c+'&nid='+notiobj.Id;
                                    List<String> childschflst = notiobj.MSD_CORE_Meeting_Request__r.ScheduleFilter__c.split(',');
                                    String childschedulefilterval;
                                    if (childschflst.size()>1) {
                                        Integer childsccount = childschflst.size()-1;
                                        childschedulefilterval = childschflst[0] +' (+'+childsccount+' more)';
                                    } else {
                                        childschedulefilterval = notiobj.MSD_CORE_Meeting_Request__r.ScheduleFilter__c;
                                    }
                                    String startdatechildval = notiobj.MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c.format('EEEE') +', '+notiobj.MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c.format('MMMM')+' '+notiobj.MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c.format('dd')+', '+notiobj.MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c.format('YYYY')+' at '+notiobj.MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c.format('hh')+':'+notiobj.MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c.format('mm')+' '+notiobj.MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c.format('aa'); 
                                    notiobj.MSD_CORE_Activity__c = '<p><strong style="color: rgb(0, 0, 0); font-size: 18px;">'+notiobj.MSD_CORE_Meeting_Request__r.Assignee_vod__r.FirstName+' '+notiobj.MSD_CORE_Meeting_Request__r.Assignee_vod__r.LastName+'</strong><strong style="font-size: 18px;"> scheduled an appointment for </strong><a href="'+navchildurl+'" rel="noopener noreferrer" target="_self" style="font-size: 18px; color: rgb(0, 133, 124);"><strong><u>'+childschedulefilterval+'</u></strong></a><span style="font-size: 18px;"> </span><strong style="font-size: 18px;">on '+startdatechildval+'</strong></p>';
                                } 
                                childNotificationWrap.childNotification = notiobj;
                                if(!childNotList.contains(childNotificationWrap)){
                                    childNotList.add(childNotificationWrap);
                                }
                            }
                        }
                    }
                }
            } 

            mheeNotifParenticationObj.isRead = meetingNotification.msd_core_read__c;
            mheeNotifParenticationObj.duration = getDuration(meetingNotification.createdDate);
            if (meetingNotification.MSD_CORE_Label__c == 'Appointments') {
                List<String> parentschflst = meetingNotification.MSD_CORE_Meeting_Request__r.ScheduleFilter__c.split(',');
                String parentschedulefilterval;
                if (parentschflst.size()>1) {
                    Integer parentsccount = parentschflst.size()-1;
                    parentschedulefilterval = parentschflst[0] + ' (+'+parentsccount+' more)';
                } else {
                    parentschedulefilterval = meetingNotification.MSD_CORE_Meeting_Request__r.ScheduleFilter__c;
                }
                String navparenturl = Label.MheePortal + meetingNotification.MSD_CORE_Meeting_Request__c+'&nid='+meetingNotification.Id;
                String startdateparentval = meetingNotification.MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c.format('EEEE') +', '+meetingNotification.MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c.format('MMMM')+' '+meetingNotification.MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c.format('dd')+', '+meetingNotification.MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c.format('YYYY')+' at '+meetingNotification.MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c.format('hh')+':'+meetingNotification.MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c.format('mm')+' '+meetingNotification.MSD_CORE_Meeting_Request__r.Start_DateTime_vod__c.format('aa'); 
                meetingNotification.MSD_CORE_Activity__c = '<p><strong style="color: rgb(0, 0, 0); font-size: 18px;">'+meetingNotification.MSD_CORE_Meeting_Request__r.Assignee_vod__r.FirstName+' '+meetingNotification.MSD_CORE_Meeting_Request__r.Assignee_vod__r.LastName+'</strong><strong style="font-size: 18px;"> scheduled an appointment for </strong><a href="'+navparenturl+'" rel="noopener noreferrer" target="_self" style="font-size: 18px; color: rgb(0, 133, 124);"><strong><u>'+parentschedulefilterval+'</u></strong></a><span style="font-size: 18px;"> </span><strong style="font-size: 18px;">on '+startdateparentval+'</strong></p>';
            } 
            mheeNotifParenticationObj.parentNotification = meetingNotification;
            mheeNotifParenticationObj.childNotificationList = childNotList;
            
            mheeNotifParenticationlst.add(mheeNotifParenticationObj);
            if(parentNotificationList.get(strMonth)!=null){
                parentNotificationList.remove(strMonth);
                parentNotificationList.put(strMonth, mheeNotifParenticationlst);
            }else{
                parentNotificationList.put(strMonth, mheeNotifParenticationlst);
            }
        }
        mheeNotWrapperObj.parentNotificationList = parentNotificationList;
        return mheeNotWrapperObj;
    }
    
    @TestVisible static String getDuration(Datetime createdDate){
        String timeval = '';
        if(createdDate.date() == System.today()){
            DateTime dtm = System.Now();
            dtm = dtm.addHours(-createdDate.hourGmt());
            if (Integer.valueOf(dtm.hourGmt()) == 0) {
                DateTime gtmv = System.now();
                gtmv = gtmv.addMinutes(-createdDate.minuteGmt());
                if (Integer.valueOf(gtmv.minuteGmt()) == 0) {
                    timeval = 'Just Now';
                }else{
                    timeval = String.valueOf(gtmv.minuteGmt());
                    timeval += ' Minutes ago';
                }
            } else if (Integer.valueOf(dtm.hourGmt()) == 1) {
                timeval = String.valueOf(dtm.hourGmt());
                timeval += ' hour ago';
            } else {
                timeval = String.valueOf(dtm.hourGmt());
                timeval += ' hours ago';
            }
         
        }else {
            timeval = createdDate.format('EEEE') +', '+createdDate.format('MMMM')+' '+createdDate.format('dd')+', '+createdDate.format('YYYY')+' at '+createdDate.format('hh')+':'+createdDate.format('mm')+' '+createdDate.format('aa'); 
        }
        return timeval;
    }
    /**
     * @description mainrec
    */
    public class mainrec{
        /**
     * @description activity
     * @return activity
     */
        @AuraEnabled
        public String activity {get;set;}
         /**
     * @description dateval
     * @return dateval
     */
        @AuraEnabled
        public String dateval {get;set;}
         /**
     * @description meetid
     * @return meetid
     */
        @AuraEnabled
        public String meetid {get;set;}
          /**
     * @description grouprec
     * @return grouprec
     */
        @AuraEnabled
        public groupedrecwrap grouprec {get;set;}
    }

    /**
     * @description groupedrecwrap
    */
    public class groupedrecwrap{
        @AuraEnabled
            /**
     * @description notiwrap
     * @return notiwrap
     */
        public List<notificationwrap> notiwrap {get;set;}
    }

    /**
     * @description notificationwrap
    */
    public class notificationwrap{
             /**
     * @description activityID
     * @return activityID
     */
        @AuraEnabled
        public String activityID {get;set;}
              /**
     * @description activity
     * @return activity
     */
        @AuraEnabled
        public String activity {get;set;}
              /**
     * @description dateval
     * @return dateval
     */
        @AuraEnabled
        public String dateval {get;set;}
              /**
     * @description resid
     * @return resid
     */
        @AuraEnabled
        public String resid {get;set;}
              /**
     * @description read
     * @return read
     */
        @AuraEnabled
        public Boolean read {get;set;}
              /**
     * @description groupact
     * @return groupact
     */
        @AuraEnabled
        public String groupact {get;set;}
              /**
     * @description isMultipleMeeting
     * @return isMultipleMeeting
     */
        @AuraEnabled
        public Boolean isMultipleMeeting {get;set;}
              /**
     * @description multipleMeetingCount
     * @return multipleMeetingCount
     */
        @AuraEnabled
        public String multipleMeetingCount {get;set;}
              /**
     * @description createddate
     * @return createddate
     */
         @AuraEnabled
        public datetime createddate {get;set;}
    }

     /**
     * @description notificationwrapgroup
     */
    public class notificationwrapgroup{
        /**
     * @description mainrec
     * @return mainrec
     */
        @AuraEnabled
        public notificationwrap mainrec {get;set;}
        /**
     * @description grouprec
     * @return grouprec
     */
        @AuraEnabled
        public List<notificationwrap> grouprec {get;set;}
    }

     /**
     * @description prodlst
     */
    public class prodlst{
        /**
     * @description prodid
     * @return prodid
     */
        @AuraEnabled
        public String prodid {get;set;}
        /**
     * @description notifi_id
     * @return notifi_id
     */
        @AuraEnabled
        public String notifi_id {get;set;}
        /**
     * @description prodname
     * @return prodname
     */
        @AuraEnabled
        public String prodname {get;set;}
        /**
     * @description proddesc
     * @return proddesc
     */
        @AuraEnabled
        public String proddesc {get;set;}
        /**
     * @description proddos
     * @return proddos
     */
        @AuraEnabled
        public String proddos {get;set;}
        /**
     * @description prodgen
     * @return prodgen
     */
        @AuraEnabled
        public String prodgen {get;set;}
        /**
     * @description total
     * @return total
     */
        @AuraEnabled
        public Decimal total {get;set;}
        /**
     * @description aggresult
     * @return aggresult
     */
        @AuraEnabled
        public List<AggregateResult> aggresult {get;set;}
         /**
     * @description prodpilink
     * @return prodpilink
     */
        @AuraEnabled
        public String prodpilink {get;set;}
    }

     /**
     * @description noticount
    */
    public class noticount{
        /**
     * @description saved
     * @return saved
     */
        @AuraEnabled
        public Integer saved{get;set;}
        /**
     * @description appointment
     * @return appointment
     */
        @AuraEnabled
        public Integer appointment{get;set;}
        /**
     * @description closed
     * @return closed
     */
        @AuraEnabled
        public Integer closed{get;set;}
        /**
     * @description total
     * @return total
     */
        @AuraEnabled
        public Integer total{get;set;}
        /**
     * @description activity
     * @return activity
     */
        @AuraEnabled
        public Integer activity{get;set;}
    }

      /**
       * @description NotificationWrapper
       */
    public class NotificationWrapper {
        /**
     * @description totalNotificationRecord
     * @return totalNotificationRecord
     */
        @AuraEnabled
        public Integer totalNotificationRecord { get; set; }
        /**
     * @description notificationList
     * @return notificationList
     */
        @AuraEnabled
        public Map<String,List<notificationwrap>> notificationList { get; set; }
    }
    /**
     * @description MheeNotificationWrapper
     */
    public class MheeNotificationWrapper{
        /**
     * @description totalParentNotificationCount
     * @return totalParentNotificationCount
     */
        @AuraEnabled
        public Integer totalParentNotificationCount { get; set; }
        /**
     * @description parentNotificationList
     * @return parentNotificationList
     */
        @AuraEnabled
        public Map<String,List<MheeNotifParenticationWrapper>> parentNotificationList {get;set;}
    }
     /**
     * @description MheeNotifParenticationWrapper
     */
    public class MheeNotifParenticationWrapper{
        /**
     * @description isChild
     * @return isChild
     */
        @AuraEnabled
        public Boolean isChild { get; set; }
        /**
     * @description childCount
     * @return childCount
     */
        @AuraEnabled
        public String childCount { get; set; }
        /**
     * @description isRead
     * @return isRead
     */
        @AuraEnabled
        public Boolean isRead { get; set; }
        /**
     * @description duration
     * @return duration
     */
        @AuraEnabled
        public String duration { get; set; }
        /**
     * @description parentNotification
     * @return parentNotification
     */
        @AuraEnabled
        public MSD_CORE_Notification__c parentNotification {get;set;}
        /**
     * @description childNotificationList
     * @return childNotificationList
     */
        @AuraEnabled
        public List<MheeChildNotifictionWrapper> childNotificationList {get;set;}
    }
    /**
     * @description MheeChildNotifictionWrapper
     */
    public class MheeChildNotifictionWrapper{
/**
     * @description duration
     * @return duration
     */
        @AuraEnabled
        public String duration { get; set; }
        /**
     * @description childNotification
     * @return childNotification
     */
        @AuraEnabled
        public MSD_CORE_Notification__c childNotification { get; set; }
    }


}