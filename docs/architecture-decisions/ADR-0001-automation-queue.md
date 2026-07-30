# ADR-0001: Automation queue vs handbook module IDs

## Status

Accepted

## Context

The handbook defines coarser modules; the master automation prompt defines a finer 120-module queue.

## Decision

Use the automation queue for delivery sequencing. Map every handbook requirement in HANDBOOK_TRACEABILITY.md.

## Consequences

More frequent owner test gates; clearer boundaries; no silent dropping of handbook requirements.
