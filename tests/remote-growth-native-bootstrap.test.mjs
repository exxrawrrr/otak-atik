import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";

const base = "scripts/windows/remote-growth-native";
const template = "examples/remote-growth-native/plugin-template";

test("native bootstrap assets exist", () => {
  for (const file of [
    `${base}/start-here.ps1`,
    `${base}/setup-tunnel.ps1`,
    `${base}/run-tunnel.ps1`,
    `${base}/status-tunnel.ps1`,
    `${base}/stop-tunnel.ps1`,
    `${base}/doctor.ps1`,
    `${base}/build-plugin.ps1`,
    `${template}/plugin.json`,
    `${template}/.app.json.template`
  ]) {
    assert.equal(fs.existsSync(file), true, "missing " + file);
  }
});

test("native tunnel setup keeps identity and secrets out of repository paths", () => {
  const setup = fs.readFileSync(`${base}/setup-tunnel.ps1`, "utf8");
  const run = fs.readFileSync(`${base}/run-tunnel.ps1`, "utf8");

  assert.match(setup, /LOCALAPPDATA/);
  assert.match(setup, /CONTROL_PLANE_/);
  assert.match(setup, /ConvertFrom-SecureString/);
  assert.match(setup, /SHA256SUMS\.txt/);
  assert.doesNotMatch(setup, /D:\\RAFDI_DATA/i);
  assert.doesNotMatch(run, /D:\\RAFDI_DATA/i);
  assert.doesNotMatch(setup, /plugin_asdk_app_[0-9a-f]{32}/i);
});

test("public plugin template contains no live app binding", () => {
  const manifest = JSON.parse(fs.readFileSync(`${template}/plugin.json`, "utf8"));
  const appTemplate = fs.readFileSync(`${template}/.app.json.template`, "utf8");

  assert.equal(manifest.extensions?.["com.openai"]?.apps, undefined);
  assert.match(appTemplate, /REPLACE_WITH_YOUR_OWN_APP_ID/);
  assert.doesNotMatch(appTemplate, /plugin_asdk_app_[0-9a-f]{32}/i);
});

test("plugin builder generates app binding outside the checkout", () => {
  const builder = fs.readFileSync(`${base}/build-plugin.ps1`, "utf8");

  assert.match(builder, /LOCALAPPDATA/);
  assert.match(builder, /plugin_asdk_app_/);
  assert.match(builder, /secret scan/i);
  assert.match(builder, /Join-Path \$Build '\.app\.json'/);
  assert.doesNotMatch(builder, /plugin_asdk_app_[0-9a-f]{32}/i);
});
