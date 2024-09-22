/*
* MSD_CORE_InboundSocialPostHandlerTest
* Created By:    David Helmer
* Created Date:  8/12/2015
* Modified By:   
* Modified On:   
* Description:   Test class for the MSD_CORE_InboundSocialPostHandlerImpl class
*/

@isTest
private class MSD_CORE_InboundSocialPostHandlerTest {
    private static final String ExistingContent = 'existingContent';
    private static final String Content = 'Content';

    private static final String Name = 'A post name';
    private static final String ExistingName = 'An existing post';

    private static final String AnR6PostId = 'anr6postid';

    private static final String PersonaFirstName = 'Firstname';
    private static final String PersonaLastName = 'PersonaName';      

    private static final String DefaultProfileURL = 'http://default.com';
    private static final String InsertedPersonaProfileURL = 'http://inserted.com';

    private static final String Facebook = 'Facebook';
    private static final String Twitter = 'Twitter';

    private static final String PrivateMessageType = 'Private';

    private static final String PostExternalId = 'PostExternalId';
    private static final String AnotherPostExternalId = 'AnotherPostExternalId';
    private static final String PersonaExternalId = 'PersonaExternalId';    

    private static final String PersonaMediaProvider = 'PersonaMediaProvider';
    private static final String OtherMediaProvider = 'Other';

    private static final String PersonaLastNameUnTrimmed = '  ' + PersonaLastName + ' ';
    private static final String PersonaRealName = 'ARealPersonaName';
    private static final String PersonaRealNameUnTrimmed = '     ' + PersonaRealName + '   ';    
    private static final String PersonaFirstAndLastName = PersonaFirstName + ' ' + PersonaLastName;
    private static final String LongFirstName = 'DavidDavidDavidDavidDavidDavidDavidDavidDavid';
    private static final String LongLastName = 'HelmerHelmerHelmerHelmerHelmerHelmerHelmerHelmerHelmerHelmerHelmerHelmerHelmerHelmerHelmerHelmerHelmerHelmer';
    private static final String AbbreviatedLongFirstName = 'DavidDavidDavidD...';
    private static final String AbbreviatedLongLastName = 'DavidDavidDavidDavidDavidDavidDavidDavidDavid HelmerHelme...';
    private static final String LongFullName = LongFirstName + ' ' + LongLastName;

    private static final String USCountry = 'US';

    private static final String Consumer = 'CONSUMER';


    private static final Set<String> ClassFields = new Set<String>{ 
        'Class_Of_Trade_MRK__c', 'Class_Of_Trade_Sub_MRK__c'
    };

    private static final Set<String> NameFields = new Set<String>{ 
        'FirstName', 'LastName', 'Preferred_Last_Name_MRK__c', 'Preferred_First_Name_MRK__c'
    };

    private static final Set<String> RecordTypeCheckFields = new Set<String>{
        'RecordTypeId'
    };

    private static final Set<String> HasSourceFields = new Set<String>{
        'MSD_CORE_Source__c'
    };

    private static final Set<String> CountryFields = new Set<String>{
        'MSD_CORE_Country_Code__c'
    };

    /*
     *  Given Settings
    */
    private static Service_Cloud_Settings_MVN__c givenThereAreSettings(){
        TestDataFactoryMVN.createSettings(false);
        return Service_Cloud_Settings_MVN__c.getInstance();
    }

    private static Id givenConsumerRecordTypeId(Service_Cloud_Settings_MVN__c serviceCloudSettings){
        String consumerRecordTypeDeveloperName = (String)serviceCloudSettings.Consumer_Record_Type_MVN__c;
        return [SELECT Id 
                  FROM RecordType 
                 WHERE DeveloperName = :consumerRecordTypeDeveloperName].Id;
    }

    /*
     *  Given Sources
    */
    private static MSD_CORE_Source__c givenASource(String externalId, String country){
        MSD_CORE_Source__c source = MSD_CORE_SocialTestDataFactory.initializeSource(externalId, externalId, country);
        insert source;
        return source;
    }

    /*
     *  Given a handler
    */
    private static MSD_CORE_InboundSocialPostHandlerImpl givenASocialPostHandler(){
        return new MSD_CORE_InboundSocialPostHandlerImpl();
    }

    ///
    // Matching Posts
    ///
    @isTest static void existingPostUpdatesContent() {
        givenThereAreSettings();
        SocialPersona persona = givenAPersona();
        SocialPost existingPost = givenPostInserted(withAnR6PostId(givenAPost()));
        Integer beforePostCount = getThePostCount();
        SocialPost post = withAnR6PostId(givenAPost());
        
        processAPost(post, persona, givenASocialPostHandler());

        System.assertEquals(beforePostCount, getThePostCount());
        assertPostUpdatedWithContent(post, Content);
    }

    private static SocialPost givenPostInserted(SocialPost post){
        post.Content = ExistingContent;
        post.Name = ExistingName;
        insert post;
        return post;
    }

    private static SocialPersona givenAPersona(){
        return givenAPersona(PersonaLastName, Facebook, PersonaMediaProvider);
    }

    private static SocialPersona givenAPersona(String lastName, String provider, String mediaProvider){
        SocialPersona persona = MSD_CORE_SocialTestDataFactory.initializePersona(lastName, provider, mediaProvider);
        persona.ProfileUrl = DefaultProfileURL;
        return persona;
    }

    private static SocialPersona givenPersonaInserted(SocialPersona persona){
        Account hcpAccount = TestDataFactoryMVN.createTestHCP();
        Id contactId = [select PersonContactId from Account where Id = :hcpAccount.Id].PersonContactId;
        persona.ParentId = contactId;
        persona.ProfileUrl = InsertedPersonaProfileURL;
        insert persona;
        return persona;
    }

    private static SocialPost givenAPost(){
        SocialPost post = MSD_CORE_SocialTestDataFactory.initializePost(Content, Name);        
        return post;
    }

    private static SocialPost givenAPost(SocialPersona persona){
        SocialPost post = MSD_CORE_SocialTestDataFactory.initializePost(Content, Name);        
        post.PersonaId = persona.Id;
        return post;
    }

    private static SocialPost withAnR6PostId(SocialPost post){
        post.R6PostId = AnR6PostId;
        return post;
    }

    private static SocialPost processAPost(
        SocialPost postToProcess,
        SocialPersona personaToProcess,
        MSD_CORE_InboundSocialPostHandlerImpl socialPostHandler){
        return processAPost(postToProcess, personaToProcess, new Map<String, Object>(), socialPostHandler);
    }

    private static SocialPost processAPost(
        SocialPost postToProcess,
        SocialPersona personaToProcess,
        Map<String, Object> rawData,
        MSD_CORE_InboundSocialPostHandlerImpl socialPostHandler){
        socialPostHandler.handleInboundSocialPost(postToProcess, personaToProcess, rawData);
        return postToProcess;
    }

    private static void assertPostUpdatedWithContent(SocialPost post, String expectedContent){
        SocialPost postToAssert = [SELECT Id, Content FROM SocialPost WHERE Name = :Name LIMIT 1];
        System.assertEquals(expectedContent, postToAssert.Content);
    }    

    @isTest static void existingPostDoesNotCreatePost() {
        givenThereAreSettings();
        SocialPersona persona = givenAPersona();
        SocialPost existingPost = givenPostInserted(withAnR6PostId(givenAPost()));
        Integer beforePostCount = getThePostCount();
        SocialPost postToProcess = withAnR6PostId(withProvider(OtherMediaProvider, givenAPost()));

        processAPost(postToProcess, persona, givenASocialPostHandler());

        System.assertEquals(beforePostCount, getThePostCount());
    }

    private static Integer getThePostCount(){
        List<SocialPost> posts = [SELECT Id FROM SocialPost];
        return posts.size();
    }

    @isTest static void privateFacebookPostsNoCheck(){
        givenThereAreSettings();
        SocialPersona persona = givenAPersona();
        SocialPost existingPost = givenPostInserted(withProvider(givenAPost(), Facebook, PrivateMessageType));        
        Integer beforePostCount = getThePostCount();

        processAPost(givenAPost(), persona, givenASocialPostHandler());

        System.assertEquals(beforePostCount + 1, getThePostCount());
    }

    private static SocialPost withProvider(SocialPost post, String provider, String messageType){
        post.provider = provider;
        post.messageType = messageType;
        return post;
    }

    @isTest static void postWithNoProviderNoCheck(){
        givenThereAreSettings();
        SocialPersona persona = givenAPersona();
        SocialPost existingPost = givenPostInserted(withNoProvider(givenAPost()));        
        Integer beforePostCount = getThePostCount();
        SocialPost postToProcess = withNoProvider(givenAPost());

        processAPost(postToProcess, persona, givenASocialPostHandler());

        System.assertEquals(beforePostCount + 1, getThePostCount());
    }

    @isTest static void postWithNoExternalIdNoCheck(){
        givenThereAreSettings();
        SocialPersona persona = givenAPersona();
        SocialPost existingPost = givenPostInserted(withNoExternalId(givenAPost()));        
        Integer beforePostCount = getThePostCount();
        SocialPost postToProcess = withNoExternalId(givenAPost());

        processAPost(postToProcess, persona, givenASocialPostHandler());

        System.assertEquals(beforePostCount + 1, getThePostCount());
    }

    private static SocialPost withNoProvider(SocialPost post){
        post.provider = null;
        return post;
    }

    private static SocialPost withNoExternalId(SocialPost post){
        post.ExternalPostId = null;
        return post;
    }

    @isTest static void existingExternalIdPostUpdatesContent() {
        givenThereAreSettings();
        SocialPersona persona = givenAPersona();
        SocialPost existingPost = givenPostInserted(withExternalId(givenAPost(), PostExternalId));        
        Integer beforePostCount = getThePostCount();
        SocialPost postToProcess = withExternalId(givenAPost(), PostExternalId);

        processAPost(postToProcess, persona, givenASocialPostHandler());

        System.assertEquals(beforePostCount, getThePostCount());
        assertPostUpdatedWithContent(postToProcess, Content);
    }

    private static SocialPost withExternalId(SocialPost post, String externalId){
        post.provider = Facebook;
        post.ExternalPostId = externalId;
        return post;
    }

    @isTest static void nonExistingPostCreatesPost(){
        givenThereAreSettings();
        SocialPersona persona = givenAPersona();
        Integer beforePostCount = getThePostCount();
        SocialPost postToProcess = givenAPost();

        processAPost(postToProcess, persona, givenASocialPostHandler());

        System.assertEquals(beforePostCount + 1, getThePostCount());
    }

    ///
    // Matching Personas
    ///
    @isTest static void existingPersonaMatchesOnProviderAndExternalId() {
        givenThereAreSettings();
        SocialPersona existingPersona = givenPersonaInserted(withExternalId(givenAPersona()));
        Integer beforePersonaCount = getPersonaCount();
        SocialPersona personaToProcess = withExternalId(givenAPersona());
        SocialPost postToProcess = givenAPost();

        processAPost(postToProcess, personaToProcess, givenASocialPostHandler());

        System.assertEquals(beforePersonaCount, getPersonaCount());
        System.assertNotEquals(personaToProcess.ProfileUrl, existingPersona.ProfileUrl);
        assertPersonaProfileURLUpdated(personaToProcess.ProfileUrl);
    }

    private static SocialPersona withExternalId(SocialPersona persona){
        persona.ExternalId = PersonaExternalId;
        return persona;
    }

    private static Integer getPersonaCount(){
        List<SocialPersona> personas = [SELECT Id FROM SocialPersona];
        return personas.size();
    }

    private static void assertPersonaProfileURLUpdated(String profileUrl){
        List<SocialPersona> personas = [SELECT Id FROM SocialPersona WHERE ProfileUrl = :profileUrl];
        System.assertEquals(1, personas.size(), 'Expecting persona with ProfileUrl ' + profileUrl);
    }

    @isTest static void existingPersonaMatchesOnMediaProviderAndExternalId() {
        givenThereAreSettings();
        SocialPersona existingPersona = givenPersonaInserted(withProvider(OtherMediaProvider, withExternalId(givenAPersona())));
        Integer beforePersonaCount = getPersonaCount();
        SocialPersona personaToProcess = withProvider(OtherMediaProvider, withExternalId(givenAPersona()));
        SocialPost postToProcess = givenAPost();

        processAPost(postToProcess, personaToProcess, givenASocialPostHandler());

        System.assertEquals(beforePersonaCount, getPersonaCount());
        System.assertNotEquals(personaToProcess.ProfileUrl, existingPersona.ProfileUrl);
        assertPersonaProfileURLUpdated(personaToProcess.ProfileUrl);
    }

    @isTest static void existingPersonaMatchesOnMediaProviderAndName() {
        givenThereAreSettings();
        SocialPersona existingPersona = givenPersonaInserted(withProvider(OtherMediaProvider, givenAPersona()));
        Integer beforePersonaCount = getPersonaCount();
        SocialPersona personaToProcess = withProvider(OtherMediaProvider,givenAPersona());
        SocialPost postToProcess = givenAPost();

        processAPost(postToProcess, personaToProcess, givenASocialPostHandler());

        System.assertEquals(beforePersonaCount, getPersonaCount());
        System.assertNotEquals(personaToProcess.ProfileUrl, existingPersona.ProfileUrl);
        assertPersonaProfileURLUpdated(personaToProcess.ProfileUrl);
    }

    @isTest static void assignsReplyToBasedOnReplyToId() {
        givenThereAreSettings();
        SocialPersona existingPersona = givenPersonaInserted(withName('replyToPersona', givenAPersona()));
        SocialPost existingPost = givenPostInserted(withPersona(givenAPost(), existingPersona));
        Integer beforePostCount = getThePostCount();
        SocialPost postToProcess = withAReplyToId(withProvider(OtherMediaProvider, givenAPost()), existingPost);
        SocialPersona persona = givenAPersona();

        processAPost(postToProcess, persona, givenASocialPostHandler());

        System.assertEquals(beforePostCount + 1, getThePostCount());
        System.assertEquals(existingPost.Id, postToProcess.ReplyTo.Id);
    }

    private static SocialPost withAReplyToId(SocialPost post, SocialPost replyTo){
        post.ReplyToId = replyTo.Id;
        return post;
    }

    @isTest static void assignsReplyToBasedOnExternalPostIdAndProvider() {
        givenThereAreSettings();
        SocialPersona persona = givenAPersona();

        SocialPost existingPost = givenPostInserted(withExternalId(givenAPost(), PostExternalId));
        Integer beforePostCount = getThePostCount();
        SocialPost postToProcess = withResponseContextExternalId(PostExternalId, givenAPost());

        processAPost(postToProcess, persona, givenASocialPostHandler());

        System.assertEquals(beforePostCount + 1, getThePostCount());
        System.assertEquals(existingPost.Id, postToProcess.ReplyTo.Id);
    }

    private static SocialPost withResponseContextExternalId(String externalId, SocialPost post){
        post.ResponseContextExternalId = externalId;
        post.Provider = Facebook;
        return post;
    }

    @isTest static void newReplyToWithWrongExternalPostId(){
        givenThereAreSettings();
        SocialPersona persona = givenAPersona();
        SocialPost existingPost = givenPostInserted(withExternalId(givenAPost(), PostExternalId));        
        Integer beforePostCount = getThePostCount();
        SocialPost postToProcess = withExternalId(givenAPost(), AnotherPostExternalId);

        processAPost(postToProcess, persona, givenASocialPostHandler());

        System.assertEquals(beforePostCount + 1, getThePostCount());
        System.assertEquals(null, postToProcess.ReplyTo);
        System.assertEquals(null, postToProcess.ReplyToId);
    }

    @isTest static void newReplyToWithWrongProvider(){
        givenThereAreSettings();
        SocialPersona persona = givenAPersona();
        SocialPost existingPost = givenPostInserted(withExternalId(givenAPost(), PostExternalId));        
        Integer beforePostCount = getThePostCount();
        SocialPost postToProcess = withProvider(withExternalId(givenAPost(), AnotherPostExternalId), Facebook, null);

        processAPost(postToProcess, persona, givenASocialPostHandler());

        System.assertEquals(beforePostCount + 1, getThePostCount());
        System.assertEquals(null, postToProcess.ReplyTo);
        System.assertEquals(null, postToProcess.ReplyToId);

    }


    ///
    // Creating A Persona
    ///
    @isTest static void personaWithoutNameDoesNotCreate() {
        givenThereAreSettings();
        SocialPersona persona = withName(null, givenAPersona());
        SocialPost postToProcess = givenAPost();

        Integer beforePersonaCount = getPersonaCount();

        processAPost(postToProcess, persona, givenASocialPostHandler());

        System.assertEquals(beforePersonaCount, getPersonaCount());
    }

    private static SocialPersona withName(String personaName, SocialPersona persona){
        persona.Name = personaName;
        return persona;
    }

    @isTest static void personaWithoutProviderDoesNotCreate() {
        givenThereAreSettings();
        SocialPersona persona = withProvider(null, givenAPersona());
        SocialPost postToProcess = givenAPost();

        Integer beforePersonaCount = getPersonaCount();

        processAPost(postToProcess, persona, givenASocialPostHandler());

        System.assertEquals(beforePersonaCount, getPersonaCount());
    }

    private static SocialPersona withProvider(String provider, SocialPersona persona){
        persona.provider = provider;
        return persona;
    }

    @isTest static void personaWithoutMediaProviderDoesNotCreate() {
        givenThereAreSettings();
        SocialPersona persona = withMediaProvider(null, givenAPersona());
        SocialPost postToProcess = givenAPost();

        Integer beforePersonaCount = getPersonaCount();

        processAPost(postToProcess, persona, givenASocialPostHandler());

        System.assertEquals(beforePersonaCount, getPersonaCount());
    }

    private static SocialPersona withMediaProvider(String provider, SocialPersona persona){
        persona.MediaProvider = provider;
        return persona;
    }


    @isTest static void nonExistingPersonaCreatesPersona(){
        givenThereAreSettings();
        SocialPersona persona = givenAPersona();
        SocialPost postToProcess = givenAPost();

        Integer beforePersonaCount = getPersonaCount();

        processAPost(postToProcess, persona, givenASocialPostHandler());

        System.assertEquals(beforePersonaCount + 1, getPersonaCount());
    }

    ///
    // Creating A Contact
    ///
    @isTest static void createContactWhenCreatingPersona() {
        givenThereAreSettings();
        SocialPersona persona = givenAPersona();
        SocialPost postToProcess = givenAPost();

        Integer beforeContactCount = getContactCount();

        processAPost(postToProcess, persona, givenASocialPostHandler());

        System.assertEquals(beforeContactCount + 1, getContactCount());
    }

    private static Integer getContactCount(){
        List<Contact> contacts = [SELECT Id FROM Contact];
        return contacts.size();
    }

    @isTest static void personaParentNameIsTrimmedPersonaName() {
        givenThereAreSettings();
        SocialPersona persona = withName(PersonaLastNameUnTrimmed, givenAPersona());
        SocialPost postToProcess = givenAPost();

        processAPost(postToProcess, persona, givenASocialPostHandler());

        assertPersonaContactLastName(PersonaLastName, persona);
    }

    private static void assertPersonaContactLastName(String expectedName, SocialPersona persona){
        System.assertNotEquals(null, persona.ParentId);
        Account accountToAssert = [SELECT Id, LastName FROM Account WHERE Id = :persona.ParentId];
        System.assertEquals(expectedName, accountToAssert.LastName);
    }

    private static void assertPersonaContactFirstName(String expectedName, SocialPersona persona){
        System.assertNotEquals(null, persona.ParentId);
        Account accountToAssert = [SELECT Id, FirstName FROM Account WHERE Id = :persona.ParentId];
        System.assertEquals(expectedName, accountToAssert.FirstName);
    }

    @isTest static void personaParentNameIsTrimmedRealName() {
        givenThereAreSettings();
        SocialPersona persona = withRealName(PersonaRealNameUnTrimmed, givenAPersona());
        SocialPost postToProcess = givenAPost();

        processAPost(postToProcess, persona, givenASocialPostHandler());

        assertPersonaContactLastName(PersonaLastName, persona);
    }

    private static SocialPersona withRealName(String realName, SocialPersona persona){
        persona.RealName = realName;
        return persona;
    }

    @isTest static void personaParentNameIsFirstAndLastName() {
        givenThereAreSettings();
        SocialPersona persona = withName(PersonaFirstAndLastName, givenAPersona());
        SocialPost postToProcess = givenAPost();

        processAPost(postToProcess, persona, givenASocialPostHandler());

        assertPersonaContactLastName(PersonaFirstAndLastName, persona);  
        assertPersonaContactFirstName(null, persona);   
    }

    @isTest static void personaParentNamesAreAbbreviated() {
        givenThereAreSettings();
        SocialPersona persona = withName(LongFullName, givenAPersona());
        SocialPost postToProcess = givenAPost();

        processAPost(postToProcess, persona, givenASocialPostHandler());

        assertPersonaContactLastName(AbbreviatedLongLastName, persona);
        assertPersonaContactFirstName(null, persona); 
    }

    private static void assertPersonaContactHasAccount(Account account, SocialPersona persona){        
        System.assertEquals(account.Id, persona.ParentId);
    }

    ///
    // Building Case
    ///
    @isTest static void postWithOutboundReplyToFindsExistingCase() {
        givenThereAreSettings();
        SocialPersona persona = givenAPersona();
        SocialPost existingPost = givenPostInserted(withIsOutbound(true, givenAPost()));
        Case existingCase = givenCaseInserted(givenACase(existingPost), existingPost);
        givenCaseIsClosed(existingCase);
        Integer beforeCaseCount = getCaseCount();
        SocialPost postToProcess = withAReplyToId(givenAPost(), existingPost);

        processAPost(postToProcess, persona, givenASocialPostHandler());

        System.assertEquals(beforeCaseCount + 1, getCaseCount());
    }

    private static SocialPost withIsOutbound(Boolean isOutbound, SocialPost post){
        post.IsOutbound = isOutbound;
        return post;
    }


    private static Case givenACase(SocialPost post){
        Case postCase = MSD_CORE_SocialTestDataFactory.initializeCase(post.Name);
        return postCase;
    }

    private static Case givenCaseIsClosed(Case caseToClose){  
        caseToClose.Status = Service_Cloud_Settings_MVN__c.getInstance().Closed_Status_MVN__c;
        update caseToClose;
        return caseToClose;
    }

    private static Case givenCaseInserted(Case caseToInsert, SocialPost post){
        insert caseToInsert;
        post.ParentId = caseToInsert.Id;
        update post;
        return caseToInsert;
    }

    private static Integer getCaseCount(){
        List<Case> cases = [SELECT Id FROM Case];
        return cases.size();
    }

    private static String RecipientId = '3141511170';    

    private static SocialPost withPersona(SocialPost post, SocialPersona persona){
        post.PersonaId = persona.Id;
        return post;
    }

    private static SocialPost withRecipient(SocialPost post, String recipient){
        post.Recipient = RecipientId;
        return post;
    }

    @isTest static void existingCaseClosedWithinMaxNumberOfDaysReOpens() {
        givenThereAreSettings();
        SocialPersona persona = givenAPersona();
        SocialPost existingPost = givenPostInserted(withIsOutbound(true, givenAPost()));
        Case existingCase = givenCaseInserted(givenACase(existingPost), existingPost);
        givenCaseIsClosed(existingCase);
        Integer beforeCaseCount = getCaseCount();
        SocialPost postToProcess = withAReplyToId(givenAPost(), existingPost);
        assertCaseClosed(existingCase);
        processAPost(postToProcess, persona, givenASocialPostHandler());

        System.assertEquals(beforeCaseCount + 1, getCaseCount());
    }

    private static String CaseOpenStatus = [SELECT MasterLabel FROM CaseStatus WHERE IsClosed = false AND IsDefault = true].MasterLabel;

    private static void assertCaseOpened(Case caseToAssert){
        Case currentCase = [SELECT Id FROM Case WHERE Id = :caseToAssert.Id AND Status = :CaseOpenStatus];
        System.assertNotEquals(null, currentCase, 'Did not find an open case with Id ' + caseToAssert.Id);
    }

    @isTest static void existingCaseClosedAfterMaxNumberOfDaysDoesNotOpen() { 
        givenThereAreSettings();
        SocialPersona persona = givenAPersona();
        SocialPost existingPost = givenPostInserted(withIsOutbound(true, givenAPost()));
        Case existingCase = givenCaseInserted(givenACase(existingPost), existingPost);
        givenCaseIsClosed(existingCase);
        assertCaseClosed(existingCase);
        Integer beforeCaseCount = getCaseCount();
        SocialPost postToProcess = withAReplyToId(givenAPost(), existingPost);

        processAPost(postToProcess, persona, givenASocialPostHandler());

        System.assertEquals(beforeCaseCount + 1, getCaseCount());
        assertCaseClosed(existingCase);
    }

    public static void assertCaseClosed(Case caseToAssert){
        Case currentCase = [SELECT Id, IsClosed, Status, Subject FROM Case WHERE Id = :caseToAssert.Id];
        System.assertEquals(true, currentCase.IsClosed, 'Case (' + currentCase.Status + ') with subject ' + currentCase.Subject + ' is not closed: ' + currentCase.IsClosed);
    }

    @isTest static void rawDataWhereSkipCreateCaseSkipsCreateCase() {
        givenThereAreSettings();
        SocialPersona persona = givenAPersona();
        SocialPost existingPost = givenPostInserted(withIsOutbound(true, givenAPost()));
        Case existingCase = givenCaseInserted(givenACase(existingPost), existingPost);
        givenCaseIsClosed(existingCase);

        Integer beforeCaseCount = getCaseCount();
        SocialPost postToProcess = withAReplyToId(givenAPost(), existingPost);

        processAPost(postToProcess, persona, withSkipCreateCaseData(), givenASocialPostHandler());

        System.assertEquals(beforeCaseCount + 1, getCaseCount());
        assertCaseClosed(existingCase);
    }

    private static Map<String, Object> withSkipCreateCaseData(){
        Map<String, Object> rawData = new Map<String, Object>();
        rawData.put('skipCreateCase', 'true');
        return rawData;
    }

    @isTest static void personaWithParentContactSetsCaseContactId() {
        givenThereAreSettings();
        SocialPersona persona = givenAPersona();
        SocialPost postToProcess = givenAPost();

        processAPost(postToProcess, persona, givenASocialPostHandler());
        
        assertCaseContactIsPersona(postToProcess, persona);
    }

    private static void assertCaseContactIsPersona(SocialPost post, SocialPersona persona){
        Case caseToAssert = [SELECT Id, AccountId FROM Case WHERE Id = :post.ParentId];
        System.assertEquals(persona.ParentId, caseToAssert.AccountId);
    }

    @isTest static void postWithProviderSetsCaseOrigin() {
        givenThereAreSettings();
        SocialPersona persona = givenAPersona();
        SocialPost postToProcess = withProvider(givenAPost(), Facebook, null);

        processAPost(postToProcess, persona, givenASocialPostHandler());
        
        assertCaseOriginIsProvider(postToProcess, Facebook);
    }

    private static void assertCaseOriginIsProvider(SocialPost post, String expectedProvider){
        Case caseToAssert = [SELECT Id, Origin FROM Case WHERE Id = :post.ParentId];
        System.assertEquals(expectedProvider, caseToAssert.Origin);
    }

    ///
    // Post Processing
    ///
    @isTest static void postContentGetsAbbreviated() {
        givenThereAreSettings();
        SocialPersona persona = givenAPersona();
        String originalContent = randomStringAll(32005);
        SocialPost postToProcess = withContent(givenAPost(), originalContent) ;

        processAPost(postToProcess, persona, givenASocialPostHandler());

        String expectedContent = originalContent.abbreviate(32000);
        assertPostUpdatedWithContent(postToProcess, expectedContent);
    }

    private static String randomStringAll(Integer count) {
        Integer[] chars = new Integer[0],
            offsets = new Integer[] { 48, 65, 97 },
                mods = new Integer[] { 10, 26, 26 };

        while(count > chars.size()) {
            Integer cat = Math.abs(Math.mod(Crypto.getRandomInteger(),3));
            chars.add(Math.mod(Math.abs(Crypto.getRandomInteger()), mods[cat])+offsets[cat]);
        }
        return String.fromCharArray(chars);
    }

    private static SocialPost withContent(SocialPost post, String newContent){
        post.Content = newContent;
        return post;
    }

    @isTest static void postPersonaIdGetsUpdated() {
        givenThereAreSettings();
        SocialPersona persona = givenAPersona();
        SocialPost postToProcess = givenAPost();

        processAPost(postToProcess, persona, givenASocialPostHandler());

        assertPostPersona(postToProcess, persona);
    }

    private static void assertPostPersona(SocialPost post, SocialPersona persona){
        System.assertEquals(post.PersonaId, persona.Id);
    }

    @isTest static void postParentIdGetsUpdated() {
        givenThereAreSettings();
        SocialPersona persona = givenAPersona();
        SocialPost postToProcess = givenAPost();

        processAPost(postToProcess, persona, givenASocialPostHandler());

        assertCaseIsPostParent(postToProcess);
    }

    private static void assertCaseIsPostParent(SocialPost post){
        Case caseToAssert = [SELECT Id FROM Case WHERE Id = :post.ParentId];
        System.assertNotEquals(null, caseToAssert);
    }

    @isTest static void createsPersonAccountForCase() {
        givenThereAreSettings();
        SocialPersona persona = givenAPersona();
        SocialPost postToProcess = givenAPost();

        processAPost(postToProcess, persona, givenASocialPostHandler());

        Case postCase = assertHasCase(postToProcess, null);
        assertCaseHasPersonAccount(postCase, null);

    }

    private static Case assertHasCase(SocialPost post, Set<String> fieldsToGet){
        Set<String> fieldSet;
        if(fieldsToGet == null){
            fieldSet = new Set<String>();
        } else {
            fieldSet = fieldsToGet.clone();
        }
        fieldSet.add('Id');
        fieldSet.add('AccountId');
        String fieldString = String.join(new List<String>(fieldSet), ', ');

        System.assertNotEquals(null, post.ParentId, 'Post is missing case id');
        String postParentId = post.ParentId;

        String postCaseQuery = 'SELECT ' + fieldString + ' FROM Case WHERE Id = :postParentId';
        Case postCase = Database.query(postCaseQuery);
        System.assertNotEquals(null, postCase, 'No case for post ParentId');
        return postCase;
    }

    private static Account assertCaseHasPersonAccount(Case caseToAssert, Set<String> fieldsToGet){
        Set<String> fieldSet;
        if(fieldsToGet == null){
            fieldSet = new Set<String>();
        } else {
            fieldSet = fieldsToGet.clone();
        }
        
        fieldSet.add('Id');
        fieldSet.add('IsPersonAccount');
        fieldSet.add('MSD_CORE_Country_Code__c');
        String accountFields = String.join(new List<String>(fieldSet), ', ');

        System.assertNotEquals(null, caseToAssert.AccountId, 'Case does not have an AccountId');
        String accountId = caseToAssert.AccountId;

        String accountQuery = 'SELECT ' + accountFields + ' FROM Account WHERE Id = :accountId';
        Account caseAccount = Database.query(accountQuery);

        System.assertNotEquals(null, caseAccount, 'No account for case AccountId');
        System.assertEquals(true, caseAccount.IsPersonAccount, 'Found an account, but it was not a person account');
        return caseAccount;
    }

    @isTest static void setsClassOfTradeToConsumer() {
        givenThereAreSettings();
        SocialPersona persona = givenAPersona();
        SocialPost postToProcess = givenAPost();

        processAPost(postToProcess, persona, givenASocialPostHandler());

        Case postCase = assertHasCase(postToProcess, null);
        Account caseAccount = assertCaseHasPersonAccount(postCase, ClassFields);
        assertAccountClassFields(caseAccount, CONSUMER);
    }

    private static void assertAccountClassFields(Account accountToAssert, String classValue){
        System.assertEquals(classValue, accountToAssert.Class_Of_Trade_MRK__c);
        System.assertEquals(classValue, accountToAssert.Class_Of_Trade_Sub_MRK__c);
    }
    
    @isTest static void setsAccountFirstAndLastName(){
        givenThereAreSettings();
        SocialPersona persona = withName(PersonaFirstAndLastName, givenAPersona());
        SocialPost postToProcess = givenAPost();

        processAPost(postToProcess, persona, givenASocialPostHandler());

        Case postCase = assertHasCase(postToProcess, null);
        Account caseAccount = assertCaseHasPersonAccount(postCase, NameFields);
        assertHasFirstLastName(caseAccount, null, PersonaFirstAndLastName);
    }

    private static void assertHasFirstLastName(Account accountToAssert, String firstName, String lastName){
        System.assertEquals(firstName, accountToAssert.FirstName);
        System.assertEquals(firstName, accountToAssert.Preferred_First_Name_MRK__c);
        System.assertEquals(lastName, accountToAssert.LastName);
        System.assertEquals(lastName, accountToAssert.Preferred_Last_Name_MRK__c);
    }

    @isTest static void setsCaseSourceToPostProvider(){
        givenThereAreSettings();
        MSD_CORE_Source__c source = givenASource(Twitter, USCountry);
        SocialPersona persona = givenAPersona();
        SocialPost postToProcess = withProvider(source.MSD_CORE_External_Id__c, givenAPost());

        processAPost(postToProcess, persona, givenASocialPostHandler());

        Case postCase = assertHasCase(postToProcess, HasSourceFields);
        assertCaseHasSource(postCase, source);
    }

    private static SocialPost withProvider(String provider, SocialPost post){
        post.Provider = provider;
        return post;
    }

    private static void assertCaseHasSource(Case caseToAssert, MSD_CORE_Source__c sourceToAssert){
        System.assertNotEquals(null, caseToAssert.MSD_CORE_Source__c, 'Case does not have a source');
        System.assertEquals(sourceToAssert.Id, caseToAssert.MSD_CORE_Source__c);
    }

    @isTest static void setsCaseCountryToSourceCountry(){
        givenThereAreSettings();
        MSD_CORE_Source__c source = givenASource(Twitter, USCountry);
        SocialPersona persona = givenAPersona();
        SocialPost postToProcess = withProvider(source.MSD_CORE_External_Id__c, givenAPost());

        processAPost(postToProcess, persona, givenASocialPostHandler());

        Case postCase = assertHasCase(postToProcess, CountryFields);
        assertCaseCountry(postCase, USCountry);
    }

    private static void assertCaseCountry(Case postCase, String country){
        System.assertEquals(country, postCase.MSD_CORE_Country_Code__c);
    }

    @isTest static void setsAccountCountryToSourceCountry(){
        givenThereAreSettings();
        MSD_CORE_Source__c source = givenASource(Facebook, USCountry);
        SocialPersona persona = givenAPersona();
        SocialPost postToProcess = withProvider(source.MSD_CORE_External_Id__c, givenAPost());

        processAPost(postToProcess, persona, givenASocialPostHandler());

        Case postCase = assertHasCase(postToProcess, CountryFields);
        Account caseAccount = assertCaseHasPersonAccount(postCase, CountryFields);
        assertAccountCountry(caseAccount, USCountry);
    }

    private static void assertAccountCountry(Account caseAccount, String country){
        System.assertEquals(country, caseAccount.MSD_CORE_Country_Code__c);
    }

    @isTest static void setsAccountRecordTypeToConsumer(){
        Service_Cloud_Settings_MVN__c settings = givenThereAreSettings();        
        SocialPersona persona = givenAPersona();
        SocialPost postToProcess = givenAPost();

        processAPost(postToProcess, persona, givenASocialPostHandler());

        Case postCase = assertHasCase(postToProcess, null);
        Account caseAccount = assertCaseHasPersonAccount(postCase, RecordTypeCheckFields);

        Id consumerRecordTypeId = givenConsumerRecordTypeId(settings);
        assertAccountRecordType(caseAccount, consumerRecordTypeId);
    }

    private static void assertAccountRecordType(Account accountToAssert, Id recordTypeId){
        System.assertEquals(recordTypeId, accountToAssert.RecordTypeId);
    }

    @isTest static void setsAccountStatusToActive(){
        Service_Cloud_Settings_MVN__c settings = givenThereAreSettings();        
        SocialPersona persona = givenAPersona();
        SocialPost postToProcess = givenAPost();

        processAPost(postToProcess, persona, givenASocialPostHandler());

        Case postCase = assertHasCase(postToProcess, null);
        Account caseAccount = assertCaseHasPersonAccount(postCase, new Set<String>{ 'Status_MRK__c' });

        assertAccountStatus(caseAccount, 'ACTIVE');
    }

    private static void assertAccountStatus(Account accountToAssert, String status){
        System.assertEquals(status, accountToAssert.Status_MRK__c);
    }


}