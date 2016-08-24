@RestResource(urlMapping='/scim/v2/Users/.search')
global class UserDotSearchResource extends ScimResource {
    private static Blob serializeUsers(List<User> users, Integer total, String startIndex, String count, String attributes, String excludedAttributes, String host, boolean prettyPrint) {
        JSONGenerator gen = JSON.createGenerator(prettyPrint);
        gen.writeStartObject();
            gen.writeNumberField('totalResults', total);
            
            if (count != null) {
                Integer countInt = Math.min(Integer.valueof(count), users.size());
                gen.writeNumberField('itemsPerPage', countInt);
            } 
            else if (total != users.size()) {
                gen.writeNumberField('itemsPerPage', users.size());
            }
            
            if (startIndex != null) {
                gen.writeNumberField('startIndex', Integer.valueof(startIndex));
            }
            
            gen.writeFieldName('schemas');
            gen.writeStartArray();
                gen.writeString('urn:ietf:params:scim:api:messages:2.0:ListResponse');
            gen.writeEndArray();
            gen.writeFieldName('Resources');
            gen.writeStartArray();
                UserResource.serializeUserWithGenerator(users, attributes, excludedAttributes, host,gen);
            gen.writeEndArray();
        gen.writeEndObject();
        return Blob.valueOf(gen.getAsString());
    }
    
    @HttpPost
    global static void doPost() {
        // TODO figure out why adding an attribute clause returns few records than should be
        // when filter provided
        // also providing attribute w/o filter seems to reduce returned set of records incorrectly
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');
        String method = req.headers.get('X-HTTP-Method-Override');
        String[] uriParts = req.requestURI.split('/',0);
        Integer numParts = uriParts.size() - 1;
        String attributes;
        String excludedAttributes;
        String filter;
        String startIndex;
        String count;

        
        if ((numParts > 0) && (uriParts[numParts] == '.search')){
            //parse body for search
            DotSearchResource searchReq = DotSearchResource.parse(req.requestBody.toString());
            
            // check schema
            if (searchReq.schemas[0] != 'urn:ietf:params:scim:api:messages:2.0:SearchRequest'){
                res.statusCode = 400;
                res.responseBody = SCIMError.serializeError(res.statusCode, 'Invalid Schema', req.headers.containsKey('X-Prettyprint'));
            }
            
            // check for both attributes and excludedAttributes
            if ((searchReq.attributes != null) && (searchReq.excludedAttributes != null)){
                res.statusCode = 400;
                res.responseBody = SCIMError.serializeError(res.statusCode, 'Cannot provide both attributes and excludedAttributes', req.headers.containsKey('X-Prettyprint'));                
            }
            
            //get filter, attributes, excludedAttributes into form FilterTranslator can consume
            if (searchReq.attributes != null){
                attributes = String.join(searchReq.attributes,',');
            }
            if (searchReq.excludedAttributes != null){
                excludedAttributes = String.join(searchReq.excludedAttributes,',');
            }
            if (searchReq.startIndex != null){
                startIndex = String.valueOf(searchReq.startIndex);
            }
            if (searchReq.count != null){
                count = String.valueOf(searchReq.count);
            }
            String host = req.headers.get('Host');
            List<User> users = new List<User>();
            try {
                QueryHolder queryHolder = FilterTranslator.buildAttributeQueryStringWithExcluded(attributes, excludedAttributes, searchReq.filter, startIndex, count, UserResource.scimNameToUserSObjectNameMap, 'User',  'isActive = true', null, null);
    
                Integer total = ScimResource.countQuery(queryHolder.getCountQuery());
                users = Database.query(queryHolder.getActualQuery());
    
                if (!users.isEmpty()) {
                    res.responseBody = serializeUsers(users, total, startIndex, count, attributes, excludedAttributes, host, req.headers.containsKey('X-Prettyprint'));        
                } else {
                    res.statusCode = 200;
                    JSONGenerator gen = JSON.createGenerator(true);
                    gen.writeStartObject();
                        gen.writeNumberField('totalResults', 0);
                        gen.writeNumberField('itemsPerPage', 0);                
                        gen.writeNumberField('startIndex', 0);
                        gen.writeFieldName('schemas');
                        gen.writeStartArray();
                            gen.writeString('urn:ietf:params:scim:api:messages:2.0:ListResponse');
                        gen.writeEndArray();
                    gen.writeEndObject();
                    res.responseBody = Blob.valueOf(gen.getAsString());
                }
            } catch (ScimException ex) {
                res.statusCode = 400;
                res.responseBody = SCIMError.serializeError(res.statusCode, ex.getMessage(), req.headers.containsKey('X-Prettyprint'));
            return;
            }  
            
        }           
    }
}