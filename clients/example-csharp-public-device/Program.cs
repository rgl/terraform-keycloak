// see http://keycloak.test:8080/realms/example/.well-known/openid-configuration
const string deviceAuthorizationEndpoint = "http://keycloak.test:8080/realms/example/protocol/openid-connect/auth/device";
const string tokenEndpoint = "http://keycloak.test:8080/realms/example/protocol/openid-connect/token";
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

Console.WriteLine($"IdToken Claims:");
Console.WriteLine($"  Issuer: {claims.Issuer}");
Console.WriteLine($"  Subject: {claims.Subject}");
Console.WriteLine($"  PreferredUsername: {claims.PreferredUsername}");
Console.WriteLine($"  Email: {claims.Email}");
Console.WriteLine($"  EmailVerified: {claims.EmailVerified}");
Console.WriteLine($"  Name: {claims.Name}");
Console.WriteLine($"  GivenName: {claims.GivenName}");
Console.WriteLine($"  FamilyName: {claims.FamilyName}");
