import React from "react";
import ReactDOM from "react-dom/client";
import { QueryClientProvider, QueryClient, useQuery } from "react-query";
import { AuthProvider } from "react-oidc-context";
import App from "./App";

function AuthApp() {
  async function fetchConfig() {
    const response = await fetch("/config.json");
    if (!response.ok) {
      throw new Error(`failed to load config with status code ${response.status} (${response.statusText}) and response ${await response.text()}`);
    }
    return response.json();
  }

  function onSigninCallback(_user) {
    window.history.replaceState(
      {},
      document.title,
      window.location.pathname);
  }

  const {data, isLoading, isError, error} = useQuery("config", fetchConfig);

  if (isLoading) {
    return <>Loading config...</>
  }

  if (isError) {
    return <>Failed to load config: {error.message}</>
  }

  const config = data;

  return (
    <AuthProvider
      redirect_uri={config.redirectUri}
      authority={config.authority}
      client_id={config.clientId}
      onSigninCallback={onSigninCallback}>
      <App />
    </AuthProvider>
  )
}

const queryClient = new QueryClient();

const root = ReactDOM.createRoot(document.getElementById("root"));

root.render(
  <React.StrictMode>
    <QueryClientProvider client={queryClient}>
      <AuthApp />
    </QueryClientProvider>
  </React.StrictMode>
);
