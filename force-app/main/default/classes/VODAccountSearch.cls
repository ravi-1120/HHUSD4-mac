global class VODAccountSearch {
	private static final String PREFIX_WHERE = ' WHERE ';
	private static final String PREFIX_AND = ' AND ';

    webService static String searchAccounts(boolean isCJK, String name, String configuredField, String city, String state, string zip, string configuredFieldName, string searchOutsideTerrRecordTypes, string searchOutsideTerrCountries) {
        String query = 'SELECT Id, Name, Formatted_Name_vod__c, Primary_Parent_vod__r.Formatted_Name_vod__c, (SELECT Id,Name,Address_line_2_vod__c,City_vod__c,toLabel (State_vod__c),toLabel(Country_vod__c),Zip_vod__c,Zip_4_vod__c,Primary_vod__c FROM Address_vod__r)';
        Flag needsWHERE = new Flag(true);
        boolean hasConfiguredfield = false;
        boolean hasName = !String.isBlank(name);
        boolean hasCity = !String.isBlank(city);
        boolean hasState = !String.isBlank(state);
        boolean hasZip = !String.isBlank(zip);
        boolean isConfiguredPicklist = false;


        boolean hasRTFilter = !String.isBlank(searchOutsideTerrRecordTypes);
        boolean hasCountryFilter = !String.isBlank(searchOutsideTerrCountries);
        if(!String.isBlank(configuredFieldName)) {
          	Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Account.fields.getMap();
        	DescribeFieldResult configuredSObjectField = fieldMap.get(configuredFieldName).getDescribe();
            isConfiguredPicklist = configuredSObjectField.getType() == Schema.DisplayType.PICKLIST;
            if(isConfiguredPicklist) {
            	query += ', toLabel(' + String.escapeSingleQuotes(configuredFieldName) + ')';
            } else {
            	query += ', ' + String.escapeSingleQuotes(configuredFieldName);
            }
        }

        if(!String.isBlank(configuredField)) {
            hasConfiguredField = true;
        }

        query += ' FROM Account';

        if(hasName) {
            query += predicatePrefix(needsWHERE);
            name = String.escapeSingleQuotes(name);
            List<String> nameList = name.split(' ');
            if(nameList.size() == 1) {
                String singleName = nameList.get(0);
                query += '(lastName LIKE \'' + singleName + '%\' OR firstName Like \'' + singleName + '%\' OR Name LIKE \'' + singleName +'%\')';
            } else {
                String firstName = nameList.get(0);
                String lastName = nameList.get(1);

                if(isCJK) {
                    firstName = nameList.get(1);
                    lastName = nameList.get(0);
                }

                query += '((lastName LIKE \'' + lastName + '%\' AND firstName Like \'' + firstName + '%\') OR ' +
                                         '(lastName LIKE \'' + name + '%\' OR firstName Like \'' + name + '%\') OR ' +
                                         'Name LIKE \'' + name +'%\')';
            }
        }
        if(hasConfiguredField) {
            configuredField = String.escapeSingleQuotes(configuredField);
            configuredFieldName = String.escapeSingleQuotes(configuredFieldName);
            query += predicatePrefix(needsWHERE);
            if(isConfiguredPicklist) {
            	query += configuredFieldName + ' = \'' + configuredField + '\'';
            } else {
            	query += configuredFieldName + ' LIKE \'%' + configuredField + '%\'';
            }
        }
        if(hasCity || hasState || hasZip) {
            query += predicatePrefix(needsWHERE);
            query += 'Id in (Select Account_vod__c FROM Address_vod__c WHERE Inactive_vod__c = false';

            if(hasCity) {
            	city = String.escapeSingleQuotes(city);
                query += ' AND City_vod__c LIKE\'' + city + '%\'';
            }
            if(hasZip) {
            	zip = String.escapeSingleQuotes(zip);
                query += ' AND (Zip_vod__c LIKE\'' + zip + '%\' OR Zip_4_vod__c LIKE \'' + zip + '%\')';
            }
            if(hasState) {
                state = String.escapeSingleQuotes(state);
                query += ' AND State_vod__c = \'' + state + '\'';
            }
            query+= ')';
        }

        if (hasRTFilter) {
            query += predicatePrefix(needsWHERE);

            String[] recordTypeNames = searchOutsideTerrRecordTypes.split(';');
            List<Id> recordTypeIds = new List<Id>();
            for (RecordType rt: [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName IN :recordTypeNames]){
                recordTypeIds.add(rt.id);
            }
            query += ' RecordTypeId IN :recordTypeIds';
        }

        if (hasCountryFilter) {
            query += predicatePrefix(needsWHERE);

            String[] countryCodes = searchOutsideTerrCountries.split(';');
            List<Id> countryIds = new List<Id>();
            for (Country_vod__c c: [SELECT Id FROM Country_vod__c WHERE Alpha_2_Code_vod__c IN :countryCodes]){
                countryIds.add(c.id);
            }
            query += ' Country_vod__c IN :countryIds';
        }

        query += ' LIMIT 50';
        System.debug(query);

        List<sObject> accountQueryResults = Database.query(query);
        List<SearchResult> searchResults = new List<SearchResult>();

        for(sObject account: accountQueryResults) {
            SearchResult currentResult = new SearchResult();
            currentResult.Id = account.Id;
            currentResult.firstLastName = (String)account.get('Name');
            currentResult.Name = (String)account.get('Formatted_Name_vod__c');
            if (account.getSObject('Primary_Parent_vod__r') != null) {
                currentResult.parentName = (String) account.getSObject('Primary_Parent_vod__r').get('Formatted_Name_vod__c');
            }
            if(!String.isBlank(configuredFieldName)) {
                currentResult.identifier = (String)account.get(configuredFieldName);
            }

            sObject addressRow = null;
            for(sObject address : account.getSObjects('Address_vod__r')) {
                if(true == address.get('Primary_vod__c')) {
                    addressRow = address;
                    break;
                }
            }

            currentResult.address = getAddressFromRow(addressRow);
            searchResults.add(currentResult);
        }

        return JSON.serialize(searchResults);
    }

    @TestVisible private static String predicatePrefix(Flag needsWHERE) {
        if (needsWHERE.getValue()) {
            needsWHERE.setValue(false);
            return PREFIX_WHERE;
        } else {
        	return PREFIX_AND;
        }
	}

    webService static String findAccountResult(boolean showAddress,
                                               boolean showRecentEvents,
                                               boolean showLastTopic,
                                               boolean showMCCP,
                                               String Id,
                                               String eventId,
                                               String eventTopicId,
                                               String eventStartTime,
                                               List<String> accountFields,
                                               List<String> territories) {
        String query = 'SELECT Formatted_Name_vod__c, Id';
        List<String> relationFields = new List<String>();

        if(showAddress) {
        	query += ', ( SELECT Id,Name,Address_line_2_vod__c,City_vod__c,toLabel (State_vod__c),toLabel(Country_vod__c),Zip_vod__c,Zip_4_vod__c,Primary_vod__c FROM Address_vod__r )';
        }

        if(Id != null) {
            Id = String.escapeSingleQuotes(Id);
        }

		Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Account.fields.getMap();
        for(String accountField : accountFields) {

            String escapedAccountField = String.escapeSingleQuotes(accountField);

            if (fieldMap.get(escapedAccountField).getDescribe().getType() == Schema.DisplayType.PICKLIST) {
            	query += ', toLabel(' + escapedAccountField + ')';
            } else {
            	query += ', ' + escapedAccountField;
                // Query relation field name in order to show name in attendee detail page area.
                if (fieldMap.get(escapedAccountField).getDescribe().getType() == Schema.DisplayType.Reference) {
                    query += ', ' + escapedAccountField.replace('__c', '__r.Name');
                    relationFields.add(escapedAccountField.replace('__c', '__r.Name'));
                }
            }
        }

        query += ' FROM Account WHERE Id =\'' + Id + '\'';

        List<sObject> accountQueryResults = Database.query(query);
        List<AccountInfo> accountInfo = new List<AccountInfo>();
        for(sObject account: accountQueryResults) {
            AccountInfo currentResult = new AccountInfo();
            Map<String,String> data = new Map<String, String>();
            for(String field : accountFields) {
                Object o = account.get(field);
                String value = '';
                if(o != null) {
                    value = String.valueOf(o);
                }

                data.put(field, value);
            }

            for(String field : relationFields) {
                Object o = getFieldValue(account, field);
                String value = '';
                if(o != null) {
                    value = String.valueOf(o);
                }
                data.put(field, value);
            }

            currentResult.accountData = data;
            if(showAddress) {
            	List<String> addresses = new List<String>();
                for(sObject addressRow :account.getSObjects('Address_vod__r')) {
                    addresses.add(getAddressFromRow(addressRow));
                }
                currentResult.addresses = addresses;
            }
            if(showRecentEvents) {
                List<EM_Attendee_vod__c> recentEventResults = [SELECT Name, OwnerId,
                                                               Event_vod__r.Start_Time_vod__c, Event_vod__r.Topic_vod__c, Event_vod__r.Name, Event_vod__r.OwnerId, Event_vod__r.Status_vod__c, toLabel(Status_vod__c)
                                                               FROM EM_Attendee_vod__c WHERE Account_vod__c = :Id
                                                               AND Event_vod__c != :eventId
                                                               AND Event_vod__c != null
                                                               ORDER BY Event_vod__r.Start_Time_vod__c desc];
                List<Event> recentEvents = new List<Event>();

                for(EM_Attendee_vod__c attendee : recentEventResults) {
                    Event recentEvent = new Event();
                    recentEvent.name = attendee.Event_vod__r.Name;
                    recentEvent.startDatetime = String.valueOfGmt(attendee.Event_vod__r.Start_Time_vod__c);
                    recentEvent.OwnerId = attendee.Event_vod__r.OwnerId;
                    recentEvent.eventStatus = attendee.Event_vod__r.Status_vod__c;
                    recentEvent.attendeeStatus = attendee.Status_vod__c;
                    recentEvents.add(recentEvent);
                }

                currentResult.recentEvents = recentEvents;

            }

            if (showLastTopic && eventTopicId != null) {
                Set<String> attendeeStatuses = VOD_Utils.getAttendeeStatuses();
            	List<EM_Attendee_vod__c> recentEventAttendees = [SELECT Name, OwnerId, Event_vod__r.Start_Time_vod__c
                                                               FROM EM_Attendee_vod__c WHERE Account_vod__c = :Id
                                                               AND Event_vod__c != :eventId
                                                               AND Event_vod__c != null
                                                               AND Event_vod__r.Topic_vod__c = :eventTopicId
                                                               AND Event_vod__r.Status_vod__c != 'Canceled_vod'
                                                               AND ((Event_vod__r.Start_Time_vod__c >= :System.today() AND Status_vod__c != 'Rejected_vod')
                                                                    OR (Event_vod__r.Start_Time_vod__c <= :System.today() AND Status_vod__c IN :attendeeStatuses))
                                                               ORDER BY Event_vod__r.Start_Time_vod__c desc];

                if(!recentEventAttendees.isEmpty()) {
                	currentResult.lastTopicDate = String.valueOfGmt(recentEventAttendees.get(0).Event_vod__r.Start_Time_vod__c);
                }
            }

            if(showMCCP) {
                List<String> dateParts = eventStartTime.split('-');
                Date dateWithTime = Date.newInstance(Integer.valueOf(dateParts[0]), Integer.valueOf(dateParts[1]), Integer.valueOf(dateParts[2]));
            	List<MC_Cycle_Plan_Target_vod__c> targets = [SELECT Id,Cycle_Plan_vod__r.Name,Cycle_Plan_vod__r.Id,
                                                             (SELECT Team_Channel_Activity_Goal_vod__c,Team_Channel_Activity_Remaining_vod__c,Channel_vod__c
                                                              FROM MC_Cycle_Plan_Channels_vod__r
                                                              WHERE Cycle_Channel_vod__r.Channel_Object_vod__c IN
                                                              	('Event_Attendee_vod__c','EM_Attendee_vod__c'))
                                                             FROM MC_Cycle_Plan_Target_vod__c
                                                             WHERE Status_vod__c = 'Active_vod'
                                                             	AND Target_vod__c = :Id
                                                             	AND Cycle_Plan_vod__r.Territory_vod__c IN :territories
                                                             	AND Cycle_Plan_vod__r.Start_Date_vod__c <= :dateWithTime
                                                             	AND Cycle_Plan_vod__r.End_Date_vod__c >= :dateWithTime
                                                             	AND Cycle_Plan_vod__r.Status_vod__c IN ('Planned_vod','In_Progress_vod')];
                Map<String, List<Channel>> cyclePlanMap = new Map<String, List<Channel>>();
                for(MC_Cycle_Plan_Target_vod__c target: targets) {
                    if(!cyclePlanMap.containsKey(target.Cycle_Plan_vod__r.Name)) {
                            cyclePlanMap.put(target.Cycle_Plan_vod__r.Name, new List<Channel>());
                    }
                    List<Channel> channelList = new List<Channel>();
                    channelList = cyclePlanMap.get(target.Cycle_Plan_vod__r.Name);

                    List<MC_Cycle_Plan_Channel_vod__c> channels = target.MC_Cycle_Plan_Channels_vod__r;
                    for(MC_Cycle_Plan_Channel_vod__c channel : channels) {
                        Channel currentChannel = new Channel();
                        currentChannel.label = channel.Channel_vod__c;
                        currentChannel.goal = String.valueOf(channel.Team_Channel_Activity_Goal_vod__c);
                        currentChannel.remaining = String.valueOf(channel.Team_Channel_Activity_Remaining_vod__c);
                        channelList.add(currentChannel);
                    }
                }
                currentResult.cyclePlans = cyclePlanMap;
            }

            accountInfo.add(currentResult);
        }
        return JSON.serialize(accountInfo);
    }

    /**
     * @description get all out of territory account information
     * @param accountFields
     * @param accountIds
     * @return a result of all the account information
     */
    webservice static String retrieveAccountInfo(List<String> accountFields, List<String> accountIds) {
        String accountWhere = 'Id IN (' + cleanAndJoinIds(accountIds) + ')';
        Map<String, Map<String, Object>> accountInfo = queryAndConvertToMap(buildQueryWithFields(accountFields, 'Account', accountWhere), accountFields);
        return JSON.serialize(accountInfo);
    }

    webservice static String retrieveAccountAndConsentRecords(List<String> accountFields, List<String> addressFields, List<String> mcConsentFields, List<String> accountIds) {
        String joinedAndCleanedAccountIds = cleanAndJoinIds(accountIds);
        String accountWhere = 'Id IN (' + joinedAndCleanedAccountIds + ')';
        Map<String, Map<String, Object>> accountInfo = queryAndConvertToMap(buildQueryWithFields(accountFields, 'Account', accountWhere), accountFields);

        //Get addresses for each account
        String addressWhere = 'Inactive_vod__c = false AND Account_vod__c IN (' + joinedAndCleanedAccountIds + ')';
        Map<String, Map<String, Object>> accountAddressInfo = queryAndConvertToMap(buildQueryWithFields(addressFields, 'Address_vod__c', addressWhere), addressFields);

        //Get MC Consent for each account
        String mcConsentWhere = 'Account_vod__c IN (' + joinedAndCleanedAccountIds + ') AND RecordType.DeveloperName = \'Approved_Email_vod\' AND (Opt_Expiration_Date_vod__c = Null OR Opt_Expiration_Date_vod__c > TODAY)';
        Map<String, Map<String, Object>> mcConsentInfo = queryAndConvertToMap(buildQueryWithFields(mcConsentFields, 'Multichannel_Consent_vod__c', mcConsentWhere), mcConsentFields);

        Map<String, Map<String,Map<String,Object>>> accountsAndConsents = new Map<String, Map<String,Map<String,Object>>>();
        accountsAndConsents.put('accounts', accountInfo);
        accountsAndConsents.put('addresses', accountAddressInfo);
        accountsAndConsents.put('mcConsent', mcConsentInfo);

        return JSON.serialize(accountsAndConsents);
    }

    private static String cleanAndJoinIds(List<String> ids) {

        List<String> escapedIds = new List<String>();
        for (String id : ids) {
            // Do not add null ids to our list of escaped ids
            if (id != null) {
                escapedIds.add(String.escapeSingleQuotes(id));
            }
        }

        return '\'' + String.join(escapedIds, '\',\'') + '\'';
    }

    @TestVisible private static Map<String, Map<String, Object>> queryAndConvertToMap(String query, List<String> fields) {
        List<sObject> queryResults = Database.query(query);
        Map<String, Map<String, Object>> rows = new Map<String, Map<String, Object>>();
        for (sObject queryRow : queryResults) {
            Map<String, Object> rowMap = new Map<String, Object>(queryRow.getPopulatedFieldsAsMap());
            for (String field : fields) {
                if (field.contains('toLabel')) {
                    field = field.replace('toLabel(', '').replace(')', '');
                }
                if(field.startsWith('FORMAT')) {
                    field = field.replace('FORMAT(', '').replace(')', '');
                }
                if (field.contains('.')) { //we only want the relational tokens
                    rowMap.put(field, getFieldValue(queryRow, field));
                }
            }
            String recordId = (String) queryRow.get('Id');
            if (recordId.startsWith(Schema.Account.getSObjectType().getDescribe().getKeyPrefix())) {
                rowMap.put('type', 'Account');
            }
            rows.put(recordId, rowMap);
        }
        return rows;
    }

    private static String buildQueryWithFields(List<String> fields, String objectName, String whereClause) {
        boolean first = true;

        String query = 'SELECT ';
        for (String field : fields) {
            String.escapeSingleQuotes(field);
            if (first) {
                query += field;
                first = false;
            } else {
                query += ', '+field;
            }
        }
        query += ' FROM '+objectName;
        if (String.isNotBlank(whereClause)) {
            query += ' WHERE ' + whereClause;
        }
        return query;
    }

    private static Object getFieldValue(sObject sObj, String field) {
        if (field.contains('.')) {
            List<String> relationFieldToken = field.split('\\.', 2);
            String relation = relationFieldToken.get(0);
            String relationField = relationFieldToken.get(1);
            sObject relationObj = sObj.getSObject(relation);
            if (relationObj != null) {
                return getFieldValue(relationObj, relationField);
            }
        } else {
            return sObj.get(field);
        }
        return null;
    }

    private static String getAddressFromRow(SObject addressRow) {
    	String addressString = '';
        if(addressRow != null) {
            String addressLine1 = (String)addressRow.get('Name');
            String addressLine2 = (String)addressRow.get('Address_line_2_vod__c');
            String cityString = (String)addressRow.get('City_vod__c');
            String stateString = (String)addressRow.get('State_vod__c');
            String zipString = (String)addressRow.get('Zip_vod__c');
            String countryString = (String)addressRow.get('Country_vod__c');
            if(!String.isBlank(addressLine1)) {
                addressString += addressLine1;
            }
            if(!String.isBlank(addressLine2)) {
                addressString += ',' + addressLine2;
            }
            if(!String.isBlank(cityString)) {
                addressString += ',' + cityString;
            }
            if(!String.isBlank(stateString)) {
                addressString += ',' + stateString;
            }
            if(!String.isBlank(zipString)) {
                addressString += ',' + zipString;
            }
            if(!String.isBlank(countryString)) {
                addressString += ',' + countryString;
            }

        }
        return addressString;
    }

    global class AccountInfo {
		Map<String,String> accountData;
        List<String> addresses;
        List<Event> recentEvents;
        String lastTopicDate;
        Map<String, List<Channel>> cyclePlans;
    }

    global class Channel {
    	String label;
        String goal;
        String remaining;
    }

    global class Event {
        String name;
        String startDatetime;
        String ownerId;
        String eventStatus;
        String attendeeStatus;
    }

    global class SearchResult {
        String Id;
        String Name;
        String firstLastName;
        String address;
        String identifier;
        String parentName;
    }

    global class Flag {
        boolean flag;

        public Flag(boolean bool) {
            flag = bool;
        }

        public void setValue(boolean bool) {
            flag = bool;
        }

        public boolean getValue() {
            return flag;
        }
    }
}