@RestResource(urlMapping='/scim/v2/Entitlements/*')
global class EntitlementResource extends ScimResource {
    
	@HttpPut   
	global static void doPut() {
		RestRequest req = RestContext.request;
		RestResponse res = RestContext.response;
		res.statusCode = 501;
        res.responseBody = SCIMError.serializeError(res.statusCode, 'Method not supported', req.headers.containsKey('X-Prettyprint'));
    	return;
    }
    
    @HttpDelete
	global static void doDelete() {
		RestRequest req = RestContext.request;
		RestResponse res = RestContext.response;
		res.statusCode = 501;
        res.responseBody = SCIMError.serializeError(res.statusCode, 'Method not supported', req.headers.containsKey('X-Prettyprint'));
    	return;
    }
    
    @HttpPatch
    global static void doPatch() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String[] uriParts = req.requestURI.split('/',0);
        Integer numParts = uriParts.size() - 1;
        
        System.debug(uriParts + ' '+ numParts);
        
        Boolean isFound = false;
        String entitlementType ='';
        String entitlementId = uriParts[numParts];
        System.debug('entId: ' + entitlementId);
        if (entitlementId.startsWith('00e')) {
            isFound = !([select ID from Profile where ID = :entitlementId].isEmpty());
            entitlementType = 'profile';
        }
        else if (entitlementId.startsWith('0PS')) {
            isFound = !([select ID from PermissionSet where ID = :entitlementId].isEmpty());
            entitlementType = 'permissionSet';
        }
        System.debug('entType: ' + entitlementType);
        if (numParts > 4 || !isFound) { 
            res.statusCode = 404;
            res.addHeader('Content-Type', 'application/json');
            res.responseBody = SCIMError.serializeError(res.statusCode, 'No such resource.', req.headers.containsKey('X-Prettyprint'));
            return;
        }        
        
        EntitlementPatchParser entitlementPP = EntitlementPatchParser.parse(req.requestBody.toString());
        String schema = entitlementPP.schemas.get(0);
        if (!schema.equals('urn:ietf:params:scim:api:messages:2.0:PatchOp')){
            res.statusCode = 400;
            res.responseBody = SCIMError.serializeError(res.statusCode, 'Improper Schema.', req.headers.containsKey('X-Prettyprint'));
            return;
        }
        
        Savepoint sp = Database.setSavepoint();
        try {
            for (EntitlementPatchParser.Operations op : entitlementPP.operations){
                String operation = op.op;
                // Entitlement Patch expects path to be members
                // and value must me list of values
                // everything else will not be parsed
                String path = op.path;
                List<User> usersToBeProcessed = new List<User>();
                if (path == 'members') {
                    for (EntitlementPatchParser.Value val : op.value){
                        User tempUser = new User();
                        tempUser.Id = (id)val.value;
                        usersToBeProcessed.add(tempUser);                        
                    }                    
                }

                for (User tempUser : usersToBeProcessed){
                    User u = [select id, userRoleId from User where id = :tempUser.id limit 1];
                    System.debug('entType: ' + entitlementType + ' op: ' + operation);
                    // process profile assignments
                    if (entitlementType == 'profile'){
                        if (operation == 'add'){
                            //not meaningful
                            ScimException scimEx = new ScimException('Cannot add a profile to an existing user');
                            scimEx.setStatusCode(400);
                            throw scimEx;
                        } else if (operation == 'replace'){
                            u.ProfileId = entitlementId;
                            update u;
                        } else if (operation == 'remove'){
                            //not meaningful
                            //double checking
                            ScimException scimEx = new ScimException('Cannot remove a profile from an existing user');
                            scimEx.setStatusCode(400);
                            throw scimEx;
                        }
                    } else if (entitlementType == 'permissionSet'){                 // process permSet
                    if (operation == 'add'){                        
                        // avoid duplicate insertion errors
                        List<PermissionSetAssignment> existingPSAs = new List <PermissionSetAssignment>();
                        existingPSAs = [SELECT Id FROM PermissionSetAssignment where AssigneeId = :u.Id and permissionSetId = :entitlementId];
                        if (existingPSAs.isEmpty()){
                            PermissionSetAssignment newPsa = new PermissionSetAssignment();
                            newPsa.assigneeId = u.Id;
                            newPsa.permissionSetId = entitlementId;
                            insert newPsa;                                                                
                        }
                    } else if (operation == 'replace'){
                        // this will replace the permSet assignments for the user
                        // it will not replace the users in the permSet
                        // which is to say, it will not remove all of the PermSet assignments and then add the mention users
                        // it will simply remove all of the mention users PermSets and add the referenced one
                        // consider changing or documenting

                        //delete the current users assignments
                        List<PermissionSetAssignment> assignedPS = [SELECT Id FROM PermissionSetAssignment where AssigneeId = :u.Id and permissionSetId in (select id from PermissionSet where isOwnedByProfile = false)];
                        delete assignedPS;
                    
                        //add the new value
                        PermissionSetAssignment newPsa = new PermissionSetAssignment();
                        newPsa.assigneeId = u.Id;
                        newPsa.permissionSetId = entitlementId;
                        System.debug('new permset: ' + newPSA);
                        insert newPsa;                        
                    } else if (operation == 'remove'){
                        //delete the current users assignments
                        List<PermissionSetAssignment> assignedPS = [select id from PermissionSetAssignment where PermissionSetId = :entitlementId and AssigneeId = :u.Id];
                        delete assignedPS;
	                }
	            }
                }
            }
        } catch (SCIMException e) {
            res.addHeader('Content-Type', 'application/json');
            res.statusCode = e.getStatusCode();
            if (res.statusCode == null) {
                res.statusCode = 500;
            } 
            res.responseBody = ScimError.serializeError(res.statusCode, e.getMessage(), req.headers.containsKey('X-Prettyprint'));
            Database.rollback(sp);
            return;
        }

        res.statusCode = 204;
        // retrieve self
        if (entitlementId != null) {
            doGet();
        }
    }
    
    @HttpGet
    global static void doGet() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String attributes = req.params.get('attributes');
        
        String membersCount = req.params.get('members.count');
        String membersStartIndex = req.params.get('members.startIndex');
        if (attributes != null) {
            attributes = attributes.replaceAll(' ', '');
        }
        
        try{
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
        
            res.addHeader('Content-Type', 'application/json');
            String host = req.headers.get('Host');
            String[] uriParts = req.requestURI.split('/',0);
            Integer numParts = uriParts.size() - 1;   
            if (numParts > 4) { 
                res.statusCode = 404;
                res.responseBody = SCIMError.serializeError(res.statusCode, 'No such resource.', req.headers.containsKey('X-Prettyprint'));
            } else if (numParts == 3) {
                EntitlementsResource.doGet();
            } else if (numParts == 4) {
                List<User> users = new List<User>();
                String entitlementId = uriParts[numParts];
                if (entitlementId.startsWith('00e')) {
                    QueryHolder profileQueryHolder = FilterTranslator.buildAttributeQueryString(attributes, 'id eq \"' + entitlementId + '\"', null, null, EntitlementsResource.scimNameToProfileSObjectNameMap, 'Profile', ' (Id != NULL) ' , null, null);
                    List<Profile> profiles = Database.query(profileQueryHolder.getActualQuery());
                    if ( !profiles.isEmpty()  ) {
                        users = [ select Id, Name, ProfileId, Profile.Name, isActive from User where isActive = true and ProfileId = :uriParts[numParts] LIMIT :membersLimit OFFSET :membersOffset];
                        List<UserIdNamePair> userIdNamePair = new List<UserIdNamePair>();
                        if (!users.isEmpty()) {
                            for (User user : users) {
                                userIdNamePair.add(new UserIdNamePair(user.id, user.Name));
                            }                        
                        }
                        res.statusCode = 200; 
                        res.responseBody = serializeEntitlement(profiles.get(0).Id, profiles.get(0), attributes, userIdNamePair, req.headers.containsKey('X-Prettyprint'));
                    }
                    else {
                        res.statusCode = 404;
                        res.responseBody = SCIMError.serializeError(res.statusCode, 'Resource https://' + host + '/services/apexrest/v2/Entitlements/' + uriParts[numParts] + ' not found', req.headers.containsKey('X-Prettyprint'));
                    }
                }
                else if (entitlementId.startsWith('0PS')) {
                    QueryHolder permsetQueryHolder = FilterTranslator.buildAttributeQueryString(attributes, 'id eq \"' + entitlementId + '\"', null, null, EntitlementsResource.scimNameToPermsetSObjectNameMap, 'PermissionSet', ' (IsOwnedByProfile = false) ' , null, null); 
                    List<PermissionSet> permsets = Database.query(permsetQueryHolder.getActualQuery());
                    if ( !permsets.isEmpty()  ) {
                        List<PermissionSetAssignment> psas = [select AssigneeId from permissionsetassignment where permissionsetid = :permsets.get(0).Id LIMIT :membersLimit OFFSET :membersOffset];
                        List<Id> ids = new List<Id>();
                        for (PermissionSetAssignment thisPsa : psas) {
                            ids.add(thisPsa.assigneeId);
                        }
                        List<UserIdNamePair> userIdNamePair = new List<UserIdNamePair>();
                        if ( !psas.isEmpty()) {
                            users = [select Id, Name from User where isActive = true and Id IN :ids];
                            for (User user : users) {
                                userIdNamePair.add(new UserIdNamePair(user.id, user.Name));
                            }
                        }  
                        res.statusCode = 200; 
                        res.responseBody = serializeEntitlement(permsets.get(0).Id, permsets.get(0), attributes, userIdNamePair, req.headers.containsKey('X-Prettyprint'));
                    }
                    else {
                        res.statusCode = 404;
                        res.responseBody = SCIMError.serializeError(res.statusCode, 'Resource https://' + host + '/services/apexrest/v2/Entitlements/' + uriParts[numParts] + ' not found', req.headers.containsKey('X-Prettyprint'));
                    }
                }
                else {
                    res.statusCode = 404;
                    res.responseBody = SCIMError.serializeError(res.statusCode, 'Resource https://' + host + '/services/apexrest/v2/Entitlements/' + uriParts[numParts] + ' not found', req.headers.containsKey('X-Prettyprint'));
                }  
            }       
        }
        catch (ScimException ex) {
            res.statusCode = 400;
            res.responseBody = SCIMError.serializeError(res.statusCode, ex.getMessage(), req.headers.containsKey('X-Prettyprint'));
            return;
        }           
    }
    
    public static boolean shouldSerialize(String id, String attributeName, String attributes) {
        if (id.startsWith('00e')) {
            return ScimResource.shouldSerialize(attributeName, attributes, EntitlementsResource.scimNameToProfileSObjectNameMap);
        }
        else if (id.startsWith('0PS')) {
            return ScimResource.shouldSerialize(attributeName, attributes, EntitlementsResource.scimNameToPermsetSObjectNameMap);
        }
        else {
            return false; // makes no sense just do not serialize
        }
    }      
    
    public static Blob serializeEntitlement(String id, SObject entitlement, String attributes, List<UserIdNamePair> users, boolean prettyPrint) {
        JSONGenerator gen = JSON.createGenerator(prettyPrint);
        serializeEntitlementWithGenerator(id, entitlement, attributes, users, gen);
        return Blob.valueOf(gen.getAsString());
    }      
    
    public class UserIdNamePair {
        private Id id;
        private String name;
        
        public UserIdNamePair(Id id, String name) {
            this.id = id;
            this.name = name;
        }
        
        public String getName() {
            return name;
        }
        
        public Id getId() {
            return id;
        }
    
        public void setName(String name) {
            this.name = name;
        }
        
        public void setId(Id id) {
            this.id = id;
        }
    }
    
    public static void serializeEntitlementWithGenerator(String id, SObject entitlement, String attributes, List<UserIdNamePair> users, JSONGenerator gen) {
	        String base = URL.getSalesforceBaseUrl().toExternalForm();
        
        	gen.writeStartObject();
            gen.writeFieldName('schemas');
            gen.writeStartArray();
                gen.writeString('urn:salesforce:schemas:extension:1.0:Entitlement');
            gen.writeEndArray();
            gen.writeStringField('id', id);
            if (shouldSerialize(id, 'displayName', attributes)) {
                gen.writeStringField('displayName', (String) entitlement.get('Name'));
            }
            if (id.startsWith('00e')){
                gen.writeStringField('type', 'Profile');
            } else {
                gen.writeStringField('type', 'Permission Set');
            }
            if (shouldSerialize(id, 'members', attributes)) {
                gen.writeFieldName('members');
                gen.writeStartArray();
                String userId;
                    if (users != null) {
                        for ( UserIdNamePair user : users ) {
                            userId = user.getId();
                            gen.writeStartObject();
                                gen.writeStringField('value', userId);
                                gen.writeStringField('display', user.getName());
                            	gen.writeStringField('$ref', base + '/services/apexrest/scim/v2/Users/' + userId);
                            gen.writeEndObject();        
                        }
                    }
                gen.writeEndArray();
            }
            
            if (shouldSerialize(id, 'meta', attributes)) {
                gen.writeFieldName('meta');
                    gen.writeStartObject();
                        String createdFormated = ((Datetime) entitlement.get('CreatedDate')).format('yyyy-MM-dd');
                        createdFormated += 'T';
                        createdFormated += ((Datetime) entitlement.get('CreatedDate')).formatGmt('hh:mm:ss');
                        gen.writeStringField('created', createdFormated + 'Z');
                        
                        String lastmodFormated = ((Datetime) entitlement.get('LastModifiedDate')).format('yyyy-MM-dd');
                        lastmodFormated += 'T';
                        lastmodFormated += ((Datetime) entitlement.get('LastModifiedDate')).formatGmt('hh:mm:ss');
                        gen.writeStringField('lastModified', lastmodFormated + 'Z');
                        
                        String path = '/services/apexrest/v2/Entitlements/' + id;
                        gen.writeStringField('location', base + path);

                    		gen.writeStringField('resourceType', 'Entitlement');                
                            
                        Blob digest = Crypto.generateDigest('SHA-1',  Blob.valueOf(user.id + lastmodFormated));
                        gen.writeStringField('version', EncodingUtil.convertToHex(digest));
                gen.writeEndObject();
            }            
            
        gen.writeEndObject();        
    }
}