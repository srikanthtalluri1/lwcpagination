public with sharing class AWP_WaiverHandlerClass {
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getWaiverRecordAndPermissions(String sortBy, String sortByType, String sortOrder, Integer pageSize, 
                                                                    String after, String lastId, String before, String firstId, boolean first, boolean last, Integer lastPageSize) {
        Map<String, Object> result = new Map<String, Object>();

        // Get the Current User's Id
        String userId = UserInfo.getUserId();

        // Fetch the user's permission sets
        List<PermissionSetAssignment> psaList = [SELECT PermissionSet.Name FROM PermissionSetAssignment WHERE AssigneeId = :userId];
        List<String> permissionSetNames = new List<String>();
        for (PermissionSetAssignment psa : psaList) {
            permissionSetNames.add(psa.PermissionSet.Name);
        }
        result.put('permissionSets', permissionSetNames);

        // Get the permission set name from custom label
        String permissionSetName = Label.See_All_Waivers;

        // Determine the query based on the user's permission sets
        List<AWP_Architecture_Waiver_Form__c> waiverRecords;
        String query = 'SELECT Id, Name, Status__c, Waiver_Reason__c, Requesting_Portfolio__c, Standard_Page_Title__c, Requesting_TPM__c ' +
                       'FROM AWP_Architecture_Waiver_Form__c ';

        if (permissionSetNames.contains(permissionSetName)) {
            // Add additional filter if needed
        }

        // Add sorting and pagination logic
        if ((after != '' && !last) || (before != '' && !first)) {
            String param = ':textParam';
            String textParam = after != '' && after != 'NULL' ? after : (before != '' && before != 'NULL' ? before : null);
            if (sortByType == 'Number' && textParam != null) {
                param = ':numberParam';
                Integer numberParam = Integer.valueOf(textParam);
            } else if (sortByType == 'Date' && textParam != null) {
                param = ':dateParam';
                Date dateParam = Date.valueOf(textParam);
            }

            String field = sortBy;
            if (after != '' && !last) {
                String operator = sortOrder == 'asc' ? '>' : '<';
                if (after == 'NULL') {
                    query += 'WHERE (' + field + ' != NULL OR (' + field + '= NULL AND Id' + operator + '\'' + lastId + '\')) ';
                } else if (sortOrder == 'desc') {
                    query += 'WHERE (' + field + operator + param + ' OR ' + field + ' = NULL OR (' + field + '=' + param + ' AND Id' + operator + '\'' + lastId + '\')) ';
                } else {
                    query += 'WHERE (' + field + operator + param + ' OR (' + field + '=' + param + ' AND Id' + operator + '\'' + lastId + '\')) ';
                }
            } else if (before != '' && !first) {
                String operator = sortOrder == 'asc' ? '<' : '>';
                if (before == 'NULL') {
                    query += 'WHERE (' + field + ' != NULL OR (' + field + '= NULL AND Id' + operator + '\'' + firstId + '\')) ';
                } else if (sortOrder == 'asc') {
                    query += 'WHERE (' + field + operator + param + ' OR ' + field + ' = NULL OR (' + field + '=' + param + ' AND Id' + operator + '\'' + firstId + '\')) ';
                } else {
                    query += 'WHERE (' + field + operator + param + ' OR (' + field + '=' + param + ' AND Id' + operator + '\'' + firstId + '\')) ';
                }
            }
        }

        String orderQuery = '';
        if (last || (before != '' && !first)) {
            orderQuery = 'ORDER BY ' + sortBy + ' ' + (sortOrder == 'asc' ? 'desc NULLS LAST ' : 'asc NULLS FIRST ') + ', Id ' + (sortOrder == 'asc' ? 'desc' : 'asc');
        } else {
            orderQuery = 'ORDER BY ' + sortBy + ' ' + (sortOrder == 'asc' ? 'asc NULLS FIRST ' : 'desc NULLS LAST ') + ', Id ' + sortOrder;
        }
        query += orderQuery + ' LIMIT ' + (last && lastPageSize > 0 ? lastPageSize : pageSize);

        waiverRecords = Database.query(query);

        if ((before != '' && !first) || last) {
            List<AWP_Architecture_Waiver_Form__c> tmp = new List<AWP_Architecture_Waiver_Form__c>();
            for (Integer i = waiverRecords.size() - 1; i >= 0; i--) {
                tmp.add(waiverRecords.get(i));
            }
            waiverRecords = tmp;
        }

        result.put('waiverRecords', waiverRecords);
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static Integer getWaiverCount() {
        return [SELECT Count() FROM AWP_Architecture_Waiver_Form__c];
    }
}
