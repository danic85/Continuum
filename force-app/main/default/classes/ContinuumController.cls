@RestResource(urlMapping='/EngagementEntries/*')
global with sharing class ContinuumController {
    @AuraEnabled
    public static List<EngagementDto> getAvailableEngagements() {
        List<Engagement__c> engagements = EngagementSelector.getAvailableEngagements();
        List<EngagementDto> response = new List<EngagementDto>();
        if (engagements.size() > 0) {
            for (Engagement__c e : engagements) {
                System.debug(e);
                System.debug(e.Engagement_Entries__r.size());

                response.add(new EngagementDto(e.Id, e.Name, (e.Engagement_Entries__r.size() > 0)));
            }
        }
        System.debug(response);
        return response;
    }

    public with sharing class EngagementDto {
        @AuraEnabled
        public Id id;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public boolean selected;
        public EngagementDto(Id id, String name, Boolean selected) {
            this.id = id;
            this.name = name;
            this.selected = selected;
        }
    }

    @AuraEnabled
    @HttpPost
    global static void startEngagementEntry(String engagementId) {
        if (endEngagementsExceptId(engagementId) == false) return;
        // Save new engagement with current start time for the given ID
        Engagement_Entry__c entry = new Engagement_Entry__c(Engagement__c = engagementId, Start__c = Datetime.now());
        insert entry;
    }

    @AuraEnabled
    public static void endEngagements() {
        endEngagementsExceptId(null);
    }

    private static boolean endEngagementsExceptId(String newEngagement) {
        // End and close all open engagements
        List<Engagement_Entry__c> openEntries = [SELECT Id, Engagement__c FROM Engagement_Entry__c WHERE Engagement__r.User__c = :UserInfo.getUserId() AND End__c = NULL];
        if (openEntries.size() > 0) {
            for(Engagement_Entry__c e : openEntries) {
                if (newEngagement != '' && e.Engagement__c == Id.valueOf(newEngagement)) return false; // Don't end the engagement if it is the current active one.
                e.End__c = Datetime.now();
            }
        }
        update openEntries;
        if (newEngagement == '') return false; // No new engagement
        return true;
    }
}
