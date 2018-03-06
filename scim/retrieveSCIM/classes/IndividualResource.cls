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
                System.debug(this.customFieldValues);
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
            QueryHolder groupQueryHolder = FilterTranslator.buildAttributeQueryStringWithExcluded(attributes, excludedAttributes, 'id eq \"' + indId + '\"', null, null, IndividualsResource.scimNameToIndividualSObjectNameMap, 'Individual', null, null, null);
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

    public static void doUpsert(RestRequest req, RestResponse res, Individual i, String operation) {
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
            System.debug('in POST custom field values');
            for (String customFieldName : indRes.customFieldValues.keySet()) {
                System.debug('custom field name: ' + customFieldName);
                Object customFieldValue = indRes.customFieldValues.get(customFieldName);
                System.debug('custom field value: ' + customFieldvalue);
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