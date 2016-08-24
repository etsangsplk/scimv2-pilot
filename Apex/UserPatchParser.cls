public class UserPatchParser {
    public List<String> schemas;
    public List<Operation> Operations;

    public class Operation {
        public String op;
        public String path;
        // map<string, string> means no support for PATCHing complex objects
        // also means that attributes must be strings and that breaks isActive
        public Map<String, String> value;
        
    }
    
    public UserPatchParser(String json){
        System.JSON.deserialize(json, UserPatchParser.class);
    }
    public static UserPatchParser parse(String json){
        return (UserPatchParser) System.JSON.deserialize(json, UserPatchParser.class);
    }
/**
 * this is original PATCH Parser
 * Replaced with assumption that there is always a map in value    
    public UserPatchParser(String json){
        Map<String,Object> parsed = (Map<String, Object>)System.JSON.deserializeUntyped(json);
        List<Object> schemasObj = (List<Object>)parsed.get('schemas');
        List<Object> operationsObj = (List<Object>)parsed.get('Operations');
        
        schemas = new List<String>();
        Operations = new List<Operation>();       
        for (Object val : schemasObj){
            schemas.add((String) val);
        }

        for (Object val : (List<Object>)operationsObj) {
            Operation tempOp = new Operation();
            Map<String, Object> tempObj = (Map<String, Object>) val;
            tempOp.op = (String)tempObj.get('op');
            tempOp.value = new List<Map<String, Object>>();

            if (tempObj.get('path') != null){
                tempOp.path = (String)tempObj.get('path');
                Map<String, Object> tempV = new Map<String, Object>{'value' => tempObj.get('value')}; 
                tempOp.value.add(tempV);
            } else {
                List<Map<String, Object>> foo1 = (List<Map<String, Object>>)tempObj.get('value');
                for (Map<string, Object> f : foo1){
                    System.debug('listf: ' + f);
                }

                for (String o1 : foo1.keySet()){
                   // tempOp.value.add(new Map<String, Object>{o1 => foo1.get(o1)});
                   System.debug('O1: '+ o1);
                }

            }                      
//            operations.add(tempOp);
        }
    }
*/
}