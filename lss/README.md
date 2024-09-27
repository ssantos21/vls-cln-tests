# LSS Setup

## Building the docker image

### Ubuntu/Linux
```bash
sudo docker build \
  --build-arg LSS_REPO=https://gitlab.com/lightning-signer/validating-lightning-signer.git \
  --build-arg LSS_GIT_HASH=d2590ba34a388a016bb91307864e993fb3cc3d84 \
  -t lss .
```

### Windows
```bash
docker build --build-arg LSS_REPO=https://gitlab.com/lightning-signer/validating-lightning-signer.git --build-arg LSS_GIT_HASH=d2590ba34a388a016bb91307864e993fb3cc3d84 -t lss .
```

## Running the container
```bash
docker compose --profile lss -f docker-compose.yml up lss
```

## Postgres Setup
To use LSS with postgres, change the environment variable LSS_DATABASE to postgres, you also need to supply the arguments PG_HOST, PG_USER, PG_PASS, PG_DB to a real postgres database
