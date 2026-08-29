# Contributing

Contributions that keep Triple Space Comma small, native, private, and predictable are welcome.

## Development

Requirements: macOS 13 or newer, Git, and Apple's Command Line Tools.

```bash
git clone https://github.com/kingabuomar/triple-space-comma.git
cd triple-space-comma
make test
make build
```

Before opening a pull request:

1. Add or update tests for gesture-state behavior.
2. Run `make test` and `make build`.
3. Confirm the app stores no typed content and introduces no network dependency.
4. Explain any Accessibility-permission or installer impact in the pull request.

Keep pull requests focused. Do not include real keystroke logs or user data.
