@RestResource(urlMapping='/scim/v2/Groups/*')
global class GroupResource extends ScimResource {

    @HttpDelete
    global static void doDelete() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String[] uriParts = req.requestURI.split('/',0);
        Integer numParts = uriParts.size() - 1;  
        
        Group[] g = Database.query('select id from group where id=\'' + uriParts[numParts] + '\'');
        if(g.size() == 1) {
        	delete g[0];
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
        if (numParts >= 4) { 
            res.statusCode = 404;
            res.responseBody = SCIMError.serializeError(res.statusCode, 'No such resource.', req.headers.containsKey('X-Prettyprint'));
            return;
        }                
        
        // put means we clear all the members whatsoever and then upsert
        String groupId = uriParts[numParts];
        List<GroupMember> groupMembers = [Select Id from GroupMember where GroupId = :groupId];
        Database.delete(groupMembers, true);
        doUpsert(groupId, System.JSON.createParser(req.requestBody.toString()));

    }

    // TODO Changes to assumptions about PATCH have broken this completely
    // TODO Fix
    // assumes path = members
    @HttpPatch
    global static void doPatch() {
    
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String[] uriParts = req.requestURI.split('/',0);
        Integer numParts = uriParts.size() - 1;   

        if (numParts > 4  || [select id from group where id = :uriParts[numParts]].size()==0){ 
            res.statusCode = 404;
            res.responseBody = SCIMError.serializeError(res.statusCode, 'No such resource.', req.headers.containsKey('X-Prettyprint'));
            return;
        }

        String groupId = uriParts[numParts];
        GroupPatchParser groupPP = GroupPatchParser.parse(req.requestBody.toString());
        
        String schema = groupPP.schemas.get(0);
        if (!schema.equals('urn:ietf:params:scim:api:messages:2.0:PatchOp')){
            res.statusCode = 400;
            res.responseBody = SCIMError.serializeError(res.statusCode, 'Improper Schema.', req.headers.containsKey('X-Prettyprint'));
            return;
        }

        Savepoint sp = Database.setSavepoint();        
        try {
            for (GroupPatchParser.Operations op : groupPP.Operations){
                String operation = op.op;
                // Group Patch expects either path=members
                // or a value value of "members":"ID"
                // everything else will not be parsed                
                if (op.value == null) {
                    res.statusCode = 400;
                    res.responseBody = SCIMError.serializeError(res.statusCode, 'Improper Operation. value array must be present', req.headers.containsKey('X-Prettyprint'));
                    Database.rollback(sp);
                    return;
                }
               if (op.path != 'members'){
                    res.statusCode = 400;
                    res.responseBody = SCIMError.serializeError(res.statusCode, 'Improper Operation. path must be members only', req.headers.containsKey('X-Prettyprint'));
                    Database.rollback(sp);
                    return;
                }
                
                // build list of member IDs
                List<GroupMember> groupMembersToBeProcessed = new List<GroupMember>();
                for (GroupPatchParser.Value val : op.value){
                    GroupMember gm = new GroupMember();
                    gm.UserOrGroupId = val.value;
                    gm.GroupId = groupId;
                    groupMembersToBeProcessed.add(gm);
                }
                
                // if operation is replace, then remove all assignemnts and reassign via add
                if (operation == 'replace'){
                    List<GroupMember> groupMember = [Select Id from GroupMember where groupId = :groupId];
                    if (!groupMember.isEmpty()) {
                        Database.delete(groupMember, true);
                    }
                } else if (operation == 'add' || operation == 'replace') {
                    for (GroupMember member : groupMembersToBeProcessed){
                        System.debug('member: ' + member);
                        insert member;
                    }
                    res.statusCode = 204;
                } else if (operation == 'remove'){
                    for (GroupMember member : groupMembersToBeProcessed){
                        GroupMember tempGM = new GroupMember();
                        tempGM = [select Id from GroupMember where groupId = :member.GroupId and UserOrGroupId = :member.UserOrGroupId limit 1];
                        Database.delete(tempGM, true);
                    }
                    res.statusCode = 204;                                                             
                } else {
                    res.statusCode = 400;
                    res.responseBody = SCIMError.serializeError(res.statusCode, 'Improper Operations', req.headers.containsKey('X-Prettyprint'));
                    return;
                }
            }
        } catch (Exception e) {
            res.addHeader('Content-Type', 'application/json');
            if (res.statusCode == null) {
                res.statusCode = 500;
            } 
            res.responseBody = ScimError.serializeError(res.statusCode, e.getMessage() + ' FIELD_INTEGRITY_EXCEPTIONs likely caused by attempted assignment to wrong User license.', req.headers.containsKey('X-Prettyprint'));
            Database.rollback(sp);
            return;
        }

        if (groupId != null) {
            // retrieve self
            doGet(groupId, null, false);
        }
    }
    
    
    public static Id doUpsert(String groupId, System.JSONParser parser) {
        
        List<Map<String,String>> members;
        List<String> attributes;
        String displayName;
        
        try {
            if (groupId != null && [select id from group where id = :groupId].size() == 0) {
                throw new ScimException('Group ' + groupId + ' not found');
            }
        
            while (parser.nextToken() != null) {
                if (ScimResource.isNextTokenField(parser, 'members')) {    
                    members = ScimResource.parseObjectArray('members', parser);                            
                }
                if (ScimResource.isNextTokenField(parser, 'displayName')) {    
                    displayName = ScimResource.parseString('displayName', parser);                            
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
            
            if (groupId == null) {
                Group g = new Group();
                g.Name = displayName;
                insert g;
                groupId = g.Id;
            }
            else {
                Group g = [Select Id, Name from Group where Id = :groupId];
                if (!g.Name.equals(displayName)) {
                    g.Name = displayName;
                    update g;
                }
            }
            
            // defuse v1 .delete here
            // The meta operations are per the spec
            // They are quite unrestful
            
            if (attributes != null) {
                for (String attribute : attributes) {
                    if ('members'.equals(attribute)) {
                        // A meta attribute with an attributes array that contains a members value
                        // Per spec this means removing all members
                        List<GroupMember> groupMembers = [Select Id from GroupMember where GroupId = :groupId];
                        Database.delete(groupMembers, true);
                    }
                }
            } 
            
            if ( members != null ) {
                for ( Map<String,String> member : members ) {
                    String userOrGroupId;
                    if (member.containsKey('value')) userOrGroupId = member.get('value');
                    if (userOrGroupId != null) {
                        List<GroupMember> groupMember = [Select Id from GroupMember where GroupId = :groupId AND UserOrGroupId = :userOrGroupId];
                        if (groupMember.isEmpty()) {
                            GroupMember newGroupMember = new GroupMember();
                            newGroupMember.groupId = groupId;
                            newGroupMember.UserOrGroupId = userOrGroupId;
                            insert newGroupMember;
                    } 
                    }
                }
            }  
            return groupId;
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
    
    public static void serializeGroupWithGenerator(List<Group> groups, String attributes, String host, JSONGenerator gen) {
        serializeGroupWithGenerator(groups, attributes, host, gen, 200, 0);
    }
    
    public static void serializeGroupWithGenerator(List<Group> groups, String attributes, String host, JSONGenerator gen, Integer membersLimit, Integer membersOffset) {
        Map<Id, List<GroupMember>> gmMap = new Map<Id, List<GroupMember>>();
        if (shouldSerialize('members', attributes)) {
            for (GroupMember gm : [select GroupId, UserOrGroupId from GroupMember where GroupId in :groups LIMIT :membersLimit OFFSET :membersOffset]) {
                Id groupId = gm.GroupId;
                List<GroupMember> gms = gmMap.get(groupId);
                if (gms == null) {
                    gms = new List<GroupMember>();
                    gmMap.put(groupId, gms);
                }
                gms.add(gm);
            }            
        }
        
        String scimRef = host + '/services/apexrest/scim/v2/';
        for (Group g : groups) {
            gen.writeStartObject();
                gen.writeFieldName('schemas');
                gen.writeStartArray();
                    gen.writeString('urn:ietf:params:scim:schemas:core:2.0:Group');
                gen.writeEndArray();
                gen.writeStringField('id', g.id);            
                if (shouldSerialize('displayName', attributes)) {
                    gen.writeStringField('displayName', g.name);
                }
                
                if (shouldSerialize('members', attributes)) {
                    gen.writeFieldName('members');
                    gen.writeStartArray();
                        List<GroupMember> members = gmMap.get(g.id);
                        if (members != null) {
                            for (GroupMember member : members) {
                                gen.writeStartObject();
                                    gen.writeStringField('value', member.UserOrGroupId);  
                                    String strId = member.UserOrGroupId;
                                    if ( strId.startsWith('005') ) {
                                        gen.writeStringField('type', 'User');
                                        gen.writeStringField('$ref', 'https://' + scimref + 'Users/' + member.UserOrGroupId);
                                    } else {
                                        gen.writeStringField('type', 'Group');
                                        gen.writeStringField('$ref', 'https://' + scimref + 'Groups/' + member.UserOrGroupId);
                                    }
                                gen.writeEndObject();
                            } 
                        }  
                    gen.writeEndArray();
                }
                
                if (shouldSerialize('meta', attributes)) {
                    gen.writeFieldName('meta');
                        gen.writeStartObject();
                            String createdFormated = g.CreatedDate.format('yyyy-MM-dd');
                            createdFormated += 'T';
                            createdFormated += g.CreatedDate.formatGmt('hh:mm:ss');
                            gen.writeStringField('created', createdFormated + 'Z');
                            
                            String lastmodFormated = g.LastModifiedDate.format('yyyy-MM-dd');
                            lastmodFormated += 'T';
                            lastmodFormated += g.LastModifiedDate.formatGmt('hh:mm:ss');
                            gen.writeStringField('lastModified', lastmodFormated + 'Z');
                            
                            String base = URL.getSalesforceBaseUrl().toExternalForm();
                            String path = '/services/apexrest/v2/Groups/' + g.id;
                            gen.writeStringField('location', base + path);

                    		gen.writeStringField('resourceType', 'Group');                    
                    
                            Blob digest = Crypto.generateDigest('SHA-1',  Blob.valueOf(user.id + lastmodFormated));
                            gen.writeStringField('version', EncodingUtil.convertToHex(digest));                                        
                        gen.writeEndObject();
                }
            gen.writeEndObject();    
        }   
    }    
    
    public static boolean shouldSerialize(String attributeName, String attributes) {
        return ScimResource.shouldSerialize(attributeName, attributes, GroupsResource.scimNameToGroupSObjectNameMap);
    }  

    @HttpPost
    global static void doPost() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String method = req.headers.get('X-HTTP-Method-Override');
        if ( method == null ) method = 'POST';
        if ( method.equals('DELETE') ) {
            doDelete(); 
        } else {
            System.JSONParser parser = System.JSON.createParser(req.requestBody.toString());
            Id groupId = doUpsert(null, parser);
            if (groupId != null) {
                // retrieve self
                doGet(groupId, null, true);
            }
        }
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
            QueryHolder groupQueryHolder = FilterTranslator.buildAttributeQueryString(attributes, 'id eq \"' + id + '\"', null, null, GroupsResource.scimNameToGroupSObjectNameMap, 'Group', ' Type = \'Regular\' ', null, null);
            String actualSoql = groupQueryHolder.getActualQuery();
            List<Group> groups = Database.query(actualSoql);
            
            if ( !groups.isEmpty()  ) {
                res.statusCode = 200;
                if(isPost){
                    res.statusCode = 201; 
                }
                Boolean isPrettyPrint = req.headers.containsKey('X-Prettyprint');
                JSONGenerator gen = JSON.createGenerator(isPrettyPrint);
                serializeGroupWithGenerator(groups, attributes, host, gen, membersLimit, membersOffset);      
                res.responseBody =  Blob.valueOf(gen.getAsString());
            } else {
                res.statusCode = 404;
                res.responseBody = SCIMError.serializeError(res.statusCode, 'Resource https://' + host + '/services/apexrest/v2/Groups/' + id + ' not found', req.headers.containsKey('X-Prettyprint'));
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
            GroupsResource.doGet();
        }
    }
}