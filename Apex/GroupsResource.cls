@RestResource(urlMapping='/scim/v2/Groups')
global class GroupsResource {

    final public static Map<String, ScimSoqlAttributeProcessor> scimNameToGroupSObjectNameMap;
    
    static {
        scimNameToGroupSObjectNameMap = new Map<String, ScimSoqlAttributeProcessor>();
        scimNameToGroupSObjectNameMap.put('id', new StandardAttributeProcessor('Id', Schema.SOAPType.String, false));
        scimNameToGroupSObjectNameMap.put('displayName', new StandardAttributeProcessor('Name', Schema.SOAPType.String, false));
        scimNameToGroupSObjectNameMap.put('members', new GroupMembersAttributeProcessor());
        
        scimNameToGroupSObjectNameMap.put('meta', new StandardAttributeProcessor('CreatedDate,LastModifiedDate', Schema.SOAPType.String, true));
        scimNameToGroupSObjectNameMap.put('meta.created', new StandardAttributeProcessor('CreatedDate', Schema.SOAPType.DateTime, false));
        scimNameToGroupSObjectNameMap.put('meta.lastModified', new StandardAttributeProcessor('LastModifiedDate', Schema.SOAPType.DateTime, false));       
    }
    
    @HttpPost
    global static void doPost() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        System.JSONParser parser = System.JSON.createParser(req.requestBody.toString());
        Id groupId = GroupResource.doUpsert(null, parser);
        if (groupId != null) {
            GroupResource.doGet(groupId, null, true);
        } 
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
            
            QueryHolder groupQueryHolder = FilterTranslator.buildAttributeQueryString(attributes, filter, startIndex, count, scimNameToGroupSObjectNameMap, 'Group', ' Type = \'Regular\' ', null, null);
            
            String countSoql = groupQueryHolder.getCountQuery();
            String actualSoql = groupQueryHolder.getActualQuery();
            
            Integer total = ScimResource.countQuery(countSoql);
            List<Group> groups = Database.query(actualSoql);

            if ( !groups.isEmpty()  ) {
                res.responseBody = serializeGroups(groups, total, startIndex, count, attributes, host,req.headers.containsKey('X-Prettyprint'));
            } else {
                res.responseBody = serializeGroups(null,0,null,null,null,host,req.headers.containsKey('X-Prettyprint'));
            }
        }
        catch (Exception ex) {
            res.statusCode = 400;
            res.responseBody = SCIMError.serializeError(res.statusCode, ex.getMessage(), req.headers.containsKey('X-Prettyprint'));
            return;
        }              
    }

    private static Blob serializeGroups(List<Group> groups, Integer total, String startIndex, String count, String attributes, String host, boolean prettyPrint) {
        JSONGenerator gen = JSON.createGenerator(prettyPrint);
        gen.writeStartObject();
            gen.writeNumberField('totalResults', total);
            
            if (count != null) {
                Integer countInt = Math.min(Integer.valueof(count), groups.size());
                gen.writeNumberField('itemsPerPage', countInt);
            } 
            else if ((total != 0) && (total != groups.size())) {
                gen.writeNumberField('itemsPerPage', groups.size());
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
            if (groups != null) {
               GroupResource.serializeGroupWithGenerator(groups, attributes, host, gen);
            }
            gen.writeEndArray();
        gen.writeEndObject();
        return Blob.valueOf(gen.getAsString());
    
    }
    
}