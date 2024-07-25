public with sharing class AWP_WaiverHandlerClass {
  public static Id userId = UserInfo.getUserId();

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
    String allOrMy
  ) {
    Map<String, Object> result = new Map<String, Object>();

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
      'SELECT Id, Name, Status__c, Waiver_Reason__c, Requesting_Portfolio__c, BARR_Risk_Level__c, Affected_Standard_Portfolio__c, Renew_Counter__c, Affected_Domain_New__c, App_Name__c, Standard_Page_Title__c, Requesting_TPM__c ' +
      'FROM AWP_Architecture_Waiver_Form__c ';
    String countQuery =
      'SELECT COUNT()' + 'FROM AWP_Architecture_Waiver_Form__c ';

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
      ' OR Requesting_Portfolio__c LIKE ' +
      searchKey +
      ' OR Renew_Counter__c LIKE ' +
      searchKey +
      ' OR BARR_Risk_Level__c LIKE ' +
      searchKey +
      ' OR Affected_Standard_Portfolio__c LIKE ' +
      searchKey +
      ' OR Affected_Domain_New__c LIKE ' +
      searchKey +
      ' OR Waiver_Reason__c LIKE ' +
      searchKey +
      ' ) ';
    return query;
  }
}
