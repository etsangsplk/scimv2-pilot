public class UserPatchParserUntyped {
    public List<String> schemas = new List<String>();
    public List<Operation> Operations = new List<Operation>();

    public class Operation {
        public String op;
        public String path;
        // complex attrbutes still may not work here
        public Map<String, Object> value;
    }
    
    public UserPatchParserUntyped(String json){
        Map<String, Object> m = (Map<String, Object>) System.JSON.deserializeUntyped(json);
        // parse schemas
        List<Object> tempSchemas = (List<Object>) m.get('schemas');
        for (Object o : tempSchemas){
            if (o != null){
                schemas.add((String)o);
            }
        }
        
        // parse Operations
        List<Object> tempOperations = (List<Object>) m.get('Operations');
        for (Object o : tempOperations){
            Map<String, Object> untypedOp = (Map<String, Object>) o;
            Operation tempOp = new Operation();
            tempOp.op = (String) untypedOp.get('op');
            tempOp.path = (String) untypedOp.get('path');
            if (tempOp.path != null) {
                if (tempOp.op != 'remove'){
                    if (tempOp.path == 'active') {
                        tempOp.value = new Map<String, Boolean>{'active' => (Boolean) untypedOp.get('value')};
                    } else if (tempOp.path == 'entitlements'){
                        tempOp.value = new Map<String, Object>{'entitlements' => (Object) untypedOp.get('value')};
                    } else {
                        tempOp.value = new Map<String, String>{tempOp.path => (String) untypedOp.get('value')};
                    }
                } else {
                    tempOp.value = null;
                }                
            } else {
                if (tempOp.op != 'remove'){
                    tempOp.value = (Map<String, Object>) untypedOp.get('value');
                } else {
                    tempOp.value = null;
                }                
            }
            Operations.add(tempOp);
        }
    }
}