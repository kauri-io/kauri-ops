# Azure Environment Setup Prerequisites

 - [MacOS](#macos)
 - [Linux](#linux)
 - [Windows](#windows)

<a name="macos"></a>
### If you are using a MacOS system ###

1. Install the **Azure CLI** by using the instructions at <https://docs.microsoft.com/en-us/cli/azure/install-azure-cli>.

1. Install **kubectl** by running below command:

   ```shell
   sudo az acs kubernetes install-cli
   ```

1. Install **Homebrew** from <https://brew.sh/>.

1. Install **jq** using Homebrew:

   ```shell
   brew install jq
   ```

1. Install **gettext** using Homebrew:

   ```shell
   brew install gettext
   brew link --force gettext
   ```

1. Install **maven** using Homebrew:

   ```shell
   brew install maven
   ```
1. Install **helm** by usinf the instructions at
<https://github.com/kubernetes/helm#install>

<a name="linux"></a>
### If you are using a Linux system ###

1. Install the **Azure CLI** by using the instructions at <https://docs.microsoft.com/en-us/cli/azure/install-azure-cli>.

1. Install the **Kubernetes CLI (kubectl)** by using the instructions at <https://kubernetes.io/docs/getting-started-guides/ubuntu/>:

   ```shell
   az acs kubernetes install-cli --install-location .
   sudo mv kubectl /usr/local/bin/kubectl
   ```

1. Install **jq** by using the instructions at <https://stedolan.github.io/jq/download/>:
   ```shell
   sudo apt-get install jq
   ```

1. Install **[Maven](http://maven.apache.org/)**:

   ```shell
   sudo apt-get install maven
   ```
1. 1. Install **helm** by usinf the instructions at
<https://github.com/kubernetes/helm#install>

<a name="windows"></a>
### If you are using a Windows system ###

1. Install **[python](https://www.python.org/downloads/windows/)** (preferably 3.6). In the python setup wizard, check `pip` during the `Optional Features` step.

1. Install **Azure CLI** by running below command:

   ```shell
   pip install azure-cli
   ```
   **NOTES**:
      * We run Azure resource provisioning script in Git Bash. To smoothly run Azure CLI commands in Git Bash, Azure CLI has to be installed via pip.
      * The Azure CLI installed via MSI insatller doesn't work well in Git Bash.

1. Install **kubectl** by running below Azure CLI command with administrator privilege:

   ```shell
   az acs kubernetes install-cli
   ```

1. Install [Chocolatey](https://chocolatey.org/).

1. Install **[Maven](http://maven.apache.org/)** using Chocolatey:

   ```shell
   choco install Maven
   ```

1. Install **jq** using Chocolatey:

   ```shell
   choco install jq
   ```

1. 1. Install **helm** by usinf the instructions at
<https://github.com/kubernetes/helm#install>
