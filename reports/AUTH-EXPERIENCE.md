# Enter the world of Brasa

## Pre-implementation audit

Inspection confirmed Better Auth 1.7.5 + @better-auth/passkey 1.7.5, SimpleWebAuthn in browser and Worker/D1. Godot does not implement native WebAuthn: it uses device authorization and an opaque bearer. There are no passwords, real mail, or public administrative recovery. The secrets remained in memory; Closing Godot required repeating the pairing. Previous sources are at `work/auth-experience/before`.

| Previous step | Information/action | Need | Decision |
|---|---|---|---|
| Open Online | Title, long explanation and browser button | Choose destination | SIMPLIFY: figure/world and Continue |
| Get code | Technical status, code, reopen and cancel | Link the correct game | KEEP code; MERGE context and wait |
| Initial website | Biometric explanation, login, registration and warning together | Choose to enter or start | SIMPLIFY: a state and a primary action |
| Account name | Field before creating credential | Better Auth requires a label, not verified identity | REMOVE required field; Traveler initial tag, in-game fighter name |
| Passkey ceremony | Reliable browser/system prompt | Proof of possession and user verification | KEEP; without biometric imitation |
| Access success | Message before authorizing code | Not a useful destination | MERGE with game confirmation |
| Confirm code | Compare and approve/reject | Linking consent, protection against another request | explicit KEEP; never approve on upload or login |
| Linking success | Polling message and wait | Browser can't focus Godot guaranteed | SIMPLIFY: return to the game, without another Continue |
| fighter charge | Identity requests, catalog and fighters | Authoritative server | AUTOMATE |
| New fighter | Name, basis and creation | Real game decision | KEEP; separate account |
| Close/open Godot | Repeat everything because bearer only lives in memory | Lack of secure storage | AUTOMATE on macOS with Keychain; memory on platforms without adapter |
| Second credential | Always visible next to the login | Useful, not necessary when entering | MOVE to Account/Security |
| Recovery | Long warning on onboarding | There is no property test fallback | SIMPLIFY secondary route, use synchronized passkey/other device; report actual limit |

## Safety inspected

Preserved exact origin/RP, required residentKey, cryptographic library verification and additional server rejection of userVerified=false, five-minute signed nonce and one-time consumption on D1, account isolation, protected cookies, explicit device authorization, expiration/polling, revocation, D1 rate limiting, and recent sessions to add passkeys. The game API does not accept cookies as a substitute for the bearer. No name, appearance or local hint grants access. No passwords, OTP or recovery for personal data are added.

The scope is the UX and persistence of the existing session, without changing provider, D1 schema, secrets, economics or real accounts. The supported and testable operating system in this project is macOS; Other systems retain browser access and credentials in memory until incorporating specific secure storage. The sandboxed distribution requires including and signing the helper as an embedded executable.

## Verified references

- [Better Auth passkeys](https://better-auth.com/docs/plugins/passkey): Registration/login API without email and discoverable credentials, compared to installed fixed packages.
- [Device Authorization](https://better-auth.com/docs/plugins/device-authorization) and [sessions](https://better-auth.com/docs/concepts/session-management): Explicit consent is maintained; the token is an opaque session, refresh OAuth is not invented.
- [Cloudflare Node compatibility](https://developers.cloudflare.com/workers/runtime-apis/nodejs/): Nodejs_compat and D1 are preserved.
- [Apple Keychain](https://developer.apple.com/documentation/security/keychain-services) and [Godot OS pipes](https://docs.godotengine.org/en/stable/classes/class_os.html#class-os-method-execute-with-pipe): System storage and communication without arguments containing secrets.
- [FIDO / Passkey Central](https://www.passkeycentral.org/design-guidelines/): Brief context, system experience and progressive help.

## Implementation and validation

| Before | After | Check |
| --- | --- | --- |
| Record with account field and various actions | Start + system prompt; identity of the fighter after | Real WebAuthn with virtual authenticator |
| Repeat link when opening game | macOS Keychain, server validation, restore | 16 session/IPC tests |
| Form-like login | World, figure, Continue and secondary help | Desktop and 390×844; history materials |
| Visible technical errors | Short messages; silent cancellation | Cancellation, network and server error cases |
| Security mixed with entry | Account / Security and second passkey | Second authenticator and recent session |

Validation: 8 backend security groups; 13 local browser scenarios with WebAuthn signatures; 16 session and Keychain checks; 815 Godot UI checks with native captures. The fixtures use temporary D1, new Chrome and an exclusive test namespace in Keychain, which is deleted when finished. No personal accounts were used. Screenshots do not represent actual conversion rates.

UX deployment in the existing Worker staging, without migrations or account changes. The device code still requires confirmation. No recovery is promised if all passkeys are lost. Secure persistence implemented for macOS; the other platforms continue using memory until they have their specific adapter.

Evidence: `work/auth-experience/browser/results.json`, `godot-session.log`, `native.log`, `backend-auth-tests.log`, `deploy.log`; PNG in `browser/` and `native/`.

Final cancellation check during write-safe: The token is published as an active session only after persistence without cancellation ends. API 27/0, session and Keychain 16/0. The later staging version `2761b4cc-373f-4dca-bb84-0074498447d3` preserves this UX and incorporates the family catalog.
