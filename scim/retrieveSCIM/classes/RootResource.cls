@RestResource(urlMapping='/scim/v2/*')
global class RootResource {
    
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
            gen.writeStringField('Users', '/services/apexrest/scim/v2/Users');                       
            gen.writeStringField('Groups', '/services/apexrest/scim/v2/Groups');
            gen.writeStringField('Roles', '/services/apexrest/scim/v2/Roles');        
            gen.writeStringField('Entitlements', '/services/apexrest/scim/v2/Entitlements');
            gen.writeStringField('Users', '/services/apexrest/scim/v2/Individuals');
            gen.writeStringField('ResourceTypes', '/services/apexrest/scim/v2/ResourceTypes');
            gen.writeStringField('ServiceProviderConfigs', '/services/apexrest/scim/v2/ServiceProviderConfigs');                      
            gen.writeStringField('Schemas', '/services/apexrest/scim/v2/Schemas');   
        gen.writeEndObject();
        return Blob.valueOf(gen.getAsString());
    }
}