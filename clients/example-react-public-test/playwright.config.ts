import { defineConfig, devices } from '@playwright/test';
import fs from 'fs';
import path from 'path';

// Read environment variables from file.
// See https://github.com/motdotla/dotenv.
require('dotenv').config();

export const STORAGE_STATE_PATH = path.join(__dirname, 'test-results', '.auth.json');

fs.mkdirSync(path.dirname(STORAGE_STATE_PATH), { recursive: true });

// See https://playwright.dev/docs/test-configuration.
export default defineConfig({
  testDir: './tests',
  fullyParallel: true,
  // Fail the build on CI if you accidentally left test.only in the source code.
  forbidOnly: !!process.env.CI,
  // Retry on CI only.
  retries: process.env.CI ? 2 : 0,
  // Opt out of parallel tests on CI.
  workers: process.env.CI ? 1 : undefined,
  // Configure the reporters.
  // See https://playwright.dev/docs/test-reporters.
  reporter: [
    process.env.CI ? ['github'] : ['list'],
    ['html', { open: 'never' }],
    ['json', { outputFile: 'test-results/test-results.json' }],
    ['junit', { outputFile: 'test-results/test-results.xml' }],
  ],
  // Shared settings for all the projects below.
  // See https://playwright.dev/docs/api/class-testoptions.
  use: {
    // Use the same browser in all the projects.
    ...devices['Desktop Chrome'],
    // Always collect traces.
    // See https://playwright.dev/docs/trace-viewer.
    trace: 'on',
    // Set the viewport size.
    viewport: { width: 1024, height: 768 },
    // Always collect videos.
    // see https://playwright.dev/docs/videos.
    video: { mode: 'on', size: { width: 1024, height: 768 } },
  },
  projects: [
    {
      name: 'login',
      testMatch: 'login.setup.ts',
    },
    {
      name: 'main',
      dependencies: ['login'],
      use: {
        storageState: STORAGE_STATE_PATH,
      },
    },
  ],
});
