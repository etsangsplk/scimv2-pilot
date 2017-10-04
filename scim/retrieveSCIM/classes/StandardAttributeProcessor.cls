// Standard Processor. 
// Handles any direct mapping case
public class StandardAttributeProcessor implements ScimSoqlAttributeProcessor{
    
    private String soqlAttribute;
    private Schema.SOAPType soapType;
    private Boolean isComplex;
    
    public StandardAttributeProcessor(String soqlAttribute, Schema.SOAPType soapType, Boolean isComplex) {
        this.soqlAttribute = soqlAttribute;
        this.soapType = soapType;
        this.isComplex = isComplex;
    }
    
    public Boolean isComplex() {
        return isComplex;
    }
    
    public Schema.SOAPType getSOAPType() {
        return this.soapType;
    }
    
    // Gets back all the soql attributes in a comman separate string.
    public String getSoqlAttribute() {
        return soqlAttribute;
    }
    
    // Simple translations return the soql attribute as is
    public String getSoqlAttributeForFilterGeneration() {
        return getSoqlAttribute();
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
    
    public String getEQclause(String value) {
        return (' = ' + quoteIfNecessary(value));
    }
    
    public String getCOclause(String value) {
        return (' like \'%' + value + '%\'');
    }
    
    public String getSWclause(String value) {
        return (' like \'' + value + '%\'');
    }
    
    public String getGTclause(String value) {
        return (' > ' + quoteIfNecessary(value));
    }
    
    public String getGEclause(String value) {
        return (' >= ' + quoteIfNecessary(value));
    }
    
    public String getLTclause(String value) {
        return (' < ' + quoteIfNecessary(value));
    }
    
    public String getLEclause(String value) {
        return (' <= ' + quoteIfNecessary(value));
    }
    
    public String getPRclause(String value) {
        return ' != NULL';
    }

    public Boolean isSemijoin() {
        return false;
    }
}