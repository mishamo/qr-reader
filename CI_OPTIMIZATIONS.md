# CI Build Optimizations

## Why Builds Were Slow (7-9 minutes)

1. **Flutter SDK Download** - ~1-2 minutes every build
2. **Gradle Dependencies** - ~2-3 minutes downloading JARs
3. **Pub Dependencies** - ~30-60 seconds
4. **No Build Caching** - Rebuilding everything from scratch

## Optimizations Applied

### 1. Flutter SDK Caching
```yaml
cache: true  # Caches the Flutter SDK between builds
```
**Saves**: ~1-2 minutes

### 2. Gradle Caching
```yaml
cache: 'gradle'  # In Java setup
# Plus explicit Gradle cache for wrapper and dependencies
```
**Saves**: ~2-3 minutes

### 3. Pub Dependencies Caching
```yaml
# Caches ~/.pub-cache and .dart_tool
```
**Saves**: ~30-60 seconds

### 4. Build Artifacts Caching
```yaml
# Caches intermediate build files (excluding final APK)
```
**Saves**: ~1-2 minutes on incremental builds

## Expected Results

### Before Optimizations
- First build: 7-9 minutes
- Subsequent builds: 7-9 minutes (no caching)

### After Optimizations
- First build: 7-9 minutes (builds caches)
- Subsequent builds: **2-4 minutes** (using caches)

## Cache Strategy

Caches are keyed by:
- **Pub**: `pubspec.lock` hash
- **Gradle**: Gradle files hash
- **Build**: Source files hash

This ensures caches are invalidated when dependencies or code changes.

## Additional Speed Tips

### For Faster Testing
Consider creating a separate workflow for debug builds:
- Debug builds are ~30% faster than release builds
- Skip ProGuard/R8 optimization
- No code shrinking/obfuscation

### Parallel Jobs
For multiple variants, use matrix builds:
```yaml
strategy:
  matrix:
    include:
      - build-type: debug
      - build-type: release
```

### Self-Hosted Runners
For maximum speed, consider self-hosted runners with:
- Pre-installed Flutter SDK
- Pre-cached dependencies
- Persistent Gradle daemon

## Monitoring Performance

Check build times in GitHub Actions:
1. Go to Actions tab
2. Click on a workflow run
3. View timing for each step

Cache hit rates visible in "Cache" steps - should be 90%+ after first build.