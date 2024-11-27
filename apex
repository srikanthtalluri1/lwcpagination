\ //Add for filter Logic
    /*if (!String.isBlank(filters)) {
      List<Object> filtersList = (List<Object>) JSON.deserializeUntyped(
        filters
      );

      if (filtersList.size() > 0) {
        String filterQuery = ' AND (';
        for (Object filter : filtersList) {
          Map<String, Object> filterMap = (Map<String, Object>) filter;
          System.debug('filterMap====' + filterMap);
          for (String key : filterMap.keySet()) {
              
              /*Srikanth Changes*/
              // Ensuring the key exists and the value is a list
              /*if (filterMap.get(key) != null && filterMap.get(key) instanceof List<Object>) {
                  List<Object> filterValuesList = (List<Object>) filterMap.get(key);
              
                  if (filterValuesList.size() > 0) {
                  //if (!filterValuesList.isEmpty()) {
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
                      
                      System.debug('stringFilterValues====' + stringFilterValues);
                      
                      if (!stringFilterValues.isEmpty() || includeNull) {
                          // Constructing the filter query for the current field
                          String fieldApiName = fieldList.get(key);
                          
                          if (!stringFilterValues.isEmpty()) {
                              filterQuery += ' ' + fieldApiName + ' IN :stringFilterValues';
                          }
                          
                          if (includeNull) {
                              // Adding condition for null values
                              filterQuery += (!stringFilterValues.isEmpty() ? ' OR ' : '') + fieldApiName + ' = NULL';
                          }
                          
                          filterQuery += ' AND ';
                      }
                  }
              }*/
              /*Srikanth Changes*/
              
              
          /*}
        }
        System.debug('filterQuery====' + filterQuery);
        filterQuery = filterQuery.removeEnd(' AND ') + ') ';
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
    System.debug('countQuery===' + countQuery);*/
      
      if (!String.isBlank(filters)) {
          List<Object> filtersList = (List<Object>) JSON.deserializeUntyped(filters);
          
          // To track if only NULL/nullcheck filters are present
          Boolean onlyNullChecks = true;
          
          if (filtersList.size() > 0) {
              String filterQuery = ' AND (';
              Map<String, List<String>> fieldSpecificFilterValuesMap = new Map<String, List<String>>();
              
              // Construct the filter query
              for (Object filter : filtersList) {
                  Map<String, Object> filterMap = (Map<String, Object>) filter;
                  
                  for (String key : filterMap.keySet()) {
                      if (filterMap.get(key) != null && filterMap.get(key) instanceof List<Object>) {
                          List<Object> filterValuesList = (List<Object>) filterMap.get(key);
                          
                          Set<String> stringFilterValues = new Set<String>();
                          Boolean includeNull = false;
                          
                          // Loop through filter values
                          for (Object value : filterValuesList) {
                              if (String.valueOf(value) == 'nullcheck') {
                                  includeNull = true; // Mark nullcheck
                              } else {
                                  stringFilterValues.add(String.valueOf(value)); // Add non-null values
                                  onlyNullChecks = false; // There are other values besides nullcheck
                              }
                          }
                          
                          // Only process fields that have filter values (either non-null or nullcheck)
                          if (!stringFilterValues.isEmpty() || includeNull) {
                              String fieldApiName = fieldList.get(key);
                              
                              if (!fieldSpecificFilterValuesMap.containsKey(fieldApiName)) {
                                  fieldSpecificFilterValuesMap.put(fieldApiName, new List<String>());
                              }
                              fieldSpecificFilterValuesMap.get(fieldApiName).addAll(stringFilterValues);
                              
                              // Add the field condition to the query
                              filterQuery += '(';
                              
                              if (includeNull && onlyNullChecks) {
                                  // If only NULL checks are present for this field, do a NULL check
                                  filterQuery += fieldApiName + ' = NULL';
                              } else {
                                  // If there are non-null values, create the IN condition
                                  if (!stringFilterValues.isEmpty()) {
                                      List<String> quotedValues = new List<String>();
                                      for (String value : stringFilterValues) {
                                          quotedValues.add('\'' + value + '\'');
                                      }
                                      String quotedValuesString = String.join(quotedValues, ', ');
                                      filterQuery += fieldApiName + ' IN (' + quotedValuesString + ')';
                                  }
                                  
                                  // Include NULL check if needed (OR between IN and NULL)
                                  if (includeNull) {
                                      if (!stringFilterValues.isEmpty()) {
                                          filterQuery += ' OR ';
                                      }
                                      filterQuery += fieldApiName + ' = NULL';
                                  }
                              }
                              
                              // Close the condition for this field
                              filterQuery += ')';
                              filterQuery += ' AND ';
                          }
                      }
                  }
              }
              
              // Clean up the final query (remove last AND and close parentheses)
              filterQuery = filterQuery.removeEnd(' AND ') + ') ';
              query += filterQuery;
              countQuery += filterQuery;
          }
      }


      
      // END
      
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
      System.debug('countQuery===' + countQuery);
      
      if (allOrMy == 'allwaivers' && query.contains('AND')) {
          query = query.replaceFirst(' AND', ' WHERE');
          countQuery = countQuery.replaceFirst(' AND', ' WHERE');
      }
      
      System.debug('Final Query: ' + query);






      
      /*Srikanth Changes*/
      // Target fields to replace with their prefixed versions
      Set<String> fieldsToReplace = new Set<String>{
          'Waiver_Reason__c', 
              'Requesting_Portfolio__c', 
              'Status__c', 
              'Standard_Page_Title__c'
              };
      
      // Extract the ORDER BY clause
      Integer orderByIndex = query.indexOf('ORDER BY');
      if (orderByIndex > -1) {
          String beforeOrderBy = query.substring(0, orderByIndex);
          String orderByClause = query.substring(orderByIndex + 9); // Skip 'ORDER BY'
          Integer limitIndex = orderByClause.indexOf('LIMIT');
          if (limitIndex > -1) {
              orderByClause = orderByClause.substring(0, limitIndex).trim();
          }
          
          // Process the ORDER BY clause
          List<String> orderByFields = orderByClause.split(',');
          for (Integer i = 0; i < orderByFields.size(); i++) {
              String field = orderByFields[i].trim();
              
              // Extract the field name before ASC/DESC/NULLS FIRST if present
              String baseField = field.split(' ')[0];
              
              // Replace with the prefixed version if in the target set
              if (fieldsToReplace.contains(baseField)) {
                  field = field.replace(baseField, 'Waiver_Id__r.' + baseField);
                  orderByFields[i] = field;
              }
          }
          
          // Rebuild the ORDER BY clause
          String modifiedOrderByClause = String.join(orderByFields, ', ');
          
          // Rebuild the query with the modified ORDER BY clause
          query = beforeOrderBy + 'ORDER BY ' + modifiedOrderByClause;
      }
      
      // Log the modified query
      System.debug('Modified Query: ' + query);
      /*Srikanth Changes*/
