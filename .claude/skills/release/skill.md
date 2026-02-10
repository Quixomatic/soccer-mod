# Release

Creates a new versioned release of the Soccer Mod plugin. Updates version strings in all required files, commits, tags, and pushes to trigger the GitHub Actions release workflow.

## Usage

```
/release <version>
```

Where `<version>` is the version number without the `v` prefix (e.g., `1.4.24`).

## Instructions

1. **Validate** the version argument is provided and follows semver-ish format (e.g., `1.4.24`)

2. **Check CHANGELOG.md** for an entry matching `## <version>`. If no entry exists, stop and ask the user to write one first. The changelog entry is required before releasing.

3. **Update version in all three locations:**
   - `addons/sourcemod/scripting/soccer_mod.sp` - Update `#define PLUGIN_VERSION "<version>"` (line 4)
   - `package.json` - Update `"version": "<version>"`
   - `CHANGELOG.md` - Should already have the entry (verified in step 2)

4. **Build to verify** - Run `npm run build` to confirm the plugin compiles successfully with the new version. If build fails, stop and report the error.

5. **Show the user a summary** of all changes made and ask for confirmation before committing.

6. **Commit and tag:**
   - Stage the modified files: `soccer_mod.sp`, `package.json`, `CHANGELOG.md` (and any other changed files the user confirms)
   - Commit with message: `Release v<version>`
   - Create git tag: `v<version>`

7. **Push to remote:**
   - `git push`
   - `git push origin v<version>`
   - This triggers the GitHub Actions workflow that compiles, packages, and creates the GitHub Release

8. **Confirm** the push succeeded and remind the user to check the GitHub Actions tab for the release build status.

## Example

```
/release 1.4.24
```

This will:
- Verify `CHANGELOG.md` has a `## 1.4.24` entry
- Update `PLUGIN_VERSION` to `"1.4.24"` in soccer_mod.sp
- Update `"version"` to `"1.4.24"` in package.json
- Build with `npm run build`
- Commit as "Release v1.4.24"
- Tag as `v1.4.24`
- Push commit and tag to origin
