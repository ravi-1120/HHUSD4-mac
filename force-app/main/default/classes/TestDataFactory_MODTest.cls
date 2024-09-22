@isTest
public class TestDataFactory_MODTest {
    @isTest public static List<Appointment_Template__c> testCreateAppointments(){
        List<Appointment_Template__c> appointments = new List<Appointment_Template__c>();
        List<String> aNames = new List<String>{
            'Clinical Study Information',
            'General Adverse Event Management',
            'Other',
            'Patient Education',
            'Product Access Inquiries: Coverage and Reimbursement; Coding and Billing'
        };
        
        for(String aName : aNames){
            Appointment_Template__c aObj = new Appointment_Template__c(Name = aName,IsActive__c = true,
                IsSchedulable__c = true, Convey_Tumor__c = true
            );
            appointments.add(aObj); 
        }
        insert appointments;
        return appointments;
    }
	 @isTest public static Product_vod__c testCreateProduct(){
        Product_vod__c product = new Product_vod__c(Name = 'Test Product',
            Is_Schedulable__c = true, Is_Blacbox_Product__c = true,
            Product_Thumbnail_vod__c = 'test balckbox message', Product_Message_Header__c = 'test header message',
            Product_Message_Body__c = 'test body', Product_Message_Footer__c = 'test footer message'
            );
        
        insert product;
        return product;
    }

    @isTest public static MSD_CORE_Product_Payor__c testCreateProduct2(){
        Product_vod__c prod = testCreateProduct();

        MSD_CORE_Product_Payor__c product2 = new MSD_CORE_Product_Payor__c(Name = 'Test ProductPayor', 
            Is_Blackbox_Product__c = true, Product_Message_Header__c = 'test header message',
            Product_Message_Body__c = 'test body', Product_Message_Footer__c = 'test footer message',
            Related_System__c = 'AskMerck', MSD_CORE_Colourcode__c = '1234', MSD_CORE_Product_Catalog__c = prod.Id
            );

        insert product2;
        return product2;
    }

    @isTest public static Operating_Hours__c testCreateBusinessHours(){
        Operating_Hours__c ohObj = new Operating_Hours__c(
            Name = 'US Business Hours',
            Time_Zone__c = 'America/Los_Angeles'
        );
        insert ohObj;
        List<Time_Slots__c> tsList = new List<Time_Slots__c>();
        List<String> weeks = new List<String>{
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday'
        };
        for(String wName : weeks){
            Time startTime = Time.newInstance(8, 0, 0, 0);
            Time endTime = Time.newInstance(20, 0, 0, 0);
            Time_Slots__c tsObj = new Time_Slots__c(
                Day_of_Week__c = wName,
                Start_Time__c = startTime,
                End_Time__c = endTime,
                Operating_Hours__c = ohObj.id
            ); 
            tsList.add(tsObj);
        }
        insert tsList;
        return ohObj;
    }

    @isTest public static List<Scheduling_Groups__c> testCreateGroups(){
        List<Scheduling_Groups__c> groups = new List<Scheduling_Groups__c>();
        List<String> groupNames = new List<String>{
            'OREG','NE'
        };
        Operating_Hours__c oh = new Operating_Hours__c();
        oh.Name = 'test Operating Hours';
        insert oh;
        for(String gName : groupNames){
            Scheduling_Groups__c gObj = new Scheduling_Groups__c(
                Name = gName,
                IsActive__c = true,
                Operating_Hours__c = oh.Id
            );
            groups.add(gObj);
        }
        insert groups;
        return groups;
    }

    @isTest public static List<Holidays__c> testCreateHolidays(){
        List<Holidays__c> holidays = new List<Holidays__c>();
        List<String> hNames = new List<String>{
            'Thanksgiving','Christmas'
        };
        for(String hName : hNames){
            Holidays__c hObj = new Holidays__c(
                Name = hName,
                Date__c = Date.today()
            );
            holidays.add(hObj);
        }
        insert holidays;
        return holidays;
    }
    
    @isTest public static Event testCreateEvent(){
        Appointment_Template__c appTemplate = testCreateAppointmentTemplate();
        List<Scheduling_Groups__c> schedulingGroups = testCreateGroups();
        Product_vod__c product = testCreateProduct();
        Event evt = new Event();
        evt.Subject = 'test';
        evt.Schedule_Status__c = 'Scheduled';
        evt.StartDateTime = DateTime.now();
       // evt.EndDate = DateTime.now().addMinutes(15);
       evt.DurationInMinutes = 15;
        evt.Communication_Mode__c = 'Schedule a callback';
        evt.Scheduling_Group__c = schedulingGroups[0].Id;
        evt.Appointment_Template__c = appTemplate.Id;
        evt.Professional_Designation__c = 'MD';
        evt.Tumor_Indication__c = 'lungs';
        evt.First_Name__c = 'Test first name';
        evt.Last_Name__c = 'Test last name';
        evt.Extension__c = '44';
        evt.Phone__c = '1234567890'; 
        evt.Product_Enquiry__c = product.Id;
        evt.Email__c = 'test@example.com';
        insert evt;
        return evt;
    }
    
    @isTest public static Appointment_Template__c testCreateAppointmentTemplate(){
        Appointment_Template__c appTemplate = new Appointment_Template__c(Name = 'Clinical Study Information',IsActive__c = true);
         return appTemplate;
    }
    
    @isTest public static Map<String, Object> schedulerSaveResponseTest(){
        Map<String, Object> scheduleDetails = new Map<String, Object> ();
        Event evt = testCreateEvent();
        scheduleDetails.put('templateLabel',evt.Subject);
        scheduleDetails.put('isCallMeNow',false);
        scheduleDetails.put('localDateValue','Mon Apr 25 2022 17:30:00 GMT+0530 (India Standard Time)');
        scheduleDetails.put('localHour',17);
        scheduleDetails.put('localMinute',30);
        scheduleDetails.put('dateValue','2022-04-25');
        scheduleDetails.put('timeSlotValue','08:00:00');
        scheduleDetails.put('communicationMode',evt.Communication_Mode__c);
        scheduleDetails.put('templateId',evt.Appointment_Template__c);
        scheduleDetails.put('schedulingGroupId',evt.Scheduling_Group__c);
        scheduleDetails.put('schedulingGroup','OREG');
        scheduleDetails.put('professionalDesignation',evt.Professional_Designation__c);
        scheduleDetails.put('tumorIndication',evt.Tumor_Indication__c);
        scheduleDetails.put('FirstName',evt.First_Name__c);
        scheduleDetails.put('LastName',evt.Last_Name__c);
        scheduleDetails.put('Phone',evt.Phone__c);
        scheduleDetails.put('Extension',evt.Extension__c);
        scheduleDetails.put('Email',evt.Email__c);
        scheduleDetails.put('schedulerOwner',userInfo.getUserId());
        scheduleDetails.put('productEnquiryValue',evt.Product_Enquiry__c);
        scheduleDetails.put('productEnquiry','test');
        scheduleDetails.put('timeSlotLabel','8:00 AM');
        scheduleDetails.put('dateLabel','Monday, April 25');
        scheduleDetails.put('productParent','test');
        return scheduleDetails;
    }
    
        @isTest public static Map<String, Object> schedulerSaveResponseTest1(){
        Map<String, Object> scheduleDetails = new Map<String, Object> ();
        Event evt = testCreateEvent();
        scheduleDetails.put('templateLabel',evt.Subject);
        scheduleDetails.put('isCallMeNow',true);
        scheduleDetails.put('localDateValue','Mon Apr 25 2022 17:30:00 GMT+0530 (India Standard Time)');
        scheduleDetails.put('localHour',17);
        scheduleDetails.put('localMinute',30);
        scheduleDetails.put('dateValue','2022-04-25');
        scheduleDetails.put('timeSlotValue','08:00:00');
		scheduleDetails.put('currESTDate','2022-04-25');
		scheduleDetails.put('currESTTime','08:00:00');
        scheduleDetails.put('communicationMode','Call me now');
        scheduleDetails.put('templateId',evt.Appointment_Template__c);
        scheduleDetails.put('schedulingGroupId',evt.Scheduling_Group__c);
		scheduleDetails.put('schedulingGroup','OREG');
        scheduleDetails.put('professionalDesignation',evt.Professional_Designation__c);
        scheduleDetails.put('tumorIndication',evt.Tumor_Indication__c);
        scheduleDetails.put('FirstName',evt.First_Name__c);
        scheduleDetails.put('LastName',evt.Last_Name__c);
        scheduleDetails.put('Phone',evt.Phone__c);
        scheduleDetails.put('Extension',evt.Extension__c);
        scheduleDetails.put('Email',evt.Email__c);
        scheduleDetails.put('schedulerOwner',userInfo.getUserId()); 
        scheduleDetails.put('productEnquiryValue',evt.Product_Enquiry__c);
        scheduleDetails.put('productEnquiry','test');
		scheduleDetails.put('timeSlotLabel','8:00 AM');
		scheduleDetails.put('dateLabel','Monday, April 25');
        return scheduleDetails;
    }
    
    @isTest public static Scheduler_Configuration__c testCreateSchedulerConfig(){
        Scheduler_Configuration__c sc = new Scheduler_Configuration__c();
        sc.Name = 'AMO';
        sc.JSON_Payload__c = '{"Name":"AMO"}';
        insert sc;
        return sc;
    }
    
    @isTest public static EmailTemplate testCreateEmailTemplate(){
        EmailTemplate et = new EmailTemplate ();
        et.DeveloperName = 'MOD_Schedule_Call_Back_V2';
        et.Body = 'test';
        et.HtmlValue = 'test {!Event.StartDateTime} {!Event.Subject}';
        et.IsActive = true;
        et.Name = 'MOD Schedule Call Back V2';
        et.Encoding = 'Unicode (UTF-8)';
        et.TemplateStyle = 'newsletter';
        et.TemplateType = 'html';
        //et.FolderId = '101';
        //insert et;
        return et;
    }
    
    @isTest public static Group_Holidays__c testCreateGroupHolidays(){
        List<Scheduling_Groups__c>grp = testCreateGroups();
       	List<Holidays__c> hday = testCreateHolidays();
       	Group_Holidays__c gh = new Group_Holidays__c();
        gh.Scheduling_Group__c = grp[0].Id;
        gh.Holiday__c = hday[0].Id;
        insert gh;
        return gh;
    }
    
   
   
    @isTest public static Scheduler_Configuration__c testCreateSchedulerMapping(){
        Map<String,List<Object>> jsonMap = new Map<String,List<Object>>();
        List<Appointment_Template__c> templates = testCreateAppointments();
        List<Object> temlatesObjList = new List<Object>();
        Map<String,Object> templatesObj = new Map<String,Object>();
        templatesObj.put('value',templates[0].Id);
        templatesObj.put('order',1);
        templatesObj.put('label',templates[0].Name);
        templatesObj.put('isSchedulable',templates[0].IsSchedulable__c);
        templatesObj.put('conveyTumor',templates[0].Convey_Tumor__c);
        temlatesObjList.add(templatesObj);
        jsonMap.put('templates',temlatesObjList);
        Product_vod__c prod = testCreateProduct();
        MSD_CORE_Product_Payor__c prod2 = testCreateProduct2();
        List<Object> productsObjList = new List<Object>();
        Map<String,Object> productsObj = new Map<String,Object>();
        productsObj.put('value',prod2.Id);
        productsObj.put('parentID',prod.Id);
        productsObj.put('order',1);
        productsObj.put('label',prod2.Name);
        productsObj.put('isBlackBox',prod2.Is_Blackbox_Product__c);
       // productsObj.put('productAcessInquiry',new Map<String,Object>{'header'=>'test header','footer'=>'test footer','body'=>'test body'});
       // productsObj.put('inquiryTypes',new List<String>{'Clinical Study Information','Product question'});
        productsObjList.add(productsObj);
        Map<String,String> jsonMapString = new Map<String,String>();
        jsonMap.put('products',productsObjList);
        jsonMapString.put('name','test AMO');
        jsonMapString.put('id','101test');
        jsonMapString.put('uiCss',String.valueOf(new Map<String,Object>{'bgColor'=>'green','fgColor'=>'green'}));
        Map<String,String> communicationMode = new Map<String, String>{'label'=>'Call me now','value'=>'Call me now'};
            List<Object> communicationModeObj = new List<Object>();
        communicationModeObj.add(communicationMode);
            jsonMap.put('communicationModes',communicationModeObj);
        jsonMapString.put('businessHours',String.valueOf(new Map<String,Object> {'groupName'=>'OREG','groupId'=>'101Oreg'}));
        jsonMapString.put('holidaysByGroup',String.valueOf(new Map<String,Object> {'groupName'=>'OREG','groupId'=>'101OregH','holidays'=>new List<String>{String.valueOf(Date.today())}}));
        jsonMap.put('professionalDesignation',new List<String>{'MD','DO'});
        
        Scheduler_Configuration__c sc = new Scheduler_Configuration__c();
        String jsonString = String.valueOf(jsonMap) + String.valueOf(jsonMapString);
        System.debug('jsonString-->');
        System.debug(jsonString);
        jsonString+='"assignmentGroups" : [ ]';
        jsonString = '{ "uiCss" : { }, "templates" : [ { "value" : "a7z8F00000001JeQAI", "order" : 1, "label" : "Clinical Study Information", "isSchedulable" : true, "conveyTumor" : true } ], "professionalDesignation" : [ { "value" : "MD", "order" : 1, "label" : "MD" }, { "value" : "DO", "order" : 2, "label" : "DO" } ], "products" : [ { "value" : "a008F000000zEivQAE", "productAcessInquiry" : { "header" : "The Merck Access Program for information", "footer" : "To report an Adverse Event", "body" : "For Product Access Inquiries" }, "order" : 1, "label" : "KEYTRUDA® (pembrolizumab)", "isBlackBox" : false, "inquiryTypes" : [ "Clinical Study Information" ] } ], "name" : "1708", "id" : "a838F000000CbjtQAC", "holidaysByGroup" : [ { "holidays" : [ "2022-01-01"], "groupName" : "OREG", "groupId" : "a868F0000000GqFQAU" }, { "holidays" : [ "2022-05-02" ], "groupName" : "NE", "groupId" : "a868F0000000GqGQAU" }  ], "communicationModes" : [ { "value" : "Call me now", "message" : "Merck Associates are available Mon-Fri, 8am-8pm ET.", "label" : "Call me now" }, { "value" : "Schedule a callback", "label" : "Schedule a callback" } ], "businessHours" : [ { "OutsideOperatingHoursMessage" : "Merck Associates are not available at this time. Please try again Mon-Fri, 8am-8pm ET.", "operatingHoursMessage" : "Merck Associates are available Mon-Fri, 8am-8pm ET.", "operatingHours" : [ { "weekName" : "Thursday", "startTime" : "8:00 AM", "endTime" : "8:00 PM" } ], "groupName" : "OREG", "groupId" : "a868F0000000GqFQAU" } ], "assignmentGroups":[{"routingGroup":[{"appointmentTemplate":"Clinical Study Information","profesionalDesgination":["MD","DO"],"product":["KEYTRUDA® (pembrolizumab)"]}],"groupName":"OREG","groupId":"a868F0000000GqFQAU"}],"statusCode":1000,"statusDescription":"Success" }';
        sc.Name = 'test AMO'; 
        sc.JSON_Payload__c = jsonString;
        insert sc;
        return sc;
    }


}