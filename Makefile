# Post-Incident-Proofs Makefile
# State-of-the-art software engineering practices

.PHONY: help build test benchmark fuzz chaos-test docker-e2e clean install docs release

# Default target
help:
	@echo "Post-Incident-Proofs - Machine-checked forensic evidence system"
	@echo ""
	@echo "Available targets:"
	@echo "  build        - Build all Lean components"
	@echo "  test         - Run comprehensive test suite"
	@echo "  benchmark    - Run performance benchmarks"
	@echo "  fuzz         - Run fuzz testing with AFL++"
	@echo "  chaos-test   - Run chaos testing (30k rps burst)"
	@echo "  docker-e2e   - Run Docker end-to-end tests"
	@echo "  clean        - Clean build artifacts"
	@echo "  install      - Install dependencies"
	@echo "  docs         - Generate documentation"
	@echo "  release      - Create release bundle"
	@echo "  demo         - Start demo environment"

# Build targets
build:
	@echo "🔨 Building Post-Incident-Proofs..."
	lake build
	@echo "✅ Build completed successfully"

# Test targets
test:
	@echo "🧪 Running test suite..."
	lake exe tests
	@echo "✅ All tests passed"

# Benchmark targets
benchmark:
	@echo "📊 Running benchmarks..."
	lake exe benchmarks
	@echo "✅ Benchmarks completed"

# Fuzz testing
fuzz:
	@echo "🔍 Running fuzz tests..."
	@if ! command -v afl-fuzz >/dev/null 2>&1; then \
		echo "❌ AFL++ not found. Installing..."; \
		sudo apt-get update && sudo apt-get install -y afl++; \
	fi
	@mkdir -p fuzz/inputs fuzz/outputs
	@echo "Running log chain fuzz test..."
	timeout 300s afl-fuzz -i fuzz/inputs -o fuzz/outputs -- lake exe log_verifier @@ || true
	@echo "Running rate limit fuzz test..."
	timeout 300s afl-fuzz -i fuzz/inputs -o fuzz/outputs -- lake exe rate_verifier @@ || true
	@echo "✅ Fuzz testing completed"

# Chaos testing
chaos-test:
	@echo "🌪️  Running chaos tests..."
	@echo "Testing 30k rps burst for rate limiting..."
	lake exe chaos_test --burst-size 30000 --duration 60
	@echo "Testing 10k cycle stress for version control..."
	lake exe stress_test --cycles 10000 --checkpoint-size 2147483648
	@echo "✅ Chaos testing completed"

# Docker end-to-end testing
docker-e2e:
	@echo "🐳 Running Docker E2E tests..."
	docker-compose up -d
	@sleep 30
	@echo "Checking Grafana health..."
	curl -f http://localhost:3000/api/health || exit 1
	@echo "Checking Prometheus health..."
	curl -f http://localhost:9090/-/healthy || exit 1
	docker-compose down
	@echo "✅ Docker E2E tests passed"

# Clean targets
clean:
	@echo "🧹 Cleaning build artifacts..."
	lake clean
	rm -rf fuzz/outputs
	rm -rf benchmark-results
	rm -rf logs/*
	rm -rf keys/*
	@echo "✅ Clean completed"

# Install dependencies
install:
	@echo "📦 Installing dependencies..."
	@if ! command -v lean >/dev/null 2>&1; then \
		echo "Installing Lean 4..."; \
		wget https://github.com/leanprover/lean4/releases/download/v4.7.0/lean-4.7.0-linux.tar.gz; \
		tar -xzf lean-4.7.0-linux.tar.gz; \
		echo "export PATH=\$$PATH:\$$PWD/lean-4.7.0-linux/bin" >> ~/.bashrc; \
	fi
	@if ! command -v docker >/dev/null 2>&1; then \
		echo "Installing Docker..."; \
		sudo apt-get update && sudo apt-get install -y docker.io docker-compose; \
	fi
	@echo "✅ Dependencies installed"

# Generate documentation
docs:
	@echo "📚 Generating documentation..."
	mkdir -p docs
	lake exe docs
	@echo "✅ Documentation generated"

# Create release bundle
release:
	@echo "📦 Creating release bundle..."
	lake build
	lake exe tests
	lake exe bundle_generator --window 24h --output post-incident-proofs-release.zip
	lake exe verify_bundle post-incident-proofs-release.zip
	@echo "✅ Release bundle created: post-incident-proofs-release.zip"

# Demo environment
demo:
	@echo "🎮 Starting demo environment..."
	@echo "This will start Grafana, Prometheus, and Loki"
	@echo "Access Grafana at: http://localhost:3000 (admin/admin)"
	@echo "Access Prometheus at: http://localhost:9090"
	@echo "Press Ctrl+C to stop"
	docker-compose up

# Development helpers
dev-setup:
	@echo "🛠️  Setting up development environment..."
	mkdir -p logs keys dashboards datasources
	@echo "Generating HMAC key..."
	openssl rand -hex 32 > keys/hmac.key
	@echo "✅ Development environment ready"

# Performance monitoring
monitor:
	@echo "📈 Starting performance monitoring..."
	@echo "Monitoring system performance for 60 seconds..."
	@echo "Log throughput target: ≥ 200k entries/s"
	@echo "Rate limit throughput target: ≥ 30k rps"
	@echo "Bundle generation target: < 5MB for 24h"
	@echo "Proof compilation target: < 3s"
	@echo ""
	@echo "Press Ctrl+C to stop monitoring"
	@while true; do \
		echo "=== $(date) ==="; \
		lake exe benchmark --quick; \
		sleep 10; \
	done

# Security audit
security-audit:
	@echo "🔒 Running security audit..."
	@echo "Checking for known vulnerabilities..."
	@echo "Verifying cryptographic implementations..."
	@echo "Validating tamper detection mechanisms..."
	lake exe security_audit
	@echo "✅ Security audit completed"

# Security testing
security: build
	@echo "🔐 Running security tests..."
	lake exe security
	@echo "✅ Security tests completed"

# Observability testing
observability: build
	@echo "📊 Running observability tests..."
	lake exe observability
	@echo "✅ Observability tests completed"

# Comprehensive validation
validate: build
	@echo "✅ Running comprehensive system validation..."
	lake exe validate
	@echo "✅ System validation completed"

# Quick validation
validate-quick:
	@echo "✅ Quick validation..."
	lake build
	lake exe tests --quick
	@echo "✅ Validation passed"

# Full CI simulation
ci:
	@echo "🚀 Running full CI pipeline..."
	$(MAKE) build
	$(MAKE) test
	$(MAKE) benchmark
	$(MAKE) fuzz
	$(MAKE) chaos-test
	$(MAKE) docker-e2e
	$(MAKE) security-audit
	@echo "✅ Full CI pipeline completed successfully" 