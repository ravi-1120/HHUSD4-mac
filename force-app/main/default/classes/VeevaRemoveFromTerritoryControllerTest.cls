@IsTest
public class VeevaRemoveFromTerritoryControllerTest {

    @IsTest
    static void getAccountUserTerritoriesTest() {
        Profile profile = [SELECT Id FROM Profile LIMIT 1];

        User user = createUser(profile);
        List<String> territoryNames = new List<String>{'101', '102', '103'};
        List<Territory2> territories = createAndAssignTerritoriesToUser(user.Id, territoryNames);

        Test.startTest();

        Account acct1;
        Account acct2;
        List<ObjectTerritory2Association> userAccountTerritories;
        System.runAs(user) {
            acct1 = new Account(Name='Clinton Ackerman');
            acct2 = new Account(Name='Serena Smith');
            List<Account> accts = new List<Account>{acct1, acct2};
            insert accts;

            createObjectTerritoryAssociations(acct1.Id, territories);
            createObjectTerritoryAssociations(acct2.Id, territories);

            userAccountTerritories = VeevaRemoveFromTerritoryController.getUserAccountTerritories(acct1.Id);
        }

        Test.stopTest();

        System.assert(userAccountTerritories.size() == 3);
    }

    private static User createUser(Profile profile) {
        User user = new User(LastName = 'User',
                           FirstName='Fake',
                           Alias = 'fuser',
                           Email = 'user@rft.veeva.com',
                           Username = Math.random() + '@' + Math.random(),
                           ProfileId = profile.Id,
                           TimeZoneSidKey = 'GMT',
                           LanguageLocaleKey = 'en_US',
                           EmailEncodingKey = 'UTF-8',
                           LocaleSidKey = 'en_US'
        );
        insert user;
        return user;
    }

    private static void createObjectTerritoryAssociations(Id accountId, List<Territory2> territoriesToAlign) {
        List<ObjectTerritory2Association> objTerrAssignments = new List<ObjectTerritory2Association>();
        for (Territory2 territory : territoriesToAlign) {
            ObjectTerritory2Association ot2a = new ObjectTerritory2Association(Territory2Id=territory.Id, ObjectId=accountId, AssociationCause='Territory2Manual');
            objTerrAssignments.add(ot2a);
        }
        insert objTerrAssignments;
    }

    private static List<Territory2> createAndAssignTerritoriesToUser(Id userId, List<String> territoryNames) {
        Territory2Model territory2Model = new Territory2Model(Name='Model', DeveloperName='Model');
        insert territory2Model;
        Territory2Type territory2Type = [SELECT Id FROM Territory2Type LIMIT 1];
        List<Territory2> territories = createTerritories(territoryNames, territory2Model, territory2Type);

        createUserTerritoryAssociations(userId, territories);

        return territories;
    }

    private static void createUserTerritoryAssociations(Id userId, List<Territory2> territories) {
        List<UserTerritory2Association> associations = new List<UserTerritory2Association>();
        for (Territory2 territory : territories) {
            UserTerritory2Association association = new UserTerritory2Association(Territory2Id=territory.Id, UserId=userId);
            associations.add(association);
        }
        insert associations;
    }

    private static List<Territory2> createTerritories(List<String> territoryNames, Territory2Model territory2Model, Territory2Type territory2Type) {
        List<Territory2> territories = new List<Territory2>();
        for (String territoryName : territoryNames) {
            Territory2 territory = new Territory2(
                Name=territoryName,
                Territory2ModelId=territory2Model.Id,
                DeveloperName='X' + territoryName,
                Territory2TypeId=territory2Type.Id
            );
            territories.add(territory);
        }
        insert territories;
        return territories;
    }
}