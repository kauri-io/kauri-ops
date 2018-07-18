# GKE Environment setup

* **[First ensure you have the required prerequisites setup](PREREQUISITES.md)**

1. Install Google Compute Platform SDK

* MACOS https://cloud.google.com/sdk/docs/quickstart-macos
* Windows https://cloud.google.com/sdk/docs/quickstart-windows

2. Update the google components and install kubectl

```bash
gcloud --quiet components update
gcloud --quiet components update kubectl
```

3. Run the following command:

 ```bash
 source env_setup.sh --config-file config/config<env>.json
 ```
