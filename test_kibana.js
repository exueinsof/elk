const { chromium } = require('playwright');

const baseUrl = process.env.KIBANA_URL || 'https://localhost:5601';
const username = process.env.KIBANA_USERNAME || 'elastic';
const password = process.env.KIBANA_PASSWORD;

if (!password) {
  console.error('KIBANA_PASSWORD is required');
  process.exit(1);
}

async function ensureLoggedIn(page) {
  await page.goto(`${baseUrl}/login`, { waitUntil: 'networkidle' });

  const usernameInput = page.locator('[name="username"]');
  if (await usernameInput.count()) {
    await usernameInput.fill(username);
    await page.locator('[name="password"]').fill(password);
    await page.locator('[data-test-subj="loginSubmit"]').click();
    await page.waitForLoadState('networkidle');
  }
}

async function pageLooksHealthy(page, url, expectedText, negativeTexts) {
  await page.goto(url, { waitUntil: 'networkidle' });
  await page.waitForTimeout(3000);
  const bodyText = await page.evaluate(() => document.body.innerText);

  const hasNegativeText = negativeTexts.some((text) => bodyText.includes(text));
  const hasExpectedText = expectedText ? bodyText.includes(expectedText) : true;

  return { bodyText, ok: hasExpectedText && !hasNegativeText };
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ ignoreHTTPSErrors: true });
  const page = await context.newPage();

  await ensureLoggedIn(page);

  console.log('-> Discover / Dashboard pfSense');
  const discover = await pageLooksHealthy(
    page,
    `${baseUrl}/app/dashboards`,
    null,
    ['No results match your search criteria', 'Error loading']
  );
  console.log(discover.ok ? '   OK' : '   FAIL');

  console.log('-> Security Network');
  const security = await pageLooksHealthy(
    page,
    `${baseUrl}/app/security/network`,
    null,
    ['Detection engine permissions required', '(500)', 'Error loading']
  );
  console.log(security.ok ? '   OK' : '   FAIL');

  console.log('-> Observability Logs');
  const observability = await pageLooksHealthy(
    page,
    `${baseUrl}/app/observability/logs`,
    null,
    ['No results match your search criteria', '(500)', 'Error loading']
  );
  console.log(observability.ok ? '   OK' : '   FAIL');

  await browser.close();
})();
