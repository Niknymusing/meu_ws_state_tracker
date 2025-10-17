# MEU System Workspace State Tracker

A Haskell-based Workspace State Tracker for the Model-Execute-Update (MEU) framework that manages software project development through a network of interconnected MEU triplets.

## Overview

The MEU System Workspace State Tracker is the core orchestrator for the Model-Execute-Update framework, providing:

- **MEU Triplet Management**: Create, refine, and track MEU triplets with their M, E, U domains
- **Registry System**: Maintain comprehensive registries for types, values, DSL primitives, tests, and axioms
- **Geometric Logic Verification**: SMT-based verification of acceptance criteria using geometric formulas
- **Concurrent Operations**: Thread-safe operations using STM for high-performance concurrent access
- **Dataflow Management**: Type-safe dataflow arrows between MEU triplet domains

## Quick Start

### Prerequisites

- GHC 9.6+
- Cabal 3.8+ or Stack 2.13+
- Z3 SMT solver (automatically installed with SBV)

### Installation

```bash
# Clone and build
git clone https://github.com/meu-framework/ws-state-tracker.git
cd ws-state-tracker
cabal build

# Run the CLI
cabal exec meu-ws-tracker -- --help
```

### Basic Usage

```bash
# Initialize a new MEU system
meu-ws-tracker init --project-name "my-project" --description "My MEU project"

# Start the state tracker server
meu-ws-tracker server --port 8080

# Create a source triplet
meu-ws-tracker triplet create --type source --description "Main triplet"
```

## Architecture

The system is built using advanced Haskell features:

- **GADTs** for type-safe MEU triplet domains
- **Effectful monads** for stacked computation
- **STM** for concurrent registry operations
- **SBV + Z3** for SMT-based geometric logic verification
- **Free monads** for domain-specific languages

## Project Structure

```
src/
├── MEU/
│   ├── Core/           # Core types and MEU triplet implementation
│   ├── WS/             # Workspace state tracker and registries
│   ├── Transforms/     # Refinement and coarsening operations
│   ├── Logic/          # Geometric logic and SMT integration
│   ├── DSL/            # Domain-specific language support
│   ├── Internal/       # Internal utilities and monad stack
│   └── IO/             # I/O operations and CLI interface
tests/
├── unit/               # Unit tests for individual components
├── integration/        # Integration tests for MEU workflows
└── contract/           # Contract tests for API endpoints
```

## Performance

Designed to handle enterprise-scale MEU systems:

- 1000+ interconnected MEU triplets
- <10ms registry operations for 10k entries
- <1s refinement operations for 10 sub-triplets
- <100MB memory usage for 500 triplets

## Documentation

- [User Guide](docs/guide/README.md) - Complete user documentation
- [API Reference](docs/api/README.md) - API documentation
- [Architecture Guide](docs/architecture/README.md) - System architecture details
- [Contributing](CONTRIBUTING.md) - Development guidelines

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Support

- [Issues](https://github.com/meu-framework/ws-state-tracker/issues)
- [Discussions](https://github.com/meu-framework/ws-state-tracker/discussions)
- [Documentation](https://meu-framework.github.io/ws-state-tracker)