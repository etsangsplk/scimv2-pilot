@RestResource(urlMapping='/scim/v2/Individuals/*')
global with sharing class IndividualResource extends SCIMResource {

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

    global static void doGet(String indId, String attributes, String excludedAttributes, Boolean isPost){
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
                serializeIndividualWithGenerator(inds, attributes, excludedAttributes, host, gen, indsLimit, indsOffset);      
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

    public static void serializeIndividualWithGenerator(List<Individual> inds, String attributes, String excludedAttributes, String host, JSONGenerator gen) {
        serializeIndividualWithGenerator(inds, attributes, excludedAttributes, host, gen, 200, 0);
    }
    
    public static void serializeIndividualWithGenerator(List<Individual> inds, String attributes, String excludedAttributes, String host, JSONGenerator gen, Integer indsLimit, Integer indsOffset) {
        String scimRef = host + '/services/apexrest/scim/v2/';
        for (Individual i : inds) {
            gen.writeStartObject();
                gen.writeFieldName('schemas');
                gen.writeStartArray();
                    gen.writeString('urn:salesforce:schemas:extension:2.0:individual');
                gen.writeEndArray();
                gen.writeStringField('id', i.id);            


                if (shouldSerialize('name', attributes, excludedAttributes)) {
                    gen.writeFieldName('name');
                        gen.writeStartObject();
                            if ((shouldSerialize('name.familyName', attributes, excludedAttributes)) && (i.Lastname != null)) gen.writeStringField('familyName', i.Lastname);
                            if ((shouldSerialize('name.givenName', attributes, excludedAttributes)) && (i.Firstname != null)) gen.writeStringField('givenName', i.Firstname);
                            if ((shouldSerialize('name.honorificPrefix', attributes, excludedAttributes)) && (i.Salutation != null)) gen.writeStringField('honorificPrefix', i.Salutation);
                        gen.writeEndObject();
                }

                if ((shouldSerialize('birthDate', attributes, excludedAttributes)) && (i.birthDate != null)) gen.writeDateField('birthDate', i.birthDate);
                if ((shouldSerialize('individualsAge', attributes, excludedAttributes)) && (i.individualsAge != null)) gen.writeStringField('individualsAge', i.individualsAge);

                if ((shouldSerialize('canStorePiiElsewhere', attributes, excludedAttributes)) && (i.canStorePiiElsewhere != null)) gen.writeBooleanField('canStorePiiElsewhere', i.canStorePiiElsewhere);
                if ((shouldSerialize('hasOptedOutGeoTracking', attributes, excludedAttributes)) && (i.hasOptedOutGeoTracking != null)) gen.writeBooleanField('hasOptedOutGeoTracking', i.hasOptedOutGeoTracking);
                if ((shouldSerialize('hasOptedOutProcessing', attributes, excludedAttributes)) && (i.hasOptedOutProcessing != null)) gen.writeBooleanField('hasOptedOutProcessing', i.hasOptedOutProcessing);
                if ((shouldSerialize('hasOptedOutProfiling', attributes, excludedAttributes)) && (i.hasOptedOutProfiling != null)) gen.writeBooleanField('hasOptedOutProfiling', i.hasOptedOutProfiling);
                if ((shouldSerialize('hasOptedOutSolicit', attributes, excludedAttributes)) && (i.hasOptedOutSolicit != null)) gen.writeBooleanField('hasOptedOutSolicit', i.hasOptedOutSolicit);
                if ((shouldSerialize('hasOptedOutTracking', attributes, excludedAttributes)) && (i.hasOptedOutTracking != null)) gen.writeBooleanField('hasOptedOutTracking', i.hasOptedOutTracking);
                if ((shouldSerialize('sendIndividualData', attributes, excludedAttributes)) && (i.sendIndividualData != null)) gen.writeBooleanField('sendIndividualData', i.sendIndividualData);
                if ((shouldSerialize('shouldForget', attributes, excludedAttributes)) && (i.shouldForget != null)) gen.writeBooleanField('shouldForget', i.shouldForget);


                if (shouldSerialize('meta', attributes)) {
                    gen.writeFieldName('meta');
                        gen.writeStartObject();
                            String createdFormated = i.CreatedDate.format('yyyy-MM-dd');
                            createdFormated += 'T';
                            createdFormated += i.CreatedDate.formatGmt('hh:mm:ss');
                            gen.writeStringField('created', createdFormated + 'Z');
                            
                            String lastmodFormated = i.LastModifiedDate.format('yyyy-MM-dd');
                            lastmodFormated += 'T';
                            lastmodFormated += i.LastModifiedDate.formatGmt('hh:mm:ss');
                            gen.writeStringField('lastModified', lastmodFormated + 'Z');
                            
                            String base = URL.getSalesforceBaseUrl().toExternalForm();
                            String path = '/services/apexrest/v2/Individuals/' + i.id;
                            gen.writeStringField('location', base + path);

                    		gen.writeStringField('resourceType', 'Individual');                    
                    
                            Blob digest = Crypto.generateDigest('SHA-1',  Blob.valueOf(user.id + lastmodFormated));
                            gen.writeStringField('version', EncodingUtil.convertToHex(digest));                                        
                        gen.writeEndObject();
                }
            gen.writeEndObject();    
        }   
    }    
    
    public static boolean shouldSerialize(String attributeName, String attributes) {
        return ScimResource.shouldSerialize(attributeName, attributes, IndividualsResource.scimNameToIndividualSObjectNameMap);
    }  
   
   public static boolean shouldSerialize(String attributeName, String attributes, String excludedAttributes) {
        return ScimResource.shouldSerializeWithExcluded(attributeName, attributes, excludedAttributes, IndividualsResource.scimNameToIndividualSObjectNameMap);
    }       
}