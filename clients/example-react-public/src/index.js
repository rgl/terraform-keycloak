import React from "react";
import ReactDOM from "react-dom/client";
import { AuthProvider } from "react-oidc-context";
import App from "./App";

function onSigninCallback(_user) {
  window.history.replaceState(
    {},
    document.title,
    window.location.pathname);
}

const root = ReactDOM.createRoot(document.getElementById("root"));

root.render(
  <React.StrictMode>
    <AuthProvider
      redirect_uri="http://example-react-public.test:8082/"
      authority="http://keycloak.test:8080/realms/example"
      client_id="example-react-public"
      onSigninCallback={onSigninCallback}>
      <App />
    </AuthProvider>
  </React.StrictMode>
);
