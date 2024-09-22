/*
 * MSD_CORE_InboundSocialPostHandlerImpl
 * Created by: David Helmer
 * Created Date: July 30th, 2015
 * Last Modified Date: July 30th, 2015
 * Description: Handler that takes inbound Social Posts (from Social Studio) and creates
 *              Interactions, Personas, and Person Accounts.
 *              It is a modification of the following class and is a key part of the 
 *              Social Studio to SFDC integration:
 *              https://help.salesforce.com/HTViewHelpDoc?id=social_customer_service_apexclass_ref.htm
 */

global virtual class MSD_CORE_InboundSocialPostHandlerImpl implements Social.InboundSocialPostHandler {
    final static Integer CONTENT_MAX_LENGTH = 32000;

    private static final Service_Cloud_Settings_MVN__c serviceCloudSettings = Service_Cloud_Settings_MVN__c.getInstance();

    global Social.InboundSocialPostResult handleInboundSocialPost(SocialPost post, SocialPersona persona, Map<String, Object> rawData) {
        Social.InboundSocialPostResult result = new Social.InboundSocialPostResult();

        Savepoint sp = Database.setSavepoint();
        try {
            result.setSuccess(true);
            matchPost(post);
            matchPersona(persona);

            if ((post.Content != null) && (post.Content.length() > CONTENT_MAX_LENGTH)) {
                post.Content = post.Content.abbreviate(CONTENT_MAX_LENGTH);
            }

            if (post.Id != null) {
                handleExistingPost(post, persona);
                return result;
            }

            setReplyTo(post, persona);
            buildPersona(persona);
            Case parentCase = createCase(post, persona);
            
            setRelationshipsOnPost(post, persona, parentCase);

            upsert post;
        } catch(Exception e){
            Database.rollback(sp);
            System.debug('Error handling inbound social post: ' + e.getMessage());
            throw e;
        }

        return result;
    }

    private void handleExistingPost(SocialPost post, SocialPersona persona) {
        update post;
        if (persona.Id != null){
            updatePersona(persona);
        }
    }

    private void setReplyTo(SocialPost post, SocialPersona persona) {
        SocialPost replyTo = findReplyTo(post, persona);
        if(replyTo.Id != null) {
            post.ReplyToId = replyTo.Id;
            post.ReplyTo = replyTo;
        }
    }

    private SocialPersona buildPersona(SocialPersona persona) {
        if (persona.Id == null){
            createPersona(persona);
        }
        else{
            updatePersona(persona);
        }
        return persona;
    }
    
    private void updatePersona(SocialPersona persona) {
        try {
            update persona;
        }catch(Exception e) {
            System.debug('Error updating social persona: ' + e.getMessage());
        }
    }

    private void setRelationshipsOnPost(SocialPost postToUpdate, SocialPersona persona, Case parentCase) {
        if (persona.Id != null){
            postToUpdate.PersonaId = persona.Id;
        }
        if(parentCase.Id != null){
            postToUpdate.ParentId = parentCase.Id;
        }
    }

    private Case createCase(SocialPost post, SocialPersona persona) {
        Case newCase = new Case(subject = post.Name);
        String notes = '';
        String personaName = '';
        if (persona != null && persona.ParentId != null) {
            if (persona.ParentId.getSObjectType() == Account.sObjectType){
                newCase.AccountId = persona.ParentId;
            }

            personaName = persona.RealName + ' (' + persona.Name + ')';
        }
        if (post != null) {
            if(post.Provider != null){
                if(post.Provider != serviceCloudSettings.MSD_CORE_Social_Facebook_Provider__c
                    && post.Provider != serviceCloudSettings.MSD_CORE_Social_Twitter_Provider__c){
                    newCase.Origin = serviceCloudSettings.MSD_CORE_Social_Other_Origin__c;
                } else {
                    newCase.Origin = post.Provider;    
                }
                
                MSD_CORE_Source__c source = getSourceByExternalId(newCase.Origin);
                if(source != null){
                    newCase.MSD_CORE_Source__c = source.Id;
                    newCase.MSD_CORE_Country_Code__c = source.MSD_CORE_Country_Code__c;
                }  
            }

            notes += post.MessageType + ' from ';
            if(personaName != null && personaName != ''){
                notes += personaName + ' on ';
            }
            notes += newCase.Origin;
            if(post.ReplyTo != null && post.ReplyTo.PersonaId != null){
                SocialPersona replyToPersona = [SELECT Id, 
                                                       RealName, 
                                                       Name 
                                                  FROM SocialPersona 
                                                 WHERE Id = :post.ReplyTo.PersonaId];
                notes += '\n' + Label.MSD_CORE_In_Reply_To + ': ' + replyToPersona.RealName + ' (' + replyToPersona.Name + ')';
            }
            notes += '\n\n' + post.Content + '\n\n' + Label.MSD_CORE_Post_URL + ':\n' + post.PostUrl;
        }
        newCase.Interaction_Notes_MVN__c = notes;
        insert newCase;
        return newCase;
    }

    private void matchPost(SocialPost post) {
        if (post == null || post.Id != null) {
            return;
        }
        
        performR6PostIdCheck(post);
        
        if (post.Id == null){
            performExternalPostIdCheck(post);
        }
    }
    
    private void performR6PostIdCheck(SocialPost post){
        if(post.R6PostId == null) {
            return;
        }
        List<SocialPost> postList = [SELECT Id FROM SocialPost WHERE R6PostId = :post.R6PostId LIMIT 1];
        if (!postList.isEmpty()) {
            post.Id = postList[0].Id;
        }
    }
    
    private void performExternalPostIdCheck(SocialPost post) {
        if (post.Provider == serviceCloudSettings.MSD_CORE_Social_Facebook_Provider__c 
            && post.messageType == serviceCloudSettings.MSD_CORE_Social_Private_Message_Type__c) {
            return;
        }
        if (post.Provider == null || post.externalPostId == null) {
            return;
        } 
        List<SocialPost> postList = [SELECT Id FROM SocialPost WHERE ExternalPostId = :post.ExternalPostId AND Provider = :post.Provider LIMIT 1];
        if (!postList.isEmpty()) {
            post.Id = postList[0].Id;
        }
    }
    
    private SocialPost findReplyTo(SocialPost post, SocialPersona persona) {
        if(post.ReplyToId != null && post.ReplyTo == null){
            return findReplyToBasedOnReplyToId(post);
        }
        if(post.ResponseContextExternalId != null){
            return findReplyToBasedOnExternalPostIdAndProvider(post, post.ResponseContextExternalId);
        }
        return new SocialPost();
    }

    private SocialPost findReplyToBasedOnReplyToId(SocialPost post){
        List<SocialPost> posts = [SELECT Id, ParentId, IsOutbound, PersonaId FROM SocialPost WHERE id = :post.ReplyToId LIMIT 1];
        if(posts.isEmpty()){
            return new SocialPost();
        }
        return posts[0];
    }

    private SocialPost findReplyToBasedOnExternalPostIdAndProvider(SocialPost post, String externalPostId){
        List<SocialPost> posts = [SELECT Id, ParentId, IsOutbound, PersonaId FROM SocialPost WHERE Provider = :post.Provider AND ExternalPostId = :externalPostId LIMIT 1];
        if(posts.isEmpty()){
            return new SocialPost();
        }
        return posts[0];
    }

    private void matchPersona(SocialPersona persona) {
        if (persona != null) {
            List<SocialPersona> personaList = new List<SocialPersona>();
            if(persona.Provider != serviceCloudSettings.MSD_CORE_Social_Other_Provider__c && String.isNotBlank(persona.ExternalId)) {
                personaList = [SELECT Id, ParentId FROM SocialPersona WHERE
                    Provider = :persona.Provider AND
                    ExternalId = :persona.ExternalId LIMIT 1];
            } else if(persona.Provider == serviceCloudSettings.MSD_CORE_Social_Other_Provider__c && String.isNotBlank(persona.ExternalId) && String.isNotBlank(persona.MediaProvider)) {
                personaList = [SELECT Id, ParentId FROM SocialPersona WHERE
                    MediaProvider = :persona.MediaProvider AND
                    ExternalId = :persona.ExternalId LIMIT 1];
            } else if(persona.Provider == serviceCloudSettings.MSD_CORE_Social_Other_Provider__c && String.isNotBlank(persona.Name) && String.isNotBlank(persona.MediaProvider)) {
                personaList = [SELECT Id, ParentId FROM SocialPersona WHERE
                    MediaProvider = :persona.MediaProvider AND
                    Name = :persona.Name LIMIT 1];
            }
                    
            if (!personaList.isEmpty()) {
                persona.Id = personaList[0].Id;
                persona.ParentId = personaList[0].ParentId;
            }
        }
    }

    private void createPersona(SocialPersona persona) {
        if (persona == null || String.isNotBlank(persona.Id) || !isThereEnoughInformationToCreatePersona(persona)){
            return;
        }

        SObject parent = createPersonaParent(persona);
        persona.ParentId = parent.Id;
        insert persona;
    }

    private boolean isThereEnoughInformationToCreatePersona(SocialPersona persona) {
        return String.isNotBlank(persona.Name) && 
               String.isNotBlank(persona.Provider) && 
               String.isNotBlank(persona.MediaProvider);
    }

    global virtual SObject createPersonaParent(SocialPersona persona) {
        String name = persona.Name.trim();

        String firstName = '';
        String lastName = name;

        firstName = firstName.abbreviate(19);
        lastName = lastName.abbreviate(60);

        return createPersonaAccount(lastName, firstName, persona.Provider);
    }

    private Account createPersonaAccount(String lastName, String firstName, String provider){
        String classType = serviceCloudSettings.MSD_CORE_Consumer_Type__c;
        String activeStatus = serviceCloudSettings.MSD_CORE_Account_Status_Active__c;
        String consumerRecordTypeDeveloperName = (String)serviceCloudSettings.Consumer_Record_Type_MVN__c;
        Id consumerRecordTypeId = [SELECT Id
                                     FROM RecordType
                                    WHERE DeveloperName = :consumerRecordTypeDeveloperName].Id;
        Account account = new Account(
            LastName = lastName, 
            FirstName = firstName,
            Preferred_Last_Name_MRK__c = lastName,
            Preferred_First_Name_MRK__c = firstName,
            Class_Of_Trade_MRK__c = classType,
            Class_Of_Trade_Sub_MRK__c = classType,
            RecordTypeId = consumerRecordTypeId,
            Status_MRK__c = activeStatus);

        MSD_CORE_Source__c source = null;
        if(provider != serviceCloudSettings.MSD_CORE_Social_Facebook_Provider__c
            && provider != serviceCloudSettings.MSD_CORE_Social_Twitter_Provider__c){
            source = getSourceByExternalId(serviceCloudSettings.MSD_CORE_Social_Other_Origin__c);
        }else{
            source = getSourceByExternalId(provider);
        }
        
        if(source != null){
            account.MSD_CORE_Country_Code__c = source.MSD_CORE_Country_Code__c;
        }        

        insert account;
        return account;
    }

    private MSD_CORE_Source__c getSourceByExternalId(String externalId){
        List<MSD_CORE_Source__c> sources = [SELECT Id, MSD_CORE_Country_Code__c 
                                                FROM MSD_CORE_Source__c 
                                                WHERE MSD_CORE_External_Id__c = :externalId
                                                AND MSD_CORE_Active__c = true];

        if(sources == null || sources.size() == 0){
            return null;
        } else {
            return sources.get(0);
        }
    }
}