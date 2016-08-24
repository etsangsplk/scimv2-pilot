@RestResource(urlMapping='/scim/v2/Roles/*')
global class RoleResource extends ScimResource {
	
	// TODO method for iterating users to remove Role assignments probably can be optimized
    @HttpDelete
    global static void doDelete() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String[] uriParts = req.requestURI.split('/',0);
        Integer numParts = uriParts.size() - 1;  
        
        UserRole[] r = Database.query('select id from userrole where id=\'' + uriParts[numParts] + '\'');
        if(r.size() == 1) {
			for (UserRole role : r){
				for (User u : [select id, userRoleId from User where userRoleId = :role.Id]){
					u.userRoleId = null;
                    update u;
				}
			}
			//Now delete the Role
			// Of course this assumes we can actually delete Roles
			// My guess is that we cannot this if the Role is involved with sharing rules
			// and I have no idea what to do there
        	delete r[0];
            res.statusCode = 204;
        } else {
            res.statusCode = 404;
            res.responseBody = SCIMError.serializeError(res.statusCode, 'No such resource.', req.headers.containsKey('X-Prettyprint'));
            return;
        }
    }    
    
	@HttpPut
	global static void doPut() {
	
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String[] uriParts = req.requestURI.split('/',0);
        Integer numParts = uriParts.size() - 1;   
		// clear assignments then doPatch
        UserRole[] r = Database.query('select id from userrole where id=\'' + uriParts[numParts] + '\'');
        if(r.size() == 1) {
			for (UserRole role : r){
				for (User u : [select id, userRoleId from User where userRoleId = :role.Id]){
					u.UserRoleId = null;
                    update u;
				}
			}
        } else {
            res.statusCode = 404;
            res.responseBody = SCIMError.serializeError(res.statusCode, 'No such resource.', req.headers.containsKey('X-Prettyprint'));
            return;
        }
        doPatch();
	}
    
	@HttpPatch
	global static void doPatch(){
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String[] uriParts = req.requestURI.split('/',0);
        Integer numParts = uriParts.size() - 1;   
        
        if (numParts >= 4  || [select id from UserRole where id = :uriParts[numParts]].size()==0){ 
            res.statusCode = 404;
            res.responseBody = SCIMError.serializeError(res.statusCode, 'No such resource.', req.headers.containsKey('X-Prettyprint'));
            return;
        }
        
        String roleId = uriParts[numParts];
        RolePatchParser rolePP = RolePatchParser.parse(req.requestBody.toString());

        String schema = rolePP.schemas.get(0);
        if (!schema.equals('urn:ietf:params:scim:api:messages:2.0:PatchOp')){
            res.statusCode = 400;
            res.responseBody = SCIMError.serializeError(res.statusCode, 'Improper Schema.', req.headers.containsKey('X-Prettyprint'));
            return;
        }

        Savepoint sp = Database.setSavepoint();        
        try {
            for (RolePatchParser.Operations op : rolePP.Operations){
                String operation = op.op;
                // Role Patch expects either path=members
                // everything else will not be parsed
                
                List<User> usersToBeProcessed = new List<User>();
                for (RolePatchParser.Value val : op.value){
                    User tempUser = new User();
                    if (op.path != 'members'){
                        res.statusCode = 400;
                        res.responseBody = SCIMError.serializeError(res.statusCode, 'Improper Operation. path must be members', req.headers.containsKey('X-Prettyprint'));
                        Database.rollback(sp);
                        return;
                    }
                    
                    tempUser.Id = val.value;
                    usersToBeProcessed.add(tempUser);
                }
                for (User tempUser : usersToBeProcessed){
                    User u = [select id, userRoleId from User where id = :tempUser.id limit 1];
                    if (operation == 'add'){
                        if (u.userRoleId == null) {
                            u.userRoleId = roleId;
                            update u;
                            res.statusCode = 204;
                        } else {
                            res.statusCode = 400;
                            res.responseBody = SCIMError.serializeError(res.statusCode, 'Cannot \'add\' role to user who already has a role. Use \'replace\'', req.headers.containsKey('X-Prettyprint'));   
                            Database.rollback(sp);
                            return;
                        }
                    } else if (operation == 'replace'){
                        u.userRoleId = roleId;
                        update u;                    
                        res.statusCode = 204;            
                    } else if  (operation == 'remove'){
                        if (roleId == u.UserRoleId){
                            u.UserRoleId = null;
                            update u;
                            res.statusCode = 204;                            
                        } else {
                            res.statusCode = 400;
                            res.responseBody = SCIMError.serializeError(res.statusCode, 'Cannot remove a role that the user doesn\'t have', req.headers.containsKey('X-Prettyprint'));                    
                            Database.rollback(sp);  
                            return;
                        }
                    } else {
                        res.statusCode = 400;
                        res.responseBody = SCIMError.serializeError(res.statusCode, 'Improper Operations', req.headers.containsKey('X-Prettyprint'));
                        Database.rollback(sp);
                        return;
                    }
                }
            }
        } catch (Exception e) {
            res.addHeader('Content-Type', 'application/json');
            if (res.statusCode == null) {
                res.statusCode = 500;
            } 
            res.responseBody = ScimError.serializeError(res.statusCode, e.getMessage(), req.headers.containsKey('X-Prettyprint'));
            Database.rollback(sp);  
        }

        if (roleId != null) {
            // retrieve self
            doGet(roleId, null, false);
        }
    }

    @HttpPost
    global static void doPost(){
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String method = req.headers.get('X-HTTP-Method-Override');
        if ( method == null ) method = 'POST';
        if ( method.equals('DELETE') ) {
            doDelete(); 
        } else {
            System.JSONParser parser = System.JSON.createParser(req.requestBody.toString());
            Id roleId = doUpsert(null, parser);
            if (roleId != null) {
                // retrieve self
                doGet(roleId, null, true);
            }
        }
    }

    // TODO - fix this, de-group-ify it
    public static Id doUpsert(String roleId, System.JSONParser parser) {
        
        List<Map<String,String>> members;
        List<String> attributes;
        String displayName;
        
        try {
            if (roleId != null && [select id from UserRole where id = :roleId].size() == 0) {
                throw new ScimException('Role ' + roleId + ' not found');
            }
        
            while (parser.nextToken() != null) {
                if (ScimResource.isNextTokenField(parser, 'members')) {    
                    members = ScimResource.parseObjectArray('members', parser);                            
                }
                if (ScimResource.isNextTokenField(parser, 'meta')) {    
                    while ((parser.nextToken() != null) && (parser.getCurrentToken() != JSONToken.END_OBJECT)) {
                        if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                            String name = parser.getText();
                            if ('attributes'.equals(name)) {
                                attributes = ScimResource.parseStringArray('attributes', parser);
                            }
                        }                      
                    }                     
                }
            }
            
            //todo defuse the v1 .delete stuff
            // The meta operations are per the spec
            // They are quite unrestful
            if (attributes != null) {
                UserRole[] r = Database.query('select id from UserRole where id=\'' + roleId + '\'');
                for (UserRole role : r){
                    for (User u : [select id, userRoleId from User where userRoleId = :role.Id]){
                        u.userRoleId = null;
                        update u;
                    }
                }
            }
            
            if ( members != null ) {
                for ( Map<String,String> member : members ) {
                    String userRoleId;
                    if (member.containsKey('value')) userRoleId = member.get('value');
                    String operation = member.get('operation');
                    if ('delete'.equals(operation)) {
                        // delete if there
                        List<User> user = [Select Id, UserRoleId from User where userRoleId = :roleId];
                        if (!user.isEmpty()) {
                            user[0].UserRoleId = null;
                            update user[0];
                        }                    
                    }
                    else {
                        // add if not there
                        if (userRoleId != null) {
	                        List<User> user = [Select Id, UserRoleId from User where id = :member.get('value')];
							user[0].UserRoleId = roleId;
                            update user[0];
                        } 
                    }
                }
            }  
            return roleId;
        }
        catch (Exception e) {
            RestRequest req = RestContext.request;
            RestResponse res = RestContext.response;
            res.addHeader('Content-Type', 'application/json');
            res.statusCode = 500;
            res.responseBody = ScimError.serializeError(res.statusCode, e.getMessage(), req.headers.containsKey('X-Prettyprint'));  
            return null;      
        }  
    }
	
	
	public static void serializeRoleWithGenerator(List<UserRole> roles, String attributes, String host, JSONGenerator gen) {
        serializeRoleWithGenerator(roles, attributes, host, gen, 200, 0);
    }
    
    public static void serializeRoleWithGenerator(List<UserRole> roles, String attributes, String host, JSONGenerator gen, Integer membersLimit, Integer membersOffset) {
        Map<Id, List<User>> rmMap = new Map<Id, List<User>>();
        if (shouldSerialize('members', attributes)) {
            for (User u : [select id, UserRoleId from User where UserRoleId = :roles LIMIT :membersLimit OFFSET :membersOffset]){
                List<User> usersWithRole = rmMap.get(u.UserRoleId);
                if (usersWithRole == null) {
                    usersWithRole = new List<User>();
                    rmMap.put(u.UserRoleId, usersWithRole);
                }
                usersWithRole.add(u);
            }
            
        }
        
        String scimRef = host + '/services/apexrest/v2/';
        for (UserRole r : roles) {
            gen.writeStartObject();
                gen.writeFieldName('schemas');
                gen.writeStartArray();
                    gen.writeString('urn:salesforce:schemas:extension:1.0:Role');
                gen.writeEndArray();
                gen.writeStringField('id', r.id);            
                if (shouldSerialize('displayName', attributes)) {
                    gen.writeStringField('displayName', r.name);
                }
                
                if (shouldSerialize('members', attributes)) {
                    gen.writeFieldName('members');
                    gen.writeStartArray();
                        List<User> users = rmMap.get(r.id);
                        if (users != null) {
                            for (User user : users) {
                                gen.writeStartObject();
                                    gen.writeStringField('value', user.id);  
                                    gen.writeStringField('$ref', 'https://' + scimref + 'Users/' + user.id);
                                gen.writeEndObject();
                            } 
                        }  
                    gen.writeEndArray();
                }
                
                if (shouldSerialize('meta', attributes)) {
                    gen.writeFieldName('meta');
                        gen.writeStartObject();
                            String lastmodFormated = r.LastModifiedDate.format('yyyy-MM-dd');
                            lastmodFormated += 'T';
                            lastmodFormated += r.LastModifiedDate.formatGmt('hh:mm:ss');
                            gen.writeStringField('lastModified', lastmodFormated + 'Z');
                            
                            String base = URL.getSalesforceBaseUrl().toExternalForm();
                            String path = '/services/apexrest/scim/v2/Roles/' + r.id;
                            gen.writeStringField('location', base + path);
                    
                    		gen.writeStringField('resourceType', 'Role');
                            
                            Blob digest = Crypto.generateDigest('SHA-1',  Blob.valueOf(user.id + lastmodFormated));
                            gen.writeStringField('version', EncodingUtil.convertToHex(digest));                                        
                        gen.writeEndObject();
                }
            gen.writeEndObject();    
        }   
    }    
    
    public static boolean shouldSerialize(String attributeName, String attributes) {
        return ScimResource.shouldSerialize(attributeName, attributes, RolesResource.scimNameToRoleSObjectNameMap);
    }  
   
    global static void doGet(String id, String attributes, boolean isPost) {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');
        
        String membersCount = req.params.get('members.count');
        String membersStartIndex = req.params.get('members.startIndex');
                
        try {
            Integer membersLimit = 200;
            if (membersCount != null) {
                FilterTranslator.validateCount(membersCount);
                membersLimit = Integer.valueof(membersCount);
            }
            
            Integer membersOffset = 0;
            if (membersStartIndex != null) {
                FilterTranslator.validateStartIndex(membersStartIndex);
                membersOffset = Integer.valueof(membersStartIndex) - 1;
            }
            else {
                membersOffset = 0;
            }        
        
        
            String host = req.headers.get('Host');
            // problem query here
            QueryHolder roleQueryHolder = FilterTranslator.buildAttributeQueryString(attributes, 'id eq \"' + id + '\"', null, null, RolesResource.scimNameToRoleSObjectNameMap, 'UserRole', ' (Id != NULL) ', null, null);
            String actualSoql = roleQueryHolder.getActualQuery();
            List<UserRole> roles = Database.query(actualSoql);
            
            if ( !roles.isEmpty()  ) {
                res.statusCode = 200;
                if(isPost){
                    res.statusCode = 201; 
                }
                Boolean isPrettyPrint = req.headers.containsKey('X-Prettyprint');
                JSONGenerator gen = JSON.createGenerator(isPrettyPrint);
                serializeRoleWithGenerator(roles, attributes, host, gen, membersLimit, membersOffset);      
                res.responseBody =  Blob.valueOf(gen.getAsString());
            } else {
                res.statusCode = 404;
                res.responseBody = SCIMError.serializeError(res.statusCode, 'Resource https://' + host + '/services/apexrest/v2/Roles/' + id + ' not found', req.headers.containsKey('X-Prettyprint'));
            }    
        }  
        catch (ScimException ex) {
            res.statusCode = 400;
            res.responseBody = SCIMError.serializeError(res.statusCode, ex.getMessage(), req.headers.containsKey('X-Prettyprint'));
            return;
        }     
    }

    @HttpGet
    global static void doGet() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        String attributes = req.params.get('attributes');
        if (attributes != null) {
            attributes = attributes.replaceAll(' ', '');
        } 
        
        String[] uriParts = req.requestURI.split('/',0);
        Integer numParts = uriParts.size() - 1;
        if (numParts > 4) { 
            res.statusCode = 404;
            res.responseBody = SCIMError.serializeError(res.statusCode, 'No such resource.', req.headers.containsKey('X-Prettyprint'));
        } else if (numParts == 4) {
            doGet(uriParts[numParts], attributes, false);   
        } else if (numParts == 3) {
            RolesResource.doGet();
        }
    }
}