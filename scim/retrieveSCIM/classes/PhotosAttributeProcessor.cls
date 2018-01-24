// PhoneNumbers Processor. 
public class PhotosAttributeProcessor implements ScimSoqlAttributeProcessor{
    
    private String soqlAttribute;
    private Schema.SOAPType soapType;
    
    public PhotosAttributeProcessor() {
        this.soqlAttribute = 'FullPhotoUrl,SmallPhotoUrl';
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
        return ' ( User.FullPhotoUrl = \'' + value + '\' OR User.SmallPhotoUrl = \'' + value + '\') ';
    }

    public String getNEclause(String value) {
        return ' ( User.FullPhotoUrl != \'' + value + '\' OR User.SmallPhotoUrl != \'' + value + '\') ';
    }
    
    public String getCOclause(String value) {
        throw new IllegalFilterException('Unsupported comparison for photos field');
    }
    
    public String getSWclause(String value) {
        throw new IllegalFilterException('Unsupported comparison for photos field');
    }

    public String getEWclause(String value) {
        throw new IllegalFilterException('Unsupported comparison for photos field');
    }
    
    public String getGTclause(String value) {
        throw new IllegalFilterException('Unsupported comparison for photos field');
    }
    
    public String getGEclause(String value) {
        throw new IllegalFilterException('Unsupported comparison for photos field');
    }
    
    public String getLTclause(String value) {
        throw new IllegalFilterException('Unsupported comparison for photos field');
    }
    
    public String getLEclause(String value) {
        throw new IllegalFilterException('Unsupported comparison for photos field');
    }
    
    public String getPRclause(String value) {
        return ' (User.FullPhotoUrl != NULL OR User.SmallPhotoUrl != NULL) ';
    }

}