# GKE Environment Setup Prerequisites

 - [MacOS](#macos)
 - [Linux](#linux)
 - [Windows](#windows)

<a name="macos"></a>
### If you are using a MacOS system ###

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

1. Install **helm** by usinf the instructions at
<https://github.com/kubernetes/helm#install>

<a name="linux"></a>
### If you are using a Linux system ###

1. Install **jq** by using the instructions at <https://stedolan.github.io/jq/download/>:
   ```shell
   sudo apt-get install jq
   ```
1. 1. Install **helm** by usinf the instructions at
<https://github.com/kubernetes/helm#install>

<a name="windows"></a>
### If you are using a Windows system ###

1. Install [Chocolatey](https://chocolatey.org/).

1. Install **jq** using Chocolatey:

   ```shell
   choco install jq
   ```

1. 1. Install **helm** by usinf the instructions at
<https://github.com/kubernetes/helm#install>
