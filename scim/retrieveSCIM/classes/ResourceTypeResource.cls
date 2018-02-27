@RestResource(urlMapping='/scim/v2/ResourceTypes/*')
global class ResourceTypeResource {
    
    @HttpGet
    global static void doGet() {
        
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');
        res.statusCode = 200; 

        String[] uriParts = req.requestURI.split('/',0);
        Integer numParts = uriParts.size() - 1;  
        String schemaType = uriParts[numParts];
        Boolean doUser = true;
        Boolean doGroup = true;
        Boolean doEntitlement = true;
        Boolean doRole = true;
        Boolean doIndividual = true;

        if (schemaType.equalsIgnoreCase('urn:ietf:params:scim:schemas:core:2.0:User') || schemaType.equalsIgnoreCase('User')) {
            doGroup = false;
            doEntitlement = false;
            doRole = false;
            doIndividual = false;
        } else if (schemaType.equalsIgnoreCase('urn:ietf:params:scim:schemas:core:2.0:Group') || schemaType.equalsIgnoreCase('Group')) {
            doUser = false;
            doEntitlement = false;
            doRole = false;            
            doIndividual = false;
        } else if (schemaType.equalsIgnoreCase('urn:salesforce:schemas:extension:2.0:Entitlement') || schemaType.equalsIgnoreCase('Entitlement')) {
            doUser = false;
            doGroup = false;
            doRole = false;      
            doIndividual = false;      
        } else if (schemaType.equalsIgnoreCase('urn:salesforce:schemas:extension:2.0:Role') || schemaType.equalsIgnoreCase('Role')) {
            doUser = false;
            doGroup = false;
            doEntitlement = false;
            doIndividual = false;            
        } else if (schemaType.equalsIgnoreCase('urn:salesforce:schemas:extension:2.0:Individual') || schemaType.equalsIgnoreCase('Individual')) {
            doUser = false;
            doGroup = false;
            doRole = false;       
            doEntitlement = false;     
        }
        res.responseBody = serializeConfigs(req.headers.containsKey('X-Prettyprint'), doUser, doGroup, doEntitlement, doRole, doIndividual);
        
    }  
    
    public static Blob serializeConfigs(boolean prettyPrint, boolean doUser, boolean doGroup, boolean doEntitlement, boolean doRole, boolean doIndividual) {
        Integer totalResults = 5;

        if (!doUser) totalResults--;
        if (!doGroup) totalResults--;
        if (!doEntitlement) totalResults--;
        if (!doRole) totalResults--;
        if (!doIndividual) totalResults--;

        String base = URL.getSalesforceBaseUrl().toExternalForm();               
        String path = '/services/apexrest/scim/v2/';
        String fullPath = base + path;

        JSONGenerator gen = JSON.createGenerator(prettyPrint);
        gen.writeStartObject();
        if (totalResults > 1){
            gen.writeNumberField('totalResults', totalResults);
            gen.writeNumberField('itemsPerPage', totalResults);
            gen.writeNumberField('startIndex', 1);
        
            gen.writeFieldName('schemas');
                gen.writeStartArray();
                gen.writeString('urn:ietf:params:scim:api:messages:2.0:ListResponse');
                gen.writeEndArray();
    
        
            gen.writeFieldName('Resources');
            gen.writeStartArray();                        
        }


        if (doUser) {
            if (totalResults > 1){
                gen.writeStartObject();
            }
                gen.writeStringField('id', 'urn:ietf:params:scim:schemas:core:2.0:User');
                gen.writeStringField('name', 'User');
                gen.writeStringField('description', 'Resource type for Users. Users are thinsg that can login.');
                gen.writeStringField('endpoint', '/Users');
                gen.writeStringField('schema', 'urn:ietf:params:scim:schemas:core:2.0:User');
                gen.writeFieldName('schemaExtensions');
                gen.writeStartArray();
                    gen.writeStartObject();
                        gen.writeStringField('schema', 'urn:ietf:params:scim:schemas:extension:enterprise:2.0:User');
                        gen.writeStringField('required', 'false');
                    gen.writeEndObject();
                    gen.writeStartObject();
                        gen.writeStringField('schema', 'urn:salesforce:schemas:extension:' + UserInfo.getOrganizationId());
                        gen.writeStringField('required', 'false');
                    gen.writeEndObject();
                    gen.writeStartObject();
                        gen.writeStringField('schema', 'urn:salesforce:schemas:extension:external:1.0');
                        gen.writeStringField('required', 'false');
                    gen.writeEndObject();
                    gen.writeStartObject();
                        gen.writeStringField('schema', 'urn:salesforce:schemas:extension:1.0');
                        gen.writeStringField('required', 'false');
                    gen.writeEndObject();            
                    gen.writeStartObject();
                        gen.writeStringField('schema', 'urn:salesforce:schemas:extension:communities:1.0');
                        gen.writeStringField('required', 'false');
                    gen.writeEndObject();            
                gen.writeEndArray();
                gen.writeFieldName('meta');
                gen.writeStartObject();
                        gen.writeStringField('location', fullPath + 'Users');
                        gen.writeStringField('resourceType', 'ResourceType');
                gen.writeEndObject();
            if (totalResults > 1){
                gen.writeEndObject();
            }
        }        

        if (doGroup){            
            if (totalResults > 1){
                gen.writeStartObject();
            }
                gen.writeStringField('id', 'urn:ietf:params:scim:schemas:core:2.0:Group');
                gen.writeStringField('name', 'Group');
                gen.writeStringField('description', 'Resource type for Groups. Group govern some access and sharing.');
                gen.writeStringField('endpoint', '/Groups');
                gen.writeStringField('schema', 'urn:ietf:params:scim:schemas:core:2.0:Group');
    
                gen.writeFieldName('meta');
                gen.writeStartObject();
                        gen.writeStringField('location', fullPath + 'Groups');
                        gen.writeStringField('resourceType', 'ResourceType');
                gen.writeEndObject();
            if (totalResults > 1){
                gen.writeEndObject();
            }
            
        }

        if (doEntitlement){
            if (totalResults > 1){
                gen.writeStartObject();
            }
                gen.writeStringField('id', 'urn:salesforce:schemas:extension:1.0:Entitlement');
                gen.writeStringField('name', 'Entitlement');
                gen.writeStringField('description', 'Resource type for Entitlements. Entitlements including Profiles and Permission Sets.');
                gen.writeStringField('endpoint', '/Entitlements');
                gen.writeStringField('schema', 'urn:salesforce:schemas:extension:1.0:Entitlement');
    
                gen.writeFieldName('meta');
                gen.writeStartObject();
                        gen.writeStringField('location', fullPath + 'Entitlements');
                        gen.writeStringField('resourceType', 'ResourceType');
                gen.writeEndObject();
            if (totalResults > 1){
                gen.writeEndObject();
            }
        }
        
        if (doRole) {
            if (totalResults > 1){
                gen.writeStartObject();
            }
                gen.writeStringField('id', 'urn:salesforce:schemas:extension:1.0:Role');
                gen.writeStringField('name', 'Role');
                gen.writeStringField('description', 'Resource type for Roles. Roles can control sharing.');
                gen.writeStringField('endpoint', '/Roles');
                gen.writeStringField('schema', 'urn:salesforce:schemas:extension:1.0:Role');
    
                gen.writeFieldName('meta');
                gen.writeStartObject();
                        gen.writeStringField('location', fullPath + 'Roles');
                        gen.writeStringField('resourceType', 'ResourceType');
                gen.writeEndObject();
            if (totalResults > 1){
                gen.writeEndObject();
            }
            
        }

        if (doIndividual) {
            if (totalResults > 1){
                gen.writeStartObject();
            }
                gen.writeStringField('id', 'urn:salesforce:schemas:extension:2.0:Individual');
                gen.writeStringField('name', 'Individual');
                gen.writeStringField('description', 'Resource type for Users. Users are thinsg that can login.');
                gen.writeStringField('endpoint', '/Individuals');
                gen.writeStringField('schema', 'urn:salesforce:schemas:extension:2.0:Individual');
                gen.writeFieldName('schemaExtensions');
                gen.writeStartArray();
                    gen.writeStartObject();
                        gen.writeStringField('schema', 'urn:salesforce:schemas:extension:2.0:Individual:' + UserInfo.getOrganizationId());
                        gen.writeStringField('required', 'false');
                    gen.writeEndObject();
                gen.writeEndArray();
                gen.writeFieldName('meta');
                gen.writeStartObject();
                        gen.writeStringField('location', fullPath + 'Individuals');
                        gen.writeStringField('resourceType', 'ResourceType');
                gen.writeEndObject();
            if (totalResults > 1){
                gen.writeEndObject();
            }
        }  

        if (totalResults > 1){
            gen.writeEndArray();                        
            gen.writeFieldName('meta');
                gen.writeStartObject();
                    gen.writeStringField('location', fullPath + 'ResourceTypes');
                    gen.writeStringField('resourceType', 'ListResponse');
                    
                    Blob digest = Crypto.generateDigest('SHA-1',  Blob.valueOf(fullPath));
                    gen.writeStringField('version', EncodingUtil.convertToHex(digest));
            gen.writeEndObject();
        }
        
        gen.writeEndObject();  

        return Blob.valueOf(gen.getAsString());

    }
}