---
layout: post
title: "Reauthing a CLI when its session quietly expires"
date: 2026-11-14
categories: [Blog, Nix]
tags: [automation, ai, technology, cybersecurity]
description: "A pattern for re-authenticating a command-line client that signs in through a hosted identity provider, when the stored token looks healthy but the session behind it is gone."
author: matt
pin: false
toc: true
comments: false
math: false
mermaid: false
---

Every CLI that authenticates through a hosted identity provider eventually lands in the same place: a config file full of plausible-looking credentials, an API that answers `401`, and no obvious reason the two disagree. This is the generic playbook I now use for that class of problem. It is written as a hypothetical process — placeholders only, no host names or identifiers.

The shape of the failure: the API is fine, the token file parses, and the session behind the token is not what the file claims.

## Step 1: establish what the server thinks

Before touching local files, ask the identity provider about the session. Most of them expose a read endpoint for the client object, which reports each session with a status, a last-activity time, and an expiry time:

```
GET https://clerk.<domain>/v1/client
Cookie: __client=<client-cookie>
```

Three outcomes matter, and they are not interchangeable:

- **`active`** — the session is alive; the problem is local (a stale token, a wrong field, a rejected header).
- **`expired`** — the session reached its own `expire_at` and cannot be revived. A token refresh will fail forever, and `POST …/sessions/{id}/touch` will answer `401 signed out`.
- **absent** — the session was deleted, or the client cookie points at a different client than the token does.

The distinction earns its keep: an expired session is not a credential-file bug, and no amount of editing the file will fix it.

The arithmetic behind `expired` is usually a fixed window from `last_active_at`, not from the last successful token refresh. **Minting a short-lived token does not count as activity.** That is the subtle trap: a keepalive that mints every hour can look perfectly healthy in its own logs while the session ages out on schedule. Only a real client interaction — a page load, an explicit touch call while the session is still active — moves `last_active_at`.

Corollary for the keepalive unit: log the *refresh success rate*, and separately assert that the session's remaining lifetime is not shrinking toward zero. A green timer proves nothing about either.

## Step 2: confirm the local file is not the only problem

Local corruption is common but it is a second-order cause. Check for it explicitly, because a hand-edit made while debugging can outlive the original fault:

- A token field that is shorter than any real JWT, or contains an obvious literal (some CLIs will happily save a flag value as a token if you pass one where a credential is expected — never invoke `login --help` on a tool that takes its argument positionally).
- A cached user/account object that has been nulled out. Several clients send the token correctly and still get `401` because a downstream field they echo is missing.
- A client cookie that no longer matches the session id.

Verify by extracting the JWT claims: issuer, subject, audience, session id, and expiry should all correspond to what the provider reports. A token with correct claims that still gets rejected almost always means the *file around it* is stale, not the token.

## Step 3: get one working credential source

For a recovery that avoids the browser entirely, the least invasive route is a reset code delivered to a mailbox you can read programmatically:

```
# ask the provider to mail a code to the account
POST …/v1/client/sign_ins
  strategy=reset_password_email_code
  identifier=<account>

# read it over IMAP rather than a browser
<mail client> list --newest 5 | grep -oE '[0-9]{6} is your (reset )?(password|verification) code'

# verify it on THAT sign-in object, not the collection endpoint
POST …/v1/client/sign_ins/<sign-in-id>/attempt_first_factor
  strategy=reset_password_email_code
  code=<code>
```

Two failure modes worth pre-empting. First, the code is scoped to the sign-in object, so a code obtained earlier in the debugging session will fail with a code-incorrect error against a later one. Second, verification posted to the collection endpoint can return `200` and simply not apply; the object-scoped path is the one that changes status.

If the account has a password you can recover from a password manager, a plain password sign-in is fewer steps — but keep a cookie jar:

```
curl -c $J -b $J … -d 'strategy=password' -d "identifier=$USER" --data-urlencode "password=$PW"
curl -c $J -b $J -X POST "…/v1/client/sessions/$SID/tokens" -d '{}'
```

Without `-c/-b`, the provider rotates its client cookie during sign-in and the token mint fails with `401` for reasons that look like a credentials problem but are a cookie problem.

## Step 4: make the prevention structural

A recovery runbook is a symptom. The structural fixes are:

1. **An explicit environment in the service unit.** Package managers love to suggest declaring binaries as top-level unit keys; a key the unit parser does not recognise is silently dropped, and the failure surfaces as "executable not found" hours later. Use an explicit `PATH` in an environment assignment.
2. **A touch call, not just a token mint,** on a schedule shorter than the provider's idle window — and a check on whether it actually moved the expiry. Measured on one hosted provider: a touch moved `last_active_at` to now, while `expire_at` stayed pinned at seven days after the session was created. Extending the idle clock and extending the session are different promises, so the keepalive must read `expire_at` and fail loudly when it enters the last day or two; a periodic real sign-in stays in the runbook either way.
3. **A gate that asks the API, not the local file.** A cheap `usage`/`whoami`-style call against the real endpoint is the only honest health check; several CLIs report success from a refresh helper that would accept a fabricated token.
4. **Never hand-edit the credential file.** If a field has to change, find the command that owns it, or reconstruct the object from the provider's own response.

## What to take away

- Ask the provider about the session before editing anything locally.
- Treat "expired" and "unauthorised" as different bugs with different fixes.
- A token mint is not activity; a keepalive that only mints will still let a session die on schedule.
- Recovery is a one-off, but the shape of the outage tells you which of the four structural fixes is missing.
