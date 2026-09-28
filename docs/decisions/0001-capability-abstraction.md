# ADR 0001 — Capability abstraction

## Status

Accepted.

## Decision

Skills depend on provider-neutral capability IDs rather than provider tool names.

## Why

Provider names, schemas, and transports change.

The job described by a skill usually does not.

## Consequence

Adapters must translate provider functionality into the canonical capability vocabulary.
