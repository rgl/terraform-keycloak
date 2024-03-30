// see https://keycloak.test:8443/realms/example/.well-known/openid-configuration
const string deviceAuthorizationEndpoint = "https://keycloak.test:8443/realms/example/protocol/openid-connect/auth/device";
const string tokenEndpoint = "https://keycloak.test:8443/realms/example/protocol/openid-connect/token";
const string clientId = "example-csharp-public-device";
const string scope = "openid";

var httpClient = new HttpClient();

var client = new DeviceAuthorizationClient(
    httpClient,
    deviceAuthorizationEndpoint,
    tokenEndpoint,
    clientId);

var deviceAuthorization = await client.GetDeviceAuthorizationAsync(scope);

Console.WriteLine($"Using a Web Browser, authenticate at one of the following verification URIs:");
Console.WriteLine($"  VerificationUriComplete: {deviceAuthorization.VerificationUriComplete}");
Console.WriteLine($"  VerificationUri: {deviceAuthorization.VerificationUri}");
Console.WriteLine($"  UserCode: {deviceAuthorization.UserCode}");

Console.WriteLine($"Waiting for authentication...");

var deviceAccessToken = await client.GetDeviceAccessTokenAsync(deviceAuthorization);

Console.WriteLine($"Authentication complete");

var claims = Claims.FromJwt(deviceAccessToken.IdToken);

Console.WriteLine($"IdToken Claim Issuer: {claims.Issuer}");
Console.WriteLine($"IdToken Claim Subject: {claims.Subject}");
Console.WriteLine($"IdToken Claim PreferredUsername: {claims.PreferredUsername}");
Console.WriteLine($"IdToken Claim Email: {claims.Email}");
Console.WriteLine($"IdToken Claim EmailVerified: {claims.EmailVerified}");
Console.WriteLine($"IdToken Claim Name: {claims.Name}");
Console.WriteLine($"IdToken Claim GivenName: {claims.GivenName}");
Console.WriteLine($"IdToken Claim FamilyName: {claims.FamilyName}");
