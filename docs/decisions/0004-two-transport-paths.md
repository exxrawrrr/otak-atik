# ADR 0004 — Remote MCP and browser bridge are separate paths

## Status

Accepted.

## Context

The original experimental setup used both a Remote Desktop Commander connector and MCP SuperAssistant in Chrome.

This created understandable confusion about whether both were required.

## Decision

otak-atik documents two independent transport modes:

1. Remote Desktop Commander remote MCP — recommended default for compatible clients.
2. MCP SuperAssistant browser bridge — optional compatibility mode.

Neither is modeled as a prerequisite for the other.

## Consequence

The Windows installer may prepare helpers for both, but first-run guidance recommends Remote Desktop Commander and labels browser-bridge launchers as optional.
