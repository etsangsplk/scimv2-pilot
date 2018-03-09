@RestResource(urlMapping='/scim/v2/Users/*')
global with sharing class UserResource extends ScimResource {
    // TODO Support Frozen
    final public static Map<String, ScimSoqlAttributeProcessor> scimNameToUserSObjectNameMap;
    final public static Map<String, Schema.SOAPType> customFieldToSoapTypeMap;
    
    final private static String enterpriseExtensionURN = 'urn:ietf:params:scim:schemas:extension:enterprise:2.0:User';
    final private static String externalSchemaURN = 'urn:salesforce:schemas:extension:2.0:external';
    final private static String otherSchemaURN = 'urn:salesforce:schemas:extension:2.0';
    final private static String communitiesSchemaURN = 'urn:salesforce:schemas:extension:2.0:communities';
    final private static String orgId = UserInfo.getOrganizationId();
    
    final private static String baseURL = '/services/apexrest/scim/v2/';
    
    final public static Set<String> portalUserTypes = new Set<String>();
    
    final public static Set<String> queriableUserTypes = new Set<String>{'Standard', 'PowerPartner','PowerCustomerSuccess','CustomerSuccess','SelfService','CspLitePortal', 'CsnOnly'};
    final public static Set<String> unsupportedAttrs = new Set<String>{'middlename', 'honorificPrefix', 'honorificSuffix', 'costCenter'};
    final public static Set<String> readOnlyAttrs = new Set<String>{'displayName', 'profileURL', 'photos', 'userType', 'id', 'formatted', 'organization'};
    final public static Set<String> notNillableAttrs = new Set<String>{'alias','password', 'emails'};
    
    static {
        portalUserTypes.add('cspliteportal');
        portalUserTypes.add('powercustomersuccess');
        portalUserTypes.add('customersuccess');
        portalUserTypes.add('powerpartner');
        portalUserTypes.add('partner');
    
        scimNameToUserSObjectNameMap = new Map<String, ScimSoqlAttributeProcessor>();
        scimNameToUserSObjectNameMap.put('id', new StandardAttributeProcessor('Id', Schema.SOAPType.String, false));
        scimNameToUserSObjectNameMap.put('userName', new StandardAttributeProcessor('Username', Schema.SOAPType.String, false));
        
        // Org may not have federation identifier. Only add it if it shows up in describe
        if (isFieldAccessible('FederationIdentifier')) {        
            scimNameToUserSObjectNameMap.put('externalId', new StandardAttributeProcessor('FederationIdentifier', Schema.SOAPType.String, false));
        }
        
        scimNameToUserSObjectNameMap.put('name', new StandardAttributeProcessor('Name,Lastname,Firstname', Schema.SOAPType.String, true));
        scimNameToUserSObjectNameMap.put('name.formatted', new StandardAttributeProcessor('Name', Schema.SOAPType.String, false));
        scimNameToUserSObjectNameMap.put('name.familyName', new StandardAttributeProcessor('Lastname', Schema.SOAPType.String, false));
        scimNameToUserSObjectNameMap.put('name.givenName', new StandardAttributeProcessor('Firstname', Schema.SOAPType.String, false));
        scimNameToUserSObjectNameMap.put('displayName', new StandardAttributeProcessor('Name', Schema.SOAPType.String, false));
        scimNameToUserSObjectNameMap.put('nickName', new StandardAttributeProcessor('CommunityNickname', Schema.SOAPType.String, false));
        scimNameToUserSObjectNameMap.put('emails', new StandardAttributeProcessor('Email', Schema.SOAPType.String, false));     
        scimNameToUserSObjectNameMap.put('addresses', new StandardAttributeProcessor('Street,City,State,PostalCode,Country', Schema.SOAPType.String, true));
        scimNameToUserSObjectNameMap.put('addresses.streetAddress', new StandardAttributeProcessor('Street', Schema.SOAPType.String, false));
        scimNameToUserSObjectNameMap.put('addresses.locality', new StandardAttributeProcessor('City', Schema.SOAPType.String, false));
        scimNameToUserSObjectNameMap.put('addresses.region', new StandardAttributeProcessor('State', Schema.SOAPType.String, false));
        scimNameToUserSObjectNameMap.put('addresses.postalCode', new StandardAttributeProcessor('PostalCode', Schema.SOAPType.String, false));
        scimNameToUserSObjectNameMap.put('addresses.country', new StandardAttributeProcessor('Country', Schema.SOAPType.String, false));
        scimNameToUserSObjectNameMap.put('phoneNumbers', new PhoneNumbersAttributeProcessor());
        
        scimNameToUserSObjectNameMap.put('userType', new StandardAttributeProcessor('UserType', Schema.SOAPType.String, false));
        scimNameToUserSObjectNameMap.put('title', new StandardAttributeProcessor('Title', Schema.SOAPType.String, false));
        scimNameToUserSObjectNameMap.put('preferredLanguage', new StandardAttributeProcessor('LanguageLocaleKey', Schema.SOAPType.String, false));
        scimNameToUserSObjectNameMap.put('emailEncodingKey', new StandardAttributeProcessor('EmailEncodingKey', Schema.SOAPType.String, false));  
        scimNameToUserSObjectNameMap.put('locale', new StandardAttributeProcessor('LocaleSidKey', Schema.SOAPType.String, false));      
        scimNameToUserSObjectNameMap.put('timezone',new StandardAttributeProcessor('TimeZoneSidKey', Schema.SOAPType.String, false));
        scimNameToUserSObjectNameMap.put('active', new StandardAttributeProcessor('IsActive', Schema.SOAPType.Boolean, false));
        scimNameToUserSObjectNameMap.put('entitlements', new EntitlementsAttributeProcessor());
        scimNameToUserSObjectNameMap.put('groups', new GroupsAttributeProcessor());
        scimNameToUserSObjectNameMap.put('roles', new RolesAttributeProcessor());
        
        // profileUrl - should this be URL to user object
        scimNameToUserSObjectNameMap.put('profileURL', new StandardAttributeProcessor('profileURL', Schema.SOAPType.String, false));
        
        // enterprise extensions
        scimNameToUserSObjectNameMap.put(enterpriseExtensionURN, new StandardAttributeProcessor('organization,employeeNumber,Division,Department,ManagerId,Manager.Name', null, true));
        scimNameToUserSObjectNameMap.put(enterpriseExtensionURN, new StandardAttributeProcessor('employeeNumber,Division,Department,ManagerId,Manager.Name', null, true));
        scimNameToUserSObjectNameMap.put(enterpriseExtensionURN + ':organization', new StandardAttributeProcessor('organization', Schema.SOAPType.String, false));
        scimNameToUserSObjectNameMap.put(enterpriseExtensionURN + ':employeeNumber', new StandardAttributeProcessor('employeeNumber', Schema.SOAPType.String, false));
        scimNameToUserSObjectNameMap.put(enterpriseExtensionURN + ':division', new StandardAttributeProcessor('Division', Schema.SOAPType.String, false));
        scimNameToUserSObjectNameMap.put(enterpriseExtensionURN + ':department', new StandardAttributeProcessor('Department', Schema.SOAPType.String, false));
        
        scimNameToUserSObjectNameMap.put(enterpriseExtensionURN + ':delegatedApprover', new StandardAttributeProcessor('DelegatedApproverId', Schema.SOAPType.String, true));
        scimNameToUserSObjectNameMap.put(enterpriseExtensionURN + ':delegatedApprover.delegatedApproverId', new StandardAttributeProcessor('DelegatedApproverId', Schema.SOAPType.String, false));
        
        scimNameToUserSObjectNameMap.put(enterpriseExtensionURN + ':manager', new StandardAttributeProcessor('ManagerId,Manager.Name', Schema.SOAPType.String, true));
        scimNameToUserSObjectNameMap.put(enterpriseExtensionURN + ':manager.value', new StandardAttributeProcessor('ManagerId', Schema.SOAPType.String, false));
        scimNameToUserSObjectNameMap.put(enterpriseExtensionURN + ':manager.displayName', new StandardAttributeProcessor('Manager.Name', Schema.SOAPType.String, false));
        
        // Org may not have Chatter
        if (isFieldAccessible('FullPhotoUrl') && isFieldAccessible('SmallPhotoUrl')) {        
            scimNameToUserSObjectNameMap.put('photos', new PhotosAttributeProcessor());
        }
        scimNameToUserSObjectNameMap.put('meta', new StandardAttributeProcessor('CreatedDate,LastModifiedDate', Schema.SOAPType.String, true));
        scimNameToUserSObjectNameMap.put('meta.created', new StandardAttributeProcessor('CreatedDate', Schema.SOAPType.DateTime, false));
        scimNameToUserSObjectNameMap.put('meta.lastModified', new StandardAttributeProcessor('LastModifiedDate', Schema.SOAPType.DateTime, false));
        
        customFieldToSoapTypeMap = new Map<String, Schema.SOAPType>();
        // Also the custom fields.
        Map<String, Schema.SObjectField> r = Schema.sObjectType.User.fields.getMap();
        String customFields = '';
        for (String key : r.keySet()) {
            SObjectField thisField = r.get(key);
            DescribeFieldResult thisDescribeResult = thisField.getDescribe();
            if (thisDescribeResult.isCustom()) {
                String customField = thisDescribeResult.getName();
                customFields = customFields + customField + ',';
                customFieldToSoapTypeMap.put(thisDescribeResult.getName(), thisDescribeResult.getSOAPType());
                scimNameToUserSObjectNameMap.put('urn:salesforce:schemas:extension:' + orgId + ':' + customField, new StandardAttributeProcessor(customField, thisDescribeResult.getSOAPType(), false));
            }
        }

        if (customFields.length() > 0) {
            customFields = customFields.substring(0, (customFields.length() - 1));     
            scimNameToUserSObjectNameMap.put('urn:salesforce:schemas:extension:' + orgId, new StandardAttributeProcessor(customFields, null, true));
        }
        
        // External User Extensions
        // TODO - parameterize type string
        scimNameToUserSObjectNameMap.put(externalSchemaURN, new StandardAttributeProcessor('', SOAPType.String, true));
        scimNameToUserSObjectNameMap.put(externalSchemaURN + ':accountId', new StandardAttributeProcessor('AccountId', SOAPType.String, false));
        scimNameToUserSObjectNameMap.put(externalSchemaURN + ':contactId', new StandardAttributeProcessor('ContactId', SOAPType.String, false));
        
        // Communities User Extension
        // ReadOnly
        scimNameToUserSObjectNameMap.put(communitiesSchemaURN, new StandardAttributeProcessor('', SOAPType.String, true));
        scimNameToUserSObjectNameMap.put(communitiesSchemaURN + ':networkId', new NetworkAttributeProcessor());
        scimNameToUserSObjectNameMap.put(communitiesSchemaURN + ':networkName', new NetworkAttributeProcessor());
        
        // Alias
        scimNameToUserSObjectNameMap.put(otherSchemaURN, new StandardAttributeProcessor('', SOAPType.String, true));        
        scimNameToUserSObjectNameMap.put(otherSchemaURN + ':alias', new StandardAttributeProcessor('alias', SOAPType.String, false));        


    }
    
    private static boolean isFieldAccessible(String fieldName) {
        Schema.SObjectField field = Schema.sObjectType.User.fields.getMap().get(fieldName);
        if (field != null) {        
            Schema.DescribeFieldResult f = field.getDescribe();
            return (f != null && f.isAccessible());
        }
        return false;
    }
    
    public List<String> attributes {get;set;}
    public List<String> schemas {get;set;}
    public String id {get;set;}
    public String externalId {get;set;}
    public String userName {get;set;}
    public Map<String,String> name {get;set;}
    public String displayName {get;set;}
    public String nickName {get;set;}
    public String profileUrl {get;set;}
    public List<Map<String,String>> emails {get;set;}
    public List<Map<String,String>> addresses {get;set;}
    public List<Map<String,String>> phoneNumbers {get;set;}
    public List<Map<String,String>> photos {get;set;}
    public String userType {get;set;}
    public String title {get;set;}
    public String preferredLanguage {get;set;}
    public String emailEncodingKey {get;set;}
    public String locale {get;set;}
    public String timezone {get;set;}
    public Boolean active {get;set;}
    public List<Map<String,String>> groups {get;set;}
    public List<Map<String,String>> entitlements {get;set;}
    public List<Map<String,String>> roles {get;set;}
    public Map<String,String> meta {get;set;}
    public String employeeNumber {get;set;}
    public String costCenter {get;set;}
    public String organization {get;set;}
    public String division {get;set;}
    public String department {get;set;}
    public Map<String,String> manager {get;set;}
    public Map<String,String> delegatedApprover {get;set;}
    public String password {get;set;}
    public Map<String,Object> customFieldValues {get;set;}
    public Map<String,Object> externalUserProperties {get;set;}
    public Map<String,Object> otherUserProperties {get;set;}
    public List<Map<String, String>> network {get;set;}

    public List<Map<String, String>> operations {get;set;}
    

    
    /**
     * Instantiate a UserResource with user provided blob content
     */
    public UserResource(Blob body) {
        System.JSONParser parser = System.JSON.createParser(body.toString());
        
        while (parser.nextToken() != null) {
            if (isNextTokenField(parser,'schemas')) this.schemas = parseStringArray('schemas', parser);                            
            if (isNextTokenField(parser,'id')) this.id = parseString('id',parser);
            if (isNextTokenField(parser,'externalId')) this.externalId = parseString('externalId', parser);
            if (isNextTokenField(parser,'userName')) this.userName = parseString('userName', parser);
            if (isNextTokenField(parser,'name')) this.name = parseSimpleObject('name', parser);
            if (isNextTokenField(parser,'displayName')) this.displayName = parseString('displayName', parser);
            if (isNextTokenField(parser,'nickName')) this.nickName = parseString('nickName', parser);
            if (isNextTokenField(parser,'profileUrl')) this.profileUrl = parseString('profileUrl', parser);
            if (isNextTokenField(parser,'emails')) this.emails =  parseOptionalObjectArray('emails', parser);
            if (isNextTokenField(parser,'addresses')) this.addresses = parseObjectArray('addresses', parser);
            if (isNextTokenField(parser,'phoneNumbers')) this.phoneNumbers =  parseObjectArray('phoneNumbers', parser);
            if (isNextTokenField(parser,'photos')) this.photos =  parseObjectArray('photos', parser);
            if (isNextTokenField(parser,'userType')) this.userType = parseString('userType', parser);
            if (isNextTokenField(parser,'title')) this.title = parseString('title', parser);
            if (isNextTokenField(parser,'preferredLanguage')) this.preferredLanguage = parseString('preferredLanguage', parser);
			if (isNextTokenField(parser,'emailEncodingKey')) this.emailEncodingKey = parseString('emailEncodingKey', parser);
            if (isNextTokenField(parser,'locale')) this.locale = parseString('locale', parser);
            if (isNextTokenField(parser,'timezone')) this.timezone = parseString('timezone', parser);
            if (isNextTokenField(parser,'active')) this.active = parseBoolean('active', parser);
            if (isNextTokenField(parser,'employeeNumber')) this.employeeNumber = parseString('employeeNumber', parser);
            if (isNextTokenField(parser,'costCenter')) this.costCenter = parseString('costCenter', parser);
            if (isNextTokenField(parser,'organization')) this.organization = parseString('organization', parser);
            if (isNextTokenField(parser,'division')) this.division = parseString('division', parser);
            if (isNextTokenField(parser,'department')) this.department = parseString('department', parser);
            if (isNextTokenField(parser,'manager')) this.manager = parseSimpleObject('manager', parser);
            if (isNextTokenField(parser,'delegatedApprover')) this.delegatedApprover = parseSimpleObject('delegatedApprover', parser);
            if (isNextTokenField(parser,'entitlements')) this.entitlements =  parseObjectArray('entitlements', parser);
            if (isNextTokenField(parser,'groups')) this.groups =  parseObjectArray('groups', parser);
            if (isNextTokenField(parser,'roles')) this.roles =  parseObjectArray('roles', parser);
            if (isNextTokenField(parser,'password')) this.password = parseString('password', parser);
            if (isNextTokenField(parser,'urn:salesforce:schemas:extension:' + orgId)) this.customFieldValues = parseSimpleObject('urn:salesforce:schemas:extension:' + orgId, parser);
            if (isNextTokenField(parser,'urn:salesforce:schemas:extension:2.0:external')) this.externalUserProperties = parseSimpleObject('urn:salesforce:schemas:extension:2.0:external', parser);
            if (isNextTokenField(parser,'urn:salesforce:schemas:extension:2.0')) this.otherUserProperties = parseSimpleObject('urn:salesforce:schemas:extension:2.0', parser);
            
            if (isNextTokenField(parser, 'meta')) {    
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
    }
    
    @HttpPost
    global static void doPost() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String method = req.headers.get('X-HTTP-Method-Override');
        if ( method == null ) method = 'POST';
        if ( method.equals('DELETE') ) {
            doDelete(req,res); 
        }else {
            User user = new User();
            doCreateOrUpdate(req, res, user, method); 
        }
    }     
    public static void doCreateOrUpdate(RestRequest req, RestResponse res, User u, String operation) {
        // TODO add support for Person Account

        Boolean isCreate = ( operation == 'POST' );
        Boolean isUpdate =  ( operation == 'PUT' );
        res.addHeader('Content-Type', 'application/json');    
        res.statusCode = 201;
        String error = '';
        UserResource user;
        Savepoint sp = Database.setSavepoint();
        try {
            user = new UserResource(req.requestBody);
        } catch (ScimException scex) {
            res.statusCode = scex.getStatusCode();
            error = scex.getMessage();
        } catch (Exception e) {
            res.statusCode = 400;
            error = e.getMessage();
        }
        
        // In order to be able to create users with PermSets and Groups I moved this declaration up here
        // I bet there is a better way to handle the problem
        List<PermissionSetAssignment> newPsas = new List<PermissionSetAssignment>();        
        List<GroupMember> newGMs = new List<GroupMember>();

        if (res.statusCode == 201) {
            if ( isUpdate ) {
                if ((user.id != null) && ( user.id != u.id)) {
                    error += 'INVALID:id_attribute_is_readonly;';  
                    res.statusCode = 400;
                }
            }
    
            if (user.externalId != null) {
                if (scimNameToUserSObjectNameMap.containsKey('externalId')) {
                    u.put('FederationIdentifier', user.externalId);
                }
                else {
                    error += 'INVALID:externalId_not_available_in_your_organization;';  
                    res.statusCode = 400;
                }
            }
    
            if ( ( user.userName == null) && (  ( isCreate ) || ( isUpdate ) )  ){
                error += 'REQUIRED_FIELD_MISSING:userName;';  
                res.statusCode = 400;
            } else {
                if ( user.userName != null ) {
                    u.userName = user.userName;
                }
            }
            
            if ( user.name != null) {                
                if (user.name.containsKey('familyName')) {
                    u.lastName = user.name.get('familyName');
                } else {
                    if ( ( isCreate ) || ( isUpdate ) ) {
                        error += 'REQUIRED_FIELD_MISSING:name.familyName;';  
                        res.statusCode = 400;  
                    } 
                }
                if (user.name.containsKey('givenName')) {
                    u.firstName = user.name.get('givenName');
                }
                if (user.name.containsKey('middleName')) {
                    error += 'UNSUPPORTED_FIELD:name.middleName;';  
                    res.statusCode = 400;   
                }
                if (user.name.containsKey('honorificPrefix')) {
                    error += 'UNSUPPORTED_FIELD:name.honorificPrefix;';  
                    res.statusCode = 400;   
                }
                if (user.name.containsKey('honorificSuffix')) {
                    error += 'UNSUPPORTED_FIELD:name.honorificSuffix;';  
                    res.statusCode = 400;   
                }
            }

                            
            if (user.name != null && user.name.containsKey('familyName')) {
                u.lastName = user.name.get('familyName');
            } else {
                if ( ( isCreate ) || ( isUpdate ) ) {
                    error += 'REQUIRED_FIELD_MISSING:name.familyName;';  
                    res.statusCode = 400;  
                } 
            }
            
            // nickname 
            if ( user.nickName != null) {
                u.communityNickname = user.nickName;
            } else {
                if ( isCreate ) {
                    u.communityNickname = user.userName;   
                }
            }

            // alias
            if ((user.otherUserProperties) != null && (user.otherUserProperties.containsKey('alias'))){
                String tempAlias = (String)user.otherUserProperties.get('alias');
                if ( tempAlias.length() > 8){
                    //truncate alias to 8 characters silently
                    u.alias = tempAlias.substring(0,8);                    
                } else {
                    u.Alias = (String)user.otherUserProperties.get('alias');                    
                }

            } else {
                if (isCreate){
                    String timeString = Datetime.now().getTime().format().replace(',','');
                    u.alias = timeString.substring(timeString.length() - 8, timeString.length());                    
                }
            }

            //email
            if ((user.emails == null) || (user.emails.isEmpty())) {
                if ( ( isCreate ) || ( isUpdate ) ) {
                    error += 'REQUIRED_FIELD_MISSING:email;';  
                    res.statusCode = 400;
                }
            } else if ( user.emails.size() != 1 ) {
                error += 'INVALID:only_a_single_email_is_allowed;';  
                res.statusCode = 400;
            } else {
                Map<String,String> email = user.emails.get(0);
                if ( email.containsKey('value') ) {
                    u.email = email.get('value');
                } else {
                    if ( ( isCreate ) || ( isUpdate ) ) {
                        error += 'REQUIRED_FIELD_MISSING:email;';  
                        res.statusCode = 400;            
                    }
                }
            }
            
            if ( user.addresses != null ) {
                if ( user.addresses.size() > 1 ) {
                    error += 'INVALID:only_a_single_address_is_allowed;';  
                    res.statusCode = 400;
                } else if (user.addresses.size() == 1 ) {
                    Map<String,String> address = user.addresses.get(0);
                    if (address.containsKey('streetAddress')) u.street = address.get('streetAddress');
                    if (address.containsKey('locality')) u.city = address.get('locality');
                    if (address.containsKey('region')) u.state = address.get('region');
                    if (address.containsKey('postalCode')) u.postalCode = address.get('postalCode');
                    if (address.containsKey('country')) u.country = address.get('country');
                }
            }
            
            if ( user.phoneNumbers != null ) {
                if ( user.phoneNumbers.size() > 1) {
                    error += 'INVALID:only_a_single_phone_is_allowed';
                    res.statusCode = 400;
                } else if ( user.phoneNumbers.size() == 1){
                    for (Map<String,String>phone : user.phoneNumbers) {
                        String val = null;
                        if (phone.containsKey('value')) val = phone.get('value');
                        if ( val != null) {
                            if ((phone.containsKey('type')) && (phone.get('type') == 'work')) {
                                u.phone = val;
                            } else if ((phone.containsKey('type')) && (phone.get('type') == 'mobile')) {
                                u.mobilePhone = val;
                            } else if ((phone.containsKey('type')) && (phone.get('type') == 'fax')) {
                                u.fax = val;
                            }
                        }
                    }
                }
            }
    
            if ( user.title != null) {
                u.title = user.title;
            }
            
            if ( user.preferredLanguage != null) {
                u.languagelocalekey = user.preferredLanguage;
            } else if (isCreate) {
                u.languagelocalekey = 'en_US';
            }
            
            if ( user.emailEncodingKey != null) {
                u.emailEncodingKey = user.emailEncodingKey;
            } else if (isCreate) {
                u.languagelocalekey = 'UTF-8';
            }
                        
            if ( user.locale != null) {
                u.localesidkey = user.locale;
            } else if (isCreate){
                u.localesidkey = 'en_US';
            }
    
            if ( user.timezone != null) {
                u.timezonesidkey = user.timezone;
            } else if (isCreate){
                u.timezonesidkey = 'America/Los_Angeles';
            }        
            
            if ( (user.active != null) && (!user.active) ) u.isActive = false;
            if ( (user.active != null) && (user.active) ) u.isActive = true;
            
            if (user.roles != null) { 
                if ((user.roles.isEmpty()) || (user.roles.size() != 1) ) {
                    error += 'INVALID:user_must_have_only_one_role;';  
                    res.statusCode = 400;
                } else {
                    //TODO - improve this
                    u.put('userRoleId', user.roles.get(0).get('value'));
                }
            }        

            // Profiles and Permission Sets
            // PUT, DELETE
            if ( user.entitlements != null && !user.entitlements.isEmpty() && !isCreate) {                
                List<PermissionSetAssignment> existingPsas = [Select Id, PermissionSetId from PermissionSetAssignment where AssigneeId = :u.Id AND PermissionSet.IsOwnedByProfile = False];
                if (isUpdate) {
                    Database.delete(existingPsas, true);
                    u.put('profileid', null);
                }
                
                Map<Id, PermissionSetAssignment> existingPermsetIdToPsas = new Map<Id, PermissionSetAssignment>();
                for (PermissionSetAssignment psa : existingPsas) {
                    existingPermsetIdToPsas.put(psa.permissionsetid, psa);
                }
                Set<Id> existingPermsetIds = existingPermsetIdToPsas.keySet();
                List<PermissionSetAssignment> toDeletePsas = new List<PermissionSetAssignment>();
                
                for (Map<String,String> entitlmentIdMap : user.entitlements) {
                    String entitlementId = (String) entitlmentIdMap.get('value');
                    if (entitlementId != null) {
                        if (entitlementId.startsWith('00e')) {
                            u.put('profileid', entitlementId);
                            // don't bother delete, not multi valued.
                        }
                        else if (entitlementId.startsWith('0PS')) {
                            if (!existingPermsetIds.contains(entitlementId)) {
                                PermissionSetAssignment thisPsa = new PermissionSetAssignment();
                                thisPsa.AssigneeId = u.Id;
                                thisPsa.PermissionSetId = entitlementId;
                                newPsas.add(thisPsa);
                                // ignore if not there and is delete, per spec "MAY return a HTTP 400 error." which means I am free to not bother.
                            }
                        }
                    }
                }
                Database.DeleteResult[] deleteDRs = Database.delete(toDeletePsas, false);
                for (Database.DeleteResult thisDR : deleteDRs) {
                	if (!thisDR.isSuccess()) {
                		for (Database.Error thisError : thisDR.getErrors()) {
                			error += 'INVALID:' + thisError.getMessage() + ';';
                		}
                		res.statusCode = 400;
                	}
                }
                
                Database.SaveResult[] newSRs = Database.insert(newPsas, false);
                for (Database.SaveResult thisSR : newSRs) {
                	if (!thisSR.isSuccess()) {
                		for (Database.Error thisError : thisSR.getErrors()) {
                			error += 'INVALID:' + thisError.getMessage() + ';';
                		}
                		res.statusCode = 400;
                	}
                }                
            }
            
            // POST
            // Cannot do PermSets until the user is created
            // This will do Profile
            // PermSet processing is defered and package up the PermSets for insertion after the user is created
            if ( user.entitlements != null && !user.entitlements.isEmpty() && isCreate) {
                for (Map<String,String> entitlmentIdMap : user.entitlements) {
                    String entitlementId = (String) entitlmentIdMap.get('value');
                    if (entitlementId != null) {
                        if (entitlementId.startsWith('00e')) {
                            u.put('profileid', entitlementId);
                        }
                        else if (entitlementId.startsWith('0PS')) {
                            PermissionSetAssignment thisPsa = new PermissionSetAssignment();
                            thisPsa.AssigneeId = null; // will provide new user.id after insert
                            thisPsa.PermissionSetId = entitlementId;
                            newPsas.add(thisPsa);                            
                        }
                    }
            	}
            }
              
            
            if ( ( isCreate  ||  isUpdate ) && u.get('profileid') == null ) {
                error += 'REQUIRED_FIELD_MISSING:user_must_have_one_entitlement_which_must_be_a_profileid;';  
                res.statusCode = 400;
            }            

            //Groups
           // PUT
           // Like PermSets Groups have to be added after user exists
            if ( user.groups != null && !user.groups.isEmpty() && !isCreate){             
                List<GroupMember> existingGroups = [select Id, GroupId from GroupMember where UserOrGroupId = :u.id];
                List<GroupMember> toDeleteGMs = new List<GroupMember>();
                Map<Id, GroupMember> existingIdToGroups = new Map<Id, GroupMember>();
                for (GroupMember gm : existingGroups) {
                    existingIdToGroups.put(gm.GroupId, gm);
                }
            
                Set<Id> existingGroupIds = existingIdToGroups.keySet();
                List<GroupMember> toDeleteGroups = new List<GroupMember>();
                
                for (Map<String,String> groupIdMap : user.groups) {
                    String groupId = (String) groupIdMap.get('value');
                    if (groupId != null){
                        if (!existingGroupIds.contains(groupId)){
                            GroupMember thisGm = new GroupMember();
                            thisGm.UserOrGroupId = u.id;
                            thisGm.GroupId = groupId;
                            newGMs.add(thisGm);
                        }
                    }
                }
                
                Database.DeleteResult[] deleteDRs = Database.delete(toDeleteGms, false);
                for (Database.DeleteResult thisDR : deleteDRs) {
                	if (!thisDR.isSuccess()) {
                		for (Database.Error thisError : thisDR.getErrors()) {
                			error += 'INVALID:' + thisError.getMessage() + ';';
                		}
                		res.statusCode = 400;
                	}
                }
                
                Database.SaveResult[] newSRs = Database.insert(newGMs, false);
                for (Database.SaveResult thisSR : newSRs) {
                	if (!thisSR.isSuccess()) {
                		for (Database.Error thisError : thisSR.getErrors()) {
                			error += 'INVALID:' + thisError.getMessage() + ';';
                		}
                		res.statusCode = 400;
                	}
                }                
            }
            
            // POST
            // Like PermSets, add Groups to the list and insert them after user create
            if ( user.groups != null && !user.groups.isEmpty() && isCreate){
                for (Map<String,String> groupIdMap : user.groups) {
                    String groupId = (String) groupIdMap.get('value');
                        GroupMember thisGm = new GroupMember();
                        thisGm.UserOrGroupId = null; //will assign after user crate
                        thisGm.GroupId = groupId;
                        newGMs.add(thisGm);
                }
            }
            
            if ( user.employeeNumber != null) {
                u.employeeNumber = user.employeeNumber;
            }
            
            if ( user.costCenter != null ) {
                error += 'UNSUPPORTED_FIELD:costCenter;';  
                res.statusCode = 400;
            } 
            
            
            if ( user.division != null) {
                u.division = user.division;
            }
            
            if ( user.department != null) {
                u.department = user.department;
            }
    
            if ( user.manager != null) {
                if (user.manager.containsKey('value')) u.managerId = user.manager.get('value');
            }
            
            if ( user.delegatedApprover != null) {
                if (user.delegatedApprover.containsKey('delegatedApproverId')) u.delegatedApproverId = user.delegatedApprover.get('delegatedApproverId');
            }            
            
            if (user.customFieldValues != null) {
                for (String customFieldName : user.customFieldValues.keySet()) {
                    Object customFieldValue = user.customFieldValues.get(customFieldName);
                    
                    // NOTE: customFieldValue is always a string, because of a limitation of 
                    // the parseSimpleObject de-serializing always with getText.
                    // making it dynamic there makes the method not simple in principle, so
                    // for simplicity, we just coerce it back to the right type here based on
                    // the field's type
                    Schema.SOAPType type = customFieldToSoapTypeMap.get(customFieldName);
                    if (type == Schema.SOAPType.Boolean) {
                        u.put(customFieldName, Boolean.valueOf(customFieldValue));
                    }
                    else if (type == Schema.SOAPType.Date) {
                        u.put(customFieldName, Date.valueOf(customFieldValue));
                    }
                    else if (type == Schema.SOAPType.DateTime) {
                        u.put(customFieldName, Datetime.valueOf(customFieldValue));
                    }
                    else if (type == Schema.SOAPType.Double) {
                        u.put(customFieldName, Double.valueOf(customFieldValue));
                    }
                    else if (type == Schema.SOAPType.ID) {
                        u.put(customFieldName, String.valueOf(customFieldValue));
                    }
                    else if (type == Schema.SOAPType.Integer) {
                        u.put(customFieldName, Integer.valueOf(customFieldValue));
                    }
                    else if (type == Schema.SOAPType.String) {
                        u.put(customFieldName, String.valueOf(customFieldValue));
                    }
                    else if (type == Schema.SOAPType.Time) {
                        u.put(customFieldName, Datetime.valueOf(customFieldValue));
                    }     
                    else if (type == Schema.SOAPType.base64binary) {
                        u.put(customFieldName, EncodingUtil.base64Decode((String) customFieldValue));
                    }                                                    
                    else {
                        error += 'INVALID:unsupported field type for field : ' + customFieldName;  
                        res.statusCode = 400;
                    }                                                                            
                }
            }

            // HANDLE EXTERNAL USERS
            // if userType is set and (.isPortal) then :
            // If no externalUserProperties -> create account and contact on the fly
            // if has externalUserProperties -> if has account create contact on the fly, otherwise use as is

            // TODO add support to PersonAccount
            RecordType personAccountRecordType =  [SELECT Id FROM RecordType WHERE Name = 'Person Account' and SObjectType = 'Account'];
            if (isCreate) {
                if(u.profileId != null){
                    Id profileId = u.profileId; // required for create
                    List<Profile> profiles = [select usertype from profile where Id = :profileId];
                    if (profiles.size() != 1) {
                        error += 'INVALID: profile id is invalid : ' + profileId;  
                        res.statusCode = 400;                        
                    } else {
                        Profile profile = profiles.get(0);
                        boolean inferringExternalUserProfile = isPortalType(profile.userType);
                        // only run this if user knows what he is doing, i.e. specified an appropriate profile type.
                        if (inferringExternalUserProfile) {
                            Id accountId;
                            Id contactId;
                            if (user.externalUserProperties != null && user.externalUserProperties.get('accountId') != null) {
                                // if set, just pick it up                        
                                accountId = (Id) user.externalUserProperties.get('accountId');
                            } else if (personAccountRecordType != null){
                                // Person Accounts are enabled
                                // So use them
                                // TODO verify this code will compile in non-person account enabled org
                                
                                Account personAccount = new Account();
                                personAccount.RecordType = personAccountRecordType;
                                personAccount.FirstName = u.firstName;
                                personAccount.LastName = u.lastName;
                                personAccount.put('PersonEmail', u.email);
                                personAccount.put('PersonTitle', u.title);                                
                                Database.insert(personAccount);

                                List<Account> personAccounts = [select personContactId from Account where id =: personAccount.id limit 1];
                                contactId = personAccounts[0].PersonContactId;    
                            }
                            else {
                                // TODO is this really what we want to do?
                                // If PersonAccount NOT enabled and no Account.ID specified
                                // else create account one on the fly
                                // Instead - build interface to look up Account 
                                // if that returns null pitch a fit                                
                                Account jitAccount = new Account();
                                jitAccount.Name = user.userName + 'JITUserAccount';
                                jitAccount.OwnerId = UserInfo.getUserId();
                                Database.insert(jitAccount);
                                accountId = jitAccount.Id;
                             }
         
                            if (user.externalUserProperties != null && user.externalUserProperties.get('contactId') != null) {
                                contactId = (Id) user.externalUserProperties.get('contactId');
                            } else if (contactId == null){
                                // create a contact on the fly using the account
                                Contact jitContact = new Contact();
                                jitContact.FirstName = u.firstName;
                                jitContact.LastName = u.lastName;
                                jitContact.accountId = accountId;
                                jitContact.Email = u.email;
                                Database.insert(jitContact);
                                contactId = jitContact.Id;
                            }
                            u.contactId = contactId;
                        }
                    }
                }
            }
            else {
                // for updates, account id is fair. contact is not changeable.
                Id userId = u.id;
                User userWithContact = [select contactId, ProfileId, userType from user where Id = :userId];
                Id profileId = userWithContact.profileId;
                Profile profile = [select usertype from profile where Id = :profileId];
                boolean inferringExternalUserProfile = isPortalType(profile.userType);
                if (inferringExternalUserProfile) { 
                    Id accountId;
                    if (user.externalUserProperties != null && user.externalUserProperties.get('accountId') != null) {
                        // if set, just pick it up                        
                        accountId = (Id) user.externalUserProperties.get('accountId');
                    }
                    Id contactId = userWithContact.contactId;
                    
                    Contact existingContact = [select Id from Contact where Id = :contactId];
                    existingContact.accountId = accountId;
                    Database.update(existingContact);
                }
            }
        }

        if (res.statusCode == 201 ) {
            try {
                if (isCreate) {
                    insert u;
                    // now do PermSet assignments
                    List <PermissionSetAssignment> updatedPsas = new List<PermissionSetAssignment>();
                    for (PermissionSetAssignment psa : newPsas){
                        PermissionSetAssignment tempPSA = new PermissionSetAssignment();
                        tempPSA.PermissionSetId = psa.PermissionSetId;
                        tempPSA.AssigneeId = u.id;
                        updatedPSas.add(tempPSA);
                    }
                    if (!newPsas.isEmpty()){
                        Database.SaveResult[] newSRs = Database.insert(updatedPsas, false);
                        for (Database.SaveResult thisSR : newSRs) {
                            if (!thisSR.isSuccess()) {
                                for (Database.Error thisError : thisSR.getErrors()) {
                                    error += 'INVALID:' + thisError.getMessage() + ';';
                                }
                                res.statusCode = 400;
                            }
                        }                        
                    }
                    // now do Group assignments
                    List<GroupMember> updatedGMs = new List<GroupMember>();
                    for (GroupMember gm : newGMs){
                        GroupMember tempGM = new GroupMember();
                        tempGM.GroupId = gm.GroupId;
                        tempGM.UserOrGroupId = u.id;
                        updatedGMs.add(tempGM);
                    }
                    if (!newPsas.isEmpty()){
                        Database.SaveResult[] newSRs = Database.insert(updatedGMs, false);
                        for (Database.SaveResult thisSR : newSRs) {
                            if (!thisSR.isSuccess()) {
                                for (Database.Error thisError : thisSR.getErrors()) {
                                    error += 'INVALID:' + thisError.getMessage() + ';';
                                }
                                res.statusCode = 400;
                            }
                        }                        
                    }                    
                    if (user.password != null) {
                        System.setPassword(u.id, user.password);
                    }
                    /**
                     * Added following to allow users to be created in inactive state
                     * But overall this implimentation ignores inactive users
                     * */
                    else if (u.IsActive){  
                        System.resetPassword(u.id, true);
                        res.statusCode = 200;
                    }
                } else {
                    update u;
                    if (user.password != null && u.isActive) {
                        System.setPassword(u.id, user.password);
                    }  
                    res.statusCode = 200;
                }    
                
                String attributes = req.params.get('attributes');
                String excludedAttributes = req.params.get('excludedAttributes');
                
                String soql = FilterTranslator.buildAttributeQueryStringWithExcluded(attributes, excludedAttributes, 'id eq \"' + u.id + '\"', null, null, scimNameToUserSObjectNameMap, 'User', null, null, null).getActualQuery();
                List<User> users = Database.query(soql);
                if (!users.isEmpty()) {
                    // active could be set to false in which case will not return.
                    User uNew = users.get(0);
                    res.addHeader('Location', 'https://' + req.headers.get('Host') + '/services/apexrest/scim/v2/Users/' + uNew.Id);  
                    res.responseBody = UserResource.serializeUser(uNew, attributes, excludedAttributes, req.headers.get('Host'),req.headers.containsKey('X-Prettyprint'));
                }
                
                // return to commit, anything else rolls back
                return;
                
            } catch (Exception e) {
                res.statusCode = 409;
                res.responseBody = ScimError.serializeError(res.statusCode, e.getMessage(), req.headers.containsKey('X-Prettyprint'));
            }
        } else {
            res.statusCode = 409;
            res.responseBody = ScimError.serializeError(res.statusCode, error, req.headers.containsKey('X-Prettyprint'));
        }
        
        // the inserting failed in some ways, we rollback.
        Database.rollback(sp);
    }
    
    public static void doPatch(RestRequest req, RestResponse res, User u){
        res.addHeader('Content-Type', 'application/json');    
        res.statusCode = 201;
        String error = '';
        UserResource user;
        Savepoint sp = Database.setSavepoint();
        try {
             user = new UserResource(req.requestBody);
        } catch (ScimException scex) {
            res.statusCode = scex.getStatusCode();
            error = scex.getMessage();
        } catch (Exception e) {
            res.statusCode = 400;
            error = e.getMessage();
        }
    }
    
    public static boolean isPortalType(String userType) {
        return portalUserTypes.contains(userType.toLowerCase());
    }  
    
    public static void doDelete(System.RestRequest req, System.RestResponse res) {
        // this doesn't remove any associated Contacts or Accounts
        String[] uriParts = req.requestURI.split('/',0);
        Integer numParts = uriParts.size() - 1;          
        String host = req.headers.get('Host');
        
        User[] u = Database.query('select id, username, CommunityNickname, isActive from user where id=\'' + uriParts[numParts] + '\'');
        if(u.size() == 1 && u[0].isActive) {
            
            //TODO Add check for certain conditions that make delete not so simple
            //TODO By changing communityNickname do we screw things up in an active community?
            //Matt to provide
            //User[] userRefedBy = Database.query('select id from user where id=\'' + uriParts[numParts] + '\'');
            u[0].isActive = false;
            String tempUsername = u[0].id + '_' + u[0].username;
            String tempNickname = u[0].id;
            u[0].username = tempUsername;
            u[0].CommunityNickname = tempNickname;
            update u[0];
            res.statusCode = 204;
        } else {
            res.statusCode = 404;
            res.responseBody = SCIMError.serializeError(res.statusCode, 'Resource https://' + host + '/services/apexrest/scim/v2/Users/' + uriParts[numParts] + ' not found', req.headers.containsKey('X-Prettyprint'));
        }
    }  
    
    public static boolean isValidId(String id) {
//        return java:common.udd.Udd.isValidId(id); JUST FOR IAN
        List<User> users = [select id from User where id =: id];
        if (users.size() > 0) {
            return true;
        } else {
            return false;
        }
    }
   
    @HttpGet
    global static void doGet() {
        RestResponse res = RestContext.response;
        RestRequest req = RestContext.request;
        try {
            String host = req.headers.get('Host');
            res.addHeader('Content-Type', 'application/json');
            String[] uriParts = req.requestURI.split('/',0);
            Integer numParts = uriParts.size() - 1;           

            if (numParts >= 5) { // had to increase this is 5 because changed service url
                res.statusCode = 404;
                res.responseBody = SCIMError.serializeError(res.statusCode, 'No such resource', req.headers.containsKey('X-Prettyprint'));
            } else {
                
                String attributes = req.params.get('attributes');
                if (attributes != null) {
                    attributes = attributes.replaceAll(' ', '');
                }
                
                String excludedAttributes = req.params.get('excludedAttributes');
                if (excludedAttributes != null) {
                    excludedAttributes = excludedAttributes.replaceAll(' ', '');
                }
                
                if ((attributes != null) && (excludedAttributes != null)){
                    res.statusCode = 400;
                    res.responseBody = SCIMError.serializeError(res.statusCode, 'Cannot provide both attributes and excludedAttributes', req.headers.containsKey('X-Prettyprint'));
                    return;
                }
                                
                // isValidId only works if checked in                
                //if(isValidId(uriParts[numParts]) || uriParts[numParts] == 'Me'){
                if (uriParts[numParts] != 'Users' || uriParts[numParts] == 'Me'){ 

                String userId;
                	if (uriParts[numParts] == 'Me'){
                		userId = UserInfo.getUserId();
                	} else {
                		userId = uriParts[numParts];
                        if (!isValidId(uriParts[numParts])) {
                            res.statusCode = 404;
                            res.responseBody = SCIMError.serializeError(res.statusCode, 'No such resource', req.headers.containsKey('X-Prettyprint'));
                            return;
                        }
                	}
                    
                    List<User> users = new List<User>();
                    String filter = 'id eq \"' + userId + '\"';
                    if (req.params.get('filter') != null ) {
                        filter = '(id eq \"' + userId + '\") and ' + req.params.get('filter') ;
                    }
                    
//                    String soql = FilterTranslator.buildAttributeQueryString(attributes, filter, null, null, scimNameToUserSObjectNameMap, 'User',  'isActive = true', null, null).getActualQuery();
// following added to filter out internal-style users e.g. automatedProcess
                    String queryUserType = 'userType in (\'' + String.join(new List<String>(queriableUserTypes), '\',\'') + '\')';
                    QueryHolder queryHolder = FilterTranslator.buildAttributeQueryStringWithExcluded(attributes, excludedAttributes, filter, null, null, scimNameToUserSObjectNameMap, 'User', queryUserType, null, null);
                    users = Database.query(queryHolder.getActualQuery());

                    if ( !users.isEmpty()  ) {
                        res.addHeader('Location', 'https://' + host + '/services/apexrest/scim/v2/Users/' + users.get(0).Id);   
                        res.statusCode = 200; 
                        res.responseBody = UserResourceSerializer.serializeUser(users.get(0),attributes,excludedAttributes,host,req.headers.containsKey('X-Prettyprint'));
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
                } else {
                    //res.statusCode = 404;
                    //res.responseBody = SCIMError.serializeError(res.statusCode, 'Invalid Id', req.headers.containsKey('X-Prettyprint'));
                    UsersResource.doGet();
                }
            }
        }
        catch (ScimException ex) {
            res.statusCode = 400;
            res.responseBody = SCIMError.serializeError(res.statusCode, ex.getMessage(), req.headers.containsKey('X-Prettyprint'));
            return;
        }        
    }
    
 
    @HttpDelete
    global static void doDelete() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        doDelete(req, res);
    }    

    @HttpPut
    global static void doPut() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String[] uriParts = req.requestURI.split('/',0);
        Integer numParts = uriParts.size() - 1;

        if (numParts > 4) { 
            res.statusCode = 404;
            res.responseBody = SCIMError.serializeError(res.statusCode, 'No such resource', req.headers.containsKey('X-Prettyprint'));
            return;
        } 
        
        try {
            String soql = FilterTranslator.buildAttributeQueryString(null, 'id eq \"' + uriParts[numParts] + '\"', null, null, scimNameToUserSObjectNameMap, 'User',  null, null, null).getActualQuery();
            List<User> users = Database.query(soql);
            if (users != null && users.size() == 1 ) {
                User user = users.get(0);            
                user.Username = null;
                if (scimNameToUserSObjectNameMap.containsKey('externalId')) {
                    user.put('FederationIdentifier', null);
                }
                user.Lastname = null;
                user.Firstname = null;
                user.CommunityNickname = null;
                user.Email = null;
                user.Street = null;
                user.City = null;
                user.State = null;
                user.PostalCode = null;
                user.Country = null;
                user.Phone = null;
                user.MobilePhone = null;
                user.Fax = null;
                user.Title = null;
                user.LanguageLocaleKey = null;
                user.LocaleSidKey = null;
                user.IsActive = null;
                user.ProfileId = null;
                user.Profile.Name = null;
                user.employeeNumber = null;
                user.Division = null;
                user.Department = null;
                user.managerId = null;
                user.UserRoleId = null;
                
                // NOTE ABOUT CUSTOM FIELDS
                // It is impossible to know what the proper default values for each and every custom fields is.
                // And not all custom fields are nilable.
                // So instead of trying to be clever, opting to not handle it instead.
                // Just tell the user to supply desired default values here.
                
                doCreateOrUpdate(req, res, user, 'PUT'); 
            } else {
                res.statusCode = 404;
                res.responseBody = ScimError.serializeError(res.statusCode, 'Resource https://' + req.headers.get('Host') + '/services/apexrest/scim/v2/Users/' + uriParts[numParts] + ' not found', req.headers.containsKey('X-Prettyprint'));
            } 
        } catch ( Exception e ) {
             res.statusCode = 404;
             res.responseBody = ScimError.serializeError(res.statusCode, e.getMessage(), req.headers.containsKey('X-Prettyprint'));
        } 
    }
   
    public static Map<String, String> setResponse (String errorType, String attrName, String errorString, String responseCode){
        Map<String, String> response = new Map<String, String>();
        response.put('statusCode', responseCode);
        response.put('errorString', errorType + ' ' + attrName + ' ' + errorString);
        return response;
    }
 
    public static boolean isUnsupported (String attr) {
        Boolean result = false;
        if (unsupportedAttrs.contains(attr)) {
            result = true;
        }
        return result;
    }

    public static boolean isNotNillable (String attr) {
        Boolean result = false;
        if (notNillableAttrs.contains(attr)) {
            result = true;
        }
        return result;
    }

    
    public static boolean isReadOnly (String attr) {
        Boolean result = false;
        if (readOnlyAttrs.contains(attr)) {
            result = true;
        }
        return result;
    }
    
    @HttpPatch
    global static void doPatch() {
        // will use SCIMPatchSimple rules for Patch
        
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');    
        res.statusCode = 201;
        String error = '';

        String[] uriParts = req.requestURI.split('/',0);
        Integer numParts = uriParts.size() - 1;           
        if (numParts >= 5) { 
            res.statusCode = 404;
            res.responseBody = SCIMError.serializeError(res.statusCode, 'No such resource', req.headers.containsKey('X-Prettyprint'));
            return;
        }                 

        User user = [ Select ID, Username, IsActive from User where Id = :uriParts[numParts]];
        User tempUser = new User();
        tempUser.id = user.Id;
        
		UserPatchResource upr = new UserPatchResource(req.requestBody);
        String schema = upr.schemas.get(0);

        System.debug('Patch Resource: ' + upr);
        if (!schema.equals('urn:ietf:params:scim:api:messages:2.0:PatchOp')){
            res.statusCode = 400;
            res.responseBody = SCIMError.serializeError(res.statusCode, 'Improper Schema.', req.headers.containsKey('X-Prettyprint'));
            return;
        }
        
        String passwordString;
        
        Savepoint sp = Database.setSavepoint();
        try {
            for (UserPatchResource.Operation op : upr.operations){
                String operation = op.op;
                String path = op.path;
                
                // check for remove operations first
                // to avoid deref'ing nulls
                if (op.op == 'remove') {
                    // need to do enterprise extensions
                    // and other extensions (alias)
                    if (op.path != null) {
                        if(op.path == 'givenName') tempUser.firstname = null;
                        else if (op.path == 'familyName') tempuser.LastName = null;
                        else if (op.path == 'title') tempuser.title = null;
                        else if (op.path == 'preferredLanguage') tempuser.languagelocalekey = null;
                        else if (op.path == 'emailEncodingKey') tempuser.emailEncodingKey = null;
                        else if (op.path == 'locale') tempuser.localesidkey = null;
                        else if (op.path == 'timezone') tempuser.timezonesidkey = null;
                        else if (op.path == 'employeeNumber') tempuser.employeeNumber = null;
                        else if (op.path == 'division') tempuser.division = null;
                        else if (op.path == 'department') tempuser.department = null;
                        else if (op.path == 'nickName') tempuser.communityNickname = null;
                        else if (op.path == 'manager') tempuser.managerId = null;
                        else if (op.path == 'delegatedApprover') tempuser.delegatedApproverId = null;
                        else if (op.path == 'active') tempuser.isActive = false;
                        else if (op.path == 'roles') tempuser.userRoleId = null;
                        else if (op.path.startsWith('addresses')) {
                            tempuser.street = null;
                            tempuser.city = null;
                            tempuser.State = null;
                            tempuser.postalcode = null;
                            tempuser.Country = null;
                        }
                        else if (op.path == 'groups') {
                            List<GroupMember> currentGroups = [select id, groupId from GroupMember where userOrGroupId =: user.id];
                            delete currentGroups;
                        }
                        else if (op.path == 'entitlements'){
                            // cannot remove all entitlements
                            res.statusCode = 400;
                            error += 'INVALID: Cannot remove all entitlements. Use replace';
                            SCIMException e = new SCIMException();
                            e.setMessage(error);
                            e.setStatusCode(res.statusCode);
                        }
                        else if (isUnsupported(op.path)){
                            res.statusCode = 400;
                            error += 'UNSUPPORTED_FIELD: ' + op.path;
                            SCIMException e = new SCIMException();
                            e.setMessage(error);
                            e.setStatusCode(400);
                        }
                        else if (isNotNillable(op.path)){
                            res.statusCode = 400;
                            error += 'FIELD CANNOT BE NULL: ' + op.path;
                            SCIMException e = new SCIMException();
                            e.setMessage(error);
                            e.setStatusCode(400);                            
                        } else if (scimNameToUserSObjectNameMap.containsKey(op.path)){ // handle custom attributes
                            ScimSoqlAttributeProcessor customProcessor =  scimNameToUserSObjectNameMap.get(op.path);
                            tempUser.put(customProcessor.getSoqlAttribute(), null);
                        }
                	} else if (op.path == null) {
                    	res.statusCode = 400;
                    	error += 'MISING PATH';
	                    SCIMException e = new SCIMException();
    	                e.setMessage(error);
        	            e.setStatusCode(res.statusCode);
            	    }
                } else if ((op.op == 'add' )||(op.op == 'replace')){
                    System.debug(op.value.customFieldValues);
                    System.debug(op.value.externalUserProperties);                    
                    System.debug(op.value.otherUserProperties);

                    if (op.value.name != null){
                        Map<String, String> nameMap = op.value.name;
                        if (nameMap.containsKey('givenName')) tempUser.FirstName = nameMap.get('givenName');
                        else if (nameMap.containsKey('familyName')) tempUser.lastName = nameMap.get('familyName');
                    }
                    else if (op.value.title != null) tempUser.Title = op.value.title;
                    else if (op.value.preferredLanguage != null) tempuser.languagelocalekey = op.value.preferredLanguage;
                    else if (op.value.emailEncodingKey != null) tempuser.emailEncodingKey = op.value.emailEncodingKey;
                    else if (op.value.locale != null) tempuser.localesidkey = op.value.locale;
                    else if (op.value.timezone != null) tempuser.timezonesidkey = op.value.timezone;
                    else if (op.value.employeeNumber != null) tempuser.employeeNumber = op.value.employeeNumber;
                    else if (op.value.division != null) tempuser.division = op.value.division;
                    else if (op.value.department != null) tempuser.department = op.value.department;
                    else if (op.value.nickName != null) tempuser.communityNickname = op.value.nickName;
                    else if (op.value.password != null) passwordString = op.value.password;
                    else if (op.value.active != null) tempuser.isActive = op.value.active;
                    else if (op.value.addresses != null) {
                        if (op.value.addresses.size() > 1){
                            error += 'INVALID: User can only have one address';
                            res.statusCode = 400;
                        } else {
                            Map<String, String> tempAddressVal = op.value.addresses[0];
                            for (String key : tempAddressVal.keySet()){
                                if (key == 'streetAddress') tempuser.Street = tempAddressVal.get('streetAddress');
                                if (key == 'locality') tempuser.city = tempAddressVal.get('locality');
                                if (key == 'region') tempuser.state = tempAddressVal.get('region');
                                if (key == 'postalCode') tempuser.postalCode = tempAddressVal.get('postalCode');
                                if (key == 'country') tempuser.country = tempAddressVal.get('country');
                                
                            }
                        }
                    }
                    else if (op.value.emails != null) {
                        System.debug('PATCHing emails');
                        if (op.value.emails.size() > 1) {
                            error += 'INVALID: User can only have one email';
                            res.statusCode = 400;
                        } else {
                            Map<String, String> tempEmailVal = op.value.emails[0];
                            System.debug(tempEmailVal);
                            tempUser.Email = tempEmailVal.get('value');
                        }
                    }
                    else if (op.value.roles != null) {
                        if(op.value.roles.size() > 1){
                            error += 'INVALID:user_must_have_only_one_role;';  
                            res.statusCode = 400;
                        } else {
                            Map<String, String> tempRoleVal = op.value.roles[0];
	                        tempuser.userRoleId = tempRoleVal.get('value');
                        }
                    }
                    else if (op.value.manager != null) {
                        tempuser.managerId = (String) op.value.manager.get('value');
                    }
                    else if (op.value.delegatedApprover != null) {
                        tempuser.delegatedApproverId = (String) op.value.delegatedApprover.get('value');
                    }
                    else if (op.value.emails != null) {
                        if (op.value.emails.size() > 1){
                            error += 'INVALID: User can only have one email';
                            res.statusCode = 400;                          
                        } else {
                            Map<String, String> tempEmailVal = op.value.emails[0];
                            tempuser.email = tempEmailVal.get('value');
                        }
                    }
                    else if (op.value.groups != null){
                        List<GroupMember> groupsToProcess = new List<GroupMember>();
                        for (Map<String, String> g: op.value.groups){
                            GroupMember gm = new GroupMember();
                            gm.GroupId = (String) g.get('value');
                            gm.UserOrGroupId = user.Id;
                            groupsToProcess.add(gm);
                        }
                        //clean out existing groups if required
                        if (op.op == 'replace'){
                            List<GroupMember> currentGroups = [select id, groupId from GroupMember where userOrGroupId =: user.id];
                            delete currentGroups;
                        }
                        insert groupsToProcess;
                    }
                    else if (op.value.entitlements != null) {
                        List<String> profileToProcess = new List<String>();
                        List<PermissionSetAssignment> permSetsToProcess = new List<PermissionSetAssignment>();           
                        
                        String tempEntId;
                        for (Map<String, String> g: op.value.entitlements){
                            tempEntId = g.get('value');
                            if (tempEntId.startsWith('00e')) {
                                profileToProcess.add(tempEntId);
                            } else if (tempEntId.startsWith('0PS')) {
                                PermissionSetAssignment psa = new PermissionSetAssignment();
                                psa.PermissionSetId = tempEntId;
                                psa.AssigneeId = user.id;
                                permSetsToProcess.add(psa);
                            } else {
                                //bad entitlement id
                                res.statusCode = 400;
                                error += 'INVALID entitlement id: ' + tempEntId;
                                SCIMException e = new SCIMException();
                                e.setMessage(error);
                                e.setStatusCode(res.statusCode);
                                throw e;
                            }
                        }
                        if (operation == 'replace'){
                            if (profileToProcess.size() != 0){
                                if (profileToProcess.size() > 1){
                                    // cannot have multiple profiles
                                    res.statusCode = 400;
                                    error += 'INVALID: cannot have multiple profiles: ' + profileToProcess;
                                    SCIMException e = new SCIMException();
                                    e.setMessage(error);
                                    e.setStatusCode(res.statusCode);
                                    throw e;
                                } else if (profileToProcess.size() == 1){
                                    tempUser.ProfileId = profileToProcess[0];
                                }
                            }
                            if (permSetsToProcess.size() !=0){
                                // delete existing assignments
                                // then add new ones
                                List<PermissionSetAssignment> existingPSA = [select id from PermissionSetAssignment where assigneeId = :user.id AND PermissionSet.IsOwnedByProfile = False];
                                Database.delete(existingPSA);
                            }
                        }
                        if ((profileToProcess.size() !=0) && (operation == 'add')){
                            // cannot have multiple profiles
                            res.statusCode = 400;
                            error += 'INVALID: cannot have multiple profiles: ' + profileToProcess;
                            SCIMException e = new SCIMException();
                            e.setMessage(error);
                            e.setStatusCode(res.statusCode);
                            throw e;
                        }
                        
                        // insert new permSets
                        Database.SaveResult[] newSRs = Database.insert(permSetsToProcess, false);
                        for (Database.SaveResult thisSR : newSRs) {
                            if (!thisSR.isSuccess()) {
                                for (Database.Error thisError : thisSR.getErrors()) {
                                    error += 'INVALID:' + thisError.getMessage() + ';';
                                }
                                res.statusCode = 400;
                            }
                        }      
                    }
                    else if (op.value.customFieldValues != null){ // handle custom attributes
                        Set<String> keys = op.value.customFieldValues.keySet();
                        for (String key : keys) {
                            if (scimNameToUserSObjectNameMap.containsKey(key)){
                                Object customFieldValue = scimNameToUserSObjectNameMap.get(key);
                                ScimSoqlAttributeProcessor customProcessor =  scimNameToUserSObjectNameMap.get(key);
                                                     
                                // NOTE: customFieldValue is always a string, because of a limitation of 
                                // the parseSimpleObject de-serializing always with getText.
                                // making it dynamic there makes the method not simple in principle, so
                                // for simplicity, we just coerce it back to the right type here based on
                                // the field's type
                                Schema.SOAPType type = customProcessor.getSOAPType();

                                // TODO
                                // should not have to do straigh string comparison
                                // but cannot figure out why the same code copied from doCreateOrUpdate
                                // won't work here
                                if (String.valueOf(type) == 'BOOLEAN') {
                                    tempUser.put(customProcessor.getSoqlAttribute(), Boolean.valueOf(op.value.customFieldValues.get(key)));
                                }
                                
                                else if (String.valueOf(type) == 'DATE') {
                                    tempUser.put(customProcessor.getSoqlAttribute(), Date.valueOf(op.value.customFieldValues.get(key)));
                                }
                                else if (String.valueOf(type) == 'DATETIME') {
                                    tempUser.put(customProcessor.getSoqlAttribute(), Datetime.valueOf(op.value.customFieldValues.get(key)));
                                }
                                else if (String.valueOf(type) == 'DOUBLE') {
                                    tempUser.put(customProcessor.getSoqlAttribute(), Double.valueOf(op.value.customFieldValues.get(key)));
                                }
                                else if (String.valueOf(type) == 'ID') {
                                    tempUser.put(customProcessor.getSoqlAttribute(), String.valueOf(op.value.customFieldValues.get(key)));
                                }
                                else if (String.valueOf(type) == 'INTEGER') {
                                    tempUser.put(customProcessor.getSoqlAttribute(), Integer.valueOf(op.value.customFieldValues.get(key)));
                                }
                                else if (String.valueOf(type) == 'STRING') {
                                    tempUser.put(customProcessor.getSoqlAttribute(), String.valueOf(op.value.customFieldValues.get(key)));
                                }
                                else if (String.valueOf(type) == 'TIME') {
                                    tempUser.put(customProcessor.getSoqlAttribute(), Datetime.valueOf(op.value.customFieldValues.get(key)));
                                }     
                                else if (String.valueOf(type) == 'BASE64BINARY') {
                                    tempUser.put(customProcessor.getSoqlAttribute(), EncodingUtil.base64Decode((String) op.value.customFieldValues.get(key)));
                                }                                                    
                                else {
                                    error += 'INVALID:unsupported field type for field : ' + key;  
                                    res.statusCode = 400;
                                }   
                            }  
                        }
                    }
                    else if (op.value.otherUserProperties != null) {
                        if (op.value.otherUserProperties.containsKey(otherSchemaURN + ':alias')){
                            String tempAlias = (String)op.value.otherUserProperties.get(otherSchemaURN + ':alias');
                            if (tempAlias.length() > 8){
                                tempUser.Alias = tempAlias.substring(0,8);
                            } else tempUser.Alias = tempAlias;
                        }   
                    }
                     

                } else {
                    res.statusCode = 400;
                    error += 'INPROPER Operation: ' + op.op;
                    SCIMException e = new SCIMException();
                    e.setMessage(error);
                    e.setStatusCode(res.statusCode);
                }
                
                if (res.statusCode == 201){
                    System.debug('tempUser: ' + tempUser);
                    update tempUser;
                    if (passwordString != null){
                        System.setPassword(user.id, passwordString);
                    }
                } else {
                    SCIMException e = new SCIMException();
                    e.setMessage(error);
                    e.setStatusCode(res.statusCode);
                    throw e;
                }
            }
        } catch (SCIMException e) {
            res.addHeader('Content-Type', 'application/json');
            res.statusCode = e.getStatusCode();
            if (res.statusCode == null) {
                res.statusCode = 400;
            } 
            res.responseBody = ScimError.serializeError(res.statusCode, e.getMessage(), req.headers.containsKey('X-Prettyprint'));
            Database.rollback(sp);
            return;
        }
        doGet(); 
    }   
}