public class FilterTranslator {
    List<String> tokens = new List<String>();
    Map<String, ScimSoqlAttributeProcessor> attributes;
    Pattern myPattern = Pattern.compile('[\\(\\)]|"(?:[^"\n]|.)*?"|[a-zA-Z0-9."@:_-]+');       
    String expression = '';
    Matcher myMatcher = myPattern.matcher(expression);
       
    public FilterTranslator(String expression, Map<String, ScimSoqlAttributeProcessor> attributes) {
        this.expression = expression;
        this.myMatcher = myPattern.matcher(this.expression);
        this.attributes = attributes;
    }

    public List<String> getTokens() {
        if (tokens.isEmpty()) {
            while (myMatcher.find()) {
                String matchedToken = expression.substring(myMatcher.start(), myMatcher.end());
                tokens.add(matchedToken);
            }
        }
        return tokens;
    }
       
    public String getTranslatedFilter() {
        List<String> tokens = getTokens();
        Integer nest = 0;
        String operator = '';
        String parsedString = '';
        ScimSoqlAttributeProcessor currentProcessor;
        Integer semiJoinCount = 0;        
           
        // STATES:
        // 0 = beginning of expression
        // ( [passthrough, increase nest] -> 0
        // attributeName [convert to SOQL attribute] -> 1
           
        // 1 = at attribute name
        // operator other than pr [store at operator] -> 2
        // 'pr' [ is not null ] ->3
           
        // 2 = at operator
        // 'eq' [ = token]
        // 'co' [ like '%token%']
        // 'sw' [ like 'token%']
        // 'gt' [ > token]
        // 'ge' [ >= token]
        // 'lt' [ < token]
        // 'le' [ <= token]
        // -> 3
           
        // 3 = end of expression
        // ) [passthrough, decrease nest] -> 0
        // and|or [passthrough] -> 0
        Integer state = 0;
        for (String token : tokens) {
            if (state == 0) {
                if (token.equals('(')) {
                    parsedString += '(';
                    nest++;
                    continue;
                } else if (token == 'emails.value'){
                    currentProcessor = attributes.get('emails');
                    parsedString += currentProcessor.getSoqlAttributeForFilterGeneration();
                    state = 1;
                    continue;
                } else if (attributes.containsKey(token)) {
                    currentProcessor = attributes.get(token);
                    if (currentProcessor.isComplex()) {
                        // composite attribute, need to be more specific.
                        throw new IllegalFilterException('Complex attribute ' + token + '. Please specify subattribute.');
                    }
                    parsedString += currentProcessor.getSoqlAttributeForFilterGeneration();
                    state = 1;
                    continue;
                } 

                else {                    
                    throw new IllegalFilterException('Unsupported attribute : ' + token);
                }
            }
            else if (state == 1) {
                String tempToken = token.toLowerCase(); // did this to support case insensitive operators
                if (tempToken.equals('eq') || 
                    tempToken.equals('co') ||
                    tempToken.equals('sw') ||
                    tempToken.equals('gt') ||
                    tempToken.equals('ge') ||
                    tempToken.equals('lt') ||
                    tempToken.equals('le')) {
                        operator = tempToken;                    
                        state = 2;
                        continue;
                }
                else if (tempToken.equals('pr')) {
                    parsedString += currentProcessor.getPRclause(null);
                    state = 3;
                    continue;
                }
                else {
                    throw new IllegalFilterException('Unsupported Operator : ' + token);
                }
            }
            else if (state == 2) {
                String strippedToken;
                if (!token.startsWith('"') && !token.endsWith('"')) {
                    throw new IllegalFilterException('Argument has to be a quoted string literal : ' + token);
                }
                else {
                    strippedToken = token.substring(1,token.length()-1);
                }
                
                if (operator.equals('eq')) {
                    if (currentProcessor.isSemijoin()) {
                        semiJoinCount++;
                    }
                
                    parsedString += currentProcessor.getEQclause(strippedToken);
                    state = 3;
                }
                else if (operator.equals('co')) {
                    parsedString += currentProcessor.getCOclause(strippedToken);
                    state = 3;
                }
                else if (operator.equals('sw')) {
                    parsedString += currentProcessor.getSWclause(strippedToken);
                    state = 3;
                }
                else if (operator.equals('gt')) {
                    parsedString += currentProcessor.getGTclause(strippedToken);
                    state = 3;
                }
                else if (operator.equals('ge')) {
                    parsedString += currentProcessor.getGEclause(strippedToken);
                    state = 3;
                }
                else if (operator.equals('lt')) {
                    parsedString += currentProcessor.getLTclause(strippedToken);
                    state = 3;
                } 
                else if (operator.equals('le')) {
                    parsedString += currentProcessor.getLEclause(strippedToken);
                    state = 3;
                }
                else {
                    // Technically won't get here because previous state would have caught this
                    throw new IllegalFilterException('Unsupported Operator : ' + token);
                }
            }
            else if (state == 3) {
                currentProcessor = null;    // clear processor
                token = token.toLowercase();
                if (token.equals('and') || token.equals('or')) {
                    parsedString += (' ' + token + ' ');
                    state = 0;
                    continue;
                }
                else if (token.equals(')')) {
                    parsedString += ')';
                    nest--;
                    continue;
                }                   
                else {
                    throw new IllegalFilterException('Illegal token : ' + token);
                }
            }
        }


        if (nest != 0) {
            throw new IllegalFilterException('Unbalanced brackets, check your filter');
        }
        
        if (semijoinCount > 1) {
            throw new IllegalFilterException('Only one membership criteria allowed in filter.');        
        }        
        return parsedString;
    }
    
    public static QueryHolder buildAttributeQueryString(String attributes, String filter, String startIndex, String count, Map<String, ScimSoqlAttributeProcessor> scimNameToSObjectNameMap, String table, String extraClause, String limitOverride, String offsetOverride) {
        
        Set<String> uniqueSObjectFieldNames = new Set<String>();
        String soql = 'select ';

        if (attributes != null) {
            String[] attrs = attributes.split(',');
            for (String attr : attrs) {
                // hack to avoid organization from entering the query string
                if(attr == 'urn:ietf:params:scim:schemas:extension:enterprise:2.0:User:organization') {
                    break;
                }
                
                ScimSoqlAttributeProcessor attrProcessor = scimNameToSObjectNameMap.get(attr);
                if (attrProcessor == null) {
                    throw new IllegalFilterEXception('Unsupported attribute: ' + attr);
                }
                String name = attrProcessor.getSoqlAttribute();
                if (name != null) {
                    uniqueSObjectFieldNames.addAll(attrProcessor.getSoqlAttributeList());
                }
            }
        }
        else {
            for (String key : scimNameToSObjectNameMap.keyset()) {
            ScimSoqlAttributeProcessor attrProcessor = scimNameToSObjectNameMap.get(key);
            String name = attrProcessor.getSoqlAttribute();
                if ((name != null) && (name != 'organization')) {
                    uniqueSObjectFieldNames.addAll(attrProcessor.getSoqlAttributeList());
                }
            }
        }
        
        for (String uniqueSObjectFileName : uniqueSObjectFieldNames) {
            if (uniqueSObjectFileName.length() != 0) {
                soql = soql + uniqueSObjectFileName + ',';
            } 
        }

        // remove ending comma if any
        if (soql.endsWith(',')) {
            soql = soql.substring(0, soql.length() -1);
        }
        
        String countSoql;
        if (extraClause != null) {
            soql += ' from ' + table + ' where ( ' + extraClause + ' ) ';
            countSoql = 'select count(Id) from ' + table + ' where ( ' + extraClause + ' ) ';
        }
        else {
            soql += ' from ' + table;
            countSoql = 'select count(Id) count from ' + table + ' '; 
        }
        
        if (filter != NULL && filter.length() != 0) {
            FilterTranslator translator = new FilterTranslator(filter, scimNameToSObjectNameMap);
            String thisFilter = ' AND ( ' + translator.getTranslatedFilter() + ' ) '; 
            soql += thisFilter;
            countSoql += thisFilter;
        }
        
        soql += ' ORDER BY ID ';
        
        String noPagingSoql = soql;

        Integer lim = NULL;
        if (limitOverride != NULL) {
            soql += ' LIMIT ' + limitOverride;
        }
        else {
            if (count != NULL) {
                validateCount(count);
                lim = Integer.valueof(count);
                soql += ' LIMIT ' + count;
            }
            else {
                // Never pull back more than 200
                soql += ' LIMIT 200 ';
            }
        }
        
        Integer offset = NULL;
        if (offsetOverride != NULL) {
            soql += ' OFFSET ' + offsetOverride;
        }
        else {
            if (startIndex != NULL) {
                validateStartIndex(startIndex);
                offset = Integer.valueof(startIndex) - 1;
                soql += ' OFFSET ' + offset;
            }
        }
        return new QueryHolder(countSoql, soql, noPagingSoql, lim, offset);
    }
    
    public static QueryHolder buildAttributeQueryStringWithExcluded(String attributes, String excludedAttributes, String filter, String startIndex, String count, Map<String, ScimSoqlAttributeProcessor> scimNameToSObjectNameMap, String table, String extraClause, String limitOverride, String offsetOverride) {
        Set<String> uniqueSObjectFieldNames = new Set<String>();
        Set<String> excludedeSObjectFieldNames = new Set<String>();
        String soql = 'select ';

        if (attributes != null) {
            String[] attrs = attributes.split(',');
            for (String attr : attrs) {
                // hack to avoid organization from entering the query string
                if(attr == 'urn:ietf:params:scim:schemas:extension:enterprise:2.0:User:organization') {
                    break;
                }

                ScimSoqlAttributeProcessor attrProcessor = scimNameToSObjectNameMap.get(attr); 
                if (attrProcessor == null) {
                    throw new IllegalFilterEXception('Unsupported attribute: ' + attr);
                }
                String name = attrProcessor.getSoqlAttribute();
                if (name != null) {
                    uniqueSObjectFieldNames.addAll(attrProcessor.getSoqlAttributeList());
                }
            }
        } else {
            for (String key : scimNameToSObjectNameMap.keyset()) {
                ScimSoqlAttributeProcessor attrProcessor = scimNameToSObjectNameMap.get(key);
                String name = attrProcessor.getSoqlAttribute();
                if ((name != null) && (name != 'organization')) {
                    uniqueSObjectFieldNames.addAll(attrProcessor.getSoqlAttributeList());
                }
            }
        }

        if (excludedAttributes != null){
            String[] exAttrs = excludedAttributes.split(',');
            for (string attr : exAttrs){               
                // hack to avoid organization from entering the query string
                if(attr == 'urn:ietf:params:scim:schemas:extension:enterprise:2.0:User:organization') {
                    break;
                }

                ScimSoqlAttributeProcessor attrProcessor = scimNameToSObjectNameMap.get(attr);
                if (attrProcessor == null) {
                    throw new IllegalFilterEXception('Unsupported attribute: ' + attr);
                }
                String name = attrProcessor.getSoqlAttribute();
                if (name != null) {
                    excludedeSObjectFieldNames.add(attrProcessor.getSoqlAttribute());
                }
            }
            uniqueSObjectFieldNames.removeAll(excludedeSObjectFieldNames);            
        }

        for (String uniqueSObjectFileName : uniqueSObjectFieldNames) {
            if (uniqueSObjectFileName.length() != 0) {
                soql = soql + uniqueSObjectFileName + ',';
            } 
        }
        
        // remove ending comma if any
        if (soql.endsWith(',')) {
            soql = soql.substring(0, soql.length() -1);
        }
        
        String countSoql;
        if (extraClause != null) {
            soql += ' from ' + table + ' where ( ' + extraClause + ' ) ';
            countSoql = 'select count(Id) from ' + table + ' where ( ' + extraClause + ' ) ';
        }
        else {
            soql += ' from ' + table;
            countSoql = 'select count(Id) from ' + table + ' '; 
        }
        if (filter != NULL && filter.length() != 0) {
            FilterTranslator translator = new FilterTranslator(filter, scimNameToSObjectNameMap);
            String thisFilter = ' WHERE ( ' + translator.getTranslatedFilter() + ' ) ';
            soql += thisFilter;
            countSoql += thisFilter;
        }
        
        soql += ' ORDER BY ID ';
        
        String noPagingSoql = soql;

        Integer lim = NULL;
        if (limitOverride != NULL) {
            soql += ' LIMIT ' + limitOverride;
        }
        else {
            if (count != NULL) {
                validateCount(count);
                lim = Integer.valueof(count);
                soql += ' LIMIT ' + count;
            }
            else {
                // Never pull back more than 200
                soql += ' LIMIT 200 ';
            }
        }
        
        Integer offset = NULL;
        if (offsetOverride != NULL) {
            soql += ' OFFSET ' + offsetOverride;
        }
        else {
            if (startIndex != NULL) {
                validateStartIndex(startIndex);
                offset = Integer.valueof(startIndex) - 1;
                soql += ' OFFSET ' + offset;
            }
        }

        return new QueryHolder(countSoql, soql, noPagingSoql, lim, offset);
    }
    
    public static void validateCount(String count) {
        if(!count.isNumeric()){
            throw new IllegalFilterException('Illegal count value : ' + count);
        }
        Integer countInt = Integer.valueOf(count);
        if (countInt > 200 || countInt < 1) {
            throw new IllegalFilterException('Illegal count value : ' + count);
        }    
    }
    
    public static void validateStartIndex(String startIndex) {
        if (!startIndex.isNumeric()) {
            throw new IllegalFilterException('Illegal startIndex value : ' + startIndex);
        }
    
        Integer startIndexInt = Integer.valueOf(startIndex);
        if(startIndexInt < 1){
            throw new IllegalFilterException('Illegal startIndex value: ' + startIndex);
        }    
        
        if(startIndexInt > 2001){
            throw new IllegalFilterException('Start index too big. Consider filtering down your result set, e.g. id gt "(the last id in the result set)"');
        }            
    }
    
}