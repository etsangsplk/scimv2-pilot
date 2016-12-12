// PhoneNumbers Processor. 
public class PhoneNumbersAttributeProcessor implements ScimSoqlAttributeProcessor{
    
    private String soqlAttribute;
    private Schema.SOAPType soapType;
    
    public PhoneNumbersAttributeProcessor() {
        this.soqlAttribute = 'Phone,MobilePhone,Fax';
        this.soapType = Schema.SOAPType.String;
    }
    
    public Schema.SOAPType getSOAPType() {
        return this.soapType;
    }
    
    // Gets back all the soql attributes in a comman separate string.
    public String getSoqlAttribute() {
        return soqlAttribute;
    }
    
    // Gets back all the soql attributes in a list of strings.
    public List<String> getSoqlAttributeList() {
        return soqlAttribute.split(',');
    }
    
    private String quoteIfNecessary(String value) {
        if (this.soapType == Schema.SOAPType.String) {
            return '\'' + value + '\'';
        }
        return value;
    }
    
    public String getSoqlAttributeForFilterGeneration() {
        // Complex query.
        return '';
    }    
    
    public Boolean isComplex() {
        return false;
    }

    public Boolean isSemijoin() {
        return false;
    }    
    
    public String getEQclause(String value) {
        return ' ( User.Phone = \'' + value + '\' OR User.MobilePhone = \'' + value + '\' OR User.Fax = \'' + value + '\') ';
    }
    
    public String getCOclause(String value) {
        throw new IllegalFilterException('Unsupported comparison for entitlements field');
    }
    
    public String getSWclause(String value) {
        throw new IllegalFilterException('Unsupported comparison for entitlements field');
    }
    
    public String getGTclause(String value) {
        throw new IllegalFilterException('Unsupported comparison for entitlements field');
    }
    
    public String getGEclause(String value) {
        throw new IllegalFilterException('Unsupported comparison for entitlements field');
    }
    
    public String getLTclause(String value) {
        throw new IllegalFilterException('Unsupported comparison for entitlements field');
    }
    
    public String getLEclause(String value) {
        throw new IllegalFilterException('Unsupported comparison for entitlements field');
    }
    
    public String getPRclause(String value) {
        return ' (User.Phone != NULL OR User.MobilePhone != NULL OR User.Fax != NULL) ';
    }

}