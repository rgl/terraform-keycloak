import { test, expect, Page } from '@playwright/test';

test('main', async ({ page }) => {
  // navigate to the application page.
  // NB the page was already authenticated in login.setup.ts.
  const loginUrl = process.env.EXAMPLE_LOGIN_URL;
  if (!loginUrl) {
    throw "you must set the EXAMPLE_LOGIN_URL environment variable";
  }
  await page.goto(loginUrl);
  await page.getByText('User Claims').click();

  // verify the claims.
  const claims = await getClaims(page, "User Claims");
  const expectedUsername = process.env.EXAMPLE_USERNAME;
  const actualUsername = claims["PreferredUsername"];
  if (actualUsername != expectedUsername) {
    throw Error(`PreferredUsername expected ${expectedUsername} but got ${actualUsername}`);
  }
});

interface Claims {
  [key: string]: string;
}

async function getClaims(page: Page, tableCaption: string): Promise<Claims> {
  return page.evaluate((caption: string) => {
    function getTable(caption: string): HTMLTableElement | null {
      const captions = document.querySelectorAll<HTMLTableCaptionElement>("table > caption");
      const captionCount = captions.length;
      for (let i = 0; i < captionCount; ++i) {
        const el = captions[i];
        if (el.textContent?.trim() == caption) {
          return el.parentElement as HTMLTableElement;
        }
      }
      return null;
    }
    const data: Claims = {};
    const table = getTable(caption);
    if (!table) {
      return data;
    }
    const rows = table.querySelectorAll("tbody > tr");
    const rowCount = rows.length;
    for (let i = 0; i < rowCount; ++i) {
      const row = rows[i];
      const columns = row.querySelectorAll("th,td");
      if (columns.length !== 2) {
        continue;
      }
      const key = columns[0].textContent?.trim() || "";
      const value = columns[1].textContent?.trim() || "";
      if (!key) {
        continue;
      }
      data[key] = value;
    }
    return data;
  }, tableCaption);
}
