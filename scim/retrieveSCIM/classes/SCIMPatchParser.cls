public class SCIMPatchParser {
    public List<String> schemas;
    public List<Operation> Operations;

    public class Operation {
        public String op;
        public String path;
        public Map<String, String> value; // map<string, string> means no support for PATCHing complex objects
    }
    public static SCIMPatchParser parse(String json){
        return (SCIMPatchParser) System.JSON.deserialize(json, SCIMPatchParser.class);
    }
}