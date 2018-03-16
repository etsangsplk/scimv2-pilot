@RestResource(urlMapping='/scim/v2/Roles')
global class RolesResource {

    final public static Map<String, ScimSoqlAttributeProcessor> scimNameToRoleSObjectNameMap;
    
    static {
        scimNameToRoleSObjectNameMap = new Map<String, ScimSoqlAttributeProcessor>();
        scimNameToRoleSObjectNameMap.put('id', new StandardAttributeProcessor('Id', Schema.SOAPType.String, false));
        scimNameToRoleSObjectNameMap.put('displayName', new StandardAttributeProcessor('Name', Schema.SOAPType.String, false));
        scimNameToRoleSObjectNameMap.put('members', new RoleMembersAttributeProcessor());
        
        scimNameToRoleSObjectNameMap.put('meta', new StandardAttributeProcessor('LastModifiedDate', Schema.SOAPType.String, true));
        scimNameToRoleSObjectNameMap.put('meta.lastModified', new StandardAttributeProcessor('LastModifiedDate', Schema.SOAPType.DateTime, false));       
    }
    
	@HttpPost
	global static void doPost() {
        methodNotSupported();
        return;
    }   
    
    @HttpPut   
	global static void doPut() {
        methodNotSupported();
        return;
    }   

    @HttpDelete   
	global static void doDelete() {
        methodNotSupported();
        return;
    }   

    
    private static void methodNotSupported(){
		RestRequest req = RestContext.request;
		RestResponse res = RestContext.response;
		res.statusCode = 501;
        res.responseBody = SCIMError.serializeError(res.statusCode, 'Method not supported', req.headers.containsKey('X-Prettyprint'));
    	return;
    }
    
    @HttpGet
    global static void doGet() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        try {
            res.addHeader('Content-Type', 'application/json');
            res.statusCode = 200; 
            String host = req.headers.get('Host');
            
            String attributes = req.params.get('attributes');
            if (attributes != null) {
                attributes = attributes.replaceAll(' ', '');
            }   
            
            String filter = req.params.get('filter');
            String startIndex = req.params.get('startIndex');
            String count = req.params.get('count');
            
            QueryHolder roleQueryHolder = FilterTranslator.buildAttributeQueryString(attributes, filter, startIndex, count, scimNameToRoleSObjectNameMap, 'UserRole', ' (Id != NULL) ', null, null);
            
            String countSoql = roleQueryHolder.getCountQuery();
            String actualSoql = roleQueryHolder.getActualQuery();
            
            Integer total = ScimResource.countQuery(countSoql);
            List<UserRole> roles = Database.query(actualSoql);
            
            if ( !roles.isEmpty()  ) {
                res.responseBody = serializeRoles(roles, total, startIndex, count, attributes, host,req.headers.containsKey('X-Prettyprint'));
            } else {
                res.responseBody = serializeRoles(null,0,null,null,null,host,req.headers.containsKey('X-Prettyprint'));
            }
        }
        catch (Exception ex) {
            res.statusCode = 400;
            res.responseBody = SCIMError.serializeError(res.statusCode, ex.getMessage(), req.headers.containsKey('X-Prettyprint'));
            return;
        }              
    }

    private static Blob serializeRoles(List<UserRole> roles, Integer total, String startIndex, String count, String attributes, String host, boolean prettyPrint) {
        JSONGenerator gen = JSON.createGenerator(prettyPrint);
        gen.writeStartObject();
            gen.writeNumberField('totalResults', total);
            
            if (count != null) {
                Integer countInt = Math.min(Integer.valueof(count), roles.size());
                gen.writeNumberField('itemsPerPage', countInt);
            } 
            else if ((total != 0) && (total != roles.size())) {
                gen.writeNumberField('itemsPerPage', roles.size());
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
            if (roles != null) {
                RoleResource.serializeRoleWithGenerator(roles, attributes, host, gen);           
            }
 
            gen.writeEndArray();
        gen.writeEndObject();
        return Blob.valueOf(gen.getAsString());
    
    }
    
}