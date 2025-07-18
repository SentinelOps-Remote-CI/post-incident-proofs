# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security issue in Post-Incident-Proofs, please follow these steps:

### 1. **DO NOT** create a public GitHub issue

Security vulnerabilities should be reported privately to prevent exploitation.

### 2. Response Timeline

- **Initial Response**: Within 48 hours
- **Status Update**: Within 7 days
- **Resolution**: Within 30 days (depending on complexity)

### 3. Disclosure Policy

- Vulnerabilities will be disclosed publicly after a fix is available
- Credit will be given to reporters in the security advisory
- Coordinated disclosure with affected parties when necessary

## Security Features

Post-Incident-Proofs includes several security features:

### Cryptographic Integrity

- HMAC-SHA256 signatures for log chain integrity
- SHA-256 hashing for bundle verification
- Monotonic counters to prevent replay attacks

### Tamper Detection

- < 200ms detection of log modifications
- Zero false negatives in tamper detection
- Formal verification of detection algorithms

### Rate Limiting

- Sliding-window algorithm with formal proofs
- ≤ 0.1% false positives under load
- Zero false negatives guaranteed

### Version Control

- Diff/patch operations with proven invertibility
- 10k cycle stress testing on large checkpoints
- Bit-identical verification after apply/revert

## Security Best Practices

### For Users

1. **Key Management**: Store HMAC keys securely
2. **Access Control**: Limit access to log files and bundles
3. **Monitoring**: Use auto-generated dashboards for security monitoring
4. **Updates**: Keep Post-Incident-Proofs updated to latest version

### For Developers

1. **Code Review**: All changes require security review
2. **Testing**: Run security tests before deployment
3. **Dependencies**: Keep dependencies updated
4. **Documentation**: Document security assumptions and properties

## Security Testing

We maintain comprehensive security testing:

- **Fuzz Testing**: Automated input testing with AFL++
- **Chaos Testing**: High-load stress testing at 30k rps
- **Cryptographic Validation**: Formal verification of cryptographic properties
- **Penetration Testing**: Regular security assessments

## Responsible Disclosure

We follow responsible disclosure practices:

1. **Private Reporting**: Security issues reported privately
2. **Timely Response**: Quick response to security reports
3. **Coordinated Release**: Fixes released with security advisories
4. **Credit Given**: Proper attribution to security researchers

## Acknowledgments

We thank the security research community for their contributions to making Post-Incident-Proofs more secure.
