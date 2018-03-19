# Kauri Environment Setup

1. Open the `~/config/config-<env>.json` in a text editor:

   a. Ensure TARGET_ENV is set to <env> in the config file name config-<env>.json, example config-dev.json

      ```json
      "env": [
        {
          "comment": "Target cloud environment.",
          "key": "TARGET_ENV",
          "value": "dev"
        }
      ],
      ```

   b. Setup the configuration of the K8s cluster

      ```json
      "Kubenetes": [
        {
          "comment": "Master node count for K8 cluster",
          "key": "K8_MASTER_COUNT",
          "value": "1"
        },
        {
          "comment": "Agent node count for K8 cluster",
          "key": "K8_AGENT_COUNT",
          "value": "1"
        },
        {
          "comment": "Master VM size for K8 cluster",
          "key": "K8_MASTER_VM",
          "value": "Standard_D2_v2"
        },
        {
          "comment": "Agent VM size for K8 cluster",
          "key": "K8_AGENT_VM",
          "value": "Standard_D2_v2"
        },
        {
          "comment": "MongoDB Storage Account Name",
          "key": "MONGO_STORAGE_NAME",
          "value": "mongodbstorage"
        }
      ],
      ```

   c. Setup any environment variables required for kuari services

      ```json
      "KBService": [
        {
          "comment": "Port number that KB service api listens to",
          "key": "KB_SERVICE_PORT",
          "value": "8080"
        }
      ]
      ```

   d. Save and close the `~/config/config-<env>.json` file.
