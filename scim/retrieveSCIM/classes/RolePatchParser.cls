public class RolePatchParser {

    public List<String> schemas;
    public List<Operations> Operations;
    
    public class Value {
        public String value;
    }
    
    public class Operations {
        public String op;
        public String path;
        public List<Value> value;
    }
    
    
    public static RolePatchParser parse(String json) {
        return (RolePatchParser) System.JSON.deserialize(json, RolePatchParser.class);
    }
}