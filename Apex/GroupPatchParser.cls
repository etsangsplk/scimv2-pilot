public class GroupPatchParser {
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
    
    public static GroupPatchParser parse(String json){
        return (GroupPatchParser) System.JSON.deserialize(json, GroupPatchParser.class);
    }
}