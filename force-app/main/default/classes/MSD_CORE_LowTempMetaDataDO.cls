public class MSD_CORE_LowTempMetaDataDO {
    
   //Values Pulled from Object: 
   public String userProduct = ''; //from User Input, used to query data
   
   //NOTE MAKE THESE ALL REQUIRED IN THE OBJECT in SALESFORCE (Trigger in Insert and Update)
   //LTT_ = Low Temp Table            //<Spreadsheet Name//<Column>//<Data Type in SS>
   public String LTT_SupportedLowMinC  = ''; //Supported Low Min C //C //Text and number
   public String LTT_SupportedLowMinF  = ''; //Supported Low Min F //D //Text and number 
   public String LTT_SupportedLowMaxC = ''; //Supported Low Max C //E //Text and number
   public String LTT_SupportedLowMaxF = ''; //Supported Low Max F //F //Text and number
   public String LTT_LabeledTempRangeMinC = '';  //Labeled Temp Range Min C //G //Number - used only for Storage label
   public String LTT_LabeledTempRangeMinF  = ''; //Labeled Temp Range Min F //H //Number - used only for Storage label
   public String LTT_LabeledTempRangeMaxC  = ''; //Labeled Temp Range Max C //I //Number - used only for Storage label
   public String LTT_LabeledTempRangeMaxF  = ''; //Labeled Temp Range Max F //J //Number - used only for Storage label
   public String LTT_Time = ''; //Time //K //Text and Number
   public String LTT_UnitsOfTime = ''; //Units of time //L //Text
   public String LTT_NumberOfHours = ''; //Number of hours //M //Text and Number
   public String LTT_NumberOfCycles = ''; //Number of Cycles //N //Text and Number
   public String LTT_SecondLabelRangeTempMinC = '';    //Second Label Range Temp Min C //O //Text and Number - used only for Storage label
   public String LTT_SecondLabelRangeTempMinF = ''; //Second Label Range Temp Min F //P //Text and Number - used only for Storage label
   public String LTT_SecondLabelRangeTempMaxC = ''; // Second Label Range Temp Max C //Q //Text and Number - used only for Storage label
   public String LTT_SecondLabelRangeTempMaxF = '';  //Second Label Range Temp Max F //R //Text and Number - used only for Storage label
   public String LTT_UnlimitedTime = ''; //Hide if Number of Cycles N/A //S //Text
   public String LTT_Comment = ''; //Comment //T //Text
   public String LTT_Category = ''; //Category //U //Number
    
   public void spoolData(){

     System.debug('//<SS Name>//<Column> //<Data Type>//<Object Field Name> : <value>');
     System.debug('//Supported Low Min C //C //Text and number//LTT_SupportedLowMinC :' + LTT_SupportedLowMinC);
     System.debug('//Supported Low Min F //D //Text and number//LTT_SupportedLowMinF :' + LTT_SupportedLowMinF); 
     System.debug('//Supported Low Max C //E //Text and number//LTT_SupportedLowMaxC: '+LTT_SupportedLowMaxC);
     System.debug('//Supported Low Max F //F //Text and number//LTT_SupportedLowMaxF: ' + LTT_SupportedLowMaxF);
     System.debug('//Labeled Temp Range Min C //G //Number//LTT_LabeledTempRangeMinC: '+ LTT_LabeledTempRangeMinC);
     System.debug('//Labeled Temp Range Min F //H //Number//LTT_LabeledTempRangeMinF: '+ LTT_LabeledTempRangeMinF);
     System.debug('//Labeled Temp Range Max C //I //Number//LTT_LabeledTempRangeMaxC: '+ LTT_LabeledTempRangeMaxC);
     System.debug('//Labeled Temp Range Max F //J //Number//LTT_LabeledTempRangeMaxF: '+ LTT_LabeledTempRangeMaxF);
     System.debug('//Time //K //Text and Number/LTT_Time: '+ LTT_Time);
     System.debug('//Units of time //L //Text//LTT_UnitsOfTime: '+ LTT_UnitsOfTime);
     System.debug('//Number of hours //M //Text and Number//LTT_NumberOfHours: '+ LTT_NumberOfHours);
     System.debug('//Number of Cycles //N //Text and Number//LTT_NumberOfCycles: '+ LTT_NumberOfCycles);
     System.debug('//Second Label Range Temp Min C //O //Text and Number//LTT_SecondLabelRangeTempMinC: '+ LTT_SecondLabelRangeTempMinC);  
     System.debug('//Second Label Range Temp Min F //P //Text and Number//LTT_SecondLabelRangeTempMinF: '+ LTT_SecondLabelRangeTempMinF);
     System.debug('//Second Label Range Temp Max C //Q //Text and Number//LTT_SecondLabelRangeTempMaxC: '+ LTT_SecondLabelRangeTempMaxC);
     System.debug('//Second Label Range Temp Max F //R //Text and Number//LTT_SecondLabelRangeTempMaxF: '+LTT_SecondLabelRangeTempMaxF);
     System.debug('//Hide if Number of Cycles N/A //S //Text//LTT_UnlimitedTime : '+ LTT_UnlimitedTime);
     System.debug('//Comment //T //Text//LTT_Comment: '+ LTT_Comment);
     System.debug('//Category //U //Number//LTT_Category: '+ LTT_Category);
   }
    
}