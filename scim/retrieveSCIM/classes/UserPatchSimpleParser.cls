public with sharing class UserPatchSimpleParser {
    public List<String> schemas = new List<String>();
    public List<Operation> operations = new List<Operation>();

    public class Operation {
        public String op;
        public String path;
        public Map<String, Object> value;
        
	}

	public UserPatchSimpleParser(String json){
        Map<String, Object> message = (Map<String, Object>) System.JSON.deserializeUntyped(json);
        // parse schemas
        List<Object> tempSchemas = (List<Object>) message.get('schemas');
        for (Object o : tempSchemas){
            if (o != null){
                schemas.add((String)o);
            }
        }

        // parse Operations
        List<Object> ops = (List<Object>) message.get('Operations');
        for (Object op : ops){
            if (op != null) {
                operations.add((Operation)op);
            }
        }
        System.debug(operations);
    }
}