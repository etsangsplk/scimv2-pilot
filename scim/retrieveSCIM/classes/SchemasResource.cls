@RestResource(urlMapping='/scim/v2/Schemas/*')
global class SchemasResource {
    private static Boolean doUser = false;
    private static Boolean doGroup = false;
    private static Boolean doEntitlement = false;
    private static Boolean doRole = false;
    private static Boolean doEnterprise = false;
    private static Boolean doExternal = false;
    private static Boolean doOrgCustom = false;
    private static Boolean doOther = false;
    private static Boolean doCommunities = false;
    private static Boolean doIndividual = false;
    private static Boolean doIndividualExtension = false;

    // if Individual is enabled return schema. Check for enablement. Throw exception if not enabled and included
    // SELECT DeveloperName FROM EntityDefinition WHERE DeveloperName = 'Individual'
    // need a schema for Individual: urn:salesforce:schemas:extension:individual:1.0
    // and a schema for custom fields to individual urn:salesforce:schemas:extension:individual:orgid
    
    @HttpGet
    global static void doGet() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String[] uriParts = req.requestURI.split('/',0);
        Integer numParts = uriParts.size() - 1;  
        String schemaType = uriParts[numParts];

        // is Individual enabled?
        Boolean isIndividualEnabled = false;
        Integer indCount = [select count() FROM EntityDefinition WHERE DeveloperName = 'Individual' ];
        if (indCount == 1) {
            isIndividualEnabled = true;
        }
        try {

            // do everything if nothing specified
            if (numParts == 3) {
                doUser = true;
                doGroup = true;
                doEntitlement = true;
                doRole = true;
                doEnterprise = true;
                doExternal = true;
                doOrgCustom = true;
                doOther = true;
                doCommunities = true;

                if (isIndividualEnabled) {
                    doIndividual = true;
                    doIndividualExtension = true;
                }
            } else if (schemaType.equalsIgnoreCase('urn:ietf:params:scim:schemas:core:2.0:User') || schemaType.equalsIgnoreCase('User')) {
                doUser = true;
            } else if (schemaType.equalsIgnoreCase('urn:ietf:params:scim:schemas:core:2.0:Group') || schemaType.equalsIgnoreCase('Group')) {
                doGroup = true;
            } else if (schemaType.equalsIgnoreCase('urn:salesforce:schemas:extension:2.0:Entitlement') || schemaType.equalsIgnoreCase('Entitlement')) {
                doEntitlement = true;
            } else if (schemaType.equalsIgnoreCase('urn:salesforce:schemas:extension:2.0:Role') || schemaType.equalsIgnoreCase('Role')) {
                doRole = true;
            } else if (schemaType.equalsIgnoreCase('urn:ietf:params:scim:schemas:extension:enterprise:2.0:User')){
                doEnterprise = true;
            } else if (schemaType.equalsIgnoreCase('urn:salesforce:schemas:extension:2.0:external')){
                doExternal = true;
            } else if (schemaType.equalsIgnoreCase('urn:salesforce:schemas:extension:' + UserInfo.getOrganizationId())){
                doOrgCustom = true;
            } else if (schemaType.equalsIgnoreCase('urn:salesforce:schemas:extension:2.0')){
                doOther = true;
            } else if(schemaType.equalsIgnoreCase('urn:salesforce:schemas:extension:2.0:communities')){
                doCommunities = true;
            } else if((isIndividualEnabled) && (schemaType.equalsIgnoreCase('urn:salesforce:schemas:extension:2.0:Individual'))){
                doIndividual = true;
            } else if((isIndividualEnabled) && (schemaType.equalsIgnoreCase('urn:salesforce:schemas:extension:2.0:Individual:' + UserInfo.getOrganizationId()))){
                doIndividualExtension = true;
            } else {
                throw new ScimException('Invalid Schema specified');
            }
        
            res.addHeader('Content-Type', 'application/json');
            res.statusCode = 200; 
            res.responseBody = serializeSchemas(req.headers.containsKey('X-Prettyprint'));
                
        } catch (ScimException ex) {
            res.addHeader('Content-Type', 'application/json');
            res.statusCode = 400;
            res.responseBody = SCIMError.serializeError(res.statusCode, ex.getMessage(), req.headers.containsKey('X-Prettyprint'));
            return;
        }   

    }  

    private static Blob serializeSchemas(boolean prettyPrint) {

        Integer totalResults = 9;

        if (!doUser) totalResults--;
        if (!doGroup) totalResults--;
        if (!doEntitlement) totalResults--;
        if (!doRole) totalResults--;
        if (!doEnterprise) totalResults--;
        if (!doExternal) totalResults--;
        if (!doOrgCustom) totalResults--;
        if (!doOther) totalResults--;
        if (!doCommunities) totalResults--;        
        
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
    
        if (doUser){
            System.debug('in doUser');
            if (totalResults > 1){
                gen.writeStartObject();
            }

            gen.writeStringField('id', 'urn:ietf:params:scim:schemas:core:2.0:User'); 
            gen.writeStringField('name', 'User');   
            gen.writeStringField('description', 'SCIM core resource for representing users');                            
            gen.writeFieldName('attributes');
            gen.writeStartArray();
                //ID
                gen.writeStartObject();
                    gen.writeStringField('name', 'id');                       
                    gen.writeStringField('type', 'string');   
                    gen.writeBooleanField('multiValued', false); 
                    gen.writeStringField('description', 'Unique identifier for the SCIM resource as defined by the Service Provider.');   
                    gen.writeStringField('mutability', 'readOnly');                             
                    gen.writeBooleanField('required', false);                             
                    gen.writeBooleanField('caseExact', false); 
                    gen.writeStringField('uniqueness', 'server');                             
                gen.writeEndObject();
              //externalId
                gen.writeStartObject();
                    gen.writeStringField('name', 'externalId');                       
                    gen.writeStringField('type', 'string');   
                    gen.writeBooleanField('multiValued', false); 
                    gen.writeStringField('description', 'Unique identifier for the Resource as defined by the Service Consumer');
                    gen.writeStringField('mutability', 'readWrite');                            
                    gen.writeBooleanField('required', false); 
                    gen.writeBooleanField('caseExact', true); 
                gen.writeEndObject();
                //userName
                gen.writeStartObject();
                    gen.writeStringField('name', 'userName');                       
                    gen.writeStringField('type', 'string');   
                    gen.writeBooleanField('multiValued', false); 
                    gen.writeStringField('description', 'Unique identifier for the User'); 
                    gen.writeStringField('mutability', 'readWrite');                            
                    gen.writeBooleanField('required', true); 
                    gen.writeBooleanField('caseExact', false); 
                gen.writeEndObject();
                //name
                gen.writeStartObject();
                    gen.writeStringField('name', 'name');                       
                    gen.writeStringField('type', 'complex');   
                    gen.writeBooleanField('multiValued', false); 
                    gen.writeStringField('description', 'The components of the Users real name');                   
                    gen.writeStringField('mutability', 'readWrite');                            
                    gen.writeBooleanField('required', false);                             
                    gen.writeBooleanField('caseExact', false); 
                    gen.writeFieldName('subAttributes');
                    gen.writeStartArray();
                        gen.writeStartObject();
                            gen.writeStringField('name', 'formatted');                       
                            gen.writeStringField('type', 'string');   
                            gen.writeStringField('description', 'The full name formatted for display');                   
                            gen.writeStringField('mutability', 'readOnly');                             
                            gen.writeBooleanField('required', false);                             
                            gen.writeBooleanField('caseExact', false); 
                        gen.writeEndObject();  
                        gen.writeStartObject();
                            gen.writeStringField('name', 'familyName');                       
                            gen.writeStringField('type', 'string');   
                            gen.writeStringField('description', 'The family name (lastName) of the User');                   
                            gen.writeStringField('mutability', 'readWrite');                            
                            gen.writeBooleanField('required', true);                             
                            gen.writeBooleanField('caseExact', false); 
                        gen.writeEndObject();  
                        gen.writeStartObject();
                            gen.writeStringField('name', 'middleName');                       
                            gen.writeStringField('type', 'string');   
                            gen.writeStringField('description', 'The middleName of the User');                   
                            gen.writeStringField('mutability', 'readWrite');                            
                            gen.writeBooleanField('required', false);                             
                            gen.writeBooleanField('caseExact', false); 
                        gen.writeEndObject();  
                        gen.writeStartObject();
                            gen.writeStringField('name', 'givenName');                       
                            gen.writeStringField('type', 'string');   
                            gen.writeStringField('description', 'The givenName of the user');                   
                            gen.writeStringField('mutability', 'readWrite');                            
                            gen.writeBooleanField('required', false);                             
                            gen.writeBooleanField('caseExact', false); 
                        gen.writeEndObject();   
                        gen.writeStartObject();
                            gen.writeStringField('name', 'honorificPrefix');                       
                            gen.writeStringField('type', 'string');   
                            gen.writeStringField('description', 'The honorific prefix(es) of the User');                   
                            gen.writeStringField('mutability', 'readWrite');                            
                            gen.writeBooleanField('required', false);                             
                            gen.writeBooleanField('caseExact', false); 
                        gen.writeEndObject();  
                        gen.writeStartObject();
                            gen.writeStringField('name', 'honorificSuffix');                       
                            gen.writeStringField('type', 'string');   
                            gen.writeStringField('description', 'The honorific suffix(es) of the User');                   
                            gen.writeStringField('mutability', 'readWrite');                            
                            gen.writeBooleanField('required', false);                             
                            gen.writeBooleanField('caseExact', false); 
                        gen.writeEndObject();  
                    gen.writeEndArray();
                gen.writeEndObject();
                //displayName
                gen.writeStartObject();
                    gen.writeStringField('name', 'displayName');                       
                    gen.writeStringField('type', 'string');   
                    gen.writeBooleanField('multiValued', false); 
                    gen.writeStringField('description', 'The name of the User, suitable for display');                   

                    gen.writeStringField('mutability', 'readOnly');                            
                    gen.writeBooleanField('required', false); 
                    gen.writeBooleanField('caseExact', false); 
                gen.writeEndObject();
                //nickName
                gen.writeStartObject();
                    gen.writeStringField('name', 'nickName');                       
                    gen.writeStringField('type', 'string');   
                    gen.writeBooleanField('multiValued', false); 
                    gen.writeStringField('description', 'The casual way to address the user in real life');                   

                    gen.writeStringField('mutability', 'readWrite');                            
                    gen.writeBooleanField('required', false); 
                    gen.writeBooleanField('caseExact', false); 
                gen.writeEndObject();
                //profileUrl
                gen.writeStartObject();
                    gen.writeStringField('name', 'profileUrl');                       
                    gen.writeStringField('type', 'string');   
                    gen.writeBooleanField('multiValued', false); 
                    gen.writeStringField('description', 'URL to a page representing the User online');                   

                    gen.writeStringField('mutability', 'readWrite');                            
                    gen.writeBooleanField('required', false); 
                    gen.writeBooleanField('caseExact', false); 
                gen.writeEndObject();
                //title
                gen.writeStartObject();
                    gen.writeStringField('name', 'title');                       
                    gen.writeStringField('type', 'string');   
                    gen.writeBooleanField('multiValued', false); 
                    gen.writeStringField('description', 'The Users title, such as Vice President');                   

                    gen.writeStringField('mutability', 'readWrite');                            
                    gen.writeBooleanField('required', false); 
                    gen.writeBooleanField('caseExact', false); 
                gen.writeEndObject();
                //userType
                gen.writeStartObject();
                    gen.writeStringField('name', 'userType');                       
                    gen.writeStringField('type', 'string');   
                    gen.writeBooleanField('multiValued', false); 
                    gen.writeStringField('description', 'The organization-to-user relationship');                   

                    gen.writeStringField('mutability', 'readWrite');                            
                    gen.writeBooleanField('required', false); 
                    gen.writeBooleanField('caseExact', false); 
                gen.writeEndObject();

                //preferredLanguage
                gen.writeStartObject();
                    gen.writeStringField('name', 'preferredLanguage');                       
                    gen.writeStringField('type', 'string');   
                    gen.writeBooleanField('multiValued', false); 
                    gen.writeStringField('description', 'The Users preferred written or spoken language. Generally used for selecting a localized User interface.  Valid values are concatenation of the ISO 639-1 two letter language code, an underscore, and the ISO 3166-1 2 letter country code; e.g., en_US specifies the language English and country US');                   

                    gen.writeStringField('mutability', 'readWrite');                            
                    gen.writeBooleanField('required', true); 
                    gen.writeBooleanField('caseExact', false); 
                gen.writeEndObject();

                //emailEncodingKey
                gen.writeStartObject();
                    gen.writeStringField('name', 'emailEncodingKey');                       
                    gen.writeStringField('type', 'string');   
                    gen.writeBooleanField('multiValued', false); 
                    gen.writeStringField('description', 'The email encoding for the user, such as ISO-8859-1 or UTF-8.');                   

                    gen.writeStringField('mutability', 'reatruedWrite');                            
                    gen.writeBooleanField('required', false); 
                    gen.writeBooleanField('caseExact', false); 
                gen.writeEndObject();

                //locale
                gen.writeStartObject();
                    gen.writeStringField('name', 'locale');                       
                    gen.writeStringField('type', 'string');   
                    gen.writeBooleanField('multiValued', false); 
                    gen.writeStringField('description', 'Used to indicate the Users default location for purposes of localizing items such as currency, date time format, numerical representations, etc. A locale value is a concatenation of the ISO 639-1 two letter language code an underscore, and the ISO 3166-1 2 letter country code; e.g., en_US specifies the language English  and country US');                   

                    gen.writeStringField('mutability', 'readWrite');                            
                    gen.writeBooleanField('required', true); 
                    gen.writeBooleanField('caseExact', false); 
                gen.writeEndObject();
                //timezone
                gen.writeStartObject();
                    gen.writeStringField('name', 'timezone');                       
                    gen.writeStringField('type', 'string');   
                    gen.writeBooleanField('multiValued', false); 
                    gen.writeStringField('description', 'The Users time zone in the Olson timezone database format;  e.g., America/Los_Angeles');                   

                    gen.writeStringField('mutability', 'readWrite');                            
                    gen.writeBooleanField('required', false); 
                    gen.writeBooleanField('caseExact', false); 
                gen.writeEndObject();
                //displayName
                gen.writeStartObject();
                    gen.writeStringField('name', 'active');                       
                    gen.writeStringField('type', 'boolean');   
                    gen.writeBooleanField('multiValued', false); 
                    gen.writeStringField('description', 'A Boolean value indicating the Users status');                   

                    gen.writeStringField('mutability', 'readWrite');                            
                    gen.writeBooleanField('required', false); 
                    gen.writeBooleanField('caseExact', false); 
                gen.writeEndObject();
                //password
                gen.writeStartObject();
                    gen.writeStringField('name', 'password');                       
                    gen.writeStringField('type', 'string');   
                    gen.writeBooleanField('multiValued', false); 
                    gen.writeStringField('description', 'Password of the user');                      
                    gen.writeStringField('mutability', 'writeOnly');                            
                    gen.writeBooleanField('required', false);                             
                gen.writeEndObject();

                //emails
                gen.writeStartObject();
                    gen.writeStringField('name', 'emails');                       
                    gen.writeStringField('type', 'complex');   
                    gen.writeBooleanField('multiValued', true); 
                    gen.writeStringField('description', 'email address for the User');                   

                    gen.writeStringField('mutability', 'readWrite');                            
                    gen.writeBooleanField('required', true);                             
                    gen.writeBooleanField('caseExact', false); 
                    gen.writeFieldName('subAttributes');
                    gen.writeStartArray();
                        gen.writeStartObject();
                            gen.writeStringField('name', 'value');                       
                            gen.writeStringField('type', 'string');   
                            gen.writeStringField('description', 'The value');                   
                            gen.writeStringField('mutability', 'readOnly');                             
                            gen.writeBooleanField('required', false);                             
                            gen.writeBooleanField('caseExact', false); 
                        gen.writeEndObject();  
                        gen.writeStartObject();
                            gen.writeStringField('name', 'primary');                       
                            gen.writeStringField('type', 'boolean');   
                            gen.writeStringField('description', 'Is the primary value');                   
                            gen.writeStringField('mutability', 'readWrite');                            
                            gen.writeBooleanField('required', false);                             
                            gen.writeBooleanField('caseExact', false); 
                        gen.writeEndObject();  
                        gen.writeStartObject();
                            gen.writeStringField('name', 'display');                       
                            gen.writeStringField('type', 'string');   
                            gen.writeStringField('description', 'The value suitable for display');                   
                            gen.writeStringField('mutability', 'readWrite');                            
                            gen.writeBooleanField('required', false);                             
                            gen.writeBooleanField('caseExact', false); 
                        gen.writeEndObject();  
                        gen.writeStartObject();
                            gen.writeStringField('name', 'type');                       
                            gen.writeStringField('type', 'string');   
                            gen.writeStringField('description', 'A label indicating the attributes function; e.g., work or home');                   
                            gen.writeStringField('mutability', 'readWrite');                            
                            gen.writeBooleanField('required', false);                             
                            gen.writeBooleanField('caseExact', false); 
                            gen.writeFieldName('canonicalValues');
                            gen.writeStartArray();
                                gen.writeStartObject();
                                    gen.writeStringField('value', 'work');   
                                gen.writeEndObject();
                            gen.writeEndArray();
                        gen.writeEndObject();   
                    gen.writeEndArray();
                gen.writeEndObject();
                //phoneNumbers
                gen.writeStartObject();
                    gen.writeStringField('name', 'phoneNumbers');                       
                    gen.writeStringField('type', 'complex');   
                    gen.writeBooleanField('multiValued', true); 
                    gen.writeStringField('description', 'Phone numbers for the User');                   
                    gen.writeStringField('mutability', 'readWrite');                            
                    gen.writeBooleanField('required', false);                             
                    gen.writeBooleanField('caseExact', false); 
                    gen.writeFieldName('subAttributes');
                    gen.writeStartArray();
                        gen.writeStartObject();
                            gen.writeStringField('name', 'value');                       
                            gen.writeStringField('type', 'string');   
                            gen.writeStringField('description', 'The value');                   
                            gen.writeStringField('mutability', 'readOnly');                             
                            gen.writeBooleanField('required', false);                             
                            gen.writeBooleanField('caseExact', false); 
                        gen.writeEndObject();  
                        gen.writeStartObject();
                            gen.writeStringField('name', 'primary');                       
                            gen.writeStringField('type', 'boolean');   
                            gen.writeStringField('description', 'Is the primary value');                   
                            gen.writeStringField('mutability', 'readWrite');                            
                            gen.writeBooleanField('required', false);                             
                            gen.writeBooleanField('caseExact', false); 
                        gen.writeEndObject();  
                        gen.writeStartObject();
                            gen.writeStringField('name', 'display');                       
                            gen.writeStringField('type', 'string');   
                            gen.writeStringField('description', 'The value suitable for display');                   
                            gen.writeStringField('mutability', 'readWrite');                            
                            gen.writeBooleanField('required', false);                             
                            gen.writeBooleanField('caseExact', false); 
                        gen.writeEndObject();  
                        gen.writeStartObject();
                            gen.writeStringField('name', 'type');                       
                            gen.writeStringField('type', 'string');   
                            gen.writeStringField('description', 'A label indicating the attributes function; e.g., work or home');                   
                            gen.writeStringField('mutability', 'readWrite');                            
                            gen.writeBooleanField('required', false);                             
                            gen.writeBooleanField('caseExact', false); 
                            gen.writeFieldName('canonicalValues');
                            gen.writeStartArray();
                                gen.writeStartObject();
                                    gen.writeStringField('value', 'work');   
                                gen.writeEndObject();
                                gen.writeStartObject();
                                    gen.writeStringField('value', 'mobile');   
                                gen.writeEndObject();
                                gen.writeStartObject();
                                    gen.writeStringField('value', 'fax');   
                                gen.writeEndObject();
                            gen.writeEndArray();
                        gen.writeEndObject();   
                    gen.writeEndArray();
                gen.writeEndObject();
                //photos
                gen.writeStartObject();
                    gen.writeStringField('name', 'photos');                       
                    gen.writeStringField('type', 'complex');   
                    gen.writeBooleanField('multiValued', true); 
                    gen.writeStringField('description', 'URLs for the users photos');                   

                    gen.writeStringField('mutability', 'readWrite');                            
                    gen.writeBooleanField('required', false);                             
                    gen.writeBooleanField('caseExact', false); 
                    gen.writeFieldName('subAttributes');
                    gen.writeStartArray();
                        gen.writeStartObject();
                            gen.writeStringField('name', 'value');                       
                            gen.writeStringField('type', 'string');   
                            gen.writeStringField('description', 'The value');                   
                            gen.writeStringField('mutability', 'readOnly');                             
                            gen.writeBooleanField('required', false);                             
                            gen.writeBooleanField('caseExact', false); 
                        gen.writeEndObject();  
                        gen.writeStartObject();
                            gen.writeStringField('name', 'primary');                       
                            gen.writeStringField('type', 'boolean');   
                            gen.writeStringField('description', 'Is the primary value');                   
                            gen.writeStringField('mutability', 'readWrite');                            
                            gen.writeBooleanField('required', false);                             
                            gen.writeBooleanField('caseExact', false); 
                        gen.writeEndObject();  
                        gen.writeStartObject();
                            gen.writeStringField('name', 'display');                       
                            gen.writeStringField('type', 'string');   
                            gen.writeStringField('description', 'The value suitable for display');                   
                            gen.writeStringField('mutability', 'readWrite');                            
                            gen.writeBooleanField('required', false);                             
                            gen.writeBooleanField('caseExact', false); 
                        gen.writeEndObject();  
                        gen.writeStartObject();
                            gen.writeStringField('name', 'type');                       
                            gen.writeStringField('type', 'string');   
                            gen.writeStringField('description', 'A label indicating the attributes function; e.g., work or home');                   
                            gen.writeStringField('mutability', 'readWrite');                            
                            gen.writeBooleanField('required', false);                             
                            gen.writeBooleanField('caseExact', false); 
                            gen.writeFieldName('canonicalValues');
                            gen.writeStartArray();
                                gen.writeStartObject();
                                    gen.writeStringField('value', 'photo');   
                                gen.writeEndObject();
                                gen.writeStartObject();
                                    gen.writeStringField('value', 'thumbnail');   
                                gen.writeEndObject();
                            gen.writeEndArray();
                        gen.writeEndObject();   
                    gen.writeEndArray();
                gen.writeEndObject();
                //addresses
                gen.writeStartObject();
                    gen.writeStringField('name', 'addresses');                       
                    gen.writeStringField('type', 'complex');   
                    gen.writeBooleanField('multiValued', true); 
                    gen.writeStringField('description', 'The full mailing address');                   
                    gen.writeStringField('mutability', 'readWrite');                            
                    gen.writeBooleanField('required', false);                             
                    gen.writeBooleanField('caseExact', false); 
                    gen.writeFieldName('subAttributes');
                    gen.writeStartArray();
                        gen.writeStartObject();
                            gen.writeStringField('name', 'value');                       
                            gen.writeStringField('type', 'string');   
                            gen.writeStringField('description', 'The value');                   
                            gen.writeStringField('mutability', 'readOnly');                             
                            gen.writeBooleanField('required', false);                             
                            gen.writeBooleanField('caseExact', false); 
                        gen.writeEndObject();  
                        gen.writeStartObject();
                            gen.writeStringField('name', 'primary');                       
                            gen.writeStringField('type', 'boolean');   
                            gen.writeStringField('description', 'Is the primary value');                   
                            gen.writeStringField('mutability', 'readWrite');                            
                            gen.writeBooleanField('required', false);                             
                            gen.writeBooleanField('caseExact', false); 
                        gen.writeEndObject();  
                        gen.writeStartObject();
                            gen.writeStringField('name', 'display');                       
                            gen.writeStringField('type', 'string');   
                            gen.writeStringField('description', 'The value suitable for display');                   
                            gen.writeStringField('mutability', 'readWrite');                            
                            gen.writeBooleanField('required', false);                             
                            gen.writeBooleanField('caseExact', false); 
                        gen.writeEndObject();  
                        gen.writeStartObject();
                            gen.writeStringField('name', 'type');                       
                            gen.writeStringField('type', 'string');   
                            gen.writeStringField('description', 'A label indicating the attributes function; e.g., work or home');                   
                            gen.writeStringField('mutability', 'readWrite');                            
                            gen.writeBooleanField('required', false);                             
                            gen.writeBooleanField('caseExact', false); 
                            gen.writeFieldName('canonicalValues');
                            gen.writeStartArray();
                                gen.writeStartObject();
                                    gen.writeStringField('value', 'work');   
                                gen.writeEndObject();
                                gen.writeStartObject();
                                    gen.writeStringField('value', 'thumbnail');   
                                gen.writeEndObject();
                            gen.writeEndArray();
                        gen.writeEndObject();   
                        gen.writeStartObject();
                            gen.writeStringField('name', 'formatted');                       
                            gen.writeStringField('type', 'string');   
                            gen.writeStringField('description', 'The value suitable for display');                   
                            gen.writeStringField('mutability', 'readWrite');                            
                            gen.writeBooleanField('required', false);                             
                            gen.writeBooleanField('caseExact', false); 
                        gen.writeEndObject();  
                        gen.writeStartObject();
                            gen.writeStringField('name', 'streetAddress');                       
                            gen.writeStringField('type', 'string');   
                            gen.writeStringField('description', 'The full street address component');                   
                            gen.writeStringField('mutability', 'readWrite');                            
                            gen.writeBooleanField('required', false);                             
                            gen.writeBooleanField('caseExact', false); 
                        gen.writeEndObject();  
                        gen.writeStartObject();
                            gen.writeStringField('name', 'locality');                       
                            gen.writeStringField('type', 'string');   
                            gen.writeStringField('description', 'The city or locality');                   
                            gen.writeStringField('mutability', 'readWrite');                            
                            gen.writeBooleanField('required', false);                             
                            gen.writeBooleanField('caseExact', false); 
                        gen.writeEndObject();  
                        gen.writeStartObject();
                            gen.writeStringField('name', 'region');                       
                            gen.writeStringField('type', 'string');   
                            gen.writeStringField('description', 'The state or region');                   
                            gen.writeStringField('mutability', 'readWrite');                            
                            gen.writeBooleanField('required', false);                             
                            gen.writeBooleanField('caseExact', false); 
                        gen.writeEndObject();  
                        gen.writeStartObject();
                            gen.writeStringField('name', 'postalCode');                       
                            gen.writeStringField('type', 'string');   
                            gen.writeStringField('description', 'The zip or postalCode');                   
                            gen.writeStringField('mutability', 'readWrite');                            
                            gen.writeBooleanField('required', false);                             
                            gen.writeBooleanField('caseExact', false); 
                        gen.writeEndObject();  
                        gen.writeStartObject();
                            gen.writeStringField('name', 'country');                       
                            gen.writeStringField('type', 'string');   
                            gen.writeStringField('description', 'The country');                   
                            gen.writeStringField('mutability', 'readWrite');                            
                            gen.writeBooleanField('required', false);                             
                            gen.writeBooleanField('caseExact', false); 
                        gen.writeEndObject();  
                    gen.writeEndArray();
                gen.writeEndObject();
                gen.writeStartObject();
                    gen.writeStringField('name', 'entitlements');                       
                    gen.writeStringField('type', 'complex');   
                    gen.writeBooleanField('multiValued', true); 
                    gen.writeStringField('description', 'The entiitlements of a user');                   
                    gen.writeStringField('mutability', 'readWrite');                            
                    gen.writeBooleanField('required', true);   
                    gen.writeFieldName('subAttributes');
                    gen.writeStartArray();
                        gen.writeStartObject();
                            gen.writeStringField('name', 'value');                       
                            gen.writeStringField('type', 'string');   
                            gen.writeStringField('description', 'The value');                   
                            gen.writeStringField('mutability', 'readOnly');                             
                            gen.writeBooleanField('required', false);                             
                            gen.writeBooleanField('caseExact', false); 
                        gen.writeEndObject();  
                        gen.writeStartObject();
                            gen.writeStringField('name', 'primary');                       
                            gen.writeStringField('type', 'boolean');   
                            gen.writeStringField('description', 'Is the primary value');                   
                            gen.writeStringField('mutability', 'readWrite');                            
                            gen.writeBooleanField('required', false);                             
                            gen.writeBooleanField('caseExact', false); 
                        gen.writeEndObject();  
                        gen.writeStartObject();
                            gen.writeStringField('name', 'display');                       
                            gen.writeStringField('type', 'string');   
                            gen.writeStringField('description', 'The value suitable for display');                   
                            gen.writeStringField('mutability', 'readWrite');                            
                            gen.writeBooleanField('required', false);                             
                            gen.writeBooleanField('caseExact', false); 
                        gen.writeEndObject();  
                    gen.writeEndArray();                                                      
                gen.writeEndObject();                        
                gen.writeStartObject();
                    gen.writeStringField('name', 'groups');                       
                    gen.writeStringField('type', 'complex');   
                    gen.writeBooleanField('multiValued', true); 
                    gen.writeStringField('description', 'The groups a user belongs to');                   

                    gen.writeStringField('mutability', 'readOnly');                             
                    gen.writeBooleanField('required', true);     
                    gen.writeFieldName('subAttributes');
                    gen.writeStartArray();
                        gen.writeStartObject();
                            gen.writeStringField('name', 'value');                       
                            gen.writeStringField('type', 'string');   
                            gen.writeStringField('description', 'The value');                   
                            gen.writeStringField('mutability', 'readOnly');                             
                            gen.writeBooleanField('required', false);                             
                            gen.writeBooleanField('caseExact', false); 
                        gen.writeEndObject();  
                        gen.writeStartObject();
                            gen.writeStringField('name', 'display');                       
                            gen.writeStringField('type', 'string');   
                            gen.writeStringField('description', 'The value suitable for display');                   
                            gen.writeStringField('mutability', 'readWrite');                            
                            gen.writeBooleanField('required', false);                             
                            gen.writeBooleanField('caseExact', false); 
                        gen.writeEndObject();  
                    gen.writeEndArray();                                                     
                gen.writeEndObject();     
                gen.writeStartObject();
                    gen.writeStringField('name', 'roles');                       
                    gen.writeStringField('type', 'complex');   
                    gen.writeBooleanField('multiValued', false); 
                    gen.writeStringField('description', 'The role a user is assigned to');                   

                    gen.writeStringField('mutability', 'readWrite');                            
                    gen.writeBooleanField('required', true);        
                    gen.writeFieldName('subAttributes');
                    gen.writeStartArray();
                        gen.writeStartObject();
                            gen.writeStringField('name', 'value');                       
                            gen.writeStringField('type', 'string');   
                            gen.writeStringField('description', 'The value');                   
                            gen.writeStringField('mutability', 'readOnly');                             
                            gen.writeBooleanField('required', false);                             
                            gen.writeBooleanField('caseExact', false); 
                        gen.writeEndObject();  
                        gen.writeStartObject();
                            gen.writeStringField('name', 'display');                       
                            gen.writeStringField('type', 'string');   
                            gen.writeStringField('description', 'The value suitable for display');                   
                            gen.writeStringField('mutability', 'readWrite');                            
                            gen.writeBooleanField('required', false);                             
                            gen.writeBooleanField('caseExact', false); 
                        gen.writeEndObject();  
                    gen.writeEndArray();                                                  
                gen.writeEndObject();  

            gen.writeEndArray();
            gen.writeFieldName('meta');
                gen.writeStartObject();
                    gen.writeStringField('resourceType', 'Schema');
                    gen.writeStringField('location', base + path + 'Schemas/urn:ietf:params:scim:schemas:core:2.0:User');
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
            gen.writeStringField('description', 'SCIM core resource for representing groups');               
            gen.writeStringField('schema', 'urn:ietf:params:scim:schemas:core:2.0:Group');               
            gen.writeStringField('endpoint', '/Groups');   
            gen.writeFieldName('attributes');
            gen.writeStartArray(); 
                gen.writeStartObject();
                    gen.writeStringField('name', 'id');                       
                    gen.writeStringField('type', 'string');   
                    gen.writeBooleanField('multiValued', false); 
                    gen.writeStringField('description', 'Unique identifier for the SCIM resource as defined by the Service Provider.');                   

                    gen.writeStringField('mutability', 'readOnly');                             
                    gen.writeBooleanField('required', true);                             
                    gen.writeBooleanField('caseExact', false); 
                gen.writeEndObject();     
                //displayName
                gen.writeStartObject();
                    gen.writeStringField('name', 'displayName');                       
                    gen.writeStringField('type', 'string');   
                    gen.writeBooleanField('multiValued', false); 
                    gen.writeStringField('description', 'The name of the User, suitable for display');                   

                    gen.writeStringField('mutability', 'readWrite');                            
                    gen.writeBooleanField('required', false); 
                    gen.writeBooleanField('caseExact', false); 
                gen.writeEndObject();
                //members
                gen.writeStartObject();
                    gen.writeStringField('name', 'members');                       
                    gen.writeStringField('type', 'complex');   
                    gen.writeBooleanField('multiValued', true); 
                    gen.writeStringField('description', 'The members of the group');                   

                    gen.writeStringField('mutability', 'readWrite');                            
                    gen.writeBooleanField('required', false);     
                    gen.writeFieldName('subAttributes');
                    gen.writeStartArray();
                        gen.writeStartObject();
                            gen.writeStringField('name', 'value');                       
                            gen.writeStringField('type', 'string');   
                            gen.writeStringField('description', 'The id of the member');                   
                            gen.writeStringField('mutability', 'readWrite');                            
                            gen.writeBooleanField('required', false);                             
                            gen.writeBooleanField('caseExact', false); 
                        gen.writeEndObject();  
                        gen.writeStartObject();
                            gen.writeStringField('name', 'type');                       
                            gen.writeStringField('type', 'string');   
                            gen.writeStringField('description', 'The type of membership of the member in the group');                   
                            gen.writeStringField('mutability', 'readOnly');                             
                            gen.writeBooleanField('required', true);                             
                            gen.writeBooleanField('caseExact', false); 
                        gen.writeEndObject();  
                    gen.writeEndArray();                                                     
                gen.writeEndObject();
            gen.writeEndArray();
                gen.writeFieldName('meta');
                    gen.writeStartObject();
                        gen.writeStringField('resourceType', 'Schema');
                        gen.writeStringField('location', base + path + 'Schemas/Groupsurn:ietf:params:scim:schemas:core:2.0:Group');
                    gen.writeEndObject();
            if (totalResults > 1){
                    gen.writeEndObject();  
            }
            }
        
        if (doEntitlement){
            if (totalResults > 1){
                gen.writeStartObject();
            }
            gen.writeStringField('id', 'urn:salesforce:schemas:extension:2.0:Entitlement'); 
                gen.writeStringField('name', 'Entitlement');   
                gen.writeStringField('description', 'Schema resource for representing entitlements');               
                gen.writeStringField('schema', 'urn:salesforce:schemas:extension:2.0:Entitlement');               
                gen.writeStringField('endpoint', '/Entitlements');   
                gen.writeFieldName('attributes');
                gen.writeStartArray(); 
                    gen.writeStartObject();
                        gen.writeStringField('name', 'id');                       
                        gen.writeStringField('type', 'string');   
                        gen.writeBooleanField('multiValued', false); 
                        gen.writeStringField('description', 'Unique identifier for the SCIM resource as defined by the Service Provider.');                   
                        gen.writeStringField('mutability', 'readOnly');                             
                        gen.writeBooleanField('required', true);                             
                        gen.writeBooleanField('caseExact', false); 
                    gen.writeEndObject();     
                    //displayName
                    gen.writeStartObject();
                        gen.writeStringField('name', 'displayName');                       
                        gen.writeStringField('type', 'string');   
                        gen.writeBooleanField('multiValued', false); 
                        gen.writeStringField('description', 'The name of the Entitlement, suitable for display');                   
                        gen.writeStringField('mutability', 'readOnly');                            
                        gen.writeBooleanField('required', false); 
                        gen.writeBooleanField('caseExact', false); 
                    gen.writeEndObject();
                    gen.writeStartObject();
                        gen.writeStringField('name', 'type');                       
                        gen.writeStringField('type', 'string');   
                        gen.writeBooleanField('multiValued', false); 
                        gen.writeStringField('description', 'The type of entitlment');                   
                        gen.writeStringField('mutability', 'readOnly');                            
                        gen.writeBooleanField('required', false); 
                        gen.writeBooleanField('caseExact', false); 
                    gen.writeEndObject();
                    gen.writeStartObject();
                        gen.writeStringField('name', 'members');                       
                        gen.writeStringField('type', 'complex');   
                        gen.writeBooleanField('multiValued', true); 
                        gen.writeStringField('description', 'The members associated with the entitlement');                   
    
                        gen.writeStringField('mutability', 'readWrite');                            
                        gen.writeBooleanField('required', false);     
                        gen.writeFieldName('subAttributes');
                        gen.writeStartArray();
                            gen.writeStartObject();
                                gen.writeStringField('name', 'value');                       
                                gen.writeStringField('type', 'string');   
                                gen.writeStringField('description', 'The id of the member');                   
                                gen.writeStringField('mutability', 'readWrite');                            
                                gen.writeBooleanField('required', false);                             
                                gen.writeBooleanField('caseExact', false); 
                            gen.writeEndObject();  
                            gen.writeStartObject();
                                gen.writeStringField('name', 'display');                       
                                gen.writeStringField('type', 'string');   
                                gen.writeStringField('description', 'The name of the member');                   
                                gen.writeStringField('mutability', 'readOnly');                             
                                gen.writeBooleanField('required', true);                             
                                gen.writeBooleanField('caseExact', false); 
                            gen.writeEndObject();  
                        gen.writeEndArray();                                                     
                    gen.writeEndObject();
                gen.writeEndArray();
                gen.writeFieldName('meta');
                    gen.writeStartObject();
                        gen.writeStringField('resourceType', 'Schema');
                        gen.writeStringField('location', base + path + 'Schemas/urn:salesforce:schemas:extension:2.0:Entitlement');
                    gen.writeEndObject();
    
            if (totalResults > 1){
                    gen.writeEndObject();  
            }
                                                
        }   
        if (doRole){
            if (totalResults > 1){
                gen.writeStartObject();
            }

            gen.writeStringField('id', 'urn:salesforce:schemas:extension:2.0:Role'); 
            gen.writeStringField('name', 'Role');   
            gen.writeStringField('description', 'Schema resource for representing roles');               
            gen.writeStringField('schema', 'urn:salesforce:schemas:extension:2.0:Role');               
            gen.writeStringField('endpoint', '/Roles');   
            gen.writeFieldName('attributes');
            gen.writeStartArray(); 
                gen.writeStartObject();
                    gen.writeStringField('name', 'id');                       
                    gen.writeStringField('type', 'string');   
                    gen.writeBooleanField('multiValued', false); 
                    gen.writeStringField('description', 'Unique identifier for the SCIM resource as defined by the Service Provider.');                   
                    gen.writeStringField('mutability', 'readOnly');                             
                    gen.writeBooleanField('required', true);                             
                    gen.writeBooleanField('caseExact', false); 
                gen.writeEndObject();     
                //displayName
                gen.writeStartObject();
                    gen.writeStringField('name', 'displayName');                       
                    gen.writeStringField('type', 'string');   
                    gen.writeBooleanField('multiValued', false); 
                    gen.writeStringField('description', 'The name of the Role, suitable for display');                   
                    gen.writeStringField('mutability', 'readOnly');                            
                    gen.writeBooleanField('required', false); 
                    gen.writeBooleanField('caseExact', false); 
                gen.writeEndObject();
                gen.writeStartObject();
                    gen.writeStringField('name', 'members');                       
                    gen.writeStringField('type', 'complex');   
                    gen.writeBooleanField('multiValued', true); 
                    gen.writeStringField('description', 'The members associated with the entitlement');                   
                    gen.writeStringField('mutability', 'readOnly');                            
                    gen.writeBooleanField('required', false);     
                    gen.writeFieldName('subAttributes');
                    gen.writeStartArray();
                        gen.writeStartObject();
                            gen.writeStringField('name', 'value');                       
                            gen.writeStringField('type', 'string');   
                            gen.writeStringField('description', 'The id of the member');                   
                            gen.writeStringField('mutability', 'readOnly');                            
                            gen.writeBooleanField('required', false);                             
                            gen.writeBooleanField('caseExact', false); 
                        gen.writeEndObject();  
                    gen.writeEndArray();                                                     
                gen.writeEndObject();
            gen.writeEndArray();
            gen.writeFieldName('meta');
                gen.writeStartObject();
                    gen.writeStringField('location', base + path + 'Schemas/urn:salesforce:schemas:extension:2.0:Role');
                    gen.writeStringField('resourceType', 'Schema');
                gen.writeEndObject();

            if (totalResults > 1){
                    gen.writeEndObject();  
            }
                                           
        }          
        if (doEnterprise) {
            if (totalResults > 1){
                gen.writeStartObject();
            }
                gen.writeStringField('id', 'urn:ietf:params:scim:schemas:extension:enterprise:2.0:User'); 
                gen.writeStringField('name', 'Enterprise User');   
                gen.writeStringField('description', 'Schema resource for representing Enterprise User');               
                gen.writeStringField('schema', 'urn:ietf:params:scim:schemas:extension:enterprise:2.0:User');               
                gen.writeStringField('endpoint', '/Users');   
                gen.writeFieldName('attributes');
                gen.writeStartArray();             
                     gen.writeStartObject();
                        gen.writeStringField('name', 'organization');                       
                        gen.writeStringField('type', 'string');   
                        gen.writeStringField('description', 'The organization the user belongs to');                  
                        gen.writeStringField('mutability', 'readOnly');                             
                        gen.writeBooleanField('required', true);                             
                        gen.writeBooleanField('caseExact', false); 
                    gen.writeEndObject();
                    gen.writeStartObject();
                        gen.writeStringField('name', 'employeeNumber');                       
                        gen.writeStringField('type', 'string');   
                        gen.writeStringField('description', 'The employee number of the user');             
                        gen.writeStringField('mutability', 'readWrite');                            
                        gen.writeBooleanField('required', false);                             
                        gen.writeBooleanField('caseExact', false); 
                    gen.writeEndObject();
                    gen.writeStartObject();
                        gen.writeStringField('name', 'division');                       
                        gen.writeStringField('type', 'string');   
                        gen.writeStringField('description', 'The division of the user');             
                        gen.writeStringField('mutability', 'readWrite');                            
                        gen.writeBooleanField('required', false);                             
                        gen.writeBooleanField('caseExact', false); 
                    gen.writeEndObject();  
                    gen.writeStartObject();
                        gen.writeStringField('name', 'department');                       
                        gen.writeStringField('type', 'string');   
                        gen.writeStringField('description', 'The department of the user');             
                        gen.writeStringField('mutability', 'readWrite');                            
                        gen.writeBooleanField('required', false);                             
                        gen.writeBooleanField('caseExact', false); 
                    gen.writeEndObject();
                    gen.writeStartObject();
                        gen.writeStringField('name', 'manager');                       
                        gen.writeStringField('type', 'complex');   
                        gen.writeStringField('description', 'The manager of the user');             
                        gen.writeStringField('mutability', 'readWrite');                            
                        gen.writeBooleanField('required', false);                             
                        gen.writeBooleanField('caseExact', false); 
                        gen.writeFieldName('subAttributes');
                        gen.writeStartArray();
                             gen.writeStartObject();
                                gen.writeStringField('name', 'value');                       
                                gen.writeStringField('type', 'string');   
                                gen.writeStringField('description', 'The id of the manager user');                  
                                gen.writeStringField('mutability', 'readWrite');                            
                                gen.writeBooleanField('required', false);                             
                                gen.writeBooleanField('caseExact', false); 
                            gen.writeEndObject();
                            gen.writeStartObject();
                                gen.writeStringField('name', 'displayName');                       
                                gen.writeStringField('type', 'string');   
                                gen.writeStringField('description', 'The display name of the manager user');             
                                gen.writeStringField('mutability', 'readOnly');                             
                                gen.writeBooleanField('required', false);                             
                                gen.writeBooleanField('caseExact', false); 
                            gen.writeEndObject();
                        gen.writeEndArray();
                    gen.writeEndObject();
                    gen.writeStartObject();
                        gen.writeStringField('name', 'delegatedApprover');                       
                        gen.writeStringField('type', 'complex');   
                        gen.writeStringField('description', 'The delegated approver of the user');             
                        gen.writeStringField('mutability', 'readWrite');                            
                        gen.writeBooleanField('required', false);                             
                        gen.writeBooleanField('caseExact', false); 
                        gen.writeFieldName('subAttributes');
                        gen.writeStartArray();
                             gen.writeStartObject();
                                gen.writeStringField('name', 'delegatedApproverId');                       
                                gen.writeStringField('type', 'string');   
                                gen.writeStringField('description', 'The id of the delegated approver user');                  
                                gen.writeStringField('mutability', 'readWrite');                            
                                gen.writeBooleanField('required', false);                             
                                gen.writeBooleanField('caseExact', false); 
                            gen.writeEndObject();
                            gen.writeStartObject();
                                gen.writeStringField('name', 'displayName');                       
                                gen.writeStringField('type', 'string');   
                                gen.writeStringField('description', 'The display name of the delegated approver user');             
                                gen.writeStringField('mutability', 'readOnly');                             
                                gen.writeBooleanField('required', false);                             
                                gen.writeBooleanField('caseExact', false); 
                            gen.writeEndObject();
                        gen.writeEndArray();
                    gen.writeEndObject();                                                                                                                                                                               
            
            gen.writeEndArray();
            gen.writeFieldName('meta');
                gen.writeStartObject();
                    gen.writeStringField('location', base + path + 'Schemas/urn:ietf:params:scim:schemas:extension:enterprise:2.0:User');
                    gen.writeStringField('resourceType', 'Schema');
                gen.writeEndObject();

            if (totalResults > 1){
                    gen.writeEndObject();  
            }
                                                  

        }
        if (doExternal) {
            if (totalResults > 1){
                gen.writeStartObject();
            }

                gen.writeStringField('id', 'urn:salesforce:schemas:extension:2.0:external');                       
                gen.writeStringField('name', 'urn:salesforce:schemas:extension:2.0:external');                       
                gen.writeStringField('type', 'complex');   
                gen.writeStringField('description', 'Salesforce external users extensions');                   
                gen.writeStringField('schema', 'urn:salesforce:schemas:extension:2.0:external');
                gen.writeStringField('endpoint', '/Users');   
                gen.writeFieldName('attributes');
                gen.writeStartArray();
                     gen.writeStartObject();
                        gen.writeStringField('name', 'accountId');                       
                        gen.writeStringField('type', 'string');   
                        gen.writeStringField('description', 'The account the external user is associated to');                  
                        gen.writeStringField('mutability', 'readOnly');                             
                        gen.writeBooleanField('required', true);                             
                        gen.writeBooleanField('caseExact', false); 
                    gen.writeEndObject();
                    gen.writeStartObject();
                        gen.writeStringField('name', 'contactId');                       
                        gen.writeStringField('type', 'string');   
                        gen.writeStringField('description', 'The contact record the external user is associated to');             
                        gen.writeStringField('mutability', 'readWrite');                            
                        gen.writeBooleanField('required', false);                             
                        gen.writeBooleanField('caseExact', false); 
                    gen.writeEndObject();
                    gen.writeStartObject();
                        gen.writeStringField('name', 'community');                       
                        gen.writeStringField('type', 'string');   
                        gen.writeStringField('description', 'The network (Community) the user is a member of');             
                        gen.writeStringField('mutability', 'readOnly');  
                        gen.writeBooleanField('multiValued', true); 
                        gen.writeBooleanField('required', false);                             
                        gen.writeBooleanField('caseExact', false); 
                    gen.writeEndObject();
                gen.writeEndArray();                                                        
            
                gen.writeFieldName('meta');
                gen.writeStartObject();
                    gen.writeStringField('location', base + path + 'Schemas/urn:salesforce:schemas:extension:2.0:external');
                    gen.writeStringField('resourceType', 'Schema');
                gen.writeEndObject();
            
            if (totalResults > 1){
                    gen.writeEndObject();  
            }
        }           
        if (doCommunities) {
            if (totalResults > 1){
                gen.writeStartObject();
            }

                gen.writeStringField('id', 'urn:salesforce:schemas:extension:2.0:communities');
                gen.writeStringField('name', 'urn:salesforce:schemas:extension:2.0:communities');                       
                gen.writeStringField('type', 'complex');   
                gen.writeStringField('description', 'Salesforce Communities extensions');                   
                gen.writeStringField('schema', 'urn:salesforce:schemas:extension:2.0:communities');
                gen.writeStringField('endpoint', '/Users');   
                gen.writeFieldName('attributes');
                gen.writeStartArray();
                    gen.writeStartObject();
                        gen.writeStringField('name', 'networkId');                       
                        gen.writeStringField('type', 'string');   
                        gen.writeStringField('description', 'The Id of the network (Community) the user is a member of');             
                        gen.writeStringField('mutability', 'readOnly');  
                        gen.writeBooleanField('multiValued', false); 
                        gen.writeBooleanField('required', false);                             
                        gen.writeBooleanField('caseExact', false); 
                    gen.writeEndObject();
                    gen.writeStartObject();
                        gen.writeStringField('name', 'networkName');                       
                        gen.writeStringField('type', 'string');   
                        gen.writeStringField('description', 'The Name of the network (Community) the user is a member of');             
                        gen.writeStringField('mutability', 'readOnly');  
                        gen.writeBooleanField('multiValued', false); 
                        gen.writeBooleanField('required', false);                             
                        gen.writeBooleanField('caseExact', false); 
                    gen.writeEndObject();
            gen.writeEndArray();                                                        
            
                gen.writeFieldName('meta');
                gen.writeStartObject();
                    gen.writeStringField('location', base + path + 'Schemas/urn:salesforce:schemas:extension:2.0:communities');
                    gen.writeStringField('resourceType', 'Schema');
                gen.writeEndObject();
            
            if (totalResults > 1){
                    gen.writeEndObject();  
            }
        }
        if (doOrgCustom){
            if (totalResults > 1){
                gen.writeStartObject();
            }

                    gen.writeStringField('id', 'urn:salesforce:schemas:extension:' + UserInfo.getOrganizationId());                       
                    gen.writeStringField('name', 'urn:salesforce:schemas:extension:' + UserInfo.getOrganizationId());                       
                    gen.writeStringField('type', 'complex');   
                    gen.writeStringField('description', 'All extension custom fields for a user in the organization');                   
                    gen.writeStringField('schema', 'urn:salesforce:schemas:extension:' + UserInfo.getOrganizationId());    
                    gen.writeStringField('endpoint', '/Users');   
                    gen.writeFieldName('attributes');
                    gen.writeStartArray();
                        Map<String, Schema.SObjectField> r = Schema.sObjectType.User.fields.getMap();
                        for (String key : r.keySet()) {
                            SObjectField thisField = r.get(key);
                            DescribeFieldResult thisDescribeResult = thisField.getDescribe();
                            if (thisDescribeResult.isCustom()) {
                                 gen.writeStartObject();
                                    gen.writeStringField('name', thisDescribeResult.getName());                       
                                    gen.writeStringField('type', getScimTypeFromSoapType(thisDescribeResult.getSOAPType()));   
                                    gen.writeStringField('description', thisDescribeResult.getInlineHelpText() + '');       // Description somehow not available from the sobject api.            
                                    gen.writeBooleanField('readOnly', !thisDescribeResult.isUpdateable());                             
                                    gen.writeBooleanField('required', !thisDescribeResult.isNillable());                             
                                    gen.writeBooleanField('caseExact', thisDescribeResult.isCaseSensitive()); 
                                gen.writeEndObject();         
                            }
                        }
                    gen.writeEndArray();
                    gen.writeFieldName('meta');
                        gen.writeStartObject();
                            gen.writeStringField('location', base + path + 'urn:salesforce:schemas:extension:' + UserInfo.getOrganizationId());
                            gen.writeStringField('resourceType', 'Schema');
                        gen.writeEndObject();            
            if (totalResults > 1){
                    gen.writeEndObject();  
            }                      
        }        
        if (doOther) {
            if (totalResults > 1){
                gen.writeStartObject();
            }

                gen.writeStringField('id', 'urn:salesforce:schemas:extension:2.0');                       
                gen.writeStringField('name', 'urn:salesforce:schemas:extension:2.0');                       
                gen.writeStringField('type', 'complex');   
                gen.writeStringField('description', 'Salesforce User extensions');                   
                gen.writeStringField('schema', 'urn:salesforce:schemas:extension:2.0');
                gen.writeStringField('endpoint', '/Individuals');   
                gen.writeFieldName('attributes');
                gen.writeStartArray();
                     gen.writeStartObject();
                        gen.writeStringField('name', 'alias');                       
                        gen.writeStringField('type', 'string');   
                        gen.writeStringField('description', '8 character nickanme');                  
                        gen.writeStringField('mutability', 'readWrite');                             
                        gen.writeBooleanField('required', false); // a bit of a cheat                             
                        gen.writeBooleanField('caseExact', false); 
                    gen.writeEndObject();
                gen.writeEndArray();                                                        
            
                gen.writeFieldName('meta');
                gen.writeStartObject();
                    gen.writeStringField('location', base + path + 'Schemas/urn:salesforce:schemas:extension:2.0');
                    gen.writeStringField('resourceType', 'Schema');
                gen.writeEndObject();
            
            if (totalResults > 1){
                    gen.writeEndObject();  
            }                                                                                              
        }
        if (doIndividual){
            if (totalResults > 1){
                gen.writeStartObject();
            }
            gen.writeStringField('id', 'urn:salesforce:schemas:extension:2.0:individual'); 
            gen.writeStringField('name', 'Individual');   
            gen.writeStringField('description', 'Salesforce resource for representing Individual recirds');               
            gen.writeStringField('schema', 'urn:salesforce:schemas:extension:2.0:individual');               
            gen.writeStringField('endpoint', '/Individuals');   
            gen.writeFieldName('attributes');
            gen.writeStartArray(); 
                gen.writeStartObject();
                    gen.writeStringField('name', 'id');                       
                    gen.writeStringField('type', 'string');   
                    gen.writeBooleanField('multiValued', false); 
                    gen.writeStringField('description', 'Unique identifier for the SCIM resource as defined by the Service Provider.');                               
                    gen.writeStringField('mutability', 'readOnly');                             
                    gen.writeBooleanField('required', false);                             
                    gen.writeBooleanField('caseExact', false); 
                    gen.writeStringField('uniqueness', 'server');  
                gen.writeEndObject();  

                //name
                gen.writeStartObject();
                    gen.writeStringField('name', 'name');                       
                    gen.writeStringField('type', 'complex');   
                    gen.writeBooleanField('multiValued', false); 
                    gen.writeStringField('description', 'The components of the Individual\'s real name');                   
                    gen.writeStringField('mutability', 'readWrite');                            
                    gen.writeBooleanField('required', false);                             
                    gen.writeBooleanField('caseExact', false); 
                    gen.writeFieldName('subAttributes');
                    gen.writeStartArray();
                        gen.writeStartObject();
                            gen.writeStringField('name', 'familyName');                       
                            gen.writeStringField('type', 'string');   
                            gen.writeStringField('description', 'The family name (lastName) of the Individual');                   
                            gen.writeStringField('mutability', 'readWrite');                            
                            gen.writeBooleanField('required', true);                             
                            gen.writeBooleanField('caseExact', false); 
                        gen.writeEndObject();  
                        gen.writeStartObject();
                            gen.writeStringField('name', 'givenName');                       
                            gen.writeStringField('type', 'string');   
                            gen.writeStringField('description', 'The first name of the Individual');                   
                            gen.writeStringField('mutability', 'readWrite');                            
                            gen.writeBooleanField('required', false);                             
                            gen.writeBooleanField('caseExact', false); 
                        gen.writeEndObject();   
                        gen.writeStartObject();
                            gen.writeStringField('name', 'honorificPrefix');                       
                            gen.writeStringField('type', 'string');   
                            gen.writeStringField('description', 'The honorific prefix of the Individual e.g. Salutation');
                            gen.writeStringField('mutability', 'readWrite');                            
                            gen.writeBooleanField('required', false);                             
                            gen.writeBooleanField('caseExact', false); 
                        gen.writeEndObject();  
                    gen.writeEndArray();
                gen.writeEndObject();

            // birthdate
                gen.writeStartObject();
                    gen.writeStringField('name', 'birthDate');                       
                    gen.writeStringField('type', 'dateTime');   
                    gen.writeBooleanField('multiValued', false); 
                    gen.writeStringField('description', 'Individual\'s birth date');                               
                    gen.writeStringField('mutability', 'readWrite');                             
                    gen.writeBooleanField('required', false);                             
                gen.writeEndObject();                          

            // CanStorePiiElsewhere
                gen.writeStartObject();
                    gen.writeStringField('name', 'canStorePiiElsewhere');                       
                    gen.writeStringField('type', 'boolean');   
                    gen.writeBooleanField('multiValued', false); 
                    gen.writeStringField('description', 'Consent to store PII elsewhere');                               
                    gen.writeStringField('mutability', 'readWrite');                             
                    gen.writeBooleanField('required', false);                             
                gen.writeEndObject();                          

            // HasOptedOutGeoTracking
                gen.writeStartObject();
                    gen.writeStringField('name', 'hasOptedOutGeoTracking');                       
                    gen.writeStringField('type', 'boolean');   
                    gen.writeBooleanField('multiValued', false); 
                    gen.writeStringField('description', 'Has the data subject opted out of geo-tracking a.k.a. block geo-tracking');
                    gen.writeStringField('mutability', 'readWrite');                             
                    gen.writeBooleanField('required', false);                                                 
                gen.writeEndObject();  

            // HasOptedOutProcessing
                gen.writeStartObject();
                    gen.writeStringField('name', 'hasOptedOutProcessing');                       
                    gen.writeStringField('type', 'boolean');   
                    gen.writeBooleanField('multiValued', false); 
                    gen.writeStringField('description', 'Has the data subject opted out of data processing a.k.a. do not process');
                    gen.writeStringField('mutability', 'readWrite');                             
                    gen.writeBooleanField('required', false);                                                 
                gen.writeEndObject();  

            // HasOptedOutProfiling
                gen.writeStartObject();
                    gen.writeStringField('name', 'hasOptedOutProfiling');                       
                    gen.writeStringField('type', 'boolean');   
                    gen.writeBooleanField('multiValued', false); 
                    gen.writeStringField('description', 'Has the data subject opted out of profiling a.k.a. do not profile');
                    gen.writeStringField('mutability', 'readWrite');                             
                    gen.writeBooleanField('required', false);                                                 
                gen.writeEndObject();  

            // HasOptedOutSolicit
                gen.writeStartObject();
                    gen.writeStringField('name', 'hasOptedOutSolicit');                       
                    gen.writeStringField('type', 'boolean');   
                    gen.writeBooleanField('multiValued', false); 
                    gen.writeStringField('description', 'Has the data subject opted out of solicitation a.k.a do not market');
                    gen.writeStringField('mutability', 'readWrite');                             
                    gen.writeBooleanField('required', false);                                                 
                gen.writeEndObject();  
  
            // HasOptedOutTracking
                gen.writeStartObject();
                    gen.writeStringField('name', 'hasOptedOutTracking');                       
                    gen.writeStringField('type', 'boolean');   
                    gen.writeBooleanField('multiValued', false); 
                    gen.writeStringField('description', 'Has the data subject opted out of tracking a.k.a do not track');
                    gen.writeStringField('mutability', 'readWrite');                             
                    gen.writeBooleanField('required', false);                                                 
                gen.writeEndObject();  

            // IndividualsAge
                gen.writeStartObject();
                    gen.writeStringField('name', 'individualsAge');                       
                    gen.writeStringField('type', 'string');   
                    gen.writeBooleanField('multiValued', false); 
                    gen.writeStringField('description', 'Data subject\'s age range (via picklist)');                               
                    gen.writeStringField('mutability', 'readWrite');                             
                    gen.writeBooleanField('required', false);                             
                    gen.writeBooleanField('caseExact', false); 
                gen.writeEndObject();  
  
            // SendIndividualData
                gen.writeStartObject();
                    gen.writeStringField('name', 'sendIndividualData');                       
                    gen.writeStringField('type', 'boolean');   
                    gen.writeBooleanField('multiValued', false); 
                    gen.writeStringField('description', 'Export Individual\'s data');
                    gen.writeStringField('mutability', 'readWrite');                             
                    gen.writeBooleanField('required', false);                                                 
                gen.writeEndObject();  
  
            // ShouldForget
                gen.writeStartObject();
                    gen.writeStringField('name', 'shouldForget');                       
                    gen.writeStringField('type', 'boolean');   
                    gen.writeBooleanField('multiValued', false); 
                    gen.writeStringField('description', 'Forget this Individual');
                    gen.writeStringField('mutability', 'readWrite');                             
                    gen.writeBooleanField('required', false);                                                 
                gen.writeEndObject();  

            gen.writeEndArray();
            gen.writeFieldName('meta');
                        gen.writeStartObject();
                            gen.writeStringField('location', base + path + 'Schemas/urn:salesforce:schemas:extension:2.0individual');
                            gen.writeStringField('resourceType', 'Schema');
                        gen.writeEndObject();            
            if (totalResults > 1){
                    gen.writeEndObject();  
            }
        }
        if (doIndividualExtension){
            if (totalResults > 1){
                gen.writeStartObject();
            }

                    gen.writeStringField('id', 'urn:salesforce:schemas:extension:2.0:individual:' + UserInfo.getOrganizationId());
                    gen.writeStringField('name', 'Extensions to Individual');
                    gen.writeStringField('type', 'complex');
                    gen.writeStringField('description', 'All extension custom fields for an Individual in the organization');
                    gen.writeStringField('schema', 'urn:salesforce:schemas:extension:2.0:individual:' + UserInfo.getOrganizationId());
                    gen.writeStringField('endpoint', '/Individuals');
                    gen.writeFieldName('attributes');
                    gen.writeStartArray();
                        Map<String, Schema.SObjectField> r = Schema.sObjectType.Individual.fields.getMap();
                        for (String key : r.keySet()) {
                            SObjectField thisField = r.get(key);
                            DescribeFieldResult thisDescribeResult = thisField.getDescribe();
                            if (thisDescribeResult.isCustom()) {
                                 gen.writeStartObject();
                                    gen.writeStringField('name', thisDescribeResult.getName());                       
                                    gen.writeStringField('type', getScimTypeFromSoapType(thisDescribeResult.getSOAPType()));   
                                    gen.writeStringField('description', thisDescribeResult.getInlineHelpText() + '');       // Description somehow not available from the sobject api.            
                                    gen.writeBooleanField('readOnly', !thisDescribeResult.isUpdateable());                             
                                    gen.writeBooleanField('required', !thisDescribeResult.isNillable());                             
                                    gen.writeBooleanField('caseExact', thisDescribeResult.isCaseSensitive()); 
                                gen.writeEndObject();         
                            }
                        }
                    gen.writeEndArray();
                    gen.writeFieldName('meta');
                        gen.writeStartObject();
                            gen.writeStringField('location', base + path + 'Schemas/urn:salesforce:schemas:extension:2.0:individual:' + UserInfo.getOrganizationId());
                            gen.writeStringField('resourceType', 'Schema');
                        gen.writeEndObject();            
            if (totalResults > 1){
                    gen.writeEndObject();  
            }                      
        }        

        if (totalResults > 1){
            gen.writeEndArray();                        
            gen.writeFieldName('meta');
                gen.writeStartObject();
                    gen.writeStringField('location', base + path + 'Schemas');
                    gen.writeStringField('resourceType', 'ListResponse');
                gen.writeEndObject();
        }

            gen.writeEndObject();  
 
        return Blob.valueOf(gen.getAsString());
    }
    
    private static String getScimTypeFromSoapType(Schema.SOAPType soapType) {
        if (soapType == Schema.SOAPType.anytype) {
            return 'Complex';
        } 
        else if (soapType == Schema.SOAPType.base64binary) {
            return 'Binary';
        }
        else if (soapType == Schema.SOAPType.Boolean) {
            return 'Boolean';
        }
        else if (soapType == Schema.SOAPType.Date) {
            return 'DateTime';
        }
        else if (soapType == Schema.SOAPType.DateTime) {
            return 'DateTime';        
        }
        else if (soapType == Schema.SOAPType.Double) {
            return 'Decimal';        
        }
        else if (soapType == Schema.SOAPType.ID) {
            return 'String';        
        }
        else if (soapType == Schema.SOAPType.Integer) {
            return 'Integer';        
        }
        else if (soapType == Schema.SOAPType.String) {
            return 'String';          
        }
        else if (soapType == Schema.SOAPType.Time) {
            return 'DateTime';        
        }
        return 'Unsupported';
    }
}