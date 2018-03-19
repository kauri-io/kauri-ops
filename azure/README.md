# Azure Environment Setup

The following instructions contain the required steps to install the necessary utilities and setup your an environment in azure.


* **[First ensure you have the required prerequisites setup](PREREQUISITES.md)**

* **[Second ensure you have the required config setup](../README.md)**

## STEP 3 - Provision Azure Environment ##

1. Login to your Azure account and specify which subscription to use:

   ```shell
   az login
   az account set --subscription "<your-azure-subscription>"
   ```

1. Run the following command:

   ```bash
   source provision.sh --config-file config/config<env>.json
   ```
