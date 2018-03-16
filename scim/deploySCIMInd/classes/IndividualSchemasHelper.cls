public class IndividualSchemasHelper {
    public static JSONGenerator doIndividualExtension(JSONGenerator gen){
        String base = URL.getSalesforceBaseUrl().toExternalForm();               
        String path = '/services/apexrest/scim/v2/';

        gen.writeStringField('id', 'urn:salesforce:schemas:extension:2.0:individual:' + UserInfo.getOrganizationId());
        gen.writeStringField('name', 'Extensions to Individual');
        gen.writeStringField('type', 'complex');
        gen.writeStringField('description', 'All extension custom fields for an Individual in the organization');
        gen.writeStringField('schema', 'urn:salesforce:schemas:extension:2.0:individual:' + UserInfo.getOrganizationId());
        gen.writeStringField('endpoint', '/Individuals');
        gen.writeFieldName('attributes');
        gen.writeStartArray();
            Map<String, Schema.SObjectField> r = Schema.sObjectType.Individual.fields.getMap();
            for (String key : r.keySet()) {
                SObjectField thisField = r.get(key);
                DescribeFieldResult thisDescribeResult = thisField.getDescribe();
                if (thisDescribeResult.isCustom()) {
                        gen.writeStartObject();
                        gen.writeStringField('name', thisDescribeResult.getName());                       
                        gen.writeStringField('type', getScimTypeFromSoapType(thisDescribeResult.getSOAPType()));   
                        gen.writeStringField('description', thisDescribeResult.getInlineHelpText() + '');       // Description somehow not available from the sobject api.            
                        gen.writeBooleanField('readOnly', !thisDescribeResult.isUpdateable());                             
                        gen.writeBooleanField('required', !thisDescribeResult.isNillable());                             
                        gen.writeBooleanField('caseExact', thisDescribeResult.isCaseSensitive()); 
                    gen.writeEndObject();         
                }
            }
        gen.writeEndArray();
        gen.writeFieldName('meta');
            gen.writeStartObject();
                gen.writeStringField('location', base + path + 'Schemas/urn:salesforce:schemas:extension:2.0:individual:' + UserInfo.getOrganizationId());
                gen.writeStringField('resourceType', 'Schema');
            gen.writeEndObject();  
        return gen;
    }
    private static String getScimTypeFromSoapType(Schema.SOAPType soapType) {
        if (soapType == Schema.SOAPType.anytype) {
            return 'Complex';
        } 
        else if (soapType == Schema.SOAPType.base64binary) {
            return 'Binary';
        }
        else if (soapType == Schema.SOAPType.Boolean) {
            return 'Boolean';
        }
        else if (soapType == Schema.SOAPType.Date) {
            return 'DateTime';
        }
        else if (soapType == Schema.SOAPType.DateTime) {
            return 'DateTime';        
        }
        else if (soapType == Schema.SOAPType.Double) {
            return 'Decimal';        
        }
        else if (soapType == Schema.SOAPType.ID) {
            return 'String';        
        }
        else if (soapType == Schema.SOAPType.Integer) {
            return 'Integer';        
        }
        else if (soapType == Schema.SOAPType.String) {
            return 'String';          
        }
        else if (soapType == Schema.SOAPType.Time) {
            return 'DateTime';        
        }
        return 'Unsupported';
    }
}