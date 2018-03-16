@RestResource(urlMapping='/scim/v2/ServiceProviderConfig/*')
global class ServiceProviderConfigsResource {
    
    @HttpGet
    global static void doGet() {
        
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');
        res.statusCode = 200; 
        res.responseBody = serializeConfigs(req.headers.containsKey('X-Prettyprint'));
        
    }  
    
    public static Blob serializeConfigs(boolean prettyPrint) {
    
        JSONGenerator gen = JSON.createGenerator(prettyPrint);
        
        gen.writeStartObject();

            gen.writeFieldName('schemas');
            gen.writeStartArray();
                gen.writeString('urn:ietf:params:scim:schemas:core:2.0:ServiceProviderConfig');
            gen.writeEndArray();
            
            gen.writeStringField('documentationUri', 'https://help.salesforce.com/HTViewHelpDoc?id=identity_scim_overview.htm');   
        
            gen.writeFieldName('patch');
            gen.writeStartObject();
                gen.writeBooleanField('supported', true); 
            gen.writeEndObject();
        
            gen.writeFieldName('bulk');
            gen.writeStartObject();
                gen.writeBooleanField('supported', false); 
                gen.writeNumberField('maxOperations', 0);                   
                gen.writeNumberField('maxPayloadSize', 0);   
            gen.writeEndObject();
        
            gen.writeFieldName('filter');
            gen.writeStartObject();
                gen.writeBooleanField('supported', true); 
                gen.writeNumberField('maxResults', 200);                   
            gen.writeEndObject();
                    
            gen.writeFieldName('changePassword');
            gen.writeStartObject();
                gen.writeBooleanField('supported', true); 
            gen.writeEndObject();
                
            gen.writeFieldName('sort');
            gen.writeStartObject();
                gen.writeBooleanField('supported', false); 
            gen.writeEndObject();
                    
            gen.writeFieldName('etag');
            gen.writeStartObject();
                gen.writeBooleanField('supported', false); 
            gen.writeEndObject();
                
            gen.writeFieldName('authenticationSchemes');
            gen.writeStartArray();
                gen.writeStartObject();
                	gen.writeStringField('type', 'oauth2');
                    gen.writeStringField('name', 'OAuth v2.0');                       
                    gen.writeStringField('description', 'Authentication Scheme using the OAuth Standard');   
                    gen.writeStringField('specUri', 'http://tools.ietf.org/html/rfc6749');                                         
                    gen.writeStringField('documentationUri', 'https://help.salesforce.com/apex/HTViewHelpDoc?id=remoteaccess_authenticate.htm');                         
                    gen.writeBooleanField('primary', true); 
                gen.writeEndObject();
             gen.writeEndArray();  


        gen.writeFieldName('meta');
            gen.writeStartObject();
                String base = URL.getSalesforceBaseUrl().toExternalForm();               
                String path = '/services/apexrest/scim/v2/ServiceProviderConfig/';
        		String fullPath = base + path;
                gen.writeStringField('location', fullPath);

        		gen.writeStringField('resourceType', 'ServiceProviderConfig'); 
                
                Blob digest = Crypto.generateDigest('SHA-1',  Blob.valueOf(fullPath));
                gen.writeStringField('version', EncodingUtil.convertToHex(digest));
        gen.writeEndObject();
        gen.writeEndObject();                
        return Blob.valueOf(gen.getAsString());
    
    }

}