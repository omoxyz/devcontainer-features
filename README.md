# Omoxyz Dev Container Features

Custom features for dev containers used in development of Omoxyz software projects using Visual Studio Code. It ensures all developers have consistent tools and configurations.

## Features

- **Lefthook** ([lefthook](./src/lefthook/README.md)) – fast polyglot Git hooks manager to automate code checks, formatting, and tests before commits and pushes.
- **Air** ([go-air](./src/go-air/README.md)) - live reloader for Go apps.
- **Protoc** ([protoc](./src/protoc/README.md)) - protocol buffer compiler.
- **Protolint** ([protolint](./src/protolint/README.md)) - linter and fixer to enforce Protocol Buffer style and conventions.

## Usage

*Please refer to `README.md` file of the feature you want to use located in `src/{feature-id}` folder.*

## Development

1. Open this project in Container
2. Install git hooks
    ```bash
    npm install
    ```
3. To test all features, launch `Test All Features`
4. To test specific features, launch `Test Features (input)` and input a list of features you want to test separated by spaces.
5. To run global test, launch `Test Global`.
6. Use [commit conventions](https://www.conventionalcommits.org/en/v1.0.0/) for commit messages.