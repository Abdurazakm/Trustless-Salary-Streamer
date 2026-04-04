# Trustless Salary Streamer

Monorepo for a trustless salary streaming protocol:

- Smart contracts and tests: `contracts/`
- Frontend dApp: `frontend/`

## Quick Start

```bash
# 1) Install frontend dependencies
cd frontend && npm install

# 2) Prepare environment files
cd ..
cp contracts/.env.example contracts/.env
cp frontend/.env.example frontend/.env

# 3) Run Solidity tests
cd contracts && forge test -vv

# 4) Start frontend
cd ../frontend && npm run dev
```

## Deployment Notes

Canonical env names used across contracts and frontend:

- `DEPLOYER_PRIVATE_KEY`
- `RPC_URL`
- `CHAIN_ID`
- `VITE_FACTORY_ADDRESS`
- `VITE_RPC_URL`
- `VITE_CHAIN_ID`

Detailed contract design and deployment flow: see `contracts/README.md`.