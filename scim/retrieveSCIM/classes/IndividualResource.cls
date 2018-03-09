@RestResource(urlMapping='/scim/v2/Individuals/*')
global with sharing class IndividualResource extends SCIMResource {
    final public static Map<String, ScimSoqlAttributeProcessor> scimNameToIndividualSObjectNameMap;
    final private static Map<String, Schema.SOAPType> customFieldToSoapTypeMap;
    final private static String orgId = UserInfo.getOrganizationId();

    final private static String indSchema = 'urn:salesforce:schemas:extension:2.0:Individual';
    final private static String indCustomAttrSchema = 'urn:salesforce:schemas:extension:2.0:Individual:' + orgId;

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

    final public static Set<String> unsupportedAttrs = new Set<String>{};
    final public static Set<String> notNillableAttrs = new Set<String>{'familyName'};


    static {
        scimNameToIndividualSObjectNameMap = new Map<String, ScimSoqlAttributeProcessor>();
        scimNameToIndividualSObjectNameMap.put('id', new StandardAttributeProcessor('Id', Schema.SOAPType.String, false));

        scimNameToIndividualSObjectNameMap.put('name', new StandardAttributeProcessor('Name,Lastname,Firstname,Salutation', Schema.SOAPType.String, true));
        scimNameToIndividualSObjectNameMap.put('name.givenName', new StandardAttributeProcessor('Firstname', Schema.SOAPType.String, false));
        scimNameToIndividualSObjectNameMap.put('name.familyName', new StandardAttributeProcessor('Lastname', Schema.SOAPType.String, false));        
        scimNameToIndividualSObjectNameMap.put('name.honorificPrefix', new StandardAttributeProcessor('Salutation', Schema.SOAPType.String, false));

        scimNameToIndividualSObjectNameMap.put('birthDate', new StandardAttributeProcessor('BirthDate', Schema.SOAPType.DateTime, false));
        scimNameToIndividualSObjectNameMap.put('individualsAge', new StandardAttributeProcessor('IndividualsAge', Schema.SOAPType.String, false));

        // coarse-grained consents
        scimNameToIndividualSObjectNameMap.put('canStorePiiElsewhere', new StandardAttributeProcessor('CanStorePiiElsewhere', Schema.SOAPType.Boolean, false));
        scimNameToIndividualSObjectNameMap.put('hasOptedOutGeoTracking', new StandardAttributeProcessor('HasOptedOutGeoTracking', Schema.SOAPType.Boolean, false));
        scimNameToIndividualSObjectNameMap.put('hasOptedOutProcessing', new StandardAttributeProcessor('HasOptedOutProcessing', Schema.SOAPType.Boolean, false));
        scimNameToIndividualSObjectNameMap.put('hasOptedOutProfiling', new StandardAttributeProcessor('HasOptedOutProfiling', Schema.SOAPType.Boolean, false));
        scimNameToIndividualSObjectNameMap.put('hasOptedOutSolicit', new StandardAttributeProcessor('HasOptedOutSolicit', Schema.SOAPType.Boolean, false));
        scimNameToIndividualSObjectNameMap.put('hasOptedOutTracking', new StandardAttributeProcessor('HasOptedOutTracking', Schema.SOAPType.Boolean, false));

        // intents
        scimNameToIndividualSObjectNameMap.put('sendIndividualData', new StandardAttributeProcessor('SendIndividualData', Schema.SOAPType.Boolean, false));
        scimNameToIndividualSObjectNameMap.put('shouldForget', new StandardAttributeProcessor('ShouldForget', Schema.SOAPType.Boolean, false));
        
        customFieldToSoapTypeMap = new Map<String, Schema.SOAPType>();
        // Also the custom fields.
        Map<String, Schema.SObjectField> r = Schema.sObjectType.Individual.fields.getMap();
        String customFields = '';
        for (String key : r.keySet()) {
            SObjectField thisField = r.get(key);
            DescribeFieldResult thisDescribeResult = thisField.getDescribe();
            if (thisDescribeResult.isCustom()) {
                String customField = thisDescribeResult.getName();
                customFields = customFields + customField + ',';
                customFieldToSoapTypeMap.put(thisDescribeResult.getName(), thisDescribeResult.getSOAPType());
                scimNameToIndividualSObjectNameMap.put(indCustomAttrSchema + ':' + customField, new StandardAttributeProcessor(customField, thisDescribeResult.getSOAPType(), false));
            }
        }

        if (customFields.length() > 0) {
            customFields = customFields.substring(0, (customFields.length() - 1));     
            scimNameToIndividualSObjectNameMap.put(indCustomAttrSchema, new StandardAttributeProcessor(customFields, null, true));
        }

        scimNameToIndividualSObjectNameMap.put('meta', new StandardAttributeProcessor('CreatedDate,LastModifiedDate', Schema.SOAPType.String, true));
        scimNameToIndividualSObjectNameMap.put('meta.created', new StandardAttributeProcessor('CreatedDate', Schema.SOAPType.DateTime, false));
        scimNameToIndividualSObjectNameMap.put('meta.lastModified', new StandardAttributeProcessor('LastModifiedDate', Schema.SOAPType.DateTime, false));

    }

    public IndividualResource(Blob body){
        System.JSONParser parser = System.JSON.createParser(body.toString());

        while(parser.nextToken() != null) {
            if (isNextTokenField(parser,'schemas')) this.schemas = parseStringArray('schemas', parser);                            
            if (isNextTokenField(parser,'id')) this.id = parseString('id',parser);
            if (isNextTokenField(parser,'name')) this.name = parseSimpleObject('name', parser);

            if (isNextTokenField(parser,'birthDate')) this.birthDate = date.valueOf(parseString('birthDate', parser));
            if (isNextTokenField(parser,'individualsAge')) this.individualsAge = parseString('individualsAge', parser);

            if (isNextTokenField(parser,'canStorePiiElsewhere')) this.canStorePiiElsewhere = parseBoolean('canStorePiiElsewhere',parser);
            if (isNextTokenField(parser,'hasOptedOutGeoTracking')) this.hasOptedOutGeoTracking = parseBoolean('hasOptedOutGeoTracking',parser);
            if (isNextTokenField(parser,'hasOptedOutProcessing')) this.hasOptedOutProcessing = parseBoolean('hasOptedOutProcessing',parser);
            if (isNextTokenField(parser,'hasOptedOutProfiling')) this.hasOptedOutProfiling = parseBoolean('hasOptedOutProfiling',parser);
            if (isNextTokenField(parser,'hasOptedOutSolicit')) this.hasOptedOutSolicit = parseBoolean('hasOptedOutSolicit',parser);
            if (isNextTokenField(parser,'hasOptedOutTracking')) this.hasOptedOutTracking = parseBoolean('hasOptedOutTracking',parser);
            if (isNextTokenField(parser,'sendIndividualData')) this.sendIndividualData = parseBoolean('sendIndividualData',parser);
            if (isNextTokenField(parser,'shouldForget')) this.shouldForget = parseBoolean('shouldForget',parser);

            if (isNextTokenField(parser,indCustomAttrSchema)) {
                this.customFieldValues = parseSimpleObject(indCustomAttrSchema, parser);
            }

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

    @HttpGet
    global static void doGet(){
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
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
        
        String[] uriParts = req.requestURI.split('/',0);
        Integer numParts = uriParts.size() - 1;   
        if (numParts > 4) { 
            res.statusCode = 404;
            res.responseBody = SCIMError.serializeError(res.statusCode, 'No such resource.', req.headers.containsKey('X-Prettyprint'));
        } else if (numParts == 4) {
            doGet(uriParts[numParts], attributes, excludedAttributes, false);   
        } else if (numParts == 3) {
            IndividualsResource.doGet();
        }
    }

    private static void doGet(String indId, String attributes, String excludedAttributes, Boolean isPost){
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');
        
        String indsCount = req.params.get('inds.count');
        String indsStartIndex = req.params.get('inds.startIndex');
        try {
            Integer indsLimit = 200;
            if (indsCount != null) {
                FilterTranslator.validateCount(indsCount);
                indsLimit = Integer.valueof(indsCount);
            }
            
            Integer indsOffset = 0;
            if (indsStartIndex != null) {
                FilterTranslator.validateStartIndex(indsStartIndex);
                indsOffset = Integer.valueof(indsStartIndex) - 1;
            }
            else {
                indsOffset = 0;
            }   
            String host = req.headers.get('Host');
            QueryHolder groupQueryHolder = FilterTranslator.buildAttributeQueryStringWithExcluded(attributes, excludedAttributes, 'id eq \"' + indId + '\"', null, null, scimNameToIndividualSObjectNameMap, 'Individual', null, null, null);
            String actualSoql = groupQueryHolder.getActualQuery();
            List<Individual> inds = Database.query(actualSoql);
            
            if ( !inds.isEmpty()  ) {
                res.statusCode = 200;
                if(isPost){
                    res.statusCode = 201; 
                }
                Boolean isPrettyPrint = req.headers.containsKey('X-Prettyprint');
                JSONGenerator gen = JSON.createGenerator(isPrettyPrint);
                IndividualResourceSerializer.serializeIndividualWithGenerator(inds, attributes, excludedAttributes, host, gen, indsLimit, indsOffset);      
                res.responseBody =  Blob.valueOf(gen.getAsString());
            } else {
                res.statusCode = 404;
                res.responseBody = SCIMError.serializeError(res.statusCode, 'Resource https://' + host + '/services/apexrest/v2/Individuals/' + indId + ' not found', req.headers.containsKey('X-Prettyprint'));
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
    private static void doDelete(RestRequest req, RestResponse res){
        String[] uriParts = req.requestURI.split('/',0);
        Integer numParts = uriParts.size() - 1;  
        
        Individual[] i = Database.query('select id from individual where id=\'' + uriParts[numParts] + '\'');
        if(i.size() == 1) {
        	delete i[0];
            res.statusCode = 204;
        } else {
            res.statusCode = 404;
            res.responseBody = SCIMError.serializeError(res.statusCode, 'No such resource.', req.headers.containsKey('X-Prettyprint'));
            return;
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
            doUpsert(req, res, null, method); 
        }
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
            QueryHolder groupQueryHolder = FilterTranslator.buildAttributeQueryStringWithExcluded(null, null, 'id eq \"' + uriParts[numParts] + '\"', null, null, scimNameToIndividualSObjectNameMap, 'Individual', null, null, null);
            String soql = groupQueryHolder.getActualQuery();
            List<Individual> inds = Database.query(soql);
            if (inds != null && inds.size() == 1 ) {
                Individual ind = inds.get(0);            

            
                doUpsert(req, res, ind, 'PUT'); 
            } else {
                res.statusCode = 404;
                res.responseBody = ScimError.serializeError(res.statusCode, 'Resource https://' + req.headers.get('Host') + '/services/apexrest/scim/v2/Individuals/' + uriParts[numParts] + ' not found', req.headers.containsKey('X-Prettyprint'));
            } 
        } catch ( Exception e ) {
             res.statusCode = 404;
             res.responseBody = ScimError.serializeError(res.statusCode, e.getMessage(), req.headers.containsKey('X-Prettyprint'));
        } 
    }

    @HttpPatch
    global static void doPatch(){
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

        Individual ind = [ Select ID from Individual where Id = :uriParts[numParts]];
        Individual tempInd = new Individual();
        tempInd.id = ind.Id;
        
		IndividualPatchResource ipr = new IndividualPatchResource(req.requestBody);
        String schema = ipr.schemas.get(0);

        System.debug('Patch Resource: ' + ipr);
        if (!schema.equals('urn:ietf:params:scim:api:messages:2.0:PatchOp')){
            res.statusCode = 400;
            res.responseBody = SCIMError.serializeError(res.statusCode, 'Improper Schema.', req.headers.containsKey('X-Prettyprint'));
            return;
        }

        Savepoint sp = Database.setSavepoint();
        try {
            for (IndividualPatchResource.Operation op : ipr.operations){
                String operation = op.op;
                String path = op.path;
                
                // check for remove operations first
                // to avoid deref'ing nulls
                if (op.op == 'remove') {
                    System.debug('in remove via: ' + op);
                    if (isUnsupported(op.path)){
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
                    }
                	else if (op.path == null) {
                    	res.statusCode = 400;
                    	error += 'MISING PATH';
	                    SCIMException e = new SCIMException();
    	                e.setMessage(error);
        	            e.setStatusCode(res.statusCode);
            	    }
                    else if ((op.path != null) && (op.path == 'familyName')) tempInd.lastName = null;
                    else if ((op.path != null) && (op.path == 'givenName')) tempInd.firstName = null;                    
                    else if ((op.path != null) && (op.path == 'honorificPrefix')) tempInd.salutation = null;
                    // protect against bug
                    // if ((op.path != null) && (op.path == 'birthDate')) tempInd.birthDate = null;
  
                    else if ((op.path != null) && (op.path == 'individualsAge')) tempInd.individualsAge = null;

                    // technically you cannot nillify the checkboxes
                    // set them to false instead                    
                    else if ((op.path != null) && (op.path == 'canStorePiiElsewhere')) {system.debug('pii'); tempInd.canStorePiiElsewhere = false; System.debug(tempInd);}
                    else if ((op.path != null) && (op.path == 'hasOptedOutGeoTracking')) tempInd.hasOptedOutGeoTracking = false;
                    else if ((op.path != null) && (op.path == 'hasOptedOutProcessing')) tempInd.hasOptedOutProcessing = false;
                    else if ((op.path != null) && (op.path == 'hasOptedOutProfiling')) tempInd.hasOptedOutProfiling = false;
                    else if ((op.path != null) && (op.path == 'hasOptedOutSolicit')) tempInd.hasOptedOutSolicit = false;
                    else if ((op.path != null) && (op.path == 'hasOptedOutTracking')) tempInd.hasOptedOutTracking = false;
                    else if ((op.path != null) && (op.path == 'sendIndividualData')) tempInd.sendIndividualData = false;
                    else if ((op.path != null) && (op.path == 'shouldForget')) tempInd.shouldForget = false;

                    // handle custom attributes
                    // TODO update to set checkbox type fields to false not null
                    else if ((op.path != null) && scimNameToIndividualSObjectNameMap.containsKey(op.path)){ 
                            ScimSoqlAttributeProcessor customProcessor =  scimNameToIndividualSObjectNameMap.get(op.path);
                            Schema.SOAPType soapType = customProcessor.getSOAPType();
                            if(String.valueOf(soapType) == 'BOOLEAN'){
                                tempInd.put(customProcessor.getSoqlAttribute(), false);
                            } else {
                                tempInd.put(customProcessor.getSoqlAttribute(), null);
                            }

                        }

                } else if ((op.op == 'replace') || (op.op == 'add')) {
                    System.debug('in replace or add via:' + op);
                    if (op.value.name != null) {
                        Map<String, String> nameMap = op.value.name;
                        if (nameMap.containsKey('givenName')) tempInd.FirstName = nameMap.get('givenName');
                        else if (nameMap.containsKey('familyName')) tempInd.lastName = nameMap.get('familyName');
                        else if (nameMap.containsKey('honorificPrefix')) tempInd.salutation = nameMap.get('honorificPrefix');
                    }
                    else if (op.value.birthDate != null) tempInd.birthDate = op.value.birthdate;
                    else if (op.value.individualsAge != null) tempInd.individualsAge = op.value.individualsAge;

                    else if (op.value.canStorePiiElsewhere != null) tempInd.canStorePiiElsewhere = op.value.canStorePiiElsewhere;
                    else if (op.value.hasOptedOutGeoTracking != null) tempInd.hasOptedOutGeoTracking = op.value.hasOptedOutGeoTracking;
                    else if (op.value.hasOptedOutProcessing != null) tempInd.hasOptedOutProcessing = op.value.hasOptedOutProcessing;
                    else if (op.value.hasOptedOutProfiling != null) tempInd.hasOptedOutProfiling = op.value.hasOptedOutProfiling;
                    else if (op.value.hasOptedOutSolicit != null) tempInd.hasOptedOutSolicit = op.value.hasOptedOutSolicit;
                    else if (op.value.hasOptedOutTracking != null) tempInd.hasOptedOutTracking = op.value.hasOptedOutTracking;
                    else if (op.value.sendIndividualData != null) tempInd.sendIndividualData = op.value.sendIndividualData;
                    else if (op.value.shouldForget != null) tempInd.shouldForget = op.value.shouldForget;
                    else if (op.value.customFieldValues != null) {
                        // handle custom attributes
                        Set<String> keys = op.value.customFieldValues.keySet();
                        for (String key : keys) {
                            if (scimNameToIndividualSObjectNameMap.containsKey(key)){
                                Object customFieldValue = scimNameToIndividualSObjectNameMap.get(key);
                                ScimSoqlAttributeProcessor customProcessor =  scimNameToIndividualSObjectNameMap.get(key);
                                                     
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
                                    tempInd.put(customProcessor.getSoqlAttribute(), Boolean.valueOf(op.value.customFieldValues.get(key)));
                                }
                                
                                else if (String.valueOf(type) == 'DATE') {
                                    tempInd.put(customProcessor.getSoqlAttribute(), Date.valueOf(op.value.customFieldValues.get(key)));
                                }
                                else if (String.valueOf(type) == 'DATETIME') {
                                    tempInd.put(customProcessor.getSoqlAttribute(), Datetime.valueOf(op.value.customFieldValues.get(key)));
                                }
                                else if (String.valueOf(type) == 'DOUBLE') {
                                    tempInd.put(customProcessor.getSoqlAttribute(), Double.valueOf(op.value.customFieldValues.get(key)));
                                }
                                else if (String.valueOf(type) == 'ID') {
                                    tempInd.put(customProcessor.getSoqlAttribute(), String.valueOf(op.value.customFieldValues.get(key)));
                                }
                                else if (String.valueOf(type) == 'INTEGER') {
                                    tempInd.put(customProcessor.getSoqlAttribute(), Integer.valueOf(op.value.customFieldValues.get(key)));
                                }
                                else if (String.valueOf(type) == 'STRING') {
                                    tempInd.put(customProcessor.getSoqlAttribute(), String.valueOf(op.value.customFieldValues.get(key)));
                                }
                                else if (String.valueOf(type) == 'TIME') {
                                    tempInd.put(customProcessor.getSoqlAttribute(), Datetime.valueOf(op.value.customFieldValues.get(key)));
                                }     
                                else if (String.valueOf(type) == 'BASE64BINARY') {
                                    tempInd.put(customProcessor.getSoqlAttribute(), EncodingUtil.base64Decode((String) op.value.customFieldValues.get(key)));
                                }                                                    
                                else {
                                    error += 'INVALID:unsupported field type for field : ' + key;  
                                    res.statusCode = 400;
                                }   
                            }  
                        }
                    }

                } else {
                    res.statusCode = 400;
                    error += 'IMPROPER Operation: ' + op.op;
                    SCIMException e = new SCIMException();
                    e.setMessage(error);
                    e.setStatusCode(res.statusCode);
                    throw e;
                }
                
                if (res.statusCode == 201){
                    System.debug('tempInd: ' + tempInd);
                    update tempInd;
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
    private static void doUpsert(RestRequest req, RestResponse res, Individual i, String operation) {
        Boolean isCreate = ( operation == 'POST' );
        Boolean isUpdate =  ( operation == 'PUT' );
        res.addHeader('Content-Type', 'application/json');    
        res.statusCode = 201;
        String error = '';
        IndividualResource indRes;
        Savepoint sp = Database.setSavepoint();
        try {
            indRes = new IndividualResource(req.requestBody);
        } catch (ScimException scex) {
            res.statusCode = scex.getStatusCode();
            error = scex.getMessage();
        } catch (Exception e) {
            res.statusCode = 400;
            error = e.getMessage();
        }

        Individual ind = new Individual();
        if (!isCreate) {
            ind.id = i.id;
        }

        if (indRes.name != null){
            if (indRes.name.containsKey('familyName')) {
                    ind.lastName = indRes.name.get('familyName');
                } else {
                    if ( ( isCreate ) || ( isUpdate ) ) {
                        error += 'REQUIRED_FIELD_MISSING:name.familyName;';  
                        res.statusCode = 400;  
                    } 
                }
                if (indRes.name.containsKey('givenName')) {
                    ind.firstName = indRes.name.get('givenName');
                }
                if (indRes.name.containsKey('middleName')) {
                    error += 'UNSUPPORTED_FIELD:name.middleName;';  
                    res.statusCode = 400;   
                }
                if (indRes.name.containsKey('honorificPrefix')) {
                    ind.salutation = indRes.name.get('honorificPrefix');
                }
                if (indRes.name.containsKey('honorificSuffix')) {
                    error += 'UNSUPPORTED_FIELD:name.honorificSuffix;';  
                    res.statusCode = 400;   
                }
        }

        if (indRes.birthDate != null) ind.birthDate = indRes.birthDate;
        if (indRes.individualsAge != null) ind.individualsAge = indRes.individualsAge;

        if (indRes.canStorePiiElsewhere != null) ind.canStorePiiElsewhere = indRes.canStorePiiElsewhere;
        if (indRes.hasOptedOutGeoTracking != null) ind.hasOptedOutGeoTracking = indRes.hasOptedOutGeoTracking;
        if (indRes.hasOptedOutProcessing != null) ind.hasOptedOutProcessing = indRes.hasOptedOutProcessing;
        if (indRes.hasOptedOutProfiling != null) ind.hasOptedOutProfiling = indRes.hasOptedOutProfiling;
        if (indRes.hasOptedOutSolicit != null) ind.hasOptedOutSolicit = indRes.hasOptedOutSolicit;
        if (indRes.hasOptedOutTracking != null) ind.hasOptedOutTracking = indRes.hasOptedOutTracking;
        if (indRes.sendIndividualData != null) ind.sendIndividualData = indRes.sendIndividualData;
        if (indRes.shouldForget != null) ind.shouldForget = indRes.shouldForget;

        if (indRes.customFieldValues != null) {
            for (String customFieldName : indRes.customFieldValues.keySet()) {
                Object customFieldValue = indRes.customFieldValues.get(customFieldName);
                // NOTE: customFieldValue is always a string, because of a limitation of 
                // the parseSimpleObject de-serializing always with getText.
                // making it dynamic there makes the method not simple in principle, so
                // for simplicity, we just coerce it back to the right type here based on
                // the field's type
                Schema.SOAPType type = customFieldToSoapTypeMap.get(customFieldName);
                if (type == Schema.SOAPType.Boolean) {
                    ind.put(customFieldName, Boolean.valueOf(customFieldValue));
                }
                else if (type == Schema.SOAPType.Date) {
                    ind.put(customFieldName, Date.valueOf(customFieldValue));
                }
                else if (type == Schema.SOAPType.DateTime) {
                    ind.put(customFieldName, Datetime.valueOf(customFieldValue));
                }
                else if (type == Schema.SOAPType.Double) {
                    ind.put(customFieldName, Double.valueOf(customFieldValue));
                }
                else if (type == Schema.SOAPType.ID) {
                    ind.put(customFieldName, String.valueOf(customFieldValue));
                }
                else if (type == Schema.SOAPType.Integer) {
                    ind.put(customFieldName, Integer.valueOf(customFieldValue));
                }
                else if (type == Schema.SOAPType.String) {
                    ind.put(customFieldName, String.valueOf(customFieldValue));
                }
                else if (type == Schema.SOAPType.Time) {
                    ind.put(customFieldName, Datetime.valueOf(customFieldValue));
                }     
                else if (type == Schema.SOAPType.base64binary) {
                    ind.put(customFieldName, EncodingUtil.base64Decode((String) customFieldValue));
                }                                                    
                else {
                    error += 'INVALID:unsupported field type for field : ' + customFieldName;  
                    res.statusCode = 400;
                }                                                                            
            }
        }        

        if (res.statusCode == 201 ) {
            try {
                upsert ind;

                String attributes = req.params.get('attributes');
                String excludedAttributes = req.params.get('excludedAttributes');
                
                String soql = FilterTranslator.buildAttributeQueryStringWithExcluded(attributes, excludedAttributes, 'id eq \"' + ind.id + '\"', null, null, scimNameToIndividualSObjectNameMap, 'Individual', null, null, null).getActualQuery();
                List<Individual> inds = Database.query(soql);
                if (!inds.isEmpty()) {
                    // active could be set to false in which case will not return.
                    res.addHeader('Location', 'https://' + req.headers.get('Host') + '/services/apexrest/scim/v2/Individuals/' + inds[0].Id);  
                    Boolean isPrettyPrint = req.headers.containsKey('X-Prettyprint');
                    JSONGenerator gen = JSON.createGenerator(isPrettyPrint);
                    IndividualResourceSerializer.serializeIndividualWithGenerator(inds, attributes, excludedAttributes, req.headers.get('Host'), gen);      
                    res.responseBody =  Blob.valueOf(gen.getAsString());
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
}