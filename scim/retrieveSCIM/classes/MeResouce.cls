@RestResource(urlMapping='/scim/v2/Me')
global class MeResouce {
 
    @HttpGet
    global static void doGet() {
        UserResource.doGet();        
    }   
}