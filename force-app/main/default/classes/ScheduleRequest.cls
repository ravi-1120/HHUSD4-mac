/*
    JSON Request class
    Created by -  RK Koluri
    Last Modified By - Joshi Jigyasu ------------- Last Modified Date - 25-05-2023
    Description - It is an interface class to generate a payload required by HCP component
*/

public class ScheduleRequest{
    
    public String name;
    public String id;
    public UICss uiCss;
    public Templates[] templates;
    public Products[] products;
    public CommunicateModes[] communicationModes;
    public BusinessHoursNew[] businessHours;
    public List<ProfessionalDesignation> professionalDesignation;
    public List<AssignmentGroups> assignmentGroups;
    public List<HolidaysByGroup> holidaysByGroup;
    
    @AuraEnabled
    public static ScheduleRequest createScheduleRequest() {
        ScheduleRequest sObj =  new ScheduleRequest();
        sObj.name = '';
        return sObj;
    }

    public class UICss {
        public String bgColor;  //green
        public String fgColor;  //green
    }

    public class Templates {
        public String label;    //Efficacy and trial information on FDA approved indications
        public boolean isSchedulable;  
        public Integer order;
        public String value;
        public String templateMessage;
        public boolean conveyTumor;
    }

    public class Products {
        public String label;    //Efficacy and trial information on FDA approved indications
        public Integer order;
        public String value; //to store product Payor Id
        public String parentID;//to store product Catalog Id
        public String[] inquiryTypes;
        public boolean isBlackBox;
        public String additionalInformation;
        public ProductAcessInquiry productAcessInquiry;
    }

    public class ProductAcessInquiry {
        public String header;    
        public String body;   
        public String footer;
    }

    public class CommunicateModes {
        public String label;    //Call Me Now
        public String value;   // true or fale
        public String message;
    }

    public class OperatingHours {
        public String startTime;    //8:00 AM
        public String endTime;  //8:00 PM
        public String weekName; //Monday, Tuesday etc
    }

    public class BusinessHoursNew {
        public OperatingHours [] operatingHours;    
        public String operatingHoursMessage;  
        public String OutsideOperatingHoursMessage; 
        public String groupName;
        public String groupId;
    }
    
    public class BusinessHours {
        public String startTime;    //8:00 AM
        public String endTime;  //8:00 PM
        public String weekName; //Monday, Tuesday etc
    }

    public class AssignmentGroups {
        public String groupName;
        public String groupId;
        public List<String> professionalDesignation;
        public List<String> appointmentTemplate;
        public List<RoutingGroup> routingGroup;
        public List<BusinessHours> businessHours;
    }

    public class ProfessionalDesignation {
        public String label;
        public String value;
        public Integer order;
    }

    public class RoutingGroup {
		public String appointmentTemplate;
		public List<String> professionalDesignation;
        public List<String> product;
	}

    public class HolidaysByGroup {
        public String groupName;
        public String groupId;
        public List<String> holidays;
    }

    public static ScheduleRequest parse(String json){
        return (ScheduleRequest) System.JSON.deserialize(json, ScheduleRequest.class);
    }
   
}