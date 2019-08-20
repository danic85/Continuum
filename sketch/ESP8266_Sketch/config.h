// Your wifi details
#define WIFI_SSID ""
#define WIFI_PASSWORD ""
// Your user account in Salesforce org
#define SF_USERNAME ""
#define SF_PASSWORD ""
// User settings, reset security token
#define SF_TOKEN ""
//"echo | openssl s_client -connect login.salesforce.com:443 | openssl x509 -fingerprint -noout"
#define SF_LOGIN_FINGERPRINT ""
//"echo | openssl s_client -connect <your instance url>:443 | openssl x509 -fingerprint -noout"
#define SF_INSTANCE_FINGERPRINT ""
// From connected app where users may self-authorise that supports api and refresh.
#define SF_CLIENT_ID ""
#define SF_CLIENT_KEY ""