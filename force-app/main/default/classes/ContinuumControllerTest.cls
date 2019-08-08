@IsTest
public with sharing class ContinuumControllerTest {

    @TestSetup
    static void makeData(){
        Id p = [select id from profile where name = 'Standard User'].id;
        User user = new User(alias = 'c.user', email='test.user@example.org',
                emailencodingkey='UTF-8', lastname='Test', languagelocalekey='en_US',
                localesidkey='en_US', profileid = p, country='United States',IsActive = true,
                timezonesidkey='America/Los_Angeles', username='tester@noemail.com');
        
        insert user;

        Id ps = [SELECT Id from PermissionSet WHERE Name = 'Continuum_User'].id;

        PermissionSetAssignment psa = new PermissionSetAssignment
        (PermissionSetId = ps, AssigneeId = user.Id);
        insert psa; 

        List<Engagement__c> engagements = new List<Engagement__c>();

        engagements.add(new Engagement__c(
            User__c = UserInfo.getUserId(),
            Name = 'Active With Start Date but not user',
            Active__c = true,
            Start__c = Date.today().addMonths(-1)
        ));

        engagements.add(new Engagement__c(
            User__c = user.Id,
            Name = 'Active With Start Date',
            Active__c = true,
            Start__c = Date.today()
        )); // Active

        engagements.add(new Engagement__c(
            User__c = user.Id,
            Name = 'Inactive With Start Date',
            Active__c = false,
            Start__c = Date.today()
        ));

        engagements.add(new Engagement__c(
            User__c = user.Id,
            Name = 'Active With Start and End Date',
            Active__c = true,
            Start__c = Date.today(),
            End__c = Date.today().addMonths(1)
        )); // Active

        engagements.add(new Engagement__c(
            User__c = user.Id,
            Name = 'Inactive With Start and End Date',
            Active__c = false,
            Start__c = Date.today(),
            End__c = Date.today().addMonths(1)
        ));

        engagements.add(new Engagement__c(
            User__c = user.Id,
            Name = 'Inactive With Past Start',
            Active__c = false,
            Start__c = Date.today().addMonths(-1)
        ));

        engagements.add(new Engagement__c(
            User__c = user.Id,
            Name = 'Inactive With Past Start and Future End',
            Active__c = false,
            Start__c = Date.today().addMonths(-1),
            End__c = Date.today().addMonths(1)
        ));

        engagements.add(new Engagement__c(
            User__c = user.Id,
            Name = 'Active With Past Start',
            Active__c = true,
            Start__c = Date.today().addMonths(-1)
        )); // Active

        engagements.add(new Engagement__c(
            User__c = user.Id,
            Name = 'Active With Past Start and Future End',
            Active__c = true,
            Start__c = Date.today().addMonths(-1),
            End__c = Date.today().addMonths(1)
        )); // Active

        engagements.add(new Engagement__c(
            User__c = user.Id,
            Name = 'Active With Future Start',
            Active__c = false,
            Start__c = Date.today().addMonths(+1)
        ));

        engagements.add(new Engagement__c(
            User__c = user.Id,
            Name = 'Active With Past End',
            Active__c = false,
            Start__c = Date.today(),
            End__c = Date.today().addMonths(-1)
        ));

        User admin = [SELECT Id FROM User WHERE id =: UserInfo.getUserId()];

        System.runAs(admin){
            insert engagements;
        }
    }

    @IsTest
    static void getEngagementsTest() {
        User u = [SELECT id FROM User WHERE email = 'test.user@example.org'];
        System.runAs(u){
            List<ContinuumController.EngagementDto> response = ContinuumController.getAvailableEngagements();
            System.assertEquals(4, response.size());
            System.assertEquals('Active With Past Start', response[0].name); // Returns in alphabetical order
        }
    }

    @IsTest
    static void startEngagementEntryTest() {
        User u = [SELECT id FROM User WHERE email = 'test.user@example.org'];
        System.runAs(u){
            List<Engagement__c> engagements = [SELECT Id, Name, Start__c FROM Engagement__c WHERE Active__c  = true AND User__c = :UserInfo.getUserId() AND Start__c <= TODAY AND (End__c = NULL OR End__c >= TODAY)];
            System.assertEquals(4, engagements.size());

            // Start work on engagement 1
            ContinuumController.startEngagementEntry(engagements[0].Id);
            List<Engagement_Entry__c> entries = [SELECT Id, Name, Start__c, End__c, Engagement__c FROM Engagement_Entry__c WHERE End__c = NULL];
            System.assertEquals(1, entries.size());
            System.assertEquals(Datetime.now(), entries[0].Start__c);
            System.assertEquals(NULL, entries[0].End__c);
            System.assertEquals(engagements[0].Id, entries[0].Engagement__c);

            // Start work on engagement 2
            ContinuumController.startEngagementEntry(engagements[1].Id);
            entries = [SELECT Id, Name, Start__c, End__c, Engagement__c FROM Engagement_Entry__c WHERE End__c = NULL]; // Check new engagement entry
            System.assertEquals(1, entries.size());
            System.assertEquals(Datetime.now(), entries[0].Start__c);
            System.assertEquals(NULL, entries[0].End__c);
            System.assertEquals(engagements[1].Id, entries[0].Engagement__c);

            entries = [SELECT Id, Name, Start__c, End__c, Engagement__c FROM Engagement_Entry__c WHERE End__c != NULL]; // Check closed engagement entry
            System.assertEquals(1, entries.size());
            System.assertEquals(Datetime.now(), entries[0].Start__c);
            System.assertEquals(Datetime.now(), entries[0].End__c);
            System.assertEquals(engagements[0].Id, entries[0].Engagement__c);


            // Select engagement 2 again
            ContinuumController.startEngagementEntry(engagements[1].Id);
            entries = [SELECT Id, Name, Start__c, End__c, Engagement__c FROM Engagement_Entry__c WHERE End__c = NULL]; // Check new engagement entry
            System.assertEquals(1, entries.size());
            System.assertEquals(Datetime.now(), entries[0].Start__c);
            System.assertEquals(NULL, entries[0].End__c);
            System.assertEquals(engagements[1].Id, entries[0].Engagement__c);

            entries = [SELECT Id, Name, Start__c, End__c, Engagement__c FROM Engagement_Entry__c WHERE End__c != NULL]; // Check closed engagement entry
            System.assertEquals(1, entries.size(), 'If the active engagement is selected again, it should not replace with a new entry.');
        }
    }

    @IsTest
    static void endEngagementsTest() {
        User u = [SELECT id FROM User WHERE email = 'test.user@example.org'];
        System.runAs(u){
            List<Engagement__c> engagements = [SELECT Id, Name, Start__c FROM Engagement__c WHERE Active__c  = true AND User__c = :UserInfo.getUserId() AND Start__c <= TODAY AND (End__c = NULL OR End__c >= TODAY)];
            System.assertEquals(4, engagements.size());

            List<Engagement_Entry__c> newEntries = new List<Engagement_Entry__c>();
            // Start work on engagements (multiple would never be active at the same time in real life)
            newEntries.add(new Engagement_Entry__c(Engagement__c = engagements[0].Id, Start__c = Datetime.now()));
            newEntries.add(new Engagement_Entry__c(Engagement__c = engagements[1].Id, Start__c = Datetime.now()));
            newEntries.add(new Engagement_Entry__c(Engagement__c = engagements[2].Id, Start__c = Datetime.now()));
            insert newEntries;

            // End engagements
            ContinuumController.endEngagements();
            List<Engagement_Entry__c> entries = [SELECT Id, Name, Start__c, End__c, Engagement__c FROM Engagement_Entry__c WHERE End__c != NULL]; // Check closed engagement entries
            System.assertEquals(3, entries.size());
            for (Engagement_Entry__c e : entries) {
                System.assertEquals(Datetime.now(), e.Start__c);
                System.assertEquals(Datetime.now(), e.End__c);
                System.assertNotEquals(NULL, e.Engagement__c);
            }
        }
    }
}