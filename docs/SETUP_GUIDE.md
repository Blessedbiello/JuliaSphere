# JuliaSphere Setup & Installation Guide

This comprehensive guide walks you through setting up JuliaSphere for development and production environments.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Development Setup](#development-setup)
3. [Production Deployment](#production-deployment)
4. [Environment Configuration](#environment-configuration)
5. [Verification & Testing](#verification--testing)
6. [Troubleshooting](#troubleshooting)

## Prerequisites

### System Requirements

- **Operating System**: Linux (Ubuntu 20.04+ recommended), macOS 10.15+, or Windows 10+ with WSL2
- **Memory**: Minimum 4GB RAM, 8GB+ recommended for production
- **Storage**: 10GB+ available disk space
- **Network**: Internet connection for package downloads and API access

### Required Software

#### 1. Julia (Backend)
Install Julia 1.11.4 or later:

```bash
# Option 1: Using juliaup (recommended)
curl -fsSL https://install.julialang.org | sh
juliaup add 1.11.4
juliaup default 1.11.4

# Option 2: Manual installation
# Download from https://julialang.org/downloads/
```

Verify installation:
```bash
julia --version
# Should output: julia version 1.11.4
```

#### 2. Python (SDK & Scripts)
Install Python 3.11 or later:

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install python3.11 python3.11-pip python3.11-venv

# macOS (using Homebrew)
brew install python@3.11

# Or download from https://www.python.org/downloads/
```

#### 3. Docker (Optional but Recommended)
Install Docker and Docker Compose:

```bash
# Ubuntu
sudo apt install docker.io docker-compose
sudo usermod -aG docker $USER
# Log out and back in to apply group changes

# macOS
# Download Docker Desktop from https://www.docker.com/products/docker-desktop

# Verify installation
docker --version
docker-compose --version
```

#### 4. PostgreSQL (If not using Docker)
Install PostgreSQL 13+:

```bash
# Ubuntu
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql

# macOS
brew install postgresql
brew services start postgresql
```

## Development Setup

### Quick Start (Docker - Recommended)

1. **Clone the repository**:
   ```bash
   git clone https://github.com/Juliaoscode/JuliaOS.git
   cd JuliaOS
   ```

2. **Set up backend environment**:
   ```bash
   cd backend
   cp .env.example .env
   # Edit .env with your preferred settings
   ```

3. **Start everything with Docker**:
   ```bash
   docker-compose up -d
   ```

4. **Verify the backend is running**:
   ```bash
   curl http://localhost:8052/health
   # Should return: {"status": "healthy"}
   ```

### Manual Setup (Without Docker)

#### Backend Setup

1. **Navigate to backend directory**:
   ```bash
   cd backend
   ```

2. **Configure environment**:
   ```bash
   cp .env.example .env
   ```
   
   Edit `.env` file with your configuration:
   ```bash
   # Server Configuration
   HOST="127.0.0.1"
   PORT="8052"
   HOST_URL=http://127.0.0.1:8052
   
   # Database Configuration
   DB_HOST="localhost"
   DB_USER="postgres"
   DB_PASSWORD="your_password"
   DB_NAME="juliaos"
   DB_PORT="5432"
   
   # API Keys (optional - only needed for specific tools)
   GEMINI_API_KEY=your-gemini-api-key
   X_API_KEY=your-x-api-key
   X_API_KEY_SECRET=your-x-api-key-secret
   X_ACCESS_TOKEN=your-x-access-token
   X_ACCESS_TOKEN_SECRET=your-x-access-token-secret
   ```

3. **Set up database**:
   ```bash
   # Create database
   sudo -u postgres createdb juliaos
   
   # Run migrations
   sudo -u postgres psql -d juliaos -f migrations/up.sql
   ```

4. **Install Julia dependencies**:
   ```bash
   julia --project=. -e "using Pkg; Pkg.instantiate()"
   ```

5. **Start the backend server**:
   ```bash
   julia --project=. run_server.jl
   ```

#### Python SDK Setup

1. **Navigate to python directory**:
   ```bash
   cd ../python
   ```

2. **Create virtual environment**:
   ```bash
   python3.11 -m venv venv
   source venv/bin/activate  # Linux/macOS
   # or
   venv\Scripts\activate     # Windows
   ```

3. **Install the package**:
   ```bash
   pip install -e .
   ```

4. **Set up environment for scripts** (optional):
   ```bash
   cp .env.example .env
   # Edit with your API keys
   ```

5. **Test the installation**:
   ```bash
   python scripts/run_example_agent.py
   ```

#### A2A Server Setup (Optional)

1. **Navigate to A2A directory**:
   ```bash
   cd ../a2a
   ```

2. **Install dependencies**:
   ```bash
   pip install -e ../python  # Install juliaos package
   pip install -e .          # Install a2a package
   ```

3. **Start the A2A server**:
   ```bash
   cd src/a2a
   python server.py
   ```

## Production Deployment

### Docker Production Setup

1. **Create production environment file**:
   ```bash
   cd backend
   cp .env.example .env.prod
   ```
   
   Configure for production:
   ```bash
   # Server Configuration
   HOST="0.0.0.0"
   PORT="8052"
   HOST_URL=https://your-domain.com
   
   # Database Configuration (use secure passwords)
   DB_HOST="julia-db"
   DB_USER="juliaos_user"
   DB_PASSWORD="secure_random_password_here"
   DB_NAME="juliaos_prod"
   DB_PORT="5432"
   
   # API Keys
   GEMINI_API_KEY=your-production-gemini-api-key
   # ... other production API keys
   ```

2. **Create production Docker Compose**:
   ```bash
   cp docker-compose.yml docker-compose.prod.yml
   ```
   
   Edit for production (add SSL, monitoring, etc.):
   ```yaml
   version: '3.8'
   services:
     julia-db:
       image: postgres:17
       container_name: julia-db-prod
       environment:
         POSTGRES_USER: ${DB_USER}
         POSTGRES_PASSWORD: ${DB_PASSWORD}
         POSTGRES_DB: ${DB_NAME}
       volumes:
         - postgres_data:/var/lib/postgresql/data
         - ./migrations/up.sql:/docker-entrypoint-initdb.d/init.sql
       restart: unless-stopped
       
     julia_backend:
       build: .
       container_name: julia_backend_prod
       env_file:
         - .env.prod
       ports:
         - "8052:8052"
       restart: unless-stopped
       depends_on:
         - julia-db
       healthcheck:
         test: ["CMD", "curl", "-f", "http://localhost:8052/health"]
         interval: 30s
         timeout: 10s
         retries: 3
   
   volumes:
     postgres_data:
   ```

3. **Deploy to production**:
   ```bash
   docker-compose -f docker-compose.prod.yml up -d
   ```

### Cloud Deployment Options

#### AWS Deployment

1. **Using AWS ECS**:
   - Push Docker images to ECR
   - Create ECS service with the images
   - Use RDS for PostgreSQL database
   - Configure ALB for load balancing

2. **Using AWS EC2**:
   - Launch EC2 instance (t3.medium+ recommended)
   - Install Docker and dependencies
   - Clone repository and deploy with Docker Compose

#### Google Cloud Platform

1. **Using Cloud Run**:
   - Build and push to Container Registry
   - Deploy as Cloud Run service
   - Use Cloud SQL for PostgreSQL

#### DigitalOcean

1. **Using App Platform**:
   - Connect GitHub repository
   - Configure build and deploy settings
   - Add PostgreSQL database addon

### Kubernetes Deployment

1. **Create Kubernetes manifests**:
   ```yaml
   # k8s/namespace.yaml
   apiVersion: v1
   kind: Namespace
   metadata:
     name: juliaos
   
   ---
   # k8s/database.yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: postgres
     namespace: juliaos
   spec:
     # ... postgres deployment config
   
   ---
   # k8s/backend.yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: julia-backend
     namespace: juliaos
   spec:
     # ... backend deployment config
   ```

2. **Deploy to cluster**:
   ```bash
   kubectl apply -f k8s/
   ```

## Environment Configuration

### Backend Configuration (.env)

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `HOST` | Server bind address | 127.0.0.1 | Yes |
| `PORT` | Server port | 8052 | Yes |
| `HOST_URL` | Public URL | http://127.0.0.1:8052 | Yes |
| `DB_HOST` | Database host | localhost | Yes |
| `DB_USER` | Database username | postgres | Yes |
| `DB_PASSWORD` | Database password | postgres | Yes |
| `DB_NAME` | Database name | postgres | Yes |
| `DB_PORT` | Database port | 5435 | Yes |
| `GEMINI_API_KEY` | Google Gemini API key | - | No |
| `X_API_KEY` | Twitter API key | - | No |
| `X_API_KEY_SECRET` | Twitter API secret | - | No |
| `X_ACCESS_TOKEN` | Twitter access token | - | No |
| `X_ACCESS_TOKEN_SECRET` | Twitter access token secret | - | No |

### Security Considerations

1. **Database Security**:
   - Use strong passwords
   - Enable SSL connections in production
   - Restrict database access to application servers only

2. **API Security**:
   - Enable HTTPS in production
   - Use environment variables for secrets
   - Implement rate limiting

3. **Container Security**:
   - Run containers as non-root user
   - Keep base images updated
   - Scan images for vulnerabilities

### Performance Tuning

1. **Julia Backend**:
   ```bash
   # Increase Julia thread count
   export JULIA_NUM_THREADS=4
   
   # Enable Julia optimizations
   export JULIA_CPU_TARGET="generic"
   ```

2. **Database**:
   ```sql
   -- Optimize PostgreSQL settings
   ALTER SYSTEM SET shared_buffers = '256MB';
   ALTER SYSTEM SET work_mem = '4MB';
   ALTER SYSTEM SET maintenance_work_mem = '64MB';
   SELECT pg_reload_conf();
   ```

## Verification & Testing

### Health Checks

1. **Backend Health**:
   ```bash
   curl http://localhost:8052/health
   # Expected: {"status": "healthy"}
   ```

2. **Database Connection**:
   ```bash
   curl http://localhost:8052/agents
   # Expected: List of agents or empty array
   ```

3. **API Functionality**:
   ```bash
   # Create test agent
   curl -X POST http://localhost:8052/agents \
     -H "Content-Type: application/json" \
     -d '{
       "name": "test-agent",
       "description": "Test agent",
       "blueprint": {
         "tools": [],
         "strategy": {
           "name": "example_adder",
           "config_data": {}
         },
         "trigger": {
           "type": "PERIODIC_TRIGGER",
           "params": {
             "interval": 60
           }
         }
       }
     }'
   ```

### Running Tests

1. **Backend Tests**:
   ```bash
   cd backend
   julia --project=. -e "using Pkg; Pkg.test()"
   ```

2. **Python Tests**:
   ```bash
   cd python
   python -m pytest tests/ -v
   ```

### Load Testing

1. **Install testing tools**:
   ```bash
   pip install locust
   ```

2. **Run load tests**:
   ```bash
   # Create locustfile.py with your test scenarios
   locust -f locustfile.py --host=http://localhost:8052
   ```

## Troubleshooting

### Common Issues

#### "Connection refused" errors

**Symptom**: Cannot connect to backend server
**Solutions**:
1. Check if server is running: `ps aux | grep julia`
2. Verify port is not in use: `lsof -i :8052`
3. Check firewall settings
4. Verify HOST/PORT configuration in .env

#### Database connection errors

**Symptom**: "could not connect to server" 
**Solutions**:
1. Verify PostgreSQL is running: `sudo systemctl status postgresql`
2. Check database credentials in .env
3. Ensure database exists: `sudo -u postgres psql -l`
4. Run migrations: `sudo -u postgres psql -d juliaos -f migrations/up.sql`

#### Julia package installation failures

**Symptom**: "Package not found" or compilation errors
**Solutions**:
1. Update Julia registry: `julia -e "using Pkg; Pkg.Registry.update()"`
2. Clear package cache: `julia -e "using Pkg; Pkg.gc()"`
3. Reinstall packages: `julia -e "using Pkg; Pkg.instantiate()"`

#### Docker issues

**Symptom**: Container startup failures
**Solutions**:
1. Check Docker daemon: `sudo systemctl status docker`
2. Verify .env file exists and is readable
3. Check container logs: `docker-compose logs julia_backend`
4. Rebuild images: `docker-compose build --no-cache`

### Performance Issues

#### Slow response times

**Diagnostic steps**:
1. Check system resources: `htop` or `top`
2. Monitor database performance: `pg_stat_activity`
3. Check Julia thread usage: Monitor JULIA_NUM_THREADS
4. Profile application: Use Julia's built-in profiler

#### High memory usage

**Solutions**:
1. Increase swap space if needed
2. Optimize Julia GC settings
3. Monitor for memory leaks in custom code
4. Consider horizontal scaling

### Debugging Tips

1. **Enable debug logging**:
   ```bash
   # In .env
   LOG_LEVEL=DEBUG
   ```

2. **Julia debugging**:
   ```julia
   # Start Julia with debug info
   julia --project=. --check-bounds=yes run_server.jl
   ```

3. **Database debugging**:
   ```sql
   -- Enable query logging
   ALTER SYSTEM SET log_statement = 'all';
   SELECT pg_reload_conf();
   ```

### Getting Help

1. **Documentation**: Check `/docs/` directory for detailed guides
2. **Issues**: Report bugs on GitHub Issues
3. **Discussions**: Join community discussions on GitHub
4. **Logs**: Always include relevant logs when reporting issues

---

## Next Steps

After successful setup, consider:

1. **Security Hardening**: Implement SSL, authentication, and monitoring
2. **Scaling**: Set up load balancing and horizontal scaling
3. **Monitoring**: Add application performance monitoring (APM)
4. **Backups**: Implement automated database backups
5. **CI/CD**: Set up continuous integration and deployment

For production deployments, see the [Deployment Guide](./DEPLOYMENT_GUIDE.md) for advanced configuration options.