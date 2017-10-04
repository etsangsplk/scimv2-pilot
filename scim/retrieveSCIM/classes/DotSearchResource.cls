public class DotSearchResource {
    public List<String> schemas;
    public List<String> attributes;
    public List<String> excludedAttributes;    
    public String filter;
    public Integer startIndex;
    public Integer count;
    
    
    public static DotSearchResource parse(String json) {
        return (DotSearchResource) System.JSON.deserialize(json, DotSearchResource.class);
    }
}