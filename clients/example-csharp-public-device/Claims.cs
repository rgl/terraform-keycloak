using System.Text.Json;
using System.Text.Json.Serialization;

public class Claims
{
    [JsonPropertyName("iss")]
    public string Issuer { get; set; }

    [JsonPropertyName("sub")]
    public string Subject { get; set; }

    [JsonPropertyName("preferred_username")]
    public string PreferredUsername { get; set; }

    [JsonPropertyName("email")]
    public string Email { get; set; }

    [JsonPropertyName("email_verified")]
    public bool EmailVerified { get; set; }

    [JsonPropertyName("name")]
    public string Name { get; set; }

    [JsonPropertyName("given_name")]
    public string GivenName { get; set; }

    [JsonPropertyName("family_name")]
    public string FamilyName { get; set; }

    public static Claims FromJwt(string jwt)
    {
        // see https://jwt.io
        // see https://www.rfc-editor.org/rfc/rfc7519
        var parts = jwt.Split('.', 3);

        var payload = FromBase64UrlString(parts[1]);

        return JsonSerializer.Deserialize<Claims>(
            payload,
            ClaimsJsonSerializerContext.Default.Claims);
    }

    private static byte[] FromBase64UrlString(string s)
    {
        return Convert.FromBase64String(s
                .PadRight(s.Length + (4 - s.Length % 4) % 4, '=')
                .Replace('_', '/')
                .Replace('-', '+'));
    }
}

[JsonSerializable(typeof(Claims))]
public partial class ClaimsJsonSerializerContext : JsonSerializerContext
{
}
