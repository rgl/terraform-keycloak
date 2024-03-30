import { Buffer } from 'buffer';
import { spawn } from 'child_process';
import { test, expect, Page } from '@playwright/test';
import { startApp } from './app';

test('main', async ({ page }) => {
  // validate arguments.
  const username = process.env.EXAMPLE_USERNAME;
  if (!username) {
    throw "you must set the EXAMPLE_USERNAME environment variable";
  }
  const password = process.env.EXAMPLE_PASSWORD;
  if (!password) {
    throw "you must set the EXAMPLE_PASSWORD environment variable";
  }

  // start the application in background.
  const { verificationUrlPromise, claimsPromise } = startApp();

  // navigate to the application login page.
  // NB this should redirect the browser to the keycloak
  //    authentication page.
  await page.goto(await verificationUrlPromise);

  // authenticate into keycloak.
  // NB after the authentication succeeds, this should
  //    redirect the browser to the application page.
  await page.getByLabel('Username or email').fill(username);
  await page.getByLabel('Password', { exact: true }).fill(password);
  await page.getByRole('button', { name: 'Sign In' }).click();

  // grant access.
  await page.getByRole('heading', { name: 'Do you grant these access' }).click();
  await page.getByRole('button', { name: 'Yes' }).click();
  await expect(page.locator('#kc-page-title')).toContainText('Device Login Successful');

  // verify the claims.
  const claims = await claimsPromise;
  const expectedUsername = process.env.EXAMPLE_USERNAME;
  const actualUsername = claims["PreferredUsername"];
  if (actualUsername != expectedUsername) {
    throw Error(`PreferredUsername expected ${expectedUsername} but got ${actualUsername}`);
  }
});
