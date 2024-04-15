using System.Linq;
using System.Security.Claims;
using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;

var exampleUrlEnvironmentVariable = Environment.GetEnvironmentVariable("EXAMPLE_URL");

if (string.IsNullOrEmpty(exampleUrlEnvironmentVariable))
{
    throw new ApplicationException("the EXAMPLE_URL environment variable must have a value");
}

var exampleUrl = new Uri(exampleUrlEnvironmentVariable);

var exampleOidcIssuerUrl = Environment.GetEnvironmentVariable("EXAMPLE_OIDC_ISSUER_URL");

if (string.IsNullOrEmpty(exampleOidcIssuerUrl))
{
    throw new ApplicationException("the EXAMPLE_OIDC_ISSUER_URL environment variable must have a value");
}

var builder = WebApplication.CreateBuilder(args);

builder.WebHost.ConfigureKestrel(serverOptions =>
{
    serverOptions.ListenAnyIP(exampleUrl.Port, listenOptions =>
    {
        if (exampleUrl.Scheme == "https")
        {
            var tlsKeyPath = Environment.GetEnvironmentVariable("EXAMPLE_TLS_KEY_PATH");

            if (string.IsNullOrEmpty(tlsKeyPath))
            {
                tlsKeyPath = $"/etc/ssl/private/{exampleUrl.DnsSafeHost}-key.p12";
            }

            if (!File.Exists(tlsKeyPath))
            {
                throw new ApplicationException($"the {tlsKeyPath} file is not found. either create it or set its path with the EXAMPLE_TLS_KEY_PATH environment variable");
            }

            listenOptions.UseHttps(tlsKeyPath);
        }
    });
});

builder.Services.ConfigureHttpJsonOptions(options =>
{
    options.SerializerOptions.TypeInfoResolverChain.Insert(0, SourceGenerationContext.Default);
    options.SerializerOptions.PropertyNamingPolicy = SourceGenerationContext.Default.Options.PropertyNamingPolicy;
});

builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(JwtBearerDefaults.AuthenticationScheme, options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidAudience = "account",
            ValidateAudience = true,
            ValidIssuer = exampleOidcIssuerUrl,
            ValidateIssuer = true,
        };
        options.Authority = exampleOidcIssuerUrl;
    });

builder.Services
    .AddAuthorization();

var app = builder.Build();

app.UseAuthentication();

app.UseAuthorization();

app.MapGet("/protected", (ClaimsPrincipal user) => new ProtectedResponseData(user.Claims.Select(c => new ClaimData(c.Type, c.Value)).ToArray()))
    .RequireAuthorization();

app.MapGet("/", () => "Hello World!");

app.Run();


[JsonSerializable(typeof(ProtectedResponseData))]
[JsonSerializable(typeof(ClaimData[]))]
internal partial class SourceGenerationContext : JsonSerializerContext
{
}

public record ProtectedResponseData(ClaimData[] Claims);

public record ClaimData(string Name, string Value);
