# Public edition and private backup

Owner's decision on 24 September 2026: publish original code under MIT, reserve artwork/audio rights, and retain a private backup of the complete project.

- Public: `cesswhite/Brasa`, with fresh history excluding audio and video files.
- Private backup: `cesswhite/Brasa-private-backup`, with the original history and audio pack.
- The original local project retains its files. The public edition is maintained in a separate checkout.

Do not publish the backup or transfer all its references with `push --mirror` or `push --all`. To bring an improvement into the public edition, review the diff and transfer only files whose distribution is permitted.

Provenance records remain as documentation. Some historical reports refer to unpublished local artifacts. Tests that depend on the full audio pack cannot be reproduced from the public checkout alone. Report that limitation instead of creating fake samples.

## Publication checks

Review files and history for credential patterns, audio/video exclusions, third-party notices, entry-point links, skill references, and startup without the audio pack. These checks do not constitute a comprehensive security audit or verify every provider's generation plan.

Keep [LICENSING.md](../LICENSING.md) as the licensing scope. Brasa's MIT notice does not replace Apache-2.0/MIT notices for derived components or grant rights to reserved assets.

Documentation, reports, and skill instructions are in English. The game itself is in Spanish. Keep review evidence in Markdown and screenshots; do not restore development-only HTML galleries. The backend's authentication page is application code and remains included.
