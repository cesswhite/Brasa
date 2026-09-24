# Security

Do not post credentials, account data, or exploit instructions against live services in a public issue. Use private vulnerability reporting on the repository's Security tab. If it is unavailable, ask the maintainer for a private contact channel without including sensitive details.

Historical reports refer to the owner's staging service. Publishing this code does not authorize load testing, access to other accounts, migrations, or deployments against that service. Reproduce findings with an isolated local database or in an environment you are authorized to test.

Keep secrets out of Git. If a credential leaks, revoke or rotate it first. Deleting it from the current revision does not remove copies or Git history. Never print session tokens in reports.

No response time or comprehensive security audit is promised. Test reports apply to their stated date and revision.
