public without sharing class VeevaRemoveFromTerritoryHandler {

    private Boolean incrementalATLModeEnabled;
    private Set<Id> accountIds;
    private Set<Id> requestOwnerUserIds;
    private Set<String> territoryIds;

    private List<Data_Change_Request_vod__c> approvedRequests;
    private List<Data_Change_Request_vod__c> rejectedRequests;

    private Map<Id, String> userToAcceptedResolutionNote;
    private Map<Id, String> userToRejectedResolutionNote;

    private List<ObjectTerritory2Association> alignmentsToDelete;
    private List<Account_Territory_Loader_vod__c> atlsToUpdate;
    private List<Data_Change_Request_vod__c> processedRequests;

    private final String CHANGE_ACCEPTED = 'CHANGE_ACCEPTED';
    private final String CHANGE_REJECTED = 'CHANGE_REJECTED';
    private final String ACCEPTED_RESOLUTION_NOTE_NAME = 'REMOVE_FROM_TERRITORY_ACCEPTED_RESOLUTION_NOTE';
    private final String REJECTED_RESOLUTION_NOTE_NAME = 'REMOVE_FROM_TERRITORY_REJECTED_RESOLUTION_NOTE';
    private final String ACCEPTED_RESOLUTION_NOTE_DEFAULT = 'Account successfully removed from territory.';
    private final String REJECTED_RESOLUTION_NOTE_DEFAULT = 'The request to remove the account from your territory has been rejected.';

    public VeevaRemoveFromTerritoryHandler() {
        this.incrementalATLModeEnabled = this.incrementalATLModeEnabled();
        this.accountIds = new Set<Id>();
        this.requestOwnerUserIds = new Set<Id>();
        this.territoryIds = new Set<String>();
        this.approvedRequests = new List<Data_Change_Request_vod__c>();
        this.rejectedRequests = new List<Data_Change_Request_vod__c>();
        this.userToAcceptedResolutionNote = new Map<Id, String>();
        this.userToRejectedResolutionNote = new Map<Id, String>();
        this.alignmentsToDelete = new List<ObjectTerritory2Association>();
        this.atlsToUpdate = new List<Account_Territory_Loader_vod__c>();
        this.processedRequests = new List<Data_Change_Request_vod__c>();
    }

    public void processTerritoryDealignmentRequests(List<Data_Change_Request_vod__c> dealignmentRequests) {
        this.sortApprovedAndRejectedRequests(dealignmentRequests);
        this.loadResolutionNotes();
        this.processAcceptedRequests();
        this.processRejectedRequests();
        this.performTerritoryDealignment();
    }

    private Boolean incrementalATLModeEnabled() {
        Territory_Settings_vod__c territorySetting = Territory_Settings_vod__c.getOrgDefaults();
        return (territorySetting != null && (Integer) territorySetting.ATL_Mode_vod__c == 1);
    }

    private void sortApprovedAndRejectedRequests(List<Data_Change_Request_vod__c> dealignmentRequests) {
        for (Data_Change_Request_vod__c request : dealignmentRequests) {
            this.requestOwnerUserIds.add(request.OwnerId);
            if (request.Result_vod__c.equals(CHANGE_ACCEPTED)) {
                this.approvedRequests.add(request);
                this.accountIds.add(request.Account_vod__c);
                this.territoryIds.add(request.Territory_vod__c);
            } else if (request.Result_vod__c.equals(CHANGE_REJECTED)) {
                this.rejectedRequests.add(request);
            }
        }
    }
    
    private void processAcceptedRequests() {
        VeevaRemoveFromTerritoryAlignmentData alignmentData = new VeevaRemoveFromTerritoryAlignmentData(this.accountIds, this.territoryIds);        
        Map<Id, Account_Territory_Loader_vod__c> accountToUpdatedATL = new Map<Id, Account_Territory_Loader_vod__c>();

        for (Data_Change_Request_vod__c record : this.approvedRequests) {            
            Id accountId = record.Account_vod__c;
            String territoryId = record.Territory_vod__c;
            ObjectTerritory2Association alignment = alignmentData.getAlignment(accountId, territoryId);

            if (alignment != null) {
                Account_Territory_Loader_vod__c atl = accountToUpdatedATL.containsKey(accountId) 
                    ? accountToUpdatedATL.get(accountId) : alignmentData.getATL(accountId);

                if (atl != null) {
                    if (this.incrementalATLModeEnabled || (!this.incrementalATLModeEnabled && String.isBlank(atl.Territory_vod__c))) {
                        // When in Incremental ATL mode, only Territory to Add/Drop fields are processed so dropped associations represented
                        // by the update to the ATL's Territory_vod__c will need manually dropped. If in Classic ATL Mode and the
                        // Territory_vod__c field on the ATL is blank, it will not be updated so the after-update ATL logic to delete the OT2A will not
                        // be invoked. It would also need to be manually put up for deletion here.
                        this.alignmentsToDelete.add(alignment);
                    }

                    if (String.isNotBlank(atl.Territory_vod__c)) {
                        String territoryName = alignment.Territory2.Name;
                        String newTerritoryListValue = atl.Territory_vod__c.replace(';' + territoryName + ';', ';');
                        if (newTerritoryListValue.equals(';')) {
                            newTerritoryListValue = '';
                        }

                        atl.Territory_vod__c = newTerritoryListValue;
                        if (!accountToUpdatedATL.containsKey(accountId)) {
                            accountToUpdatedATL.put(accountId, atl);
                        }
                    }
                } else {
                    this.alignmentsToDelete.add(alignment);
                }
            }

            Id ownerId = record.OwnerId;
            Data_Change_Request_vod__c updatedDCR = new Data_Change_Request_vod__c(Id = record.Id, Status_vod__c='Processed_vod', External_Status_vod__c='CHANGE_PROCESSED');
            updatedDCR.Response_Datetime_vod__c = Datetime.now();
            updatedDCR.Resolution_Note_vod__c = this.userToAcceptedResolutionNote.get(ownerId);
            this.processedRequests.add(updatedDCR);
        }

        // Contains a list of all of the ATLs whose Territory_vod__c values were modified above
        this.atlsToUpdate = accountToUpdatedATL.values();
    }

    private void processRejectedRequests() {
        for (Data_Change_Request_vod__c record : this.rejectedRequests) {
            Id ownerId = record.OwnerId;
            Data_Change_Request_vod__c updatedDCR = new Data_Change_Request_vod__c(Id = record.Id, Status_vod__c='Processed_vod', External_Status_vod__c='CHANGE_PROCESSED');
            updatedDCR.Response_Datetime_vod__c = Datetime.now();
            updatedDCR.Resolution_Note_vod__c = this.userToRejectedResolutionNote.get(ownerId);
            this.processedRequests.add(updatedDCR);
        }
    }

    private void loadResolutionNotes() {
        List<User> requestOwners = [SELECT Id, LanguageLocaleKey FROM User WHERE Id IN :this.requestOwnerUserIds];
        List<Message_vod__c> resolutionNotes = [SELECT Name, Text_vod__c, Language_vod__c FROM Message_vod__c WHERE (Name = :ACCEPTED_RESOLUTION_NOTE_NAME OR Name = :REJECTED_RESOLUTION_NOTE_NAME) AND Category_vod__c = 'Feedback' AND Active_vod__c = true];

        Map<String, String> languageToAcceptedResolutionNote = new Map<String, String>();
        Map<String, String> languageToRejectedResolutionNote = new Map<String, String>();
        for (Message_vod__c message : resolutionNotes) {
            if (message.Name.equals(ACCEPTED_RESOLUTION_NOTE_NAME)) {
                languageToAcceptedResolutionNote.put(message.Language_vod__c, message.Text_vod__c);
            } else {
                languageToRejectedResolutionNote.put(message.Language_vod__c, message.Text_vod__c);
            }
        }

        for (User user : requestOwners) {
            String userLanguageKey = user.LanguageLocaleKey;
            String chosenAcceptedMessage = languageToAcceptedResolutionNote.containsKey(userLanguageKey) ? languageToAcceptedResolutionNote.get(userLanguageKey) : ACCEPTED_RESOLUTION_NOTE_DEFAULT;
            String chosenRejectedMessage = languageToRejectedResolutionNote.containsKey(userLanguageKey) ? languageToRejectedResolutionNote.get(userLanguageKey) : REJECTED_RESOLUTION_NOTE_DEFAULT;
            
            this.userToAcceptedResolutionNote.put(user.Id, chosenAcceptedMessage);
            this.userToRejectedResolutionNote.put(user.Id, chosenRejectedMessage);
        }
    }

    private void performTerritoryDealignment() {
        delete this.alignmentsToDelete;
        update this.atlsToUpdate;
        update this.processedRequests;
    }
    
}