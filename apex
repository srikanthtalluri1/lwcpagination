public with sharing class AWP_WaiverHandlerClass {
  public static Id userId = UserInfo.getUserId();
  public static Map<String, Schema.SObjectField> waiverFormFields = Schema.getGlobalDescribe()
    .get('AWP_Architecture_Waiver_Form__c')
    .getDescribe()
    .fields.getMap();
  static final String FIELDS_TO_BE_QUERIED = 'Id, Name, Status__c, Waiver_Reason__c, Requesting_Portfolio__c, Requesting_Domain_New__r.Port__r.Name, BARR_Risk_Level__c, Affected_Standard_Portfolio__c,Affected_Domain_New__r.Port__r.Name, Renew_Counter__c, App_Name__r.BARR_Risk_Level__c, App_Name__c, Standard_Page_Title__c, Requesting_TPM__c ';
  static final String OBJECT_NAME = 'AWP_Architecture_Waiver_Form__c';
  Map<String, String> waiverStatus = new Map<String, String>();
  Map<String, String> waiverReason = new Map<String, String>();
  Map<String, String> waiverBarrRisk = new Map<String, String>();
  Map<String, String> waiverAffectedPort = new Map<String, String>();
  Map<String, String> waiverRequestingPort = new Map<String, String>();

  public AWP_WaiverHandlerClass() {
    for (
      Schema.PicklistEntry status : AWP_Architecture_Waiver_Form__c.Status__c.getDescribe()
        .getPicklistValues()
    ) {
      waiverStatus.put(status.getValue(), status.getValue());
    }
    for (
      Schema.PicklistEntry reason : AWP_Architecture_Waiver_Form__c.Waiver_Reason__c.getDescribe()
        .getPicklistValues()
    ) {
      waiverReason.put(status.getValue(), status.getValue());
    }
    for (
      Schema.PicklistEntry risk : AWP_Architecture_Waiver_Form__c.BARR_Risk_Level_UI__c.getDescribe()
        .getPicklistValues()
    ) {
      waiverBarrRisk.put(status.getValue(), status.getValue());
    }

    for (String str : new List<String>{ 'Test1', 'Test2' }) {
      waiverAffectedPort.put(str, str);
    }

    for (String str : new List<String>{ 'Request1', 'Request2' }) {
      waiverRequestingPort.put(str, str);
    }
  }

  public static Map<String, String> fieldList = new Map<String, String>{
    'Requesting Portfolio' => 'Requesting_Portfolio__c',
    'Affected Standard Portfolio' => 'Affected_Standard_Portfolio__c',
    'BARR Risk Level' => 'BARR_Risk_Level_UI__c',
    'Waiver Reason' => 'Waiver_Reason__c',
    'Status' => 'Status__c'
  };

  @AuraEnabled(cacheable=true)
  public static Map<String, Object> getWaiverRecordAndPermissions(
    String searchKey,
    String sortBy,
    String sortOrder,
    Integer pageSize,
    String after,
    String lastId,
    String before,
    String firstId,
    boolean first,
    boolean last,
    Integer lastPageSize,
    String allOrMy,
    String filters
  ) {
    Map<String, Object> result = new Map<String, Object>();
    Set<String> filterValues = new Set<String>();

    System.debug('filters====' + filters);
    // Get the Current User's Id
    String userId = UserInfo.getUserId();

    // Fetch the user's permission sets
    List<PermissionSetAssignment> psaList = [
      SELECT PermissionSet.Name
      FROM PermissionSetAssignment
      WHERE AssigneeId = :userId
    ];

    List<String> permissionSetNames = new List<String>();
    for (PermissionSetAssignment psa : psaList) {
      permissionSetNames.add(psa.PermissionSet.Name);
    }
    result.put('permissionSets', permissionSetNames);

    // Get the permission set name from custom label
    String permissionSetName = Label.See_All_Waivers;

    // Determine the query based on the user's permission sets
    List<AWP_Architecture_Waiver_Form__c> waiverRecords;
    Integer waiverRecordsCount = 0;

    String query =
      'SELECT ' +
      FIELDS_TO_BE_QUERIED +
      'FROM ' +
      OBJECT_NAME +
      ' ';
    String countQuery = 'SELECT COUNT()' + 'FROM ' + OBJECT_NAME + ' ';

    if (!permissionSetNames.contains(permissionSetName)) {
      query += ' WHERE Status__c = \'Approved\'';
      countQuery += ' WHERE Status__c = \'Approved\'';
    }

    //Search logic
    if (String.isNotBlank(searchKey)) {
      String textFilter = '\'%' + searchKey + '%\'';
      if (!query.contains('WHERE')) {
        query += ' WHERE ';
        countQuery += ' WHERE ';
      } else {
        query += ' AND ';
        countQuery += ' AND ';
      }
      query = buildSearchTerm(query, textFilter);
      countQuery = buildSearchTerm(countQuery, textFilter);
    }
    //END

    // Add sorting and pagination logic
    if (
      (after != '' && !last) ||
      (after != '' && last) ||
      (before != '' && !first) ||
      (before != '' && first)
    ) {
      String param = ':textParam';
      String textParam = after != '' &&
        after != 'NULL'
        ? after
        : (before != '' && before != 'NULL' ? before : null);

      String field = sortBy;
      if ((after != '' && !last) || (after != '' && last)) {
        String operator = sortOrder == 'asc' ? '>' : '<';
        if (after == 'NULL') {
          query +=
            (!query.contains('WHERE') ? 'WHERE (' : 'AND ( ') +
            field +
            ' != NULL OR (' +
            field +
            ' = NULL AND Id ' +
            operator +
            ' \'' +
            lastId +
            '\' )) ';
        } else if (sortOrder == 'desc') {
          query +=
            (!query.contains('WHERE') ? 'WHERE (' : 'AND ( ') +
            field +
            ' ' +
            operator +
            ' ' +
            param +
            ' OR ' +
            field +
            ' = NULL OR ( ' +
            field +
            ' = ' +
            param +
            ' AND Id ' +
            operator +
            ' \'' +
            lastId +
            '\' )) ';
        } else {
          query +=
            (!query.contains('WHERE') ? 'WHERE (' : 'AND ( ') +
            field +
            ' ' +
            operator +
            ' ' +
            param +
            ' OR (' +
            field +
            ' = ' +
            param +
            ' AND Id ' +
            operator +
            ' \'' +
            lastId +
            '\' )) ';
        }
      } else if ((before != '' && !first) || (before != '' && first)) {
        String operator = sortOrder == 'asc' ? '<' : '>';
        if (before == 'NULL') {
          query +=
            (!query.contains('WHERE') ? 'WHERE (' : 'AND ( ') +
            field +
            ' != NULL OR ( ' +
            field +
            '= NULL AND Id ' +
            operator +
            ' \'' +
            firstId +
            '\' )) ';
        } else if (sortOrder == 'asc') {
          query +=
            (!query.contains('WHERE') ? 'WHERE (' : 'AND ( ') +
            field +
            ' ' +
            operator +
            ' ' +
            param +
            ' OR ' +
            field +
            ' = NULL OR ( ' +
            field +
            ' = ' +
            param +
            ' AND Id ' +
            operator +
            ' \'' +
            firstId +
            '\' )) ';
        } else {
          query +=
            (!query.contains('WHERE') ? 'WHERE (' : 'aAND ( ') +
            field +
            ' ' +
            operator +
            ' ' +
            param +
            ' OR (' +
            field +
            ' = ' +
            param +
            ' AND Id ' +
            operator +
            ' \'' +
            firstId +
            '\' )) ';
        }
      }
    }

    //Add for All or My waivers
    if (allOrMy == 'mywaivers') {
      query += (!query.contains('WHERE')
        ? ' WHERE OwnerId = \'' + userId + '\' '
        : ' AND OwnerId = \'' + userId + '\' ');
      countQuery += (!countQuery.contains('WHERE')
        ? ' WHERE OwnerId = \'' + userId + '\' '
        : ' AND OwnerId = \'' + userId + '\' ');
    }
    //END

    //Add for filter Logic
    if (!String.isBlank(filters)) {
      List<Object> filtersList = (List<Object>) JSON.deserializeUntyped(
        filters
      );

      if (filtersList.size() > 0) {
        String filterQuery = ' AND (';
        for (Object filter : filtersList) {
          Map<String, Object> filterMap = (Map<String, Object>) filter;
          System.debug('filterMap====' + filterMap);
          for (String key : filterMap.keySet()) {
            if (
              filterMap.get(key) instanceof List<Object> &&
              ((List<Object>) filterMap.get(key)).size() > 0
            ) {
              for (Object value : (List<Object>) filterMap.get(key)) {
                filterValues.add(String.valueOf(value));
              }
              filterQuery += ' ' + key + ' IN :filterValues' + ' OR';
            }
          }
        }
        System.debug('filterQuery====' + filterQuery);
        filterQuery = filterQuery.removeEnd(' OR') + ') ';
        query += filterQuery;
        countQuery += filterQuery;
      }
    }

    //END

    String orderQuery = '';
    if (last || (before != '' && !first) || (before != '' && first)) {
      orderQuery =
        'ORDER BY ' +
        sortBy +
        ' ' +
        (sortOrder == 'asc' ? 'desc NULLS LAST ' : 'asc NULLS FIRST ') +
        ', Id ' +
        (sortOrder == 'asc' ? 'desc' : 'asc');
    } else {
      orderQuery =
        'ORDER BY ' +
        sortBy +
        ' ' +
        (sortOrder == 'asc' ? 'asc NULLS FIRST ' : 'desc NULLS LAST ') +
        ', Id ' +
        sortOrder;
    }

    query +=
      orderQuery +
      ' LIMIT ' +
      (lastPageSize > 0 ? lastPageSize : pageSize);

    System.debug('filterValues====' + filterValues);
    System.debug('query===' + query);
    waiverRecords = Database.query(query);
    waiverRecordsCount = Database.countQuery(countQuery);

    if (last || (before != '' && !first) || (before != '' && first)) {
      List<AWP_Architecture_Waiver_Form__c> tmp = new List<AWP_Architecture_Waiver_Form__c>();
      for (Integer i = waiverRecords.size() - 1; i >= 0; i--) {
        tmp.add(waiverRecords.get(i));
      }
      waiverRecords = tmp;
    }

    result.put('waiverRecords', waiverRecords);
    result.put('waiverRecordsCount', waiverRecordsCount);
    return result;
  }

  private static String buildSearchTerm(String query, String searchKey) {
    query +=
      '( Name LIKE ' +
      searchKey +
      ' OR App_Name__c LIKE ' +
      searchKey +
      ' OR Standard_Page_Title__c LIKE ' +
      searchKey +
      ' OR Requesting_TPM__c LIKE' +
      searchKey +
      ' OR Requesting_Domain_New__r.Port__r.Name LIKE ' +
      searchKey +
      ' OR Renew_Counter__c LIKE ' +
      searchKey +
      ' OR App_Name__r.BARR_Risk_Level__c LIKE ' +
      searchKey +
      ' OR Affected_Domain_New__r.Port__r.Name LIKE ' +
      searchKey +
      ' OR Waiver_Reason__c LIKE ' +
      searchKey +
      ' ) ';
    return query;
  }

  @AuraEnabled(cacheable=true)
  public static Map<String, Object> getFilterDetails() {
    Map<String, Object> result = new Map<String, Object>();
    List<Object> filterOptions = new List<Object>();
    for (String s : filterList.keySet()) {
      filterOptions.add(
        new Map<String, Object>{
          'label' => s,
          'value' => s,
          'selected' => false
        }
      );
    }
    result.put('filterOptions', filterOptions);
    return result;
  }

  @AuraEnabled(cacheable=true)
  public static Map<String, List<Object>> getUniqueValues(
    List<String> fieldApiName
  ) {
    try {
      Map<String, List<AggregateResult>> results = new Map<String, List<AggregateResult>>();
      Map<String, List<Object>> fieldUniqueMap = new Map<String, List<Object>>();
      for (String field : fieldApiName) {
        if (
          new List<String>{ 'BARR Risk Level', 'Waiver Reason', 'Status' }
            .contains(field)
        ) {
          String query =
            'SELECT ' +
            fieldList.get(field) +
            ',COUNT(Id) FROM AWP_Architecture_Waiver_Form__c GROUP BY ' +
            fieldList.get(field);
          results.put(field, Database.query(query));
        } else if (
          field == 'Affected Standard Portfolio' ||
          field == 'Requesting Portfolio'
        ) {
          String query = 'SELECT Name, COUNT(Id) FROM TPM_Port__c GROUP BY Name';
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
