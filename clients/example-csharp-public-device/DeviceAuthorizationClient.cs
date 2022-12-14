// see https://www.rfc-editor.org/rfc/rfc8628

using System.Net.Http.Json;
using System.Text.Json.Serialization;

public class DeviceAuthorizationClient
{
    private readonly HttpClient _httpClient;
    private readonly string _deviceAuthorizationEndpoint;
    private readonly string _tokenEndpoint;
    private readonly string _clientId;

    public DeviceAuthorizationClient(HttpClient httpClient, string deviceAuthorizationEndpoint, string tokenEndpoint, string clientId)
    {
        _httpClient = httpClient;
        _deviceAuthorizationEndpoint = deviceAuthorizationEndpoint;
        _tokenEndpoint = tokenEndpoint;
        _clientId = clientId;
    }

    public async Task<DeviceAuthorizationResponse> GetDeviceAuthorizationAsync(string scope)
    {
        using var request = new HttpRequestMessage(HttpMethod.Post, _deviceAuthorizationEndpoint)
        {
            Content = new FormUrlEncodedContent(
                new Dictionary<string, string>
                {
                    ["client_id"] = _clientId,
                    ["scope"] = scope,
                })
        };
        using var response = await _httpClient.SendAsync(request);
        response.EnsureSuccessStatusCode();
        return await response.Content.ReadFromJsonAsync<DeviceAuthorizationResponse>(
            DeviceAuthorizationJsonSerializerContext.Default.DeviceAuthorizationResponse);
    }

    public async Task<DeviceAccessTokenResponse> GetDeviceAccessTokenAsync(DeviceAuthorizationResponse deviceAuthorization)
    {
        var pollingDelay = deviceAuthorization.Interval;
        while (true)
        {
            using var request = new HttpRequestMessage(HttpMethod.Post, _tokenEndpoint)
            {
                Content = new FormUrlEncodedContent(
                    new Dictionary<string, string>
                    {
                        ["grant_type"] = "urn:ietf:params:oauth:grant-type:device_code",
                        ["device_code"] = deviceAuthorization.DeviceCode,
                        ["client_id"] = _clientId,
                    })
            };
            using var response = await _httpClient.SendAsync(request);
            if (response.IsSuccessStatusCode)
            {
                return await response.Content.ReadFromJsonAsync<DeviceAccessTokenResponse>(
                    DeviceAuthorizationJsonSerializerContext.Default.DeviceAccessTokenResponse);
            }
            else
            {
                var errorResponse = await response.Content.ReadFromJsonAsync<DeviceAuthorizationErrorResponse>(
                    DeviceAuthorizationJsonSerializerContext.Default.DeviceAuthorizationErrorResponse);
                switch (errorResponse.Error)
                {
                    case "authorization_pending":
                        // the authorization is not yet finished. the request
                        // should be retried after a delay.
                        break;
                    case "slow_down":
                        pollingDelay += 5;
                        break;
                    default:
                        throw new Exception($"Authorization failed: {errorResponse.Error} ({errorResponse.ErrorDescription})");
                }
                await Task.Delay(TimeSpan.FromSeconds(pollingDelay));
            }
        }
    }
}

// see https://www.rfc-editor.org/rfc/rfc8628#section-3.2
public class DeviceAuthorizationResponse
{
    [JsonPropertyName("device_code")]
    public string DeviceCode { get; set; }

    [JsonPropertyName("user_code")]
    public string UserCode { get; set; }

    [JsonPropertyName("verification_uri")]
    public string VerificationUri { get; set; }

    [JsonPropertyName("verification_uri_complete")]
    public string VerificationUriComplete { get; set; }

    [JsonPropertyName("expires_in")]
    public int ExpiresIn { get; set; }

    [JsonPropertyName("interval")]
    public int Interval { get; set; }
}

// see https://www.rfc-editor.org/rfc/rfc6749#section-5.2
public class DeviceAuthorizationErrorResponse
{
    [JsonPropertyName("error")]
    public string Error { get; set; }

    [JsonPropertyName("error_description")]
    public string ErrorDescription { get; set; }
}

// see https://www.rfc-editor.org/rfc/rfc8628#section-3.5
// see https://www.rfc-editor.org/rfc/rfc6749#section-5.1
public class DeviceAccessTokenResponse
{
    [JsonPropertyName("access_token")]
    public string AccessToken { get; set; }

    [JsonPropertyName("token_type")]
    public string TokenType { get; set; }

    [JsonPropertyName("expires_in")]
    public int ExpiresIn { get; set; }

    [JsonPropertyName("refresh_token")]
    public string RefreshToken { get; set; }

    [JsonPropertyName("scope")]
    public string Scope { get; set; }

    [JsonPropertyName("id_token")]
    public string IdToken { get; set; }
}

[JsonSerializable(typeof(DeviceAuthorizationResponse))]
[JsonSerializable(typeof(DeviceAuthorizationErrorResponse))]
[JsonSerializable(typeof(DeviceAccessTokenResponse))]
public partial class DeviceAuthorizationJsonSerializerContext : JsonSerializerContext
{
}
