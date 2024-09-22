/**********************************************************************
Name:  MSD_CORE_SelectItem
======================================================
======================================================
Purpose:Controller used for MYP Product Location MultiSelect lightining 
======================================================
======================================================
History
-------
VERSION  AUTHOR            DATE              DETAIL            Description
1.0      Prasanjeet Sharma 10/21/2019        DEVELOPMENT    
***********************************************************************/

public class MSD_CORE_SelectItem {
    
    @AuraEnabled public String  label  {get; set;}
    @AuraEnabled public String  value  {get; set;}
    @AuraEnabled public Boolean  selected  {get; set;}
    
    public MSD_CORE_SelectItem( String value, String label, Boolean selected) {
        this(label,value);
        this.selected = selected;
    }
    
    public MSD_CORE_SelectItem( String value, String label) {
        this.label = label;
        this.value = value;
        this.selected = false;
    }
    
    @AuraEnabled
    public static MSD_CORE_SelectItem[] fetchOptions() {
        return new MSD_CORE_SelectItem[]{new MSD_CORE_SelectItem('Legal','Legal',false)
                                        ,new MSD_CORE_SelectItem('Pregnancy','Pregnancy',false)
                                        ,new MSD_CORE_SelectItem('Security','Security',false)
                                        ,new MSD_CORE_SelectItem('VZV','VZV',false)};
    }
}