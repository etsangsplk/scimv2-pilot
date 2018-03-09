global with sharing class IndividualPatchResource extends ScimResource {
    final private static String orgId = UserInfo.getOrganizationId();
    final private static String indSchema = 'urn:salesforce:schemas:extension:2.0:Individual';
    final private static String indCustomAttrSchema = 'urn:salesforce:schemas:extension:2.0:Individual:' + orgId;

    public List<String> schemas {get;set;} 
    public List<Operation> operations {get;set;} 
    
    public class Operation {
        public String op {get;set;}
        public String path {get;set;}
        public Value value {get;set;}
    }

    public class Value{
        public List<String> attributes {get;set;}
        public List<String> schemas {get;set;}
        public String id {get;set;}
        public Map<String,String> name {get;set;}
        public Date birthDate {get;set;}
        public String individualsAge {get;set;}
        public Boolean canStorePiiElsewhere {get;set;}
        public Boolean hasOptedOutGeoTracking {get;set;}
        public Boolean hasOptedOutProcessing {get;set;}
        public Boolean hasOptedOutProfiling {get;set;}
        public Boolean hasOptedOutSolicit {get;set;}
        public Boolean hasOptedOutTracking {get;set;}
        public Boolean sendIndividualData {get;set;}
        public Boolean shouldForget {get;set;}

        public Map<String,Object> customFieldValues {get;set;}
        public List<Map<String, String>> operations {get;set;}
    }

    public IndividualPatchResource(Blob body) {
        System.debug(body.toString());
        System.JSONParser parser = System.JSON.createParser(body.toString());
        while (parser.nextToken() != null) {
            if (ScimResource.isNextTokenField(parser,'schemas')) {
                this.schemas = parseStringArray('schemas', parser);
                System.debug(this.schemas);
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
                                    System.debug(op.op);
                                } else if (text == 'path') {
                                    op.path = parser.getText();
                                    System.debug(op.path);
                                } else if (text == 'value') {       
                                    System.debug('in value');
                                    while (parser.nextToken() != JSONToken.END_OBJECT){
                                        if (isNextTokenField(parser,'name')) val.name = parseSimpleObject('name', parser);

                                        if (isNextTokenField(parser,'birthDate')) val.birthDate = date.valueOf(parseString('birthDate', parser));
                                        if (isNextTokenField(parser,'individualsAge')) val.individualsAge = parseString('individualsAge', parser);

                                        if (isNextTokenField(parser,'canStorePiiElsewhere')) val.canStorePiiElsewhere = parseBoolean('canStorePiiElsewhere',parser);
                                        if (isNextTokenField(parser,'hasOptedOutGeoTracking')) val.hasOptedOutGeoTracking = parseBoolean('hasOptedOutGeoTracking',parser);
                                        if (isNextTokenField(parser,'hasOptedOutProcessing')) val.hasOptedOutProcessing = parseBoolean('hasOptedOutProcessing',parser);
                                        if (isNextTokenField(parser,'hasOptedOutProfiling')) val.hasOptedOutProfiling = parseBoolean('hasOptedOutProfiling',parser);
                                        if (isNextTokenField(parser,'hasOptedOutSolicit')) val.hasOptedOutSolicit = parseBoolean('hasOptedOutSolicit',parser);
                                        if (isNextTokenField(parser,'hasOptedOutTracking')) val.hasOptedOutTracking = parseBoolean('hasOptedOutTracking',parser);
                                        if (isNextTokenField(parser,'sendIndividualData')) val.sendIndividualData = parseBoolean('sendIndividualData',parser);
                                        if (isNextTokenField(parser,'shouldForget')) val.shouldForget = parseBoolean('shouldForget',parser);
                                        if (doesNextTokenFieldStartWith(parser,indCustomAttrSchema)) val.customFieldValues = parseExtendedSchemaMap(parser);

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