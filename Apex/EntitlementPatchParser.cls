public class EntitlementPatchParser {

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

	
	public static EntitlementPatchParser parse(String json) {
		return (EntitlementPatchParser) System.JSON.deserialize(json, EntitlementPatchParser.class);
	}
}