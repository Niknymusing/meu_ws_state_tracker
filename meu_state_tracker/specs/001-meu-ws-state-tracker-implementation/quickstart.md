# Quick Start Guide: MEU System Workspace State Tracker

**Feature**: MEU System Workspace State Tracker
**Version**: 1.0.0
**Last Updated**: 2025-10-17

## Overview

The MEU System Workspace State Tracker is a Haskell-based framework for managing software project development through the Model-Execute-Update (MEU) paradigm. This guide will help you get started with setting up, configuring, and using the workspace state tracker.

## Prerequisites

### System Requirements
- **Haskell**: GHC 9.6+ with Cabal 3.8+ or Stack 2.13+
- **Operating System**: Linux (Ubuntu 20.04+), macOS (12.0+), or Windows with WSL2
- **Memory**: Minimum 4GB RAM (8GB recommended for large MEU systems)
- **Storage**: 1GB free space for installation and examples

### Dependencies
- **SMT Solver**: Z3 4.8+ (automatically installed with SBV)
- **Development Tools**: Git, Make (optional)

## Installation

### Option 1: Using Cabal (Recommended)

```bash
# Clone the repository
git clone https://github.com/meu-framework/ws-state-tracker.git
cd ws-state-tracker

# Install dependencies and build
cabal update
cabal build all
cabal install

# Verify installation
meu-ws-tracker --version
```

### Option 2: Using Stack

```bash
# Clone and build with Stack
git clone https://github.com/meu-framework/ws-state-tracker.git
cd ws-state-tracker

stack setup
stack build
stack install

# Verify installation
meu-ws-tracker --version
```

### Option 3: Using Nix (Development Environment)

```bash
# Enter development shell
nix develop

# Build and run
cabal build
cabal exec meu-ws-tracker
```

## Basic Usage

### 1. Initialize a New MEU System

Create your first MEU system with a source triplet:

```bash
# Initialize a new MEU system for a web application project
meu-ws-tracker init --project-name "my-web-app" \
                    --description "E-commerce web application" \
                    --output-dir ./my-meu-system

# This creates:
# ./my-meu-system/
# ├── meu-system.json          # System configuration
# ├── source-triplet.json      # Initial source triplet
# └── workspace/               # Workspace directory
```

### 2. Start the Workspace State Tracker

```bash
# Start the tracker server
meu-ws-tracker server --config ./my-meu-system/meu-system.json \
                      --port 8080 \
                      --log-level info

# Server starts at http://localhost:8080
# API documentation available at http://localhost:8080/docs
```

### 3. Create Your First MEU Triplet

Using the CLI:

```bash
# Create a source triplet for your project
meu-ws-tracker triplet create \
  --type source \
  --description "Main web application triplet" \
  --file ./examples/web-app-triplet.json
```

Using the REST API:

```bash
curl -X POST http://localhost:8080/api/v1/triplets \
  -H "Content-Type: application/json" \
  -d '{
    "triplet_type": "source",
    "description": "Main web application triplet",
    "initial_domains": {
      "model": {
        "specifications": {},
        "dsl_primitives": {},
        "types": {},
        "values": {},
        "tests": {}
      },
      "execution": {
        "environment": {},
        "deployed_models": {},
        "logging_config": {},
        "resource_allocation": {},
        "feedback_channels": {}
      },
      "update": {
        "evaluators": {},
        "verifiers": {},
        "geometric_theory": {},
        "acceptance_criteria": {},
        "policies": {}
      }
    }
  }'
```

### 4. Define Types and DSL Primitives

Register types for your domain:

```bash
# Register a User type
meu-ws-tracker registry types add \
  --name "User" \
  --signature "{ id: UUID, name: String, email: String }" \
  --domain model

# Register a DSL primitive for user validation
meu-ws-tracker registry dsl add \
  --name "validateUser" \
  --input-type "User" \
  --output-type "Either ValidationError User" \
  --domain model \
  --description "Validates user data according to business rules"
```

### 5. Execute Refinement

Refine your source triplet into manageable subtasks:

```bash
# Refine the main triplet into authentication and user management
meu-ws-tracker triplet refine <triplet-id> \
  --subtasks "authentication,user-management,data-persistence" \
  --strategy parallel
```

Using the API:

```bash
curl -X POST http://localhost:8080/api/v1/triplets/<triplet-id>/refine \
  -H "Content-Type: application/json" \
  -d '{
    "subtasks": [
      {
        "description": "User authentication system",
        "domain_focus": "model",
        "estimated_complexity": "medium"
      },
      {
        "description": "User management interface",
        "domain_focus": "execution",
        "estimated_complexity": "low"
      },
      {
        "description": "Data persistence layer",
        "domain_focus": "mixed",
        "estimated_complexity": "high"
      }
    ],
    "refinement_strategy": "parallel"
  }'
```

## Configuration

### Basic Configuration File (`meu-system.json`)

```json
{
  "system": {
    "name": "my-web-app",
    "version": "1.0.0",
    "description": "E-commerce web application MEU system"
  },
  "tracker": {
    "port": 8080,
    "log_level": "info",
    "max_triplets": 1000,
    "smt_timeout": 30,
    "registry_shards": 16
  },
  "storage": {
    "backend": "file",
    "path": "./workspace",
    "auto_backup": true,
    "backup_interval": 3600
  },
  "verification": {
    "solver": "z3",
    "timeout": 30,
    "parallel_solvers": true,
    "cache_results": true
  },
  "performance": {
    "max_memory_mb": 512,
    "gc_strategy": "generational",
    "concurrent_operations": 10
  }
}
```

### Environment Variables

```bash
# Server configuration
export MEU_PORT=8080
export MEU_LOG_LEVEL=info
export MEU_CONFIG_FILE=./meu-system.json

# SMT solver configuration
export MEU_SMT_SOLVER=z3
export MEU_SMT_TIMEOUT=30

# Performance tuning
export MEU_MAX_MEMORY=512
export MEU_CONCURRENT_OPS=10
```

## Example Workflows

### Workflow 1: Web Application Development

1. **Initialize System**
   ```bash
   meu-ws-tracker init --project-name "ecommerce-app"
   ```

2. **Create Domain Types**
   ```bash
   # Product type
   meu-ws-tracker registry types add \
     --name "Product" \
     --signature "{ id: UUID, name: String, price: Decimal, category: Category }"

   # Order type
   meu-ws-tracker registry types add \
     --name "Order" \
     --signature "{ id: UUID, user: User, items: [OrderItem], total: Decimal }"
   ```

3. **Define Business Logic Primitives**
   ```bash
   # Price calculation
   meu-ws-tracker registry dsl add \
     --name "calculateTotal" \
     --input-type "[OrderItem]" \
     --output-type "Decimal"

   # Inventory check
   meu-ws-tracker registry dsl add \
     --name "checkInventory" \
     --input-type "Product" \
     --output-type "Bool"
   ```

4. **Create Acceptance Criteria**
   ```bash
   meu-ws-tracker verification criteria add \
     --description "Order total must equal sum of item prices" \
     --formula "forall order. calculateTotal(order.items) = order.total"
   ```

5. **Execute Refinement**
   ```bash
   meu-ws-tracker triplet refine <main-triplet> \
     --subtasks "product-catalog,shopping-cart,checkout,payment"
   ```

### Workflow 2: Testing and Verification

1. **Register Test Cases**
   ```bash
   meu-ws-tracker registry tests add \
     --name "test_user_validation" \
     --type execution \
     --input '{"id": "123", "name": "John", "email": "john@example.com"}' \
     --expected-output "Right(User(...))"
   ```

2. **Execute Verification**
   ```bash
   meu-ws-tracker verification run \
     --triplet-id <triplet-id> \
     --timeout 60
   ```

3. **Check Results**
   ```bash
   meu-ws-tracker verification status <verification-id>
   ```

## Monitoring and Debugging

### System Status

```bash
# Check system health
curl http://localhost:8080/api/v1/system/status

# Get detailed metrics
curl http://localhost:8080/api/v1/system/metrics
```

### Logging

```bash
# View logs in real-time
tail -f ~/.local/share/meu-ws-tracker/logs/tracker.log

# Search for errors
grep ERROR ~/.local/share/meu-ws-tracker/logs/tracker.log
```

### Performance Monitoring

```bash
# Registry performance
meu-ws-tracker monitor registries --interval 5

# Memory usage
meu-ws-tracker monitor memory --threshold 80

# SMT solver performance
meu-ws-tracker monitor verification --show-timings
```

## Common Issues and Solutions

### Issue 1: SMT Solver Timeout

**Problem**: Verification takes too long or times out

**Solution**:
```bash
# Increase timeout
export MEU_SMT_TIMEOUT=120

# Use parallel solvers
meu-ws-tracker server --config config.json --parallel-solvers
```

### Issue 2: Memory Usage Too High

**Problem**: System uses too much memory with large MEU systems

**Solution**:
```bash
# Enable memory optimization
export MEU_GC_STRATEGY=generational
export MEU_MAX_MEMORY=1024

# Use streaming for large operations
meu-ws-tracker triplet process --streaming --batch-size 100
```

### Issue 3: Registry Lock Contention

**Problem**: Slow registry operations with high concurrency

**Solution**:
```json
{
  "tracker": {
    "registry_shards": 32,
    "concurrent_operations": 20
  }
}
```

## Next Steps

1. **Read the Architecture Guide**: Learn about MEU triplet design patterns
2. **Explore Examples**: Check the `examples/` directory for complete projects
3. **API Reference**: Full API documentation at `/docs` endpoint
4. **Contributing**: See `CONTRIBUTING.md` for development guidelines

## Support

- **Documentation**: https://meu-framework.github.io/ws-state-tracker
- **Issues**: https://github.com/meu-framework/ws-state-tracker/issues
- **Discussions**: https://github.com/meu-framework/ws-state-tracker/discussions
- **Discord**: https://discord.gg/meu-framework

## License

This project is licensed under the MIT License. See `LICENSE` file for details.