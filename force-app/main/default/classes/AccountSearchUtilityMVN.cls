/*
 * AccountSearchUtilityMVN
 * Created by: Jennifer Wyher
 * Created Date: May 29, 2014
 * Description: This is the generic interface to support Account search from various sources.
 *				Currently the only source being used is Service Cloud and Service Cloud
 *				Accounts and Addresses are searched.
 */

public class AccountSearchUtilityMVN {
	public interface searchInterface {

        List<AccountSearchResultMockMVN> searchChildAccounts(Id accountId);
        List<AccountSearchResultMockMVN> searchParentAccounts(Id accountId);

		// Search the utility for Accounts and Addresses for the identified recordType
		List<AccountSearchResultMockMVN> search(Account account, Address_vod__c address, String typeToSearch, Boolean isPersonType, String alternateId);

		// Insert the identified result record into Salesforce
		AccountSearchResultMockMVN insertAccountDetails(AccountSearchResultMockMVN asr);

	}
}