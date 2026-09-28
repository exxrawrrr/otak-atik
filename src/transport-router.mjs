export const transports = {
  local: {
    id: "desktop-commander-local",
    label: "Desktop Commander local MCP",
    quota: "local",
    hops: 1
  },
  remote: {
    id: "remote-desktop-commander",
    label: "Remote Desktop Commander",
    quota: "hosted-remote",
    hops: 2
  },
  browser: {
    id: "mcp-superassistant",
    label: "MCP SuperAssistant browser bridge",
    quota: "local",
    hops: 3
  },
  gui: {
    id: "gui-control-mcp",
    label: "GUI-control MCP provider",
    quota: "provider-dependent",
    hops: 2
  }
};

export function chooseTransport(input = {}) {
  const {
    sameMachine = false,
    remoteAccess = false,
    browserOnly = false,
    nativeMcpAvailable = true,
    guiRequired = false,
    remoteQuotaRemaining = null
  } = input;

  if (guiRequired) {
    return {
      ...transports.gui,
      reason: "Task requires screen-level interaction such as screenshot, click, type, drag, or scroll.",
      fallback: sameMachine ? transports.local.id : transports.remote.id
    };
  }

  if (sameMachine && !browserOnly) {
    return {
      ...transports.local,
      reason: "AI client and target machine are local; a hosted relay adds no locality benefit.",
      fallback: transports.remote.id
    };
  }

  if (browserOnly && !nativeMcpAvailable && sameMachine) {
    return {
      ...transports.browser,
      reason: "Browser AI needs a local MCP bridge and no convenient native MCP connector is available.",
      fallback: transports.local.id
    };
  }

  if (remoteAccess || !sameMachine) {
    const quotaWarning =
      Number.isFinite(remoteQuotaRemaining) && remoteQuotaRemaining < 1000
        ? "Remote quota is low; reserve this path for genuinely remote work."
        : null;

    return {
      ...transports.remote,
      reason: "The AI client is remote from the target computer, so the hosted relay provides real value.",
      fallback: transports.local.id,
      warning: quotaWarning
    };
  }

  return {
    ...transports.local,
    reason: "Local MCP is the lowest-hop default for an ambiguous same-machine workflow.",
    fallback: transports.remote.id
  };
}
