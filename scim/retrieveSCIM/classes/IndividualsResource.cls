@RestResource(urlMapping='/scim/v2/Individuals')
global class IndividualsResource {
        final public static Map<String, ScimSoqlAttributeProcessor> scimNameToIndividualSObjectNameMap;
    final private static Map<String, Schema.SOAPType> customFieldToSoapTypeMap;
    final private static String orgId = UserInfo.getOrganizationId();

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

  
}