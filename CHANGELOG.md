# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2025-01-11

### Added
- **Quote Text Objects**: Support for `yi"`, `ya"`, `yi'`, `ya'`, `` yi` ``, `` ya` ``
  - Yank text inside or around double quotes, single quotes, and backticks
  - Simple matching algorithm (no escape sequence support)
- **Bracket Text Objects**: Support for parentheses, square brackets, curly braces, and angle brackets
  - Inner variants: `yi(`, `yi)`, `yi[`, `yi]`, `yi{`, `yi}`, `yi<`, `yi>`
  - Around variants: `ya(`, `ya)`, `ya[`, `ya]`, `ya{`, `ya}`, `ya<`, `ya>`
  - Simple matching algorithm (no nested bracket support)
- Comprehensive test suite for quote and bracket text-objects (19 test cases)
- Enhanced documentation with examples for all text-object types

### Changed
- Updated README.md with detailed usage examples for quotes and brackets
- Improved code documentation with detailed function comments

## [1.0.0] - 2025-01-10

### Added
- Initial release with word and WORD text-objects
- Support for `yiw`, `yaw`, `yiW`, `yaW` commands
- Cross-platform clipboard support (pbcopy, clip.exe, xclip, wl-copy)
- Automatic copy-mode exit after yanking
- TPM (Tmux Plugin Manager) compatibility
