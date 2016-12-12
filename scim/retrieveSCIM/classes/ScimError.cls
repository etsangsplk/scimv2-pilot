public class ScimError {
    public static Blob serializeError(Integer statusCode, String e, boolean prettyPrint) {
        JSONGenerator gen = JSON.createGenerator(prettyPrint);
        gen.writeStartObject();
            gen.writeStringField('schemas', '["urn:ietf:params:scim:api:messages:2.0:Error"]');
            gen.writeStringField('detail', e);
            gen.writeNumberField('status', statusCode);
        gen.writeEndObject();
        return Blob.valueOf(gen.getAsString());
    }
}