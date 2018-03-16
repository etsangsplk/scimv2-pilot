@RestResource(urlMapping='/scim/v2/me')
global class MeLowerResouce {
 
    @HttpGet
    global static void doGet() {
        UserResource.doGet();        
    }   
}