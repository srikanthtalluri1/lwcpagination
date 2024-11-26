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
