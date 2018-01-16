# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)

## [2.0.0] - 2018-01-16

## Added
- PR template

## Changed
- README to reflect the actual, encouraged API based on simple Restful
  verbs.

## Removed
- `modules` method from `Okapi::Client` and `modules:index` command
  from the CLI.

## [1.0.2] - 2017-11-01

### Changed
- FIX problem where `bundler` needed to be installed for the
  executable `okapi` to function.

## [1.0.1] - 2017-10-27

### Added
- command line client to interact with an OKAPI gateway within a
  shell. `okapi -h` for details after installing the gem.
