@RestResource(urlMapping='/scim/v2/Entitlements')
global class EntitlementsResource {

    final public static Map<String, ScimSoqlAttributeProcessor> scimNameToProfileSObjectNameMap;
    final public static Map<String, ScimSoqlAttributeProcessor> scimNameToPermsetSObjectNameMap;
    
    static {
        scimNameToProfileSObjectNameMap = new Map<String, ScimSoqlAttributeProcessor>();
        scimNameToProfileSObjectNameMap.put('id', new StandardAttributeProcessor('Id', Schema.SOAPType.String, false));
        scimNameToProfileSObjectNameMap.put('displayName', new StandardAttributeProcessor('Name', Schema.SOAPType.String, false));
        scimNameToProfileSObjectNameMap.put('members', new ProfileMembersAttributeProcessor());
        scimNameToProfileSObjectNameMap.put('meta', new StandardAttributeProcessor('CreatedDate,LastModifiedDate', Schema.SOAPType.String, true));
        scimNameToProfileSObjectNameMap.put('meta.created', new StandardAttributeProcessor('CreatedDate', Schema.SOAPType.DateTime, false));
        scimNameToProfileSObjectNameMap.put('meta.lastModified', new StandardAttributeProcessor('LastModifiedDate', Schema.SOAPType.DateTime, false));        
        
        scimNameToPermsetSObjectNameMap = new Map<String, ScimSoqlAttributeProcessor>();
        scimNameToPermsetSObjectNameMap.put('id', new StandardAttributeProcessor('Id', Schema.SOAPType.String, false));
        scimNameToPermsetSObjectNameMap.put('displayName', new StandardAttributeProcessor('Name', Schema.SOAPType.String, false));
        scimNameToPermsetSObjectNameMap.put('members', new PermsetMembersAttributeProcessor()); 
        scimNameToPermsetSObjectNameMap.put('meta', new StandardAttributeProcessor('CreatedDate,LastModifiedDate', Schema.SOAPType.String, true));
        scimNameToPermsetSObjectNameMap.put('meta.created', new StandardAttributeProcessor('CreatedDate', Schema.SOAPType.DateTime, false));
        scimNameToPermsetSObjectNameMap.put('meta.lastModified', new StandardAttributeProcessor('LastModifiedDate', Schema.SOAPType.DateTime, false));       
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
            
            // Entitlements paging is a bit trickier, because it is a mixture of profiles and permsets
            String startIndex = req.params.get('startIndex');
            String count = req.params.get('count');
            
            // Filter out the BlackTab proxy, the AutoProc User and the Guest User Profiles
            // The field returns labels so be careful by getting the label.
            String XLabel = 'BlackTab User';// System.getLabel('UserType', 'X'); ONLY FOR IAN
            String ALabel = 'Automated Process';// System.getLabel('UserType', 'A'); ONLY FOR IAN
            String GLabel = 'Guest';// System.getLabel('UserType', 'G'); ONLY FOR IAN
            
            QueryHolder profileQueryHolder = FilterTranslator.buildAttributeQueryString(attributes, filter, startIndex, count, scimNameToProfileSObjectNameMap, 'Profile', ' (UserType != \'' + XLabel + '\' AND UserType !=\'' + ALabel + '\' AND UserType != \'' + GLabel + '\') ', null, null); 
            String profileCountSoql =  profileQueryHolder.getCountQuery(); 
            String profileActualSoql = profileQueryHolder.getActualQuery(); 
            Integer totalProfiles = ScimResource.countQuery(profileCountSoql);
    
            Integer max = 200;
            if (count != NULL) {
               // if specified, never pull more than specified
                max = Integer.valueof(count);
            }
            
            List<Profile> profiles = Database.query(profileActualSoql);
            QueryHolder permsetQueryHolder = FilterTranslator.buildAttributeQueryString(attributes, filter, startIndex, count, scimNameToPermsetSObjectNameMap, 'PermissionSet', ' IsOwnedByProfile = false ', null, null);
            Integer totalPermsets = ScimResource.countQuery(permsetQueryHolder.getCountQuery());
    
            String limitOverride = String.valueOf(Math.max(0, max - profiles.size()));
            String offsetOverride = null; 
            if (startIndex != NULL) {
                Integer offset = Math.max((Integer.valueof(startIndex) - totalProfiles - 1), 0);
                offsetOverride = String.valueOf(offset);
            }
            permsetQueryHolder = FilterTranslator.buildAttributeQueryString(attributes, filter, startIndex, count, scimNameToPermsetSObjectNameMap, 'PermissionSet', ' IsOwnedByProfile = false ', limitOverride, offsetOverride);        
            
            List<PermissionSet> permsets = Database.query(permsetQueryHolder.getActualQuery());
            Integer total = totalProfiles + totalPermsets;
            
            List<User> profileUsers = [select id, Name, isActive, profileid from User where isActive = true and profileid in :profiles LIMIT 200];
            Map<Id, List<EntitlementResource.UserIdNamePair>> profileIdToUsersMaps = new Map<Id, List<EntitlementResource.UserIdNamePair>>();
            for (User thisUser: profileUsers) {
                String thisUserProfileId = thisUser.profileid; 
                List<EntitlementResource.UserIdNamePair> thisProfileUsers = profileIdToUsersMaps.get(thisUserProfileId);
                if (thisProfileUsers == null) {
                    thisProfileUsers = new List<EntitlementResource.UserIdNamePair>();
                    profileIdToUsersMaps.put(thisUserProfileId, thisProfileUsers);
                }
                thisProfileUsers.add(new EntitlementResource.UserIdNamePair(thisUser.Id, thisUser.Name));
            }
            
            List<PermissionSetAssignment> assignments = [select id, AssigneeId, Assignee.Name, PermissionSetId FROM PermissionSetAssignment where PermissionSetId IN :permsets AND assignee.isActive = true LIMIT 200];
            Map<Id, List<EntitlementResource.UserIdNamePair>> permsetIdToUsersMaps = new Map<Id, List<EntitlementResource.UserIdNamePair>>();
            for (PermissionSetAssignment assignment : assignments) {
                String thisUserPermsetId = assignment.PermissionSetId; 
                List<EntitlementResource.UserIdNamePair> thisPermsetUsers = permsetIdToUsersMaps.get(thisUserPermsetId);
                if (thisPermsetUsers == null) {
                    thisPermsetUsers = new List<EntitlementResource.UserIdNamePair>();
                    permsetIdToUsersMaps.put(thisUserPermsetId, thisPermsetUsers);
                }
                thisPermsetUsers.add(new EntitlementResource.UserIdNamePair(assignment.assigneeId, assignment.assignee.name));
            }
            
            if ( ! (profiles.isEmpty() && permsets.isEmpty()) ) {
                res.responseBody = serializeEntitlements(profiles, profileIdToUsersMaps, permsets, permsetIdToUsersMaps, attributes, total, startIndex, count, host,req.headers.containsKey('X-Prettyprint'));
            }
        }
        catch (Exception ex) {
            res.statusCode = 400;
            res.responseBody = SCIMError.serializeError(res.statusCode, ex.getMessage(), req.headers.containsKey('X-Prettyprint'));
            return;
        }        
    }

    private static void methodNotSupported(){
		RestRequest req = RestContext.request;
		RestResponse res = RestContext.response;
		res.statusCode = 501;
        res.responseBody = SCIMError.serializeError(res.statusCode, 'Method not supported', req.headers.containsKey('X-Prettyprint'));
    	return;
    }     
    
    private static Blob serializeEntitlements(List<Profile> profiles, Map<Id, List<EntitlementResource.UserIdNamePair>> profileUserIds, List<PermissionSet> permsets, Map<Id, List<EntitlementResource.UserIdNamePair>> permsetUserIds, String attributes, Integer total, String startIndex, String count, String host,boolean prettyPrint) {
        JSONGenerator gen = JSON.createGenerator(prettyPrint);
        gen.writeStartObject();
            gen.writeNumberField('totalResults', total);
            Integer retrievedCount = (profiles.size() + permsets.size());
            if (count != null) {
                Integer countInt = Math.min(Integer.valueof(count), retrievedCount);
                gen.writeNumberField('itemsPerPage', countInt);
            } 
            else if (total != retrievedCount) {
                gen.writeNumberField('itemsPerPage', retrievedCount);
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
                //Write Profiles
                for (Profile profile : profiles) {
                    EntitlementResource.serializeEntitlementWithGenerator((String) profile.id, (SObject) profile, attributes, profileUserIds.get(profile.id), gen);
                }
        
                // Write perm sets
                for (PermissionSet permset : permsets ) {
                    EntitlementResource.serializeEntitlementWithGenerator((String) permset.id, (SObject) permset, attributes, permsetUserIds.get(permset.id), gen);
                }
            gen.writeEndArray();
        gen.writeEndObject();
        return Blob.valueOf(gen.getAsString());
    }
}