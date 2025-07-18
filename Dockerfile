# Post-Incident-Proofs Dockerfile
# Multi-stage build for optimal container size and security

# Build stage
FROM leanprover/lean4:4.7.0 AS builder

# Set working directory
WORKDIR /app

# Copy source code
COPY . .

# Build the application
RUN lake build

# Create production stage
FROM ubuntu:22.04 AS production

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user for security
RUN useradd -r -s /bin/false appuser

# Set working directory
WORKDIR /app

# Copy built artifacts from builder stage
COPY --from=builder /app/build/bin/* /app/bin/
COPY --from=builder /app/build/lib/* /app/lib/

# Copy configuration files
COPY docker-compose.yml /app/
COPY prometheus.yml /app/
COPY alerts.yml /app/

# Create necessary directories
RUN mkdir -p /app/logs /app/keys /app/dashboards /app/datasources

# Set proper permissions
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Default command
CMD ["/app/bin/post-incident-proofs"]

# Development stage
FROM leanprover/lean4:4.7.0 AS development

# Install development dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy source code
COPY . .

# Create development directories
RUN mkdir -p /app/logs /app/keys /app/dashboards /app/datasources

# Build in development mode
RUN lake build

# Expose ports for development
EXPOSE 8080 3000 9090 3100

# Development command
CMD ["lake", "exe", "tests"] 