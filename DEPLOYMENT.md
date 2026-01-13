# Deployment Guide - Pub.dev Publishing

This guide covers how to deploy and update `flutter_cache_cleaner` on pub.dev.

## Publishing a New Version

### 1. Pre-Deployment Checklist

Before deploying, ensure:
- [ ] All changes are committed and pushed to GitHub
- [ ] Code analysis passes: `dart analyze`
- [ ] All tests pass (if applicable)
- [ ] README.md and CHANGELOG.md are updated
- [ ] Version number in `pubspec.yaml` follows semantic versioning

### 2. Update Version

Update the version in `pubspec.yaml`:

```yaml
version: 0.1.1  # Follow semantic versioning: MAJOR.MINOR.PATCH
```

**Versioning Guidelines:**
- **PATCH** (0.1.0 → 0.1.1): Bug fixes, backward compatible
- **MINOR** (0.1.0 → 0.2.0): New features, backward compatible
- **MAJOR** (1.0.0 → 2.0.0): Breaking changes

### 3. Update CHANGELOG.md

Add an entry for the new version:

```markdown
## [0.1.1] - 2024-XX-XX

### Fixed
- Fixed verbose flag parsing issue
- ...

### Added
- ...
```

### 4. Dry Run

Always run a dry-run before publishing:

```bash
dart pub publish --dry-run
```

**Check for:**
- Files that will be included/excluded
- Package size
- Any validation errors or warnings
- Dependencies resolution

### 5. Commit and Tag

```bash
git add pubspec.yaml CHANGELOG.md
git commit -m "Bump version to 0.1.1"
git tag v0.1.1
git push origin main --tags
```

### 6. Publish to Pub.dev

```bash
dart pub publish
```

**During publish:**
- You'll be prompted for your pub.dev credentials
- Review the summary before confirming
- Type `y` to confirm publication

### 7. Verify Publication

After publishing:
1. Visit https://pub.dev/packages/flutter_cache_cleaner
2. Verify the package version appears correctly
3. Test installation:
   ```bash
   dart pub global activate flutter_cache_cleaner
   flutter_cleaner --help
   ```

## Updating an Existing Version

If you need to update a version that's already published (e.g., critical bug fix):

1. **Increment the patch version** in `pubspec.yaml`
2. **Update CHANGELOG.md** with the fix
3. **Follow steps 4-7** from the publishing workflow above

**Note:** You cannot republish the same version number. Always increment the version.

## Quick Reference

### Common Commands

```bash
# Dry run
dart pub publish --dry-run

# Publish
dart pub publish

# Verify locally
dart analyze
dart pub global activate --source path .
flutter_cleaner --help
```

### Version Bump Workflow

```bash
# 1. Update version in pubspec.yaml
# 2. Update CHANGELOG.md
# 3. Commit and tag
git add pubspec.yaml CHANGELOG.md
git commit -m "Bump version to X.Y.Z"
git tag vX.Y.Z
git push origin main --tags

# 4. Publish
dart pub publish
```

## Troubleshooting

### "Version already published"
- The version number already exists on pub.dev
- **Solution:** Increment the version in `pubspec.yaml`

### "Package validation failed"
- Check the error message for specific issues
- Common causes: missing LICENSE, invalid pubspec.yaml, dependency issues
- **Solution:** Fix the issue and run `dart pub publish --dry-run` again

### "Authentication failed"
- Verify your pub.dev credentials
- If 2FA is enabled, you may need an app password
- **Solution:** Try logging in at pub.dev first, then retry

### "Dependency resolution failed"
- Check all dependencies are published to pub.dev
- Verify version constraints are compatible
- **Solution:** Run `dart pub get` locally to test

## Post-Deployment

After successful deployment:
- [ ] Verify package is live on pub.dev
- [ ] Test installation from pub.dev
- [ ] Monitor for any issues or questions
- [ ] Update documentation if needed

## Additional Resources

- [Pub.dev Publishing Guide](https://dart.dev/tools/pub/publishing)
- [Semantic Versioning](https://semver.org/)
- [Pub.dev Package Health](https://pub.dev/help/scoring)
