@RestResource(urlMapping='/scim/v2/Individuals/*')
global with sharing class IndividualResource extends SCIMResource {

    @HttpGet
    global static void doGet(){
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        String attributes = req.params.get('attributes');
        if (attributes != null) {
            attributes = attributes.replaceAll(' ', '');
        }

        String excludedAttributes = req.params.get('excludedAttributes');
        if (excludedAttributes != null) {
            excludedAttributes = excludedAttributes.replaceAll(' ', '');
        }

        if ((attributes != null) && (excludedAttributes != null)){
            res.statusCode = 400;
            res.responseBody = SCIMError.serializeError(res.statusCode, 'Cannot provide both attributes and excludedAttributes', req.headers.containsKey('X-Prettyprint'));
            return;
        }
        
        String[] uriParts = req.requestURI.split('/',0);
        Integer numParts = uriParts.size() - 1;   
        if (numParts > 4) { 
            res.statusCode = 404;
            res.responseBody = SCIMError.serializeError(res.statusCode, 'No such resource.', req.headers.containsKey('X-Prettyprint'));
        } else if (numParts == 4) {
            doGet(uriParts[numParts], attributes, excludedAttributes, false);   
        } else if (numParts == 3) {
            IndividualsResource.doGet();
        }
    }

    global static void doGet(String indId, String attributes, String excludedAttributes, Boolean isPost){
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');
        
        String indsCount = req.params.get('inds.count');
        String indsStartIndex = req.params.get('inds.startIndex');
        try {
            Integer indsLimit = 200;
            if (indsCount != null) {
                FilterTranslator.validateCount(indsCount);
                indsLimit = Integer.valueof(indsCount);
            }
            
            Integer indsOffset = 0;
            if (indsStartIndex != null) {
                FilterTranslator.validateStartIndex(indsStartIndex);
                indsOffset = Integer.valueof(indsStartIndex) - 1;
            }
            else {
                indsOffset = 0;
            }   
            String host = req.headers.get('Host');
            QueryHolder groupQueryHolder = FilterTranslator.buildAttributeQueryStringWithExcluded(attributes, excludedAttributes, 'id eq \"' + indId + '\"', null, null, IndividualsResource.scimNameToIndividualSObjectNameMap, 'Individual', null, null, null);
            String actualSoql = groupQueryHolder.getActualQuery();
            List<Individual> inds = Database.query(actualSoql);
            
            if ( !inds.isEmpty()  ) {
                res.statusCode = 200;
                if(isPost){
                    res.statusCode = 201; 
                }
                Boolean isPrettyPrint = req.headers.containsKey('X-Prettyprint');
                JSONGenerator gen = JSON.createGenerator(isPrettyPrint);
                serializeIndividualWithGenerator(inds, attributes, excludedAttributes, host, gen, indsLimit, indsOffset);      
                res.responseBody =  Blob.valueOf(gen.getAsString());
            } else {
                res.statusCode = 404;
                res.responseBody = SCIMError.serializeError(res.statusCode, 'Resource https://' + host + '/services/apexrest/v2/Individuals/' + indId + ' not found', req.headers.containsKey('X-Prettyprint'));
            }    
        }  
        catch (ScimException ex) {
            res.statusCode = 400;
            res.responseBody = SCIMError.serializeError(res.statusCode, ex.getMessage(), req.headers.containsKey('X-Prettyprint'));
            return;
        }                              
        
    }

    @HttpPost
    global static void doPost() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String method = req.headers.get('X-HTTP-Method-Override');
        if ( method == null ) method = 'POST';
        if ( method.equals('DELETE') ) {
            doDelete(); 
        } else {
            System.JSONParser parser = System.JSON.createParser(req.requestBody.toString());
            Id indId = doUpsert(null, parser);
            if (indId != null) {
                // retrieve self
                doGet(indId, null, true);
            }
        }
    }  

    @HttpDelete
    global static void doDelete() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String[] uriParts = req.requestURI.split('/',0);
        Integer numParts = uriParts.size() - 1;  
        
        Individual[] i = Database.query('select id from individual where id=\'' + uriParts[numParts] + '\'');
        if(i.size() == 1) {
        	delete i[0];
            res.statusCode = 204;
        } else {
            res.statusCode = 404;
            res.responseBody = SCIMError.serializeError(res.statusCode, 'No such resource.', req.headers.containsKey('X-Prettyprint'));
            return;
        }
    }   

    public static Id doUpsert(String groupId, System.JSONParser parser) {
    
    }
       
}