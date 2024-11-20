public with sharing class AWP_WaiverHandlerClass {
  public static Id userId = UserInfo.getUserId();
  public static Map<String, Schema.SObjectField> waiverFormFields = Schema.getGlobalDescribe()
    .get('AWP_Architecture_Waiver_Form__c')
    .getDescribe()
    .fields.getMap();
  // static final String FIELDS_TO_BE_QUERIED = 'Id, Name, Status__c, Waiver_Reason__c, Requesting_Portfolio__c, BARR_Risk_Level_UI__c, Affected_Standard_Portfolio__c,Renew_Counter__c, App_Name__c, Standard_Page_Title__c, Requesting_TPM__c ';

  //Above please add the fields that you want to be queried
  static final String FIELDS_TO_BE_QUERIED_NEW = 'Id, Waiver_Id__c, Waiver_Id__r.Name, Waiver_Id__r.Status__c, Waiver_Id__r.Waiver_Reason__c, Waiver_Id__r.Requesting_Portfolio__c, Waiver_Id__r.BARR_Risk_Level_UI__c, Waiver_Id__r.Renew_Counter__c, Waiver_Id__r.App_Name__c, Waiver_Id__r.Standard_Page_Title__c, Requesting_Application__c, Affected_Standard_Portfolio__c ';

  static final String OBJECT_NAME = 'AWP_Waiver_Relationship__c';
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
      waiverReason.put(reason.getValue(), reason.getValue());
    }
    for (
      Schema.PicklistEntry risk : AWP_Architecture_Waiver_Form__c.BARR_Risk_Level_UI__c.getDescribe()
        .getPicklistValues()
    ) {
      waiverBarrRisk.put(risk.getValue(), risk.getValue());
    }

    for (String str : new List<String>{ 'Test1', 'Test2' }) {
      waiverAffectedPort.put(str, str);
    }

    for (String str : new List<String>{ 'Request1', 'Request2' }) {
      waiverRequestingPort.put(str, str);
    }
  }

  //Added the fields that we are looking to have filter options. If the field from Relationship record use the formula field in the value and the label in the key
  public static Map<String, String> fieldList = new Map<String, String>{
    'Requesting Application' => 'Requesting_Application__c',
    'Affected Standard Portfolio' => 'Affected_Standard_Portfolio__c',
    'BARR Risk Level' => 'Waiver_Id__r.BARR_Risk_Level_UI__c',
    'Waiver Reason' => 'Waiver_Id__r.Waiver_Reason__c',
    'Status' => 'Waiver_Id__r.Status__c'
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
    List<AWP_Waiver_Relationship__c> waiverRecords;
    Integer waiverRecordsCount = 0;

    String query =
      'SELECT ' +
      FIELDS_TO_BE_QUERIED_NEW +
      'FROM ' +
      OBJECT_NAME +
      ' ';
    String countQuery = 'SELECT COUNT()' + 'FROM ' + OBJECT_NAME + ' ';

    if (!permissionSetNames.contains(permissionSetName)) {
      query += ' WHERE Waiver_Id__r.Status__c = \'Approved\'';
      countQuery += ' WHERE Waiver_Id__r.Status__c = \'Approved\'';
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
        ? ' WHERE Waiver_Id__r.OwnerId = \'' + userId + '\' '
        : ' AND Waiver_Id__r.OwnerId = \'' + userId + '\' ');
      countQuery += (!countQuery.contains('WHERE')
        ? ' WHERE Waiver_Id__r.OwnerId = \'' + userId + '\' '
        : ' AND Waiver_Id__r.OwnerId = \'' + userId + '\' ');
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
              
            /*if (
              filterMap.get(key) instanceof List<Object> &&
              ((List<Object>) filterMap.get(key)).size() > 0
            ) {
                
              for (Object value : (List<Object>) filterMap.get(key)) {
                filterValues.add(String.valueOf(value));
              }
              filterQuery +=
                ' ' +
                fieldList.get(key) +
                ' IN :filterValues' +
                ' AND';
            }*/
              
              /*Srikanth Changes*/
              // Ensuring the key exists and the value is a list
              if (filterMap.get(key) != null && filterMap.get(key) instanceof List<Object>) {
                  List<Object> filterValuesList = (List<Object>) filterMap.get(key);
                  if (filterValuesList.size() > 0) {
                      // Separating null and non-null values
                      Set<String> stringFilterValues = new Set<String>();
                      Boolean includeNull = false;
                      
                      for (Object value : filterValuesList) {
                          if (String.valueOf(value) == 'nullcheck') {
                              includeNull = true; // Handling "No Data" Label (null values)
                          } else {
                              stringFilterValues.add(String.valueOf(value)); // Adding non-null values
                          }
                      }
                      
                      // Constructing the filter query for the current field
                      String fieldApiName = fieldList.get(key);
                      
                      if (!stringFilterValues.isEmpty()) {
                          filterQuery += ' ' + fieldApiName + ' IN :stringFilterValues';
                      }
                      
                      if (includeNull) {
                          // Adding condition for null values
                          filterQuery += (!stringFilterValues.isEmpty() ? ' OR ' : '') + fieldApiName + ' = NULL';
                      }
                      
                      filterQuery += ' AND';
                  }
              }
              /*Srikanth Changes*/
              
              
          }
        }
        System.debug('filterQuery====' + filterQuery);
        filterQuery = filterQuery.removeEnd(' AND') + ') ';
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
      
      if (allOrMy == 'allwaivers' && query.contains('AND')) {
          query = query.replaceFirst(' AND', ' WHERE');
          countQuery = countQuery.replaceFirst(' AND', ' WHERE');
      }
      
    System.debug('query===' + query);
    System.debug('countQuery===' + countQuery);
    waiverRecords = Database.query(query);
    waiverRecordsCount = Database.countQuery(countQuery);

    if (last || (before != '' && !first) || (before != '' && first)) {
      List<AWP_Waiver_Relationship__c> tmp = new List<AWP_Waiver_Relationship__c>();
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
      '( Waiver_Id__r.Name LIKE ' +
      searchKey +
      ' OR Waiver_Id__r.Status__c LIKE ' +
      searchKey +
      ' OR Waiver_Id__r.Waiver_Reason__c LIKE ' +
      searchKey +
      ' ) ';
    return query;
  }

  @AuraEnabled(cacheable=true)
  public static Map<String, Object> getFilterDetails() {
    Map<String, Object> result = new Map<String, Object>();
    List<Object> filterOptions = new List<Object>();
    for (String s : fieldList.keySet()) {
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
    List<String> fieldApiName,
    String allOrMy
  ) {
    try {
      Map<String, List<AggregateResult>> results = new Map<String, List<AggregateResult>>();
      Map<String, List<Object>> fieldUniqueMap = new Map<String, List<Object>>();
      String condition = '';
      if (allOrMy == 'mywaivers') {
        condition += ' WHERE Waiver_Id__r.OwnerId = \'' + userId + '\' ';
      }

      List<String> tempFieldList = new List<String>{
        'BARR Risk Level',
        'Waiver Reason',
        'Status'
      };

      for (String field : fieldApiName) {
        String query =
          'SELECT ' +
          fieldList.get(field) +
          ',COUNT(Id) FROM AWP_Waiver_Relationship__c' +
          condition +
          ' GROUP BY ' +
          fieldList.get(field);
        results.put(field, Database.query(query));
        //}
        // else if (
        //   field == 'Affected Standard Portfolio' ||
        //   field == 'Requesting Application'
        // ) {
        //   String query =
        //     'SELECT ' +
        //     fieldList.get(field) +
        //     ',COUNT(Id) FROM AWP_Waiver_Relationship__c' +
        //     condition +
        //     ' GROUP BY ' +
        //     fieldList.get(field);
        //   results.put(field, Database.query(query));
        // }
      }
      for (String field : results.keySet()) {
        List<Object> uniqueValues = new List<Object>();
        for (AggregateResult ar : results.get(field)) {
          Map<String, Object> uni = new Map<String, Object>();
          uni.put(
            'value',
            (String) ar.get((fieldList.get(field)).replace('Waiver_Id__r.', ''))
          );
          uni.put('count', (Integer) ar.get('expr0'));
            
          uniqueValues.add((Object) uni);
          // }
          // else if (
          //   field == 'Affected Standard Portfolio' ||
          //   field == 'Requesting Application'
          // ) {
          //   uni.put('value', (String) ar.get('Name'));
          //   uni.put('count', (Integer) ar.get('expr0'));
          //   uniqueValues.add((Object) uni);
          // }
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

  @AuraEnabled
  public static ReturnWP fetchFields(
    String recordId,
    String objectName,
    String fieldSetName
  ) {
    ReturnWP res = new ReturnWP();
    try {
      // Querying Name Field
      if (String.isBlank(recordId)) {
        res.message = 'Invalid Id';
        return res;
      }
      res.objectLabelName = Schema.getGlobalDescribe()
        .get(objectName)
        .getDescribe()
        .getLabel();
      // List<sObject> objectList = Database.query(
      //   'SELECT id, Name FROM ' + objectName + ' WHERE Id =: recordId'
      // );
      // res.nameField = String.valueof(objectList[0].get('Name'));

      // Fetching Highlight Panel Field Set
      if (String.isBlank(fieldSetName)) {
        res.message = 'Please provide a Field Set Name';
        return res;
      }
      Schema.FieldSet fieldSet = Schema.getGlobalDescribe()
        .get(objectName)
        .getDescribe()
        .fieldSets.getMap()
        .get(fieldSetName);
      if (fieldSet == null) {
        res.message = 'Field Set provided is not Valid';
        return res;
      }
      res.fieldsAPI = new List<String>();
      for (Schema.FieldSetMember fieldSetMem : fieldSet.getFields()) {
        res.fieldsAPI.add(fieldSetMem.getFieldPath());
      }
      return res;
    } catch (Exception ex) {
      throw new AuraHandledException(ex.getMessage());
    }
  }

  public class ReturnWP {
    @AuraEnabled
    public String message;
    @AuraEnabled
    public String nameField;
    @AuraEnabled
    public List<String> fieldsAPI;
    @AuraEnabled
    public String objectLabelName;
  }
}
