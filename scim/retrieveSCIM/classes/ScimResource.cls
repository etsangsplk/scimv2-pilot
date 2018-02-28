global abstract with sharing class ScimResource {

    public static List<Map<String,String>> parseOptionalObjectArray(String context, System.JSONParser parser) {
        List<Map<String,String>> objs = new List<Map<String,String>>();
        boolean firstToken = true;
        while ((parser.nextToken() != null) && (parser.getCurrentToken() != JSONToken.END_ARRAY)) {
            if (firstToken) {
                JSONToken currentToken = parser.getCurrentToken();
                if(currentToken != JSONToken.START_ARRAY) {
                    ParseException pex = new ParseException('Expecting START_ARRAY But Found ' + currentToken + ' while parsing ' + context);
                    pex.setStatusCode(400);
                    throw pex;
                }
                firstToken = false;
            }
            
            JSONToken nextTok = parser.nextValue();
            if ( nextTok == JSONToken.START_OBJECT )  {
                 objs.add(parseSimpleObject(context, parser));
             } else {
                 String val = parser.getText();
                 Map<String,String> obj = new Map<String,String>();
                 obj.put('value',val);
                 objs.add(obj);
             }
        }
        return objs;
    }
    
    public static List<String> parseStringArray(String context, System.JSONParser parser) {
        List<String> fields = new List<String>();
        boolean firstToken = true;
        while ((parser.nextToken() != null) && (parser.getCurrentToken() != JSONToken.END_ARRAY)) {
            if (firstToken) {
                JSONToken currentToken = parser.getCurrentToken();
                if(currentToken != JSONToken.START_ARRAY) {
                    ParseException pex = new ParseException('Expecting START_ARRAY But Found ' + currentToken + ' while parsing ' + context);
                    pex.setStatusCode(400);
                    throw pex;
                }
                firstToken = false;
            }        
        
            if (parser.getCurrentToken() == JSONToken.VALUE_STRING ) fields.add(parser.getText());
        }
        return fields;
    }
        
    public static List<Map<String,String>> parseObjectArray(String context, System.JSONParser parser) {
        List<Map<String,String>> objs = new List<Map<String,String>>();
        boolean firstToken = true;
        while ((parser.nextToken() != null) && (parser.getCurrentToken() != JSONToken.END_ARRAY)) {
            if (firstToken) {
                JSONToken currentToken = parser.getCurrentToken();
                if(currentToken != JSONToken.START_ARRAY) {
                    ParseException pex = new ParseException('Expecting START_ARRAY But Found ' + currentToken + ' while parsing ' + context);
                    pex.setStatusCode(400);
                    throw pex;
                }
                firstToken = false;
            }           
        
            if (parser.getCurrentToken() == JSONToken.START_OBJECT ) objs.add(parseSimpleObject(context, parser));
            
        }
        return objs;
    }
    
    public static Map<String,String> parseSimpleObject(String context, System.JSONParser parser) {
        Map<String,String> obj = new Map<String,String>();
        String name = null;
        String value = null;
        boolean firstToken = true;
        if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
            // special case when called by parseOptionalObjectArray
            firstToken = false;
        }
        
        while ((parser.nextToken() != null) && (parser.getCurrentToken() != JSONToken.END_OBJECT)) {
            if (firstToken) {
                JSONToken currentToken = parser.getCurrentToken();
                if(currentToken != JSONToken.START_OBJECT) {
                    ParseException pex = new ParseException('Expecting START_OBJECT But Found ' + currentToken + ' while parsing ' + context);
                    pex.setStatusCode(400);
                    throw pex;
                }
                firstToken = false;
            }           
        
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                name = parser.getText();
                parser.nextToken();
                value = parser.getText();                
                obj.put(name,value);
                name = null;
                value = null;
            }                      
        }
        return obj;
    }
    
    public static String parseString(String context, System.JSONParser parser) {
        parser.nextToken();
        JSONToken currentToken = parser.getCurrentToken();
        // added null check to avoid parsing errors
        // W-2891836
        if (currentToken == JSONToken.VALUE_NULL){
            return '';
        } else if(currentToken != JSONToken.VALUE_STRING) {
            ParseException pex = new ParseException('Expecting VALUE_STRING But Found ' + currentToken + ' while parsing ' + context);
            pex.setStatusCode(400);
            throw pex;
        }
        return parser.getText();
    }
    
    public static boolean parseBoolean(String context, System.JSONParser parser) {
        parser.nextToken();
        JSONToken currentToken = parser.getCurrentToken();
        if((currentToken != JSONToken.VALUE_TRUE) && (currentToken != JSONToken.VALUE_FALSE)) {
            ParseException pex = new ParseException('Expecting BOOLEAN But Found ' + currentToken + ' while parsing ' + context);
            pex.setStatusCode(400);
            throw pex;
        }        
        return parser.getBooleanValue();
    }
     
    public static boolean isNextTokenField(System.JSONParser parser, String fieldName) {
		return ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == fieldName));    
    }
    
    public static boolean shouldSerialize(String attributeName, String attributes, Map<String, ScimSoqlAttributeProcessor> scimNameToSObjectNameMap) {
        boolean should = false;
        if (attributes == null) {
            should = true;
        } else {
            List<String> attributeList = attributes.split(',');
            for (String thisAttribute : attributeList) {
                
                //check for extended and custom schema
                if (attributeName.contains(':')){
                    if(thisAttribute.contains(attributeName)){
                        should = true;
                        break;
                    }
                }
                
                //TODO should split on : not . ?
                List<String> renderingAttributeParts = attributeName.split('\\.');
                List<String> thisAttributeParts = thisAttribute.split('\\.');
                
                // Check if we are trying to render a parent of a specified long sub notation 
                // i.e. attributes = name.formatted, rendering name
                if (renderingAttributeParts.size() <= thisAttributeParts.size()) {
                    boolean isSubNotation = true;
                    
                    for (Integer i = 0; i < renderingAttributeParts.size(); i++) {
                        if (renderingAttributeParts.get(i) != thisAttributeParts.get(i)) {
                            isSubNotation = false;
                            break;
                        }
                    }
                    
                    if (isSubNotation) {
                        should = true;
                        break;
                    }
                }
                
                // Check if we are trying to render a child of a specified parent
                // i.e. attributes = name, rendering name.formatted
                if (thisAttributeParts.size() <= renderingAttributeParts.size()) {
                    boolean isParentNotation = true;
                    
                    for (Integer i = 0; i < thisAttributeParts.size(); i++) {
                        if (renderingAttributeParts.get(i) != thisAttributeParts.get(i)) {
                            isParentNotation = false;
                            break;
                        }
                    }
                    
                    if (isParentNotation) {
                        should = true;
                        break;
                    }
                }                
                
            }
        }
        
        if (should) {
            boolean containsKey = scimNameToSObjectNameMap.containsKey(attributeName);
            return containsKey;
        }

        return should;
    }

    public static boolean shouldSerializeWithExcluded(String attributeName, String attributes, String excludedAttributes, Map<String, ScimSoqlAttributeProcessor> scimNameToSObjectNameMap) {
        boolean should = true;
        if (attributes == null && excludedAttributes == null) {
            should = true;
        } else if (excludedAttributes != null) {
            should = true;
            // check excluded first
            // remember if there is a match then DO NOT serialize
            // a.k.a. should = false
            List<String> excludedAttributeList = excludedAttributes.split(',');
            for (String thisAttribute : excludedAttributeList) {

                if (attributeName.contains(':')){
                    if(thisAttribute.equals(attributeName)){
                        should = false;
                        break;
                    }
                }                 
                
                if (thisAttribute == attributeName){
                    should = false;
                    break;
                }
            }
        } else if (attributes != null){
            should = false;
            // then check attributes
            List<String> attributeList = attributes.split(',');
            for (String thisAttribute : attributeList) {
                
                //check for extended and custom schema
                if (attributeName.contains(':')){
                    if(thisAttribute.contains(attributeName)){
                        should = true;
                        break;
                    }
                }
 
                //TODO should split on : not . ?
                List<String> renderingAttributeParts = attributeName.split('\\.');
                List<String> thisAttributeParts = thisAttribute.split('\\.');
                
                // Check if we are trying to render a parent of a specified long sub notation 
                // i.e. attributes = name.formatted, rendering name
                if (renderingAttributeParts.size() <= thisAttributeParts.size()) {
                    boolean isSubNotation = true;
                    for (Integer i = 0; i < renderingAttributeParts.size(); i++) {
                        if (renderingAttributeParts.get(i) != thisAttributeParts.get(i)) {
                            isSubNotation = false;
                            break;
                        }
                    }
                    
                    if (isSubNotation) {
                        should = true;
                        break;
                    }
                }
                
                // Check if we are trying to render a child of a specified parent
                // i.e. attributes = name, rendering name.formatted
                if (thisAttributeParts.size() <= renderingAttributeParts.size()) {
                    boolean isParentNotation = true;
                    
                    for (Integer i = 0; i < thisAttributeParts.size(); i++) {
                        if (renderingAttributeParts.get(i) != thisAttributeParts.get(i)) {
                            isParentNotation = false;
                            break;
                        }
                    }
                    
                    if (isParentNotation) {
                        should = true;
                        break;
                    }
                }
            }            
        }
        if (should) {
            boolean containsKey = scimNameToSObjectNameMap.containsKey(attributeName);
            return containsKey;
        }

        System.debug('should: ' + should + ' for ' + attributeName);
        return should;
    }
    
    public static Integer countQuery(String aggrSoql) {
        System.debug('aggrSoql: ' + aggrSoql);
        List<AggregateResult> s = Database.query(aggrSoql);
        return Integer.valueOf(s.get(0).get('expr0'));
    }
    
    // LAST RESORT QUERY METHOD
    // The dillemma is that increasing offset is a high resistance operation
    // The default of 2000 is a good enough barrier, and we should ask customers to filter down
    // to within 2000.
    //
    // But if it's not possible, and the customer cannot get by, and we cannot logistically
    // increase the SOQL offset org value, then this below will avoid the problem.
    // But this is quite inefficient (Although you can argue this kind of paging by definition
    // is flawed). Use only if all else fails.
    //
    // ALSO, the caller can logically do filter=id gt "some id" to cut down the result
    // would logically result in the equivalent of the below
    
    public static List<SObject> query(QueryHolder qh) {
        Integer offset = qh.getOffset();
        if (offset == NULL) {
            offset = 0;
        }
        Integer lim = qh.getLimit();
        if (lim == NULL) {
            lim = 200;
        }
        Integer i = 0;
        List<SObject> results = new List<SObject>();
        Integer nextPageSpillOver = null;
        
        // In essence, use a SOQL in for loop to underneath the hood get this batch by batch
        for (SObject[] entries : Database.query(qh.getNoPagingQuery())) {
            if (nextPageSpillOver != null && nextPageSpillOver > 0) {
                for (i = 0; i < Math.min(nextPageSpillOver, entries.size()); i++) {
                    results.add(entries[i]);
                }  
                // got everything after spilling over
                break;
            }
            else if (offset >= 200) {
                offset = offset - 200;
                continue;
            }
            else {
                nextPageSpillOver = (offset + lim) - 200;
                for (i = offset; i < Math.min(offset + lim, entries.size()); i++) {
                    results.add(entries[i]);
                }
                
                if (nextPageSpillOver <= 0) {
                    // got everything in this page
                    break;
                }
            }
        }
        return results;
    }
}