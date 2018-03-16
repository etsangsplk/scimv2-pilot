public class RolePatchParser {

    public List<String> schemas;
    public List<Operations> Operations;
    
    public class Value {
        public List<Map<String, String>> members;
    }
    
    public class Operations {
        public String op;
        public String path;
        public Value value;
    }
    
    
    public static RolePatchParser parse(String json) {
        return (RolePatchParser) System.JSON.deserialize(json, RolePatchParser.class);
    }
}