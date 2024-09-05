 @AuraEnabled(cacheable=true)
  public static Map<String, List<Object>> getUniqueValues(
    List<String> fieldApiName,
    String allOrMy
  ) {
    try {
      Map<String, List<AggregateResult>> results = new Map<String, List<AggregateResult>>();
      Map<String, List<Object>> fieldUniqueMap = new Map<String, List<Object>>();
      String condition = '';
      if (allOrMy == 'mywaivers') {
        condition += ' WHERE OwnerId = \'' + userId + '\' ';
      }
      for (String field : fieldApiName) {
        if (
          new List<String>{ 'BARR Risk Level', 'Waiver Reason', 'Status' }
            .contains(field)
        ) {
          String query =
            'SELECT ' +
            fieldList.get(field) +
            ',COUNT(Id) FROM AWP_Architecture_Waiver_Form__c' +
            condition +
            ' GROUP BY ' +
            fieldList.get(field);
          results.put(field, Database.query(query));
        } else if (
          field == 'Affected Standard Portfolio' ||
          field == 'Requesting Portfolio'
        ) {
          String query =
            'SELECT Name, COUNT(Id) FROM TPM_Port__c' +
            condition +
            ' GROUP BY Name';
          results.put(field, Database.query(query));
        }
      }
      for (String field : results.keySet()) {
        List<Object> uniqueValues = new List<Object>();
        for (AggregateResult ar : results.get(field)) {
          Map<String, Object> uni = new Map<String, Object>();
          if (
            new List<String>{ 'BARR Risk Level', 'Waiver Reason', 'Status' }
              .contains(field)
          ) {
            uni.put('value', (String) ar.get(fieldList.get(field)));
            uni.put('count', (Integer) ar.get('expr0'));
            uniqueValues.add((Object) uni);
          } else if (
            field == 'Affected Standard Portfolio' ||
            field == 'Requesting Portfolio'
          ) {
            uni.put('value', (String) ar.get('Name'));
            uni.put('count', (Integer) ar.get('expr0'));
            uniqueValues.add((Object) uni);
          }
        }
        fieldUniqueMap.put(field, uniqueValues);
      }
      return fieldUniqueMap;
    } catch (Exception e) {
      System.debug('message' + e.getMessage());
      System.debug('stack' + e.getStackTraceString());
      throw new AuraHandledException(e.getMessage());
    }
  }
}
