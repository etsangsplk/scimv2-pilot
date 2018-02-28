public class UserResourceSerializer {
    final private static String baseURL = '/services/apexrest/scim/v2/';
    final private static String enterpriseExtensionURN = 'urn:ietf:params:scim:schemas:extension:enterprise:2.0:User';
    final private static String externalSchemaURN = 'urn:salesforce:schemas:extension:2.0:external';
    final private static String otherSchemaURN = 'urn:salesforce:schemas:extension:2.0';
    final private static String communitiesSchemaURN = 'urn:salesforce:schemas:extension:2.0:communities';
    final private static String orgId = UserInfo.getOrganizationId();


    public static boolean shouldSerialize(String attributeName, String attributes) {
        return ScimResource.shouldSerialize(attributeName, attributes, UserResource.scimNameToUserSObjectNameMap);
    }       

    public static boolean shouldSerialize(String attributeName, String attributes, String excludedAttributes) {
        return ScimResource.shouldSerializeWithExcluded(attributeName, attributes, excludedAttributes, UserResource.scimNameToUserSObjectNameMap);
    }        
    

    public static Blob serializeUser(User user, String attributes, String excludedAttributes, String host, Boolean prettyPrint) {
        JSONGenerator gen = JSON.createGenerator(prettyPrint);
        List<User> users = new List<User>();
        users.add(user);
        serializeUserWithGenerator(users,attributes,excludedAttributes,host,gen);
        return Blob.valueOf(gen.getAsString());
    }
    
    public static Blob serializeUser(User user, String host, Boolean prettyPrint) {
        JSONGenerator gen = JSON.createGenerator(prettyPrint);
        List<User> users = new List<User>();
        users.add(user);
        serializeUserWithGenerator(users,null,null,host,gen);
        return Blob.valueOf(gen.getAsString());
    }
    
    public static Blob serializeUsers(List<User> users, Integer total, String startIndex, String count, String attributes, String excludedAttributes, String host, boolean prettyPrint) {
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
                serializeUserWithGenerator(users, attributes, excludedAttributes, host,gen);
            gen.writeEndArray();
        gen.writeEndObject();
        return Blob.valueOf(gen.getAsString());
    }

    public static void serializeUserWithGenerator(List<User> users, String attributes, String host, JSONGenerator gen){
        serializeUserWithGenerator(users, attributes, null, host, gen);
    }

        
    // add limit checks to prevent 'Too many SOQL query' problem
    // https://github.com/salesforceidentity/scimv2-pilot/issues/3
    public static void serializeUserWithGenerator(List<User> users, String attributes, String excludedAttributes, String host, JSONGenerator gen) {
              
        // based $ref for all scim objects
        String scimRef = host + baseURL;
        
        // bulk get the psa assignments
        Map<Id, List<PermissionSetAssignment>> psaMap = new Map<Id, List<PermissionSetAssignment>>();
        if (shouldSerialize('entitlements', attributes, excludedAttributes)) {
            // disabled following line to enable permSet assignment against inactive users
            // not sure this was entirely necessary
            // for (PermissionSetAssignment psa : [select AssigneeId, PermissionSetId, PermissionSet.Name FROM PermissionSetAssignment WHERE assignee.isActive = true AND assigneeId IN :users and permissionSet.IsOwnedByProfile = false]) {
            for (PermissionSetAssignment psa : [select AssigneeId, PermissionSetId, PermissionSet.Name FROM PermissionSetAssignment WHERE assigneeId IN :users and permissionSet.IsOwnedByProfile = false]) {
                Id assigneeId = psa.AssigneeId;
                List<PermissionSetAssignment> psas = psaMap.get(assigneeId);
                if (psas == null) {
                    psas = new List<PermissionSetAssignment>();
                    psaMap.put(assigneeId, psas);
                }
                psas.add(psa);
            }
        }

        // bulk get the group membership        
        Map<Id, List<GroupMember>> gmMap = new Map<Id, List<GroupMember>>();
        if (shouldSerialize('groups', attributes, excludedAttributes)) {
            for (GroupMember gm : [ select UserOrGroupId, Id, GroupId, Group.Name from GroupMember where UserOrGroupId IN :users]) {
                Id userOrGroupId = gm.UserOrGroupId;
                List<GroupMember> gms = gmMap.get(userOrGroupId);
                if (gms == null) {
                    gms = new List<GroupMember>();
                    gmMap.put(userOrGroupId, gms);
                }
                gms.add(gm);
            }
        }
/*        
        // bulk get the Network membership
        Map<Id, List<NetworkMember>> nmMap = new Map<Id, List<NetworkMember>>();
        if (shouldSerialize(communitiesSchemaURN, attributes, excludedAttributes)){
            for (NetworkMember nm : [select memberId, Id, networkId, network.name from NetworkMember where memberId IN :users]){
                Id memberId = nm.MemberId;
                List<NetworkMember> nms = nmMap.get(memberId);
                if (nms == null){
                    nms = new List<NetworkMember>();
                    nmMap.put(memberId, nms);
                }
                nms.add(nm);
            }
        }
*/
        
        for (User user : users) {
            Map<String, Schema.SObjectField> r = Schema.sObjectType.User.fields.getMap();
            Map<String, Object> customFieldMap = new Map<String, Object>();
            if (shouldSerialize('urn:salesforce:schemas:extension:' + UserInfo.getOrganizationId(), attributes)) {
                for (String key : r.keySet()) {
                    SObjectField thisField = r.get(key);
                    DescribeFieldResult thisDescribeResult = thisField.getDescribe();
                    if (thisDescribeResult.isCustom()) {
                        try {
                            Object value = user.get(thisDescribeResult.getName());  
                            if (value != null) {
                                customFieldMap.put(thisDescribeResult.getName(), value);
                            }
                        }
                        catch (Exception ex) {
                            // Eat it silently.
                            // Some field types do not support get (e.g. geolocation composite field)
                        }
                    }
                }    
            }
            
            boolean hasExternalUserExtensions = false;
            if (shouldSerialize('urn:salesforce:schemas:extension:external:1.0', attributes)) {
                if (user.AccountId != null) hasExternalUserExtensions = true;
                if (user.ContactId != null) hasExternalUserExtensions = true;
            }        
        
            gen.writeStartObject();
                gen.writeFieldName('schemas');
                gen.writeStartArray();
                    gen.writeString('urn:ietf:params:scim:schemas:core:2.0:User');
                    if (shouldSerialize(enterpriseExtensionURN, attributes)) {
                        gen.writeString(enterpriseExtensionURN);
                    }
                    if (!customFieldMap.isEmpty()) {
                        gen.writeString('urn:salesforce:schemas:extension:' + UserInfo.getOrganizationId());
                    }
                    if (shouldSerialize(externalSchemaURN, attributes) && hasExternalUserExtensions) {
                        gen.writeString('urn:salesforce:schemas:extension:external:1.0');
                    }
                gen.writeEndArray();
                gen.writeStringField('id', user.Id);
                if ((shouldSerialize('userName', attributes, excludedAttributes)) && (user.Username != null)) gen.writeStringField('userName', user.Username);
                if ((shouldSerialize('externalId', attributes, excludedAttributes))) {
                    String federationIdentifier = (String) user.get('FederationIdentifier');
                    if (federationIdentifier != null) {
                        gen.writeStringField('externalId', federationIdentifier);
                    }
                }
                if (shouldSerialize('name', attributes, excludedAttributes)) {
                    gen.writeFieldName('name');
                        gen.writeStartObject();
                            if ((shouldSerialize('name.formatted', attributes, excludedAttributes)) && (user.Name != null))  gen.writeStringField('formatted', user.Name);
                            if ((shouldSerialize('name.familyName', attributes, excludedAttributes)) && (user.Lastname != null)) gen.writeStringField('familyName', user.Lastname);
                            if ((shouldSerialize('name.givenName', attributes, excludedAttributes)) && (user.Firstname != null)) gen.writeStringField('givenName', user.Firstname);
                        gen.writeEndObject();
                }
                if ((shouldSerialize('displayName', attributes, excludedAttributes)) && (user.Name != null)) gen.writeStringField('displayName', user.Name);
                if ((shouldSerialize('nickName', attributes, excludedAttributes)) && (user.CommunityNickname != null)) gen.writeStringField('nickName', user.CommunityNickname);
                if (shouldSerialize('profileUrl', attributes, excludedAttributes))  gen.writeStringField('profileUrl', 'https://' + host + '/' + user.Id);
                if (shouldSerialize('emails', attributes, excludedAttributes)) {
                  gen.writeFieldName('emails');
                    gen.writeStartArray();
                        gen.writeStartObject();
                            gen.writeStringField('type', 'work');
                            gen.writeBooleanField('primary', true);
                            gen.writeStringField('value', user.Email);
                        gen.writeEndObject();
                    gen.writeEndArray();
                }
                if (shouldSerialize('addresses', attributes, excludedAttributes)) { 
                if  ((user.Street != null) || (user.City != null) || (user.State != null) || (user.postalCode != null) || (user.Country != null)) { 
                    gen.writeFieldName('addresses');
                        gen.writeStartArray();
                            gen.writeStartObject();
                                gen.writeStringField('type', 'work');
                                gen.writeBooleanField('primary', true);
                                String formatted = '';
                                if (user.Street != null) {
                                    gen.writeStringField('streetAddress', user.Street);
                                    formatted += user.Street + '\n';
                                }
                                if (user.City != null) {
                                    gen.writeStringField('locality', user.City);
                                    formatted += user.City + ', ';
                                }
                                if (user.State != null) {
                                    gen.writeStringField('region', user.State);
                                    formatted += user.State + ' ';
                                }
                                if (user.PostalCode != null) {
                                    gen.writeStringField('postalCode', user.PostalCode);
                                    formatted += user.PostalCode + ' ';
                                }
                                if (user.Country != null) {
                                    gen.writeStringField('country', user.Country);
                                    formatted += user.Country;
                                }
                                gen.writeStringField('formatted', formatted);
                            gen.writeEndObject();
                    gen.writeEndArray();
                    }
                }
                if ((shouldSerialize('phoneNumbers', attributes, excludedAttributes)) &&  ((user.Phone != null) || (user.MobilePhone != null) || (user.Fax != null))) {    
                    gen.writeFieldName('phoneNumbers');
                        gen.writeStartArray();
                            if (user.Phone != null) {
                                gen.writeStartObject();
                                    gen.writeStringField('type', 'work');
                                    if (user.Phone != null) gen.writeStringField('value', user.Phone);
                                gen.writeEndObject();
                            }
                            if (user.MobilePhone != null) {
                                gen.writeStartObject();
                                    gen.writeStringField('type', 'mobile');
                                    if (user.MobilePhone != null) gen.writeStringField('value', user.MobilePhone);
                                gen.writeEndObject();
                            }
                            if (user.Fax != null) {
                                gen.writeStartObject();
                                    gen.writeStringField('type', 'fax');
                                    if (user.Fax != null) gen.writeStringField('value', user.Fax);
                                gen.writeEndObject();
                            }
                        gen.writeEndArray();
                }
                if ((shouldSerialize('photos', attributes, excludedAttributes)) &&  ((user.FullPhotoUrl != null) || (user.SmallPhotoUrl != null))) {
                    gen.writeFieldName('photos');
                         gen.writeStartArray();
                            if (user.FullPhotoUrl != null) {
                                gen.writeStartObject();
                                    gen.writeStringField('type', 'photo');
                                    if (user.FullPhotoUrl != null) gen.writeStringField('value', user.FullPhotoUrl);
                                gen.writeEndObject();
                            }
                            if (user.SmallPhotoUrl != null) {
                                gen.writeStartObject();
                                    gen.writeStringField('type', 'thumbnail');
                                    if (user.SmallPhotoUrl != null) gen.writeStringField('value', user.SmallPhotoUrl);
                                gen.writeEndObject();
                            }
                        gen.writeEndArray();
                }    
                if ((shouldSerialize('userType', attributes, excludedAttributes)) &&  (user.UserType != null)) gen.writeStringField('userType', user.UserType);
                if ((shouldSerialize('title', attributes, excludedAttributes)) &&  (user.Title != null)) gen.writeStringField('title', user.Title);
                if ((shouldSerialize('preferredLanguage', attributes, excludedAttributes)) &&  (user.LanguageLocaleKey != null)) gen.writeStringField('preferredLanguage', user.LanguageLocaleKey);
                if ((shouldSerialize('emailEncodingKey', attributes, excludedAttributes)) &&  (user.emailEncodingKey != null)) gen.writeStringField('emailEncodingKey', user.emailEncodingKey);
                if ((shouldSerialize('locale', attributes, excludedAttributes)) &&  (user.LocaleSidKey != null)) gen.writeStringField('locale', user.LocaleSidKey);
                if ((shouldSerialize('timezone', attributes, excludedAttributes)) &&  (user.TimeZoneSidKey != null)) gen.writeStringField('timezone', user.TimeZoneSidKey);
                if ((shouldSerialize('active', attributes, excludedAttributes)) && (user.IsActive != null)) gen.writeBooleanField('active', user.IsActive);
            
            if (shouldSerialize('profileURL', attributes, excludedAttributes)) gen.writeStringField('profileURL', 'https://' + host + '/' + user.id);

            if (shouldSerialize('entitlements', attributes, excludedAttributes)) {
                gen.writeFieldName('entitlements');
                    gen.writeStartArray();
                        gen.writeStartObject();
                            gen.writeStringField('value', user.ProfileId);
                           	gen.writeStringField('$ref', '/Entitlements/' + user.ProfileId);                    
                            gen.writeStringField('display', user.Profile.Name);   
                    		gen.writeStringField('type', 'Profile');
                            gen.writeBooleanField('primary', true);
                        gen.writeEndObject();
                        List<PermissionSetAssignment> assignments = psaMap.get(user.id);
                        if (assignments != null) {
                            for (PermissionSetAssignment assignment : assignments) {
                            gen.writeStartObject();
                                gen.writeStringField('value', assignment.PermissionSetId);
	                           	gen.writeStringField('$ref', '/Entitlements/' + assignment.PermissionSetId);                    
                                gen.writeStringField('display', assignment.PermissionSet.Name);                        
	                    		gen.writeStringField('type', 'Permission Set');
                                gen.writeBooleanField('primary', false);
                            gen.writeEndObject();                    
                            }
                        }
                    gen.writeEndArray(); 
                }
            
                if (shouldSerialize('groups', attributes, excludedAttributes)) {
                    List<GroupMember> memberships = gmMap.get(user.id);
                    if (memberships != null) {
                        gen.writeFieldName('groups');
                        gen.writeStartArray();
                            if (memberships != null) {
                                for ( GroupMember membership : memberships ) {
                                    gen.writeStartObject();
                                        gen.writeStringField('value', membership.GroupId);
                                        gen.writeStringField('$ref', '/Groups/' + membership.GroupId);
                                        gen.writeStringField('display', membership.Group.Name);
                                    gen.writeEndObject();        
                                }
                            }
                        gen.writeEndArray();                         
                    }
                }        
                
                if (shouldSerialize('roles', attributes, excludedAttributes) && (user.userRoleId != null)) {
                    gen.writeFieldName('roles');
                    gen.writeStartArray();
                        gen.writeStartObject();
                            gen.writeStringField('value', user.UserRoleId);
                            gen.writeStringField('$ref', '/Roles/' + user.UserRoleId);
                            gen.writeStringField('display', user.UserRole.Name);
                        gen.writeEndObject();  
                    gen.writeEndArray(); 
                }               
            
            
                if (shouldSerialize(enterpriseExtensionURN, attributes, excludedAttributes)) {
                    gen.writeFieldName(enterpriseExtensionURN);
                    gen.writeStartObject();
                    if(shouldSerialize(enterpriseExtensionURN + ':organization', attributes, excludedAttributes)){
                        gen.writeStringField('organization', UserInfo.getOrganizationId());
                    }

                    if(shouldSerialize(enterpriseExtensionURN + ':division', attributes, excludedAttributes)){
                        if (user.Division != null) gen.writeStringField('division', user.Division);
                    }

                    if(shouldSerialize(enterpriseExtensionURN + ':employeeNumber', attributes, excludedAttributes)){
                        if (user.employeeNumber != null) gen.writeStringField('employeeNumber', user.employeeNumber);
                    }

                    if(shouldSerialize(enterpriseExtensionURN + ':department', attributes, excludedAttributes)){
                        if (user.Department != null) gen.writeStringField('department', user.Department);
                    }

                    if(shouldSerialize(enterpriseExtensionURN + ':manager', attributes, excludedAttributes)){
                        if (user.ManagerId != null) {
                            gen.writeFieldName('manager'); 
                            gen.writeStartObject();
                                gen.writeStringField('value', user.managerId);
                                gen.writeStringField('$ref', '/Users/' + user.managerId);
                                gen.writeStringField('displayName', user.manager.Name);
                            gen.writeEndObject();   
                        }
                    }                    
                    
                    if(shouldSerialize(enterpriseExtensionURN + ':delegatedApprover', attributes, excludedAttributes)){
                        // bulk get delegated approvers' names
                        // This is quite silly, runtime enforcements prevent the field to be a group, (see W-1097715, CL 2154516)
                        // but the udd says the field is a fk to user/group
                        // which also prevents us from querying .delegatedApprover.Name
                        Set<Id> userApproverId = new Set<Id>();
                        Map<Id, User> userApproverMap = new Map<Id,User>();
                        if (shouldSerialize(enterpriseExtensionURN, attributes, excludedAttributes)) {
                            for (User thisUser : users) {
                                String delegatedApproverId = thisUser.delegatedApproverId;
                                if (delegatedApproverId != null && delegatedApproverId.startsWith('005')) {
                                    userApproverId.add(thisUser.delegatedApproverId);
                                }
                            }
                            userApproverMap = new Map<Id,User>([select Id, Name from User where Id in :userApproverId]);
                        }
                        
                        if (user.DelegatedApproverId != null) {
                                gen.writeFieldName('delegatedApprover'); 
                                gen.writeStartObject();
                                    gen.writeStringField('delegatedApproverId', user.delegatedApproverId);
                                    gen.writeStringField('$ref', '/Users/' + user.delegatedApproverId);
                                String delegatedApproverId = user.delegatedApproverId;
                                    if (delegatedApproverId != null && delegatedApproverId.startsWith('005')) {
                                        gen.writeStringField('displayName', userApproverMap.get(user.delegatedApproverId).Name);
                                    }
                                gen.writeEndObject();   
                            }                        
                    }

                        
                    gen.writeEndObject();    
                }
                
                if (shouldSerialize(externalSchemaURN, attributes, excludedAttributes) && hasExternalUserExtensions) {
                    gen.writeFieldName('urn:salesforce:schemas:extension:external:1.0');
                    gen.writeStartObject();
                        if(shouldSerialize(externalSchemaURN + ':accountId', attributes, excludedAttributes)){
                            if (user.AccountId != null) gen.writeStringField('accountId', user.AccountId);
                        }
                        if(shouldSerialize(externalSchemaURN + ':contactId', attributes, excludedAttributes)){
                            if (user.ContactId != null) gen.writeStringField('contactId', user.ContactId);
                        }
                    gen.writeEndObject();    
                }                    

/*                
            if(shouldSerialize(communitiesSchemaURN, attributes, excludedAttributes)){
                    List<NetworkMember> memberships = nmMap.get(user.id);
                if (memberships != null) {
                    gen.writeFieldName(communitiesSchemaURN);
                    gen.writeStartArray();
                        if (memberships != null) {
                            for ( NetworkMember membership : memberships ) {
                                gen.writeStartObject();
                                    gen.writeStringField('value', membership.NetworkId);
                                    gen.writeStringField('display', membership.Network.Name);
                                gen.writeEndObject();        
                            }
                        }
                    gen.writeEndArray();                     
                }
            }
*/
                
                if (shouldSerialize('urn:salesforce:schemas:extension:' + UserInfo.getOrganizationId(), attributes, excludedAttributes)) {
                    if (!customFieldMap.isEmpty()) {    
                        gen.writeFieldName('urn:salesforce:schemas:extension:' + UserInfo.getOrganizationId());
                        gen.writeStartObject();
                            for (String key : customFieldMap.keySet()) {
                                Object value = customFieldMap.get(key);
                                if (value != null) {
                                    gen.writeObjectfield(key, value);
                                }
                            }                
                        gen.writeEndObject();    
                    }
                }            


                if (shouldSerialize(otherSchemaURN, attributes, excludedAttributes)) {
                    gen.writeFieldName('urn:salesforce:schemas:extension:1.0');
                    gen.writeStartObject();
                        if(shouldSerialize(otherSchemaURN + ':alias', attributes, excludedAttributes)){
                            if (user.alias != null) gen.writeStringField('alias', user.alias);
                        }
                    gen.writeEndObject();    
                }                    
            
            // meta always serializes
                if (shouldSerialize('meta', attributes, excludedAttributes)) {
                    gen.writeFieldName('meta');
                        gen.writeStartObject();
                            String createdFormated = user.CreatedDate.format('yyyy-MM-dd');
                            createdFormated += 'T';
                            createdFormated += user.CreatedDate.formatGmt('hh:mm:ss');
                            gen.writeStringField('created', createdFormated + 'Z');
                            
                            String lastmodFormated = user.LastModifiedDate.format('yyyy-MM-dd');
                            lastmodFormated += 'T';
                            lastmodFormated += user.LastModifiedDate.formatGmt('hh:mm:ss');
                            gen.writeStringField('lastModified', lastmodFormated + 'Z');
                            
                            String base = URL.getSalesforceBaseUrl().toExternalForm();
                            
                            String path = '/services/apexrest/scim/v2/Users/' + user.id;
                            gen.writeStringField('location', base + path);
                gen.writeStringField('resourceType', 'User');                    
                            
                            Blob digest = Crypto.generateDigest('SHA-1',  Blob.valueOf(user.id + lastmodFormated));
                            gen.writeStringField('version', EncodingUtil.convertToHex(digest));
                    gen.writeEndObject();
                }
            gen.writeEndObject();
        }
    }    
    
}