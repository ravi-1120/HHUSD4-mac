/*
* MSD_CORE_SocialTestDataFactory
* Created By:    David Helmer
* Created Date:  8/12/2015
* Modified By:   
* Modified On:   
* Description:   This is the data factory used to generate data by test classes with social data
*/
public with sharing class MSD_CORE_SocialTestDataFactory {
	public static SocialPost initializePost(String content, String name){
        return new SocialPost(Content = content, Name = name);
    }

    public static SocialPersona initializePersona(String name, String provider, String mediaProvider){                
        return new SocialPersona(Name = name, Provider = provider, MediaProvider = mediaProvider);
    }

    public static Case initializeCase(String subject){
        return new Case(subject = subject);
    }

    public static MSD_CORE_Source__c initializeSource(String name, String externalId, String country){
        return new MSD_CORE_Source__c(
            Name = name,
            MSD_CORE_External_Id__c = externalId,
            MSD_CORE_Country_Code__c = country,
            MSD_CORE_Active__c = true);
    }
}