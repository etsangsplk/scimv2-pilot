public virtual class ScimException extends Exception { 
    private Integer statusCode = 500;   // default is error
    
    public void setStatusCode(Integer statusCode) {
        this.statusCode = statusCode;
    }   
    
    public Integer getStatusCode() {
        return statusCode;
    }
}