const { chromium } = require('playwright');

const baseUrl = process.env.KIBANA_URL || 'https://localhost:5601';
const username = process.env.KIBANA_USERNAME || 'elastic';
const password = process.env.KIBANA_PASSWORD;

if (!password) {
  throw new Error('KIBANA_PASSWORD is required');
}

async function ensureLoggedIn(page) {
  await page.goto(`${baseUrl}/login`, { waitUntil: 'networkidle' });
  await page.waitForTimeout(1000);
  const usernameInput = page.locator('[name="username"]');
  if (await usernameInput.count()) {
    await usernameInput.fill(username);
    await page.locator('[name="password"]').fill(password);
    await page.locator('[data-test-subj="loginSubmit"]').click();
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(2000);
  }
}

async function clickIfVisible(page, selector) {
  const locator = page.locator(selector);
  if (await locator.count()) {
    await locator.first().click();
    return true;
  }
  return false;
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ ignoreHTTPSErrors: true });
  const page = await context.newPage();

  await ensureLoggedIn(page);
  await page.goto(`${baseUrl}/app/dashboards#/view/soc-pfsense-executive`, { waitUntil: 'networkidle' });
  await page.waitForTimeout(4000);

  console.log('TITLE', await page.title());
  console.log('URL', page.url());

  const buttons = await page.locator('button').evaluateAll((els) =>
    els.slice(0, 80).map((el) => ({
      text: el.innerText,
      testid: el.getAttribute('data-test-subj'),
      aria: el.getAttribute('aria-label'),
    }))
  );
  console.log('BUTTONS', JSON.stringify(buttons, null, 2));

  const links = await page.locator('a').evaluateAll((els) =>
    els.slice(0, 80).map((el) => ({
      text: el.innerText,
      href: el.getAttribute('href'),
      testid: el.getAttribute('data-test-subj'),
    }))
  );
  console.log('ANCHORS', JSON.stringify(links, null, 2));
  console.log('SVG_LINK_COUNT', await page.locator('svg a').count());
  console.log('SVG_TEXT_COUNT', await page.locator('svg text').count());
  console.log('TSVB_MARKDOWN_COUNT', await page.locator('[data-test-subj=\"tsvbMarkdown\"]').count());
  const markdownBodies = await page.locator('.kbnMarkdown__body').evaluateAll((els) =>
    els.map((el) => ({
      text: el.innerText,
      html: el.innerHTML,
    }))
  );
  console.log('MARKDOWN_BODIES', JSON.stringify(markdownBodies, null, 2));

  const openAlerts = page.getByRole('link', { name: 'Open pfSense Alerts' });
  if (await openAlerts.count()) {
    await openAlerts.click();
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(3000);
    const bodyText = await page.locator('body').innerText();
    console.log('CLICK_URL', page.url());
    console.log('CLICK_TITLE', await page.title());
    console.log('CLICK_HAS_TARGET', bodyText.includes('SOC pfSense Alerts - Open'));
  }

  await page.goto(`${baseUrl}/app/dashboards#/view/soc-pfsense-executive`, { waitUntil: 'networkidle' });
  await page.waitForTimeout(3000);
  const panels = page.locator('[data-shared-item="true"]');
  if (await panels.count()) {
    const box = await panels.first().boundingBox();
    if (box) {
      await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
    }
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(2500);
    const clickedBody = await page.locator('body').innerText();
    console.log('PANEL_CLICK_URL', page.url());
    console.log('PANEL_CLICK_HAS_TARGET', clickedBody.includes('SOC pfSense Alerts - Open'));
  }

  await page.goto(`${baseUrl}/app/dashboards#/view/soc-pfsense-executive`, { waitUntil: 'networkidle' });
  await page.waitForTimeout(3000);
  if ((await panels.count()) > 5) {
    const timeline = panels.nth(5);
    const box = await timeline.boundingBox();
    if (box) {
      await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
    }
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(2500);
    const timelineBody = await page.locator('body').innerText();
    console.log('TIMELINE_CLICK_URL', page.url());
    console.log('TIMELINE_CLICK_HAS_TARGET', timelineBody.includes('SOC pfSense Alerts'));
  }

  await browser.close();
})();
