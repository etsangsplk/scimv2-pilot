@RestResource(urlMapping='/scim/v2/Users')
global class UsersResource extends ScimResource {

    final private static Set<String> queriableUserTypes = new Set<String>{'Standard', 'PowerPartner','PowerCustomerSuccess','CustomerSuccess','SelfService','CspLitePortal', 'CsnOnly'};


    
    @HttpPost
    global static void doPost() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        User user = new User();
        UserResource.doCreateOrUpdate(req, res, user, 'POST'); 
    }
    
    @HttpGet
    global static void doGet() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        try {
            res.addHeader('Content-Type', 'application/json');
            res.statusCode = 200; 
            String host = req.headers.get('Host');
            List<User> users = new List<User>();
            String attributes = req.params.get('attributes');
            String filter = req.params.get('filter');
            
            String startIndex = req.params.get('startIndex');
            String count = req.params.get('count');
            // the following is defense against huge queries
            if (count == null){
                count = '10';
            }
            
            if (attributes != null) {
                attributes = attributes.replaceAll(' ', '');
                attributes += ',meta';
            } else {
//            	attributes = 'id,meta';
            }
            
            String excludedAttributes = req.params.get('excludedAttributes');
            if (excludedAttributes != null) {
                excludedAttributes = excludedAttributes.replaceAll(' ', '');
            }

//            QueryHolder queryHolder = FilterTranslator.buildAttributeQueryString(attributes, filter, startIndex, count, UserResource.scimNameToUserSObjectNameMap, 'User',  'isActive = true', null, null);
//            QueryHolder queryHolder = FilterTranslator.buildAttributeQueryStringWithExcluded(attributes, excludedAttributes, filter, startIndex, count, UserResource.scimNameToUserSObjectNameMap, 'User', null, null, null);
// following added to filter out internal-style users e.g. automatedProcess
            String queryUserType = 'userType in (\'' + String.join(new List<String>(queriableUserTypes), '\',\'') + '\')';
            QueryHolder queryHolder = FilterTranslator.buildAttributeQueryStringWithExcluded(attributes, excludedAttributes, filter, startIndex, count, UserResource.scimNameToUserSObjectNameMap, 'User', queryUserType, null, null);
            Integer total = ScimResource.countQuery(queryHolder.getCountQuery());
            users = Database.query(queryHolder.getActualQuery());

            if (!users.isEmpty()) {
                res.responseBody = UserResourceSerializer.serializeUsers(users, total, startIndex, count, attributes, excludedAttributes, host, req.headers.containsKey('X-Prettyprint'));        
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
        }
        catch (Exception ex) {
            res.statusCode = 400;
            res.responseBody = SCIMError.serializeError(res.statusCode, ex.getMessage(), req.headers.containsKey('X-Prettyprint'));
            return;
        }
    }    
}