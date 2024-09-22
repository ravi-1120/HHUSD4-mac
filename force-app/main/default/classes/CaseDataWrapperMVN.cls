public class CaseDataWrapperMVN
{
    @AuraEnabled public Case cs {get;set;}
    @AuraEnabled public boolean isAccess {get;set;}
    @AuraEnabled public String type {get;set;}
    
    public CaseDataWrapperMVN(Case cs, String type, boolean isAccess)
    {
        this.cs = cs;
        this.type = type;
        this.isAccess = isAccess;
    }
}