@RestResource(urlMapping='/scim/v2/Individuals')
global class IndividualsResource {

    @HttpGet
    global static void doGet() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        try {
            res.addHeader('Content-Type', 'application/json');
            res.statusCode = 200; 
            String host = req.headers.get('Host');
            
            String attributes = req.params.get('attributes');
            if (attributes != null) {
                attributes = attributes.replaceAll(' ', '');
            }   
            
            String excludedAttributes = req.params.get('excludedAttributes');
            if (excludedAttributes != null) {
                excludedAttributes = excludedAttributes.replaceAll(' ', '');
            }
            
            String filter = req.params.get('filter');
            String startIndex = req.params.get('startIndex');
            String count = req.params.get('count');
            
            QueryHolder indQueryHolder = FilterTranslator.buildAttributeQueryStringWithExcluded(attributes, excludedAttributes, filter, startIndex, count, scimNameToIndividualSObjectNameMap, 'Individual', null, null, null);
            
            String countSoql = indQueryHolder.getCountQuery();
            String actualSoql = indQueryHolder.getActualQuery();
            
            Integer total = ScimResource.countQuery(countSoql);
            System.debug(actualSoql);
            List<Individual> inds = Database.query(actualSoql);

            if ( !inds.isEmpty()  ) {
                res.responseBody = IndividualResourceSerializer.serializeIndividuals(inds, total, startIndex, count, attributes, excludedAttributes, host,req.headers.containsKey('X-Prettyprint'));
            } else {
                res.responseBody = IndividualResourceSerializer.serializeIndividuals(null,0,null,null,null,null,host,req.headers.containsKey('X-Prettyprint'));
            }
        }
        catch (Exception ex) {
            res.statusCode = 400;
            res.responseBody = SCIMError.serializeError(res.statusCode, ex.getMessage(), req.headers.containsKey('X-Prettyprint'));
            return;
        }              
    } 
}