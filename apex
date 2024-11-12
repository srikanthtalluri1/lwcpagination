public with sharing class WaiverController {
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> fetchWaiverDetails(String recordId) {
        AWP_Architecture_Waiver_Form__c waiver = [SELECT Id, Name, Status__c, Renew_Counter__c 
                                   FROM AWP_Architecture_Waiver_Form__c WHERE Id = :recordId LIMIT 1];

        Map<String, Object> fieldData = new Map<String, Object>();
        fieldData.put('Name', waiver.Name);
        fieldData.put('Status', waiver.Status__c);
        //fieldData.put('RationaleForWaiver', waiver.Rationale_for_Waiver__c);
        fieldData.put('RenewCounter', waiver.Renew_Counter__c);
        //fieldData.put('OriginalWaiverSubmissionDate', waiver.Original_Waiver_Submission_Date__c);

        return fieldData;
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getStatusPicklistValues() {
        List<String> picklistValues = new List<String>();

        // Use Schema information to get picklist values from AWP_Architecture_Waiver_Form__c.Status__c
        Schema.DescribeFieldResult fieldResult = AWP_Architecture_Waiver_Form__c.Status__c.getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();

        for (Schema.PicklistEntry entry : picklistEntries) {
            picklistValues.add(entry.getLabel());
        }

        return picklistValues;
    }
    
    @AuraEnabled
    public static void saveWaiver(Map<String, Object> waiverData, String recordId) {
        AWP_Architecture_Waiver_Form__c waiver;        
        if (recordId != null) {
            waiver = [SELECT Id FROM AWP_Architecture_Waiver_Form__c WHERE Id = :recordId LIMIT 1];
        } else {
            waiver = new AWP_Architecture_Waiver_Form__c();
        }        
        // Loop through the map and set values dynamically
        for (String fieldName : waiverData.keySet()) {
            waiver.put(fieldName, waiverData.get(fieldName));
        }        
        upsert waiver;
    }
}
