public class EntitlementPatchParser {
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
    public static EntitlementPatchParser parse(String json) {
        return (EntitlementPatchParser) System.JSON.deserialize(json, EntitlementPatchParser.class);
    }
}