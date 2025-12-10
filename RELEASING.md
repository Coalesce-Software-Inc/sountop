# Releasing soundmon

This document describes how to release a new version of soundmon and publish it to Homebrew.

## Prerequisites

1. A GitHub repository at `github.com/mmccune/soundmon`
2. A Homebrew tap repository at `github.com/mmccune/homebrew-tap`

## Creating a Homebrew Tap

If you haven't already, create your tap repository:

```bash
# Create a new repo named homebrew-tap on GitHub, then:
mkdir -p ~/devel/homebrew-tap/Formula
cd ~/devel/homebrew-tap

# Copy the formula
cp /path/to/soundmon/Formula/soundmon.rb Formula/

git init
git add .
git commit -m "Add soundmon formula"
git remote add origin git@github.com:mmccune/homebrew-tap.git
git push -u origin main
```

## Release Process

### 1. Update version (if using version tags in code)

Update any version strings in the code if applicable.

### 2. Commit all changes

```bash
git add .
git commit -m "Prepare for v1.0.0 release"
git push
```

### 3. Create and push a tag

```bash
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

### 4. GitHub Actions (automatic)

If you've set up the GitHub Actions workflow (`.github/workflows/release.yml`), it will:
- Build the binary
- Create a release archive
- Calculate SHA256
- Create a GitHub Release with the archive attached

### 5. Update Homebrew Formula (manual step)

After the release is created:

```bash
# Get the SHA256 of the release tarball
curl -sL https://github.com/mmccune/soundmon/archive/refs/tags/v1.0.0.tar.gz | shasum -a 256
```

Update `Formula/soundmon.rb` in your `homebrew-tap` repo:

```ruby
class Soundmon < Formula
  # ...
  url "https://github.com/mmccune/soundmon/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "YOUR_ACTUAL_SHA256_HERE"
  # ...
end
```

Commit and push the formula update:

```bash
cd ~/devel/homebrew-tap
git add Formula/soundmon.rb
git commit -m "Update soundmon to v1.0.0"
git push
```

### 6. Test the installation

```bash
brew update
brew install mmccune/tap/soundmon
# or if already installed:
brew upgrade soundmon
```

## Version Bumping Checklist

- [ ] Update version in README if displayed
- [ ] Update CHANGELOG (if you have one)
- [ ] Commit all changes
- [ ] Create git tag
- [ ] Push tag to trigger release workflow
- [ ] Update Homebrew formula with new URL and SHA256
- [ ] Test `brew install`

## Quick Release Commands

```bash
# Set the version
VERSION=1.0.0

# Tag and release
git tag -a v${VERSION} -m "Release v${VERSION}"
git push origin v${VERSION}

# After GitHub release is created, get SHA256:
curl -sL https://github.com/mmccune/soundmon/archive/refs/tags/v${VERSION}.tar.gz | shasum -a 256

# Update formula, then test:
brew update && brew reinstall mmccune/tap/soundmon
```
