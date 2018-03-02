@RestResource(urlMapping='/scim/v2/Individuals')
global class IndividualsResource {
    final public static Map<String, ScimSoqlAttributeProcessor> scimNameToIndividualSObjectNameMap;
    final private static Map<String, Schema.SOAPType> customFieldToSoapTypeMap;
    final private static String orgId = UserInfo.getOrganizationId();

    final private static String indSchema = 'urn:salesforce:schemas:extension:2.0:Individual';
    final private static String indCustomerAttrSchema = 'urn:salesforce:schemas:extension:2.0:Individual:' + orgId;

    static {
        scimNameToIndividualSObjectNameMap = new Map<String, ScimSoqlAttributeProcessor>();
        scimNameToIndividualSObjectNameMap.put('id', new StandardAttributeProcessor('Id', Schema.SOAPType.String, false));

        scimNameToIndividualSObjectNameMap.put('name', new StandardAttributeProcessor('Name,Lastname,Firstname,Salutation', Schema.SOAPType.String, true));
        scimNameToIndividualSObjectNameMap.put('name.givenName', new StandardAttributeProcessor('Firstname', Schema.SOAPType.String, false));
        scimNameToIndividualSObjectNameMap.put('name.familyName', new StandardAttributeProcessor('Lastname', Schema.SOAPType.String, false));        
        scimNameToIndividualSObjectNameMap.put('name.honorificPrefix', new StandardAttributeProcessor('Salutation', Schema.SOAPType.String, false));

        scimNameToIndividualSObjectNameMap.put('birthDate', new StandardAttributeProcessor('BirthDate', Schema.SOAPType.DateTime, false));

        // coarse-grained consents
        scimNameToIndividualSObjectNameMap.put('canStorePiiElsewhere', new StandardAttributeProcessor('CanStorePiiElsewhere', Schema.SOAPType.Boolean, false));
        scimNameToIndividualSObjectNameMap.put('hasOptedOutGeoTracking', new StandardAttributeProcessor('HasOptedOutGeoTracking', Schema.SOAPType.Boolean, false));
        scimNameToIndividualSObjectNameMap.put('hasOptedOutProcessing', new StandardAttributeProcessor('HasOptedOutProcessing', Schema.SOAPType.Boolean, false));
        scimNameToIndividualSObjectNameMap.put('hasOptedOutProfiling', new StandardAttributeProcessor('HasOptedOutProfiling', Schema.SOAPType.Boolean, false));
        scimNameToIndividualSObjectNameMap.put('hasOptedOutSolicit', new StandardAttributeProcessor('HasOptedOutSolicit', Schema.SOAPType.Boolean, false));
        scimNameToIndividualSObjectNameMap.put('hasOptedOutTracking', new StandardAttributeProcessor('HasOptedOutTracking', Schema.SOAPType.Boolean, false));

        scimNameToIndividualSObjectNameMap.put('individualsAge', new StandardAttributeProcessor('IndividualsAge', Schema.SOAPType.String, false));

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
                scimNameToIndividualSObjectNameMap.put('urn:salesforce:schemas:extension:2.0:individual:' + orgId + ':' + customField, new StandardAttributeProcessor(customField, thisDescribeResult.getSOAPType(), false));
            }
        }

        if (customFields.length() > 0) {
            customFields = customFields.substring(0, (customFields.length() - 1));     
            scimNameToIndividualSObjectNameMap.put('urn:salesforce:schemas:extension:2.0:individual:' + orgId, new StandardAttributeProcessor(customFields, null, true));
        }

        scimNameToIndividualSObjectNameMap.put('meta', new StandardAttributeProcessor('CreatedDate,LastModifiedDate', Schema.SOAPType.String, true));
        scimNameToIndividualSObjectNameMap.put('meta.created', new StandardAttributeProcessor('CreatedDate', Schema.SOAPType.DateTime, false));
        scimNameToIndividualSObjectNameMap.put('meta.lastModified', new StandardAttributeProcessor('LastModifiedDate', Schema.SOAPType.DateTime, false));

    }

    public IndividualsResource(Blob body){
        System.JSONParser parser = System.JSON.createParser(body.toString());

        while(parser.nextToken() != null) {
            if (isNextTokenField(parser,'schemas')) this.schemas = parseStringArray('schemas', parser);                            
            if (isNextTokenField(parser,'id')) this.id = parseString('id',parser);
            if (isNextTokenField(parser,'name')) this.name = parseSimpleObject('name', parser);

            if (isNextTokenField(parse,'birthDate')) this.birthDate = parseSimpleDate('birthDate', parser);

            if (isNextTokenField(parser,indCustomerAttrSchema)) this.customFieldValues = parseSimpleObject(indCustomerAttrSchema, parser);
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
            
            String excludedAttributes = req.params.get('excludedAttributes');
            if (excludedAttributes != null) {
                excludedAttributes = excludedAttributes.replaceAll(' ', '');
            }
            
            String filter = req.params.get('filter');
            String startIndex = req.params.get('startIndex');
            String count = req.params.get('count');
            
            QueryHolder indQueryHolder = FilterTranslator.buildAttributeQueryStringWithExcluded(attributes, excludedAttributes, filter, startIndex, count, scimNameToIndividualSObjectNameMap, 'Individual', null, null, null);
            
            String countSoql = indQueryHolder.getCountQuery();
            String actualSoql = indQueryHolder.getActualQuery();
            
            Integer total = ScimResource.countQuery(countSoql);
            System.debug(actualSoql);
            List<Individual> inds = Database.query(actualSoql);

            if ( !inds.isEmpty()  ) {
                res.responseBody = IndividualResourceSerializer.serializeIndividuals(inds, total, startIndex, count, attributes, excludedAttributes, host,req.headers.containsKey('X-Prettyprint'));
            } else {
                res.responseBody = IndividualResourceSerializer.serializeIndividuals(null,0,null,null,null,null,host,req.headers.containsKey('X-Prettyprint'));
            }
        }
        catch (Exception ex) {
            res.statusCode = 400;
            res.responseBody = SCIMError.serializeError(res.statusCode, ex.getMessage(), req.headers.containsKey('X-Prettyprint'));
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
            Individual ind = new Individual();
            doUpsert(req, res, ind, method); 
        }
    }  
    public static void doUpsert(RestRequest req, RestResponse res, User u, String operation) {
        // TODO add support for Person Account

        Boolean isCreate = ( operation == 'POST' );
        Boolean isUpdate =  ( operation == 'PUT' || operation == 'PATCH');
        res.addHeader('Content-Type', 'application/json');    
        res.statusCode = 201;
        String error = '';
        IndividualsResource ind;
        Savepoint sp = Database.setSavepoint();
        try {
            ind = new IndividualsResource(req.requestBody);
            System.debug('individual: ' + ind);
        } catch (ScimException scex) {
            res.statusCode = scex.getStatusCode();
            error = scex.getMessage();
        } catch (Exception e) {
            res.statusCode = 400;
            error = e.getMessage();
        }
    }  
}