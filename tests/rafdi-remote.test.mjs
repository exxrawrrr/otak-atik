import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";

const setup = fs.readFileSync(
  "experiments/rafdi-remote-growth/setup.ps1",
  "utf8"
);
const supervisor = fs.readFileSync(
  "experiments/rafdi-remote-growth/templates/supervisor.ps1.tmpl",
  "utf8"
);
const common = fs.readFileSync(
  "experiments/rafdi-remote-growth/lib/common.ps1",
  "utf8"
);

test("Rafdi Remote keeps Windows-MCP loopback-bound and bearer-protected", () => {
  assert.match(supervisor, /'--host','127\.0\.0\.1'/);
  assert.doesNotMatch(supervisor, /'--host','0\.0\.0\.0'/);
  assert.match(supervisor, /WINDOWS_MCP_AUTH_KEY/);
  assert.match(supervisor, /FASTMCP_HTTP_HOST_ORIGIN_PROTECTION\s*=\s*'true'/);
  assert.match(supervisor, /FASTMCP_HTTP_ALLOWED_HOSTS/);
});

test("Rafdi Remote enables proxy compatibility only for public mode", () => {
  assert.match(supervisor, /if \(\$AllowProxyHostOverride\)/);
  assert.match(supervisor, /\$arguments \+= '--allow-insecure-remote'/);
  assert.match(setup, /\{\{ALLOW_PROXY_HOST_OVERRIDE\}\}/);
  assert.match(setup, /if \(\$SkipFunnel\) \{ '\$false' \} else \{ '\$true' \}/);
  assert.match(setup, /\$dnsName \+ ':\*'/);
  assert.match(setup, /'localhost:\*'/);
  assert.match(setup, /'127\.0\.0\.1:\*'/);
});

test("Rafdi Remote requires explicit first-time Funnel publication", () => {
  assert.match(setup, /One-time Tailscale Funnel step/);
  assert.match(
    setup,
    /Public exposure is intentionally not enabled automatically/
  );
  assert.match(setup, /funnel --bg --yes --https=/);
});


test("Rafdi Remote detects Windows across PowerShell hosts", () => {
  assert.match(common, /Get-Variable -Name IsWindows/);
  assert.match(common, /\$PSVersionTable\.PSEdition -eq 'Desktop'/);
  assert.match(common, /\$env:OS -eq 'Windows_NT'/);
});
