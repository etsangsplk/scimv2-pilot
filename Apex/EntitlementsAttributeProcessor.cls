// Entitlements Processor. 
public class EntitlementsAttributeProcessor implements ScimSoqlAttributeProcessor{
    
    private String soqlAttribute;
    private Schema.SOAPType soapType;
    
    public EntitlementsAttributeProcessor() {
        this.soqlAttribute = 'ProfileId,Profile.Name';
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
        return true;
    }    
    
    public String getEQclause(String value) {
        if (value.startsWith('0PS')) {
            return ' ( User.Id IN ( Select AssigneeId From PermissionSetAssignment where PermissionSetId = \'' + value + '\') )';        
        }
        else {
            return ' ( User.ProfileId = \'' + value + '\' ) ';        
        }
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
        // There's always a profile so this is pointless for entitlement
        throw new IllegalFilterException('Unsupported comparison for entitlements field');
    }

}