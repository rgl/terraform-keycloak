import { test as setup, expect } from '@playwright/test';
import { STORAGE_STATE_PATH } from '../playwright.config';

setup('login', async ({ page }) => {
  // validate arguments.
  const loginUrl = process.env.EXAMPLE_LOGIN_URL;
  if (!loginUrl) {
    throw "you must set the EXAMPLE_LOGIN_URL environment variable";
  }
  const username = process.env.EXAMPLE_USERNAME;
  if (!username) {
    throw "you must set the EXAMPLE_USERNAME environment variable";
  }
  const password = process.env.EXAMPLE_PASSWORD;
  if (!password) {
    throw "you must set the EXAMPLE_PASSWORD environment variable";
  }

  // navigate to the application login page.
  // NB this should redirect the browser to the keycloak
  //    authentication page.
  await page.goto(loginUrl);

  // authenticate into keycloak.
  // NB after the authentication succeeds, this should
  //    redirect the browser to the application page.
  await page.getByLabel('Username or email').fill(username);
  await page.getByLabel('Password', { exact: true }).fill(password);
  await page.getByRole('button', { name: 'Sign In' }).click();

  // ensure the application page shows the expected username.
  await page.getByText('SAML Claims').click();
  await page.getByRole('cell', { name: 'username' }).click();
  await page.getByRole('cell', { name: username, exact: true }).click();

  // save the page state (e.g. credential cookies).
  await page.context().storageState({ path: STORAGE_STATE_PATH });
});
