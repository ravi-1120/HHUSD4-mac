public without sharing class EmReconciliationAutomatch { 
    
    private Map<String, Set<SObject>> addressEmailMatchToAccountMap = new Map<String, Set<SObject>>();
    private Map<String, Set<SObject>> accountEmailMatchToAccountMap = new Map<String, Set<SObject>>();
    private Map<String, Set<SObject>> accountNameMatchToAccountMap = new Map<String, Set<SObject>>();
    private Map<String, Set<SObject>> userEmailMatchToUserMap = new Map<String, Set<SObject>>();
    private Map<String, Set<SObject>> userNameMatchToUserMap = new Map<String, Set<SObject>>();

    private List<String> addressEmailFields;
    private List<String> accountEmailFields;
    private List<String> userEmailFields;

    public EmReconciliationAutomatch(Map<String, List<String>> emailMap) {
        this.addressEmailFields = emailMap.get('Address_vod__c') != null ? emailMap.get('Address_vod__c') : new List<String>();
        this.accountEmailFields = emailMap.get('Account') != null ? emailMap.get('Account') : new List<String>();
        this.userEmailFields = emailMap.get('User') != null ? emailMap.get('User') : new List<String>();
    }

    public void findMatches(List<EM_Attendee_vod__c> attendees) {
        List<String> batchNameClauses = new List<String>();
        List<String> emAttEmails = new List<String>();
        List<String> curNameClauses = new List<String>();
        List<String> emAttLastNames = new List<String>();
        Integer cummulativeClauseLength = 0;
        Integer maxSelectAndFromClauseLength = computeMaxSelectAndFromClauseLength();

        for (EM_Attendee_vod__c emAtt : attendees) {
            String lastName = emAtt.Last_Name_vod__c;
            if (lastName != null && (emAtt.Walk_In_Status_vod__c == 'Needs_Reconciliation_vod' || emAtt.Online_Registration_Status_vod__c == 'Needs_Reconciliation_vod')) {
                String emAttEmail = emAtt.Email_vod__c;
                if (emAttEmail != null) {
                    emAttEmails.add(emAttEmail);
                    String similarLastName = lastName;
                    if (lastName.length() > 3) {
                        similarLastName = lastName.substring(0, 3) + '%';
                    }
                    emAttLastNames.add(similarLastName);
                }
                
                String nameClause = constructSingleNameClause(emAtt);
                if (nameClause != null) {
                    if (cummulativeClauseLength + nameClause.length() > VeevaEmBusRuleUtils.MAX_SOQL_LINE_LENGTH - maxSelectAndFromClauseLength) {
                        batchNameClauses.add(String.join(curNameClauses, ' OR '));
                        curNameClauses = new List<String>();
                        cummulativeClauseLength = 0;
                    }
                    cummulativeClauseLength += nameClause.length();
                    curNameClauses.add(nameClause);
                }
            }
        }

        if (!curNameClauses.isEmpty()) {
            batchNameClauses.add(String.join(curNameClauses, ' OR '));
        }
        
        // Address Query
        List<Address_vod__c> matchAddresses = queryMatchingAddresses(emAttEmails, emAttLastNames);
        
        // Account Queries
        Map<ID, SObject> matchAccountsMap = queryMatchingAccounts(emAttEmails, batchNameClauses, getAccountIdsFromAddresses(matchAddresses), emAttLastNames);
        List<SObject> matchAccounts = matchAccountsMap.values();
        addressEmailMatchToAccountMap = constructAddressEmailMatchToAccountMap(matchAddresses, matchAccountsMap);
        populateMatchMaps(matchAccounts, accountEmailMatchToAccountMap, accountNameMatchToAccountMap, accountEmailFields);

        // User Queries
        List<SObject> matchUsers = queryMatchingUsers(emAttEmails, batchNameClauses);
        populateMatchMaps(matchUsers, userEmailMatchToUserMap, userNameMatchToUserMap, userEmailFields);
    }

    public SObject findExactMatch(EM_Attendee_vod__c emAtt) {
        String emAttEmail = emAtt.Email_vod__c;
        String emAttFirstName = emAtt.First_Name_vod__c;
        String emAttLastName = emAtt.Last_Name_vod__c;
        SObject accountMatch = findExactAccountMatch(emAttEmail, emAttFirstName, emAttLastName);
        SObject userMatch = findExactUserMatch(emAttEmail, emAttFirstName, emAttLastName);
        
        SObject match = null;
        if (accountMatch != null && userMatch == null) {
            match = accountMatch;
            setEmAttendeeWalkInStatus(emAtt, (Id) match.get('Id'), 'Reconciled_To_Existing_Account_vod');
        } else if (accountMatch == null && userMatch != null) {
            match = userMatch;
            setEmAttendeeWalkInStatus(emAtt, (Id) match.get('Id'), 'Reconciled_To_Existing_User_vod');
        }
        return match;
    }

    @TestVisible
    private String constructSingleNameClause(EM_Attendee_vod__c emAtt) {
        String nameClause = null;
        String emAttFirstName = emAtt != null ? emAtt.First_Name_vod__c : null;
        String emAttLastName = emAtt != null ? emAtt.Last_Name_vod__c : null;
        if (emAttFirstName != null && emAttLastName != null) {
            nameClause = '(FirstName =\'' + String.escapeSingleQuotes(emAttFirstName) + '\' AND LastName = \'' + String.escapeSingleQuotes(emAttLastName) + '\')';
        }
        return nameClause;
    }

    @TestVisible
    private String constructEmailClause(List<String> emailFields) {
        List<String> emailClauses = new List<String>();
        for (String emailField : emailFields) {
            emailClauses.add('(' + emailField + ' IN :emAttEmails)');
        }
        return String.join(emailClauses, ' OR ');
    }
    
    private List<Address_vod__c> queryMatchingAddresses(List<String> emAttEmails, List<String> emAttLastNames) {
        List<Address_vod__c> matchAddresses = new List<Address_vod__c>();
        if (!emAttEmails.isEmpty() && !addressEmailFields.isEmpty()) {
            String addressQuery = 'SELECT Account_vod__c,' + String.join(addressEmailFields, ',') + ' FROM Address_vod__c WHERE Account_vod__r.LastName LIKE :emAttLastNames AND (' + 
                constructEmailClause(addressEmailFields) + ')';
            matchAddresses = Database.query(addressQuery);
        }
        return matchAddresses;
    }
    
    @TestVisible
    private Set<ID> getAccountIdsFromAddresses(List<Address_vod__c> addresses) {
        Set<ID> accountIds = new Set<ID>();
        for (Address_vod__c address : addresses) {
            ID accountId = address.Account_vod__c;
            if (accountId != null) {
                accountIds.add(accountId);
            }
        }
        return accountIds;
    }

    private Map<ID, SObject> queryNameMatches(List<String> batchNameClauses, String objectName, List<String> emailFields) {
        Map<ID, SObject> matchNames = new Map<ID, SObject>();
        String emailFieldsClause = '';
        if (!emailFields.isEmpty()) {
            emailFieldsClause += ',' + String.join(emailFields, ',');
        }
        for (String batchNameClause : batchNameClauses) {
            String nameQuery = 'SELECT Id, LastName, FirstName' + emailFieldsClause + ' FROM ' + objectName + ' WHERE (' + batchNameClause + ')';
            matchNames.putAll(new Map<Id, SObject>((List<SObject>) Database.query(nameQuery)));
        }
        return matchNames;
    }

    private Map<Id, SObject> queryMatchingAccounts(List<String> emAttEmails, List<String> batchNameClauses, Set<ID> matchAddressesIds, List<String> emAttLastNames) {
        Map<ID, SObject> matchAccounts = queryNameMatches(batchNameClauses, 'Account', accountEmailFields);
        if (!emAttEmails.isEmpty() && !accountEmailFields.isEmpty()) {
            String accountEmailQuery = 'SELECT Id, LastName, FirstName,' + String.join(accountEmailFields, ',') + ' FROM Account WHERE LastName LIKE :emAttLastNames AND (' + 
                constructEmailClause(accountEmailFields) + ' OR (Id IN :matchAddressesIds))';
            matchAccounts.putAll(new Map<Id, SObject>((List<SObject>) Database.query(accountEmailQuery)));
        }
        return matchAccounts;
    }

    private List<SObject> queryMatchingUsers(List<String> emAttEmails, List<String> batchNameClauses) {
        Map<ID, SObject> matchUsers = queryNameMatches(batchNameClauses, 'User', userEmailFields);
        if (!emAttEmails.isEmpty() && !userEmailFields.isEmpty()) {
            String userEmailQuery = 'SELECT Id, LastName, FirstName,' + String.join(userEmailFields, ',') + ' FROM User WHERE ' + constructEmailClause(userEmailFields);
            matchUsers.putAll(new Map<Id, SObject>((List<SObject>) Database.query(userEmailQuery)));
        }
        return matchUsers.values();
    }

    @TestVisible
    private String formatFirstAndLastName(String firstName, String lastName) {
        String name = null;
        if (firstName != null && lastName != null) {
            name = lastName + ', ' + firstName;
        }
        return name;
    }

    @TestVisible
    private void populateMatchMaps(List<SObject> matches, Map<String, Set<SObject>> emailMatchMap, Map<String, Set<SObject>> nameMatchMap, List<String> emailFields) {
        for (SObject match : matches) {
            // Maps Email -> Set<Object>
            for (String emailField : emailFields) {
                String email = (String) match.get(emailField);
                if (email != null) {
                    if (!emailMatchMap.containsKey(email)) {
                        emailMatchMap.put(email, new Set<SObject>());
                    }
                    emailMatchMap.get(email).add(match);
                }
            }

            // Maps Name -> Set<Object>
            String firstName = (String) match.get('FirstName');
            String lastName = (String) match.get('LastName');
            if (firstName != null && lastName != null) {
                String formattedName = formatFirstAndLastName(firstName, lastName);
                if (formattedName != null && !nameMatchMap.containsKey(formattedName)) {
                    nameMatchMap.put(formattedName, new Set<SObject>());
                }
                nameMatchMap.get(formattedName).add(match);
            }
        }
    }

    @TestVisible
    private Map<String, Set<SObject>> constructAddressEmailMatchToAccountMap(List<Address_vod__c> matchAddresses, Map<ID, SObject> matchAccountsMap) {
        // Maps (Email on Address) -> Set<Account>
        Map<String, Set<SObject>> emailMatchMap = new Map<String, Set<SObject>>();
        for (Address_vod__c address : matchAddresses) {
            SObject accountLookup = matchAccountsMap.get(address.Account_vod__c);
            if (accountLookup != null) {
                for (String emailField : addressEmailFields) {
                    String email = (String) address.get(emailField);
                    if (email != null) {
                        if (!emailMatchMap.containsKey(email)) {
                            emailMatchMap.put(email, new Set<SObject>());
                        }
                        emailMatchMap.get(email).add(accountLookup);
                    }
                }
            }
        }
        return emailMatchMap;
    }

    @TestVisible
    private boolean lastNamesAreSimilar(String matchLastName, String emAttLastName) {
        boolean areSimilar = false;
        if (matchLastName != null && emAttLastName != null) {
            if (emAttLastName.length() <= 2) {
                areSimilar = emAttLastName.equalsIgnoreCase(matchLastName);
            } else if (matchLastName.length() > 2) {
                areSimilar = emAttLastName.substring(0, 3).equalsIgnoreCase(matchLastName.substring(0, 3));
            }
        }
        return areSimilar;
    }

    @TestVisible
    private SObject findExactNameMatch(String firstName, String lastName, Map<String, Set<SObject>> nameMatchMap) {  
        SObject nameMatch = null;
        Set<SObject> nameMatches = nameMatchMap.get(formatFirstAndLastName(firstName, lastName));
        if (nameMatches != null && nameMatches.size() == 1) {
            // Has to be only one name match
            nameMatch = nameMatches.iterator().next();
        }
        return nameMatch;
    }

    @TestVisible
    private SObject findExactEmailMatch(String email, String lastName, Map<String, Set<SObject>> emailMatchMap, boolean checkForLastName) {
        SObject match = null;
        Set<SObject> emailMatches = emailMatchMap.get(email);
        if (emailMatches != null) {
            List<SObject> exactEmailMatches = new List<SObject>();
            for (SObject emailMatch : emailMatches) {
                // Check for first 3 characters of lastName
                if (checkForLastName && lastNamesAreSimilar((String) emailMatch.get('LastName'), lastName)) {
                    exactEmailMatches.add(emailMatch);
                } else if (!checkForLastName) {
                    exactEmailMatches.add(emailMatch);
                }
            }

            if (exactEmailMatches.size() == 1) {
                // Has to be only one email match
                match = exactEmailMatches.get(0);
            }
        }
        return match;
    }

    private SObject findExactAccountMatch(String email, String firstName, String lastName) {
        SObject match = null;
        if (email != null) {
            match = findExactEmailMatch(email, lastName, accountEmailMatchToAccountMap, true);
        }  
        if (match == null && email != null) {
            match = findExactEmailMatch(email, lastName, addressEmailMatchToAccountMap, true);
        }
        if (match == null && firstName != null && lastName != null) {
            match = findExactNameMatch(firstName, lastName, accountNameMatchToAccountMap);
        }
        return match;
    }

    private SObject findExactUserMatch(String email, String firstName, String lastName) {
        SObject match = null;
        if (email != null) {
            match = findExactEmailMatch(email, lastName, userEmailMatchToUserMap, false);
        }
        if (match == null && firstName != null && lastName != null) {
            match = findExactNameMatch(firstName, lastName, userNameMatchToUserMap);
        }
        return match;
    }

    @TestVisible
    private void setEmAttendeeWalkInStatus(EM_Attendee_vod__c emAtt, ID walkInId, String walkInStatus) {
        emAtt.Walk_In_Reference_ID_vod__c = walkInId;
        if (emAtt.Walk_In_Status_vod__c != null){
            emAtt.Walk_In_Status_vod__c = walkInStatus;
        } else if (emAtt.Online_Registration_Status_vod__c != null) {
            emAtt.Online_Registration_Status_vod__c = walkInStatus;
        }
    }

    @TestVisible
    private Integer computeMaxSelectAndFromClauseLength() {
        Integer knownFieldsLength = 'SELECT Id, LastName, FirstName, FROM Account WHERE (  )'.length();
        Integer maxEmailFieldsClauseLength =  Math.max(String.join(userEmailFields, ',').length(), String.join(accountEmailFields, ',').length());
        return knownFieldsLength + maxEmailFieldsClauseLength;
    }
}