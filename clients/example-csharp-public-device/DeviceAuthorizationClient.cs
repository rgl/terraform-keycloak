// see https://www.rfc-editor.org/rfc/rfc8628

using System.Text.Json;
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
        var request = new HttpRequestMessage(HttpMethod.Post, _deviceAuthorizationEndpoint)
        {
            Content = new FormUrlEncodedContent(
                new Dictionary<string, string>
                {
                    ["client_id"] = _clientId,
                    ["scope"] = scope,
                })
        };
        var response = await _httpClient.SendAsync(request);
        response.EnsureSuccessStatusCode();
        var responseJson = await response.Content.ReadAsStringAsync();
        return JsonSerializer.Deserialize<DeviceAuthorizationResponse>(responseJson);
    }

    public async Task<DeviceAccessTokenResponse> GetDeviceAccessTokenAsync(DeviceAuthorizationResponse deviceAuthorization)
    {
        var pollingDelay = deviceAuthorization.Interval;
        while (true)
        {
            var request = new HttpRequestMessage(HttpMethod.Post, _tokenEndpoint)
            {
                Content = new FormUrlEncodedContent(
                    new Dictionary<string, string>
                    {
                        ["grant_type"] = "urn:ietf:params:oauth:grant-type:device_code",
                        ["device_code"] = deviceAuthorization.DeviceCode,
                        ["client_id"] = _clientId,
                    })
            };
            var response = await _httpClient.SendAsync(request);
            var responseJson = await response.Content.ReadAsStringAsync();
            if (response.IsSuccessStatusCode)
            {
                return JsonSerializer.Deserialize<DeviceAccessTokenResponse>(responseJson);
            }
            else
            {
                var errorResponse = JsonSerializer.Deserialize<DeviceAuthorizationErrorResponse>(responseJson);
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

    // see https://www.rfc-editor.org/rfc/rfc6749#section-5.2
    private class DeviceAuthorizationErrorResponse
    {
        [JsonPropertyName("error")]
        public string Error { get; set; }

        [JsonPropertyName("error_description")]
        public string ErrorDescription { get; set; }
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
