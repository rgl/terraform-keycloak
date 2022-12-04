import React from "react";
import { useAuth, hasAuthParams } from "react-oidc-context";

function App() {
  const auth = useAuth();

  React.useEffect(() => {
    if (!hasAuthParams() && !auth.isAuthenticated && !auth.activeNavigator && !auth.isLoading) {
      auth.signinRedirect();
    }
  }, [auth.isAuthenticated, auth.activeNavigator, auth.isLoading, auth.signinRedirect]);

  switch (auth.activeNavigator) {
    case "signinSilent":
      return <div>Signing in...</div>;
    case "signoutRedirect":
      return <div>Signing out...</div>;
  }

  if (auth.isLoading) {
    return <div>Loading...</div>;
  }

  if (auth.error) {
    return <div>Oops... {auth.error.message}</div>;
  }

  if (!auth.isAuthenticated) {
    return <div>Unable to log in</div>;
  }

  const claims = auth.user.profile;

  return (
    <table>
      <caption>User Claims</caption>
      <tbody>
        <tr><th>Subject</th><td>{claims.sub}</td></tr>
        <tr><th>PreferredUsername</th><td>{claims.preferred_username}</td></tr>
        <tr><th>Name</th><td>{claims.name}</td></tr>
        <tr><th>GivenName</th><td>{claims.given_name}</td></tr>
        <tr><th>FamilyName</th><td>{claims.family_name}</td></tr>
        <tr><th>Email</th><td>{claims.email}</td></tr>
        <tr><th>EmailVerified</th><td>{claims.email_verified ? "true" : "false"}</td></tr>
      </tbody>
    </table>
  );
}

export default App;
