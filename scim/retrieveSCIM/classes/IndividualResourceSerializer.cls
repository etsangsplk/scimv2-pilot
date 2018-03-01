public class IndividualResourceSerializer {

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

            Map<String, Schema.SObjectField> r = Schema.sObjectType.Individual.fields.getMap();
            Map<String, Object> customFieldMap = new Map<String, Object>();
            if (shouldSerialize('urn:salesforce:schemas:extension:2.0:individual:' + UserInfo.getOrganizationId(), attributes, excludedAttributes)) {
                for (String key : r.keySet()) {
                    SObjectField thisField = r.get(key);
                    DescribeFieldResult thisDescribeResult = thisField.getDescribe();
                    if (thisDescribeResult.isCustom()) {
                        try {
                            Object value = i.get(thisDescribeResult.getName());  
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
    
    public static Blob serializeIndividuals(List<Individual> inds, Integer total, String startIndex, String count, String attributes, String excludedAttributes, String host, boolean prettyPrint) {
        JSONGenerator gen = JSON.createGenerator(prettyPrint);
        gen.writeStartObject();
            gen.writeNumberField('totalResults', total);
            
            if (count != null) {
                Integer countInt = Math.min(Integer.valueof(count), inds.size());
                gen.writeNumberField('itemsPerPage', countInt);
            } 
            else if ((total != 0) && (total != inds.size())) {
                gen.writeNumberField('itemsPerPage', inds.size());
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
            if (inds != null) {
               serializeIndividualWithGenerator(inds, attributes, excludedAttributes, host, gen);
            }
            gen.writeEndArray();
        gen.writeEndObject();
        return Blob.valueOf(gen.getAsString());
    
    }  
}