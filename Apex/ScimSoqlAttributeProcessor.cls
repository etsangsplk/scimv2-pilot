public interface ScimSoqlAttributeProcessor {

    // Gets back all the soql attributes in a comman separate string.
    String getSoqlAttribute();
    
    // Gets back all the soql attributes in a list of strings.
    List<String> getSoqlAttributeList();
    
    // Filter Generations.
    String getEQclause(String value);
    String getCOclause(String value);
    String getSWclause(String value);
    String getGTclause(String value);
    String getGEclause(String value);
    String getLTclause(String value);
    String getLEclause(String value);
    String getPRclause(String value);
    
    // Is complex, i.e. not directly queryable
    Boolean isComplex();
    
    // For filter generation you may or may not want to return the attribute
    // since it could be a complex query instead of a simple translation
    String getSoqlAttributeForFilterGeneration();
    
    // Returns the api type
    Schema.SOAPType getSOAPType();
    
    // Is semijoin. SOQL cannot allow multiple semijoins thus we want to properly let the user know
    Boolean isSemijoin();

}