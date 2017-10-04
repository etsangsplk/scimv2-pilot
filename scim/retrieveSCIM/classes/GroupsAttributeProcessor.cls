// Groups Processor.
public class GroupsAttributeProcessor implements ScimSoqlAttributeProcessor{
    
    private String soqlAttribute;
    private Schema.SOAPType soapType;
    
    public GroupsAttributeProcessor() {
        this.soqlAttribute = 'Id';
        this.soapType = Schema.SOAPType.String;
    }
    
    public Schema.SOAPType getSOAPType() {
        return this.soapType;
    }
    
    public String getSoqlAttribute() {
        return soqlAttribute;
    }
    
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
        return ' ( User.Id IN ( Select UserOrGroupId From GroupMember where GroupId = \'' + value + '\') ) ';        
    }
    
    public String getCOclause(String value) {
        throw new IllegalFilterException('Unsupported comparison for groups field');
    }
    
    public String getSWclause(String value) {
        throw new IllegalFilterException('Unsupported comparison for groups field');
    }
    
    public String getGTclause(String value) {
        throw new IllegalFilterException('Unsupported comparison for groups field');
    }
    
    public String getGEclause(String value) {
        throw new IllegalFilterException('Unsupported comparison for groups field');
    }
    
    public String getLTclause(String value) {
        throw new IllegalFilterException('Unsupported comparison for groups field');
    }
    
    public String getLEclause(String value) {
        throw new IllegalFilterException('Unsupported comparison for groups field');
    }
    
    public String getPRclause(String value) {
        return ' ( User.Id IN ( Select UserOrGroupId From GroupMember ) ) ';
    }

}