public class GroupPatchParser {
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
    
    public static GroupPatchParser parse(String json){
        return (GroupPatchParser) System.JSON.deserialize(json, GroupPatchParser.class);
    }
}