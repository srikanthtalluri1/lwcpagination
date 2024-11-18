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
