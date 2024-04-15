using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Identity.Client;
using Microsoft.Identity.Web;

var clientId = Environment.GetEnvironmentVariable("EXAMPLE_OAUTH_CLIENT_ID") ?? "example-csharp-client-credentials-server-test";
var clientSecret = Environment.GetEnvironmentVariable("EXAMPLE_OAUTH_CLIENT_SECRET") ?? "example";
var clientAuthority = Environment.GetEnvironmentVariable("EXAMPLE_OIDC_ISSUER_URL") ?? "https://keycloak.test:8443/realms/example";
var serverUrl = Environment.GetEnvironmentVariable("EXAMPLE_SERVER_URL") ?? "https://example-csharp-client-credentials-server.test:8027";

var authApp = ConfidentialClientApplicationBuilder
    .Create(clientId)
    .WithClientSecret(clientSecret)
    .WithOidcAuthority(clientAuthority)
    .WithLegacyCacheCompatibility(false)
    .Build();

authApp.AddInMemoryTokenCache(services =>
    {
        services.Configure<MemoryCacheOptions>(options =>
        {
            options.SizeLimit = 10 * 1024 * 1024; // in bytes (10 MB)
        });
    });

var authBuilder = authApp.AcquireTokenForClient(new string[] { "profile" });

using (var client = new HttpClient())
{
    client.BaseAddress = new Uri(serverUrl);

    var authResult = await authBuilder.ExecuteAsync();
    client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", authResult.AccessToken);

    var response = await client.GetAsync("protected");

    var data = await response.Content.ReadFromJsonAsync(SourceGenerationContext.Default.ProtectedResponseData);

    string actualClientId = "";

    if (data != null)
    {
        foreach (var c in data.Claims)
        {
            if (c.Name == "client_id")
            {
                actualClientId = c.Value;
            }

            Console.WriteLine("Claim {0}={1}", c.Name, c.Value);
        }
    }

    if (actualClientId != clientId)
    {
        throw new Exception("failed to verify the returned client_id");
    }
}

[JsonSerializable(typeof(ProtectedResponseData))]
[JsonSerializable(typeof(ClaimData[]))]
internal partial class SourceGenerationContext : JsonSerializerContext
{
}

public record ProtectedResponseData(ClaimData[] Claims);

public record ClaimData(string Name, string Value);
