# Contributing

Thanks for contributing to `openclaw-memory-final`.

## Ways to contribute

- Improve docs and examples
- Improve cron prompts and reliability logic
- Add migration helpers for different environments
- Report bugs and propose improvements

## Development workflow

1. Fork and create a feature branch.
2. Run validation:
   ```bash
   bash scripts/validate.sh
   ```
3. Keep changes minimal and well documented.
4. Open a PR with:
   - problem statement
   - what changed
   - risk/rollback notes

## Commit style (recommended)

- `feat:` new capability
- `fix:` bug fix
- `docs:` documentation
- `chore:` maintenance

## PR checklist

- [ ] Docs updated
- [ ] Examples updated (if behavior changed)
- [ ] Validation script passes
- [ ] Backward compatibility considered
