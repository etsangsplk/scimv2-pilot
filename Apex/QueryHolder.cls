global class QueryHolder {
    global QueryHolder(String countQuery, String actualQuery, String noPagingQuery, Integer lim, Integer offset) {
        this.countQuery = countQuery;
        this.actualQuery = actualQuery;
        this.noPagingQuery = noPagingQuery;
        this.lim = lim;
        this.offset = offset;
    }
    
    private String countQuery;
    private String actualQuery;
    private String noPagingQuery;
    private Integer lim;
    private Integer offset;
    
    public String getCountQuery() {
        System.debug(this.countQuery);
        return this.countQuery;
    }
    
    public String getActualQuery() {
        System.debug(this.actualQuery);
        return this.actualQuery;
    }   
    
    public String getNoPagingQuery() {
        return this.noPagingQuery;
    }
    
    public Integer getLimit() {
        return this.lim;
    }       
    
    public Integer getOffset() {
        return this.offset;
    }

}