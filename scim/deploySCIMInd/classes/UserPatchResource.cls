global with sharing class UserPatchResource extends ScimResource {
    final private static String enterpriseExtensionURN = 'urn:ietf:params:scim:schemas:extension:enterprise:2.0:User';
    final private static String externalSchemaURN = 'urn:salesforce:schemas:extension:external:1.0';
    final private static String otherSchemaURN = 'urn:salesforce:schemas:extension:1.0';
    final private static String communitiesSchemaURN = 'urn:salesforce:schemas:extension:communities:1.0';
    final private static String orgId = UserInfo.getOrganizationId();

    public List<String> schemas {get;set;} 
    public List<Operation> operations {get;set;} 
    
    public class Operation {
        public String op {get;set;}
        public String path {get;set;}
        public Value value {get;set;}
    }

    public class Value{
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
     }

    public UserPatchResource(Blob body) {
        System.JSONParser parser = System.JSON.createParser(body.toString());
        while (parser.nextToken() != null) {
            if (ScimResource.isNextTokenField(parser,'schemas')) {
                this.schemas = parseStringArray('schemas', parser);
            } else if (ScimResource.isNextTokenField(parser, 'Operations')) {
                List<Operation> opers = new List<Operation>();
                while (parser.nextToken() != JSONToken.END_ARRAY){
                    Operation op = new Operation();
                    Value val = new Value();
                    while (parser.nextToken() != JSONToken.END_OBJECT){    
                        if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                            String text = parser.getText();
                            if (parser.nextToken() != JSONToken.VALUE_NULL) {
                                if (text == 'op') {
                                    op.op = parser.getText();
                                } else if (text == 'path') {
                                    op.path = parser.getText();
                                } else if (text == 'value') {
                                    while (parser.nextToken() != JSONToken.END_OBJECT){
                                        System.debug('current token: ' + parser.getCurrentName());
                                        System.debug('what i should match: ' + 'urn:salesforce:schemas:extension:' + orgId);
                                        if (isNextTokenField(parser,'id')) val.id = parseString('id',parser);
                                        if (isNextTokenField(parser,'userName')) val.userName = parseString('userName', parser);
                                        if (isNextTokenField(parser,'externalId')) val.externalId = parseString('externalId', parser);
                                        if (isNextTokenField(parser,'displayName')) val.displayName = parseString('displayName', parser);
                                        if (isNextTokenField(parser,'nickName')) val.nickName = parseString('nickName', parser);
                                        if (isNextTokenField(parser,'name')) val.name = parseSimpleObject('name', parser);
                                        if (isNextTokenField(parser,'profileUrl')) val.profileUrl = parseString('profileUrl', parser);
                                        if (isNextTokenField(parser,'userType')) val.userType = parseString('userType', parser);
                                        if (isNextTokenField(parser,'title')) val.title = parseString('title', parser);
                                        if (isNextTokenField(parser,'emailEncodingKey')) val.emailEncodingKey = parseString('emailEncodingKey', parser);
                                        if (isNextTokenField(parser,'preferredLanguage')) val.preferredLanguage = parseString('preferredLanguage', parser);
                                        if (isNextTokenField(parser,'locale')) val.locale = parseString('locale', parser);
                                        if (isNextTokenField(parser,'timezone')) val.timezone = parseString('timezone', parser);
                                        if (isNextTokenField(parser,'active')) val.active = parseBoolean('active', parser);
                                        if (isNextTokenField(parser,'employeeNumber')) val.employeeNumber = parseString('employeeNumber', parser);
                                        if (isNextTokenField(parser,'costCenter')) val.costCenter = parseString('costCenter', parser);
                                        if (isNextTokenField(parser,'organization')) val.organization = parseString('organization', parser);
                                        if (isNextTokenField(parser,'division')) val.division = parseString('division', parser);
                                        if (isNextTokenField(parser,'department')) val.department = parseString('department', parser);
                                        if (isNextTokenField(parser,'manager')) val.manager = parseSimpleObject('manager', parser);
                                        if (isNextTokenField(parser,'password')) val.password = parseString('password', parser);
                                     //   if (isNextTokenField(parser,'emails')) val.emails =  parseOptionalObjectArray('emails', parser); // this doesn't work
                                        if (isNextTokenField(parser,'emails')) val.emails =  parseObjectArray('emails', parser); // this does?
                                        if (isNextTokenField(parser,'roles')) val.roles =  parseObjectArray('roles', parser);
                                        if (isNextTokenField(parser,'groups')) val.groups =  parseObjectArray('groups', parser);
                                        if (isNextTokenField(parser,'addresses')) val.addresses = parseObjectArray('addresses', parser);
                                        if (isNextTokenField(parser,'phoneNumbers')) val.phoneNumbers =  parseObjectArray('phoneNumbers', parser);
                                        if (isNextTokenField(parser,'photos')) val.photos =  parseObjectArray('photos', parser);
                                        if (isNextTokenField(parser,'delegatedApprover')) val.delegatedApprover = parseSimpleObject('delegatedApprover', parser);
                                        if (isNextTokenField(parser,'entitlements')) val.entitlements =  parseObjectArray('entitlements', parser);
                                        
                                        if (doesNextTokenFieldStartWith(parser,'urn:salesforce:schemas:extension:' + orgId)) val.customFieldValues = parseExtendedSchemaMap(parser);
                                        if (doesNextTokenFieldStartWith(parser,'urn:salesforce:schemas:extension:external:1.0')) val.externalUserProperties = parseExtendedSchemaMap(parser);
                                        if (doesNextTokenFieldStartWith(parser,'urn:salesforce:schemas:extension:1.0')) val.otherUserProperties = parseExtendedSchemaMap(parser);
                                    }
                                    op.value = val;

                                } else {
                                    System.debug(LoggingLevel.WARN, 'Operations consuming unrecognized property: '+text);
                                    consumeObject(parser);
                                }
                            }
                        }
                    }
                    opers.add(op);
                    System.debug(op);
                }
                this.operations = opers;
            }
        }

        
		// this works for everything but custom and extended attributes
		// do not "fix" this
/*
        while (parser.nextToken() != null) {                      
            if (ScimResource.isNextTokenField(parser,'schemas')) {
                this.schemas = parseStringArray('schemas', parser);
            }
            if (ScimResource.isNextTokenField(parser, 'Operations')) {
                parser.nextToken();
                List<Operation> opers = new List<Operation>();
                while (parser.nextToken() == JSONToken.START_OBJECT){
                    Operation tempOper = (Operation)parser.readValueAs(Operation.class);
                    opers.add(tempOper);
                }
                this.operations = opers;
            }
        }
*/
    }
    public static boolean doesNextTokenFieldStartWith(System.JSONParser parser, String fieldName) {
		return ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText().startsWith(fieldName)));    
    }
    
    public static Map<String, String> parseExtendedSchemaMap(System.JSONparser parser){
        Map<String,String> obj = new Map<String,String>();
        String name = parser.getText();
        parser.nextToken();
        String value = parser.getText();
        obj.put(name, value);

        return obj;
    }
    
    public static void consumeObject(JSONParser parser) {
		Integer depth = 0;
		do {
			JSONToken curr = parser.getCurrentToken();
			if (curr == JSONToken.START_OBJECT || 
				curr == JSONToken.START_ARRAY) {
				depth++;
			} else if (curr == JSONToken.END_OBJECT ||
				curr == JSONToken.END_ARRAY) {
				depth--;
			}
		} while (depth > 0 && parser.nextToken() != null);
	}
}