public with sharing class EngagementSelector {
    public static List<Engagement__c> getAvailableEngagements() {
        // return all active engagements for the current user in the given timeframe
        return [SELECT Id, Name, (SELECT ID FROM Engagement_Entries__r WHERE End__c = NULL) FROM Engagement__c 
                                            WHERE Active__c  = true 
                                            AND User__c = :UserInfo.getUserId()
                                            AND Start__c <= TODAY 
                                            AND (End__c = NULL OR End__c >= TODAY) 
                                            ORDER BY Name ASC];
    }
}
