## SSH tips

SSH is powerful and flexible, but this also adds some setup complexity. This section includes some tips and tricks for getting the Remote - SSH extension up and running in different environments.

### Configuring the $EDITOR variable

For macOS / linux remote hosts, add this snippet to your shell configuration file (like `.bashrc` or `.zshrc`)

```bash
if [ "$VSCODE_INJECTION" = "1" ]; then
    export EDITOR="code --wait" # or 'code-insiders' if you're using VS Code Insiders
fi
```

For Windows hosts, here is the equivalent Powershell:

```pwsh
if ($env:VSCODE_INJECTION -eq "1") {
    $env:EDITOR = "code --wait"  # or 'code-insiders' for VS Code Insiders
}
```

Now running a terminal command that uses the $EDITOR variable, like `git commit`, will open the file in VS Code instead of the default terminal-based editor (like `vim` or `nano`).

### Configuring key based authentication

[SSH public key authentication](https://www.ssh.com/ssh/public-key-authentication) is a convenient, high security authentication method that combines a local "private" key with a "public" key that you associate with your user account on an SSH host. This section will walk you through how to generate these keys and add them to a host.

> **Tip:** PuTTY for Windows is not a [supported client](#installing-a-supported-ssh-client), but you can [convert your PuTTYGen keys](#reusing-a-key-generated-in-puttygen).

### Quick start: Using SSH keys

To set up SSH key based authentication for your remote host. First we'll create a key pair and then copy the public key to the host.

**Create your local SSH key pair**

Check to see if you already have an SSH key on your **local** machine. This is typically located at `~/.ssh/id_ed25519.pub` on macOS / Linux, and the `.ssh` directory in your user profile folder on Windows (for example `C:\Users\your-user\.ssh\id_ed25519.pub`).

If you do not have a key, run the following command in a **local** terminal / PowerShell to generate an SSH key pair:

```bash
ssh-keygen -t ed25519 -b 4096
```

> **Tip:** Don't have `ssh-keygen`? Install [a supported SSH client](#installing-a-supported-ssh-client).

**Restrict the permissions on the private key file**

-   For macOS / Linux, run the following shell command, replacing the path to your private key if necessary:

    ```bash
    chmod 400 ~/.ssh/id_ed25519
    ```

-   For Windows, run the following command in PowerShell to grant explicit read access to your username:

    ```powershell
    icacls "privateKeyPath" /grant <username>:R
    ```

    Then navigate to the private key file in Windows Explorer, right-click and select **Properties**. Select the **Security** tab > **Advanced** > **Disable inheritance** > **Remove all inherited permissions from this object**.

**Authorize your macOS or Linux machine to connect**

Run one of the following commands, in a **local terminal window** replacing user and host name as appropriate to copy your local public key to the SSH host.

-   Connecting to a **macOS or Linux** SSH host:

    ```bash
    export USER_AT_HOST="your-user-name-on-host@hostname"
    export PUBKEYPATH="$HOME/.ssh/id_ed25519.pub"

    ssh-copy-id -i "$PUBKEYPATH" "$USER_AT_HOST"
    ```

-   Connecting to a **Windows** SSH host:

    -   The host uses OpenSSH Server and the user [belongs to the administrator group](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_server_configuration#authorizedkeysfile):

        ```bash
        export USER_AT_HOST="your-user-name-on-host@hostname"
        export PUBKEYPATH="$HOME/.ssh/id_ed25519.pub"

        ssh $USER_AT_HOST "powershell Add-Content -Force -Path \"\$Env:PROGRAMDATA\\ssh\\administrators_authorized_keys\" -Value '$(tr -d '\n\r' < "$PUBKEYPATH")'"
        ```

    -   Otherwise:

        ```bash
        export USER_AT_HOST="your-user-name-on-host@hostname"
        export PUBKEYPATH="$HOME/.ssh/id_ed25519.pub"

        ssh $USER_AT_HOST "powershell New-Item -Force -ItemType Directory -Path \"\$HOME\\.ssh\"; Add-Content -Force -Path \"\$HOME\\.ssh\\authorized_keys\" -Value '$(tr -d '\n\r' < "$PUBKEYPATH")'"
        ```

        You may want to validate that the `authorized_keys` file in the `.ssh` folder for your **remote user on the SSH host** is owned by you and no other user has permission to access it. See the [OpenSSH wiki](https://github.com/PowerShell/Win32-OpenSSH/wiki/Security-protection-of-various-files-in-Win32-OpenSSH#authorized_keys) for details.

**Authorize your Windows machine to connect**

Run one of the following commands, in a **local PowerShell** window replacing user and host name as appropriate to copy your local public key to the SSH host.

-   Connecting to a **macOS or Linux** SSH host:

    ```powershell
    $USER_AT_HOST="your-user-name-on-host@hostname"
    $PUBKEYPATH="$HOME\.ssh\id_ed25519.pub"

    $pubKey=(Get-Content "$PUBKEYPATH" | Out-String); ssh "$USER_AT_HOST" "mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo '${pubKey}' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
    ```

-   Connecting to a **Windows** SSH host:

    -   The host uses OpenSSH Server and the user [belongs to the administrator group](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_server_configuration#authorizedkeysfile):

        ```powershell
        $USER_AT_HOST="your-user-name-on-host@hostname"
        $PUBKEYPATH="$HOME\.ssh\id_ed25519.pub"

        Get-Content "$PUBKEYPATH" | Out-String | ssh $USER_AT_HOST "powershell `"Add-Content -Force -Path `"`$Env:PROGRAMDATA\ssh\administrators_authorized_keys`" `""
        ```

    -   Otherwise:

        ```powershell
        $USER_AT_HOST="your-user-name-on-host@hostname"
        $PUBKEYPATH="$HOME\.ssh\id_ed25519.pub"

        Get-Content "$PUBKEYPATH" | Out-String | ssh $USER_AT_HOST "powershell `"New-Item -Force -ItemType Directory -Path `"`$HOME\.ssh`"; Add-Content -Force -Path `"`$HOME\.ssh\authorized_keys`" `""
        ```

        Validate that the `authorized_keys` file in the `.ssh` folder for your **remote user on the SSH host** is owned by you and no other user has permission to access it. See the [OpenSSH wiki](https://github.com/PowerShell/Win32-OpenSSH/wiki/Security-protection-of-various-files-in-Win32-OpenSSH#authorized_keys) for details.

### Improving your security with a dedicated key

While using a single SSH key across all your SSH hosts can be convenient, if anyone gains access to your private key, they will have access to all of your hosts as well. You can prevent this by creating a separate SSH key for your development hosts. Just follow these steps:

1. Generate a separate SSH key in a different file.

    **macOS / Linux**: Run the following command in a **local terminal**:

    ```bash
    ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519-remote-ssh
    ```

    **Windows**: Run the following command in a **local PowerShell**:

    ```powershell
    ssh-keygen -t ed25519 -f "$HOME\.ssh\id_ed25519-remote-ssh"
    ```

2. Follow the same steps in the [quick start](#quick-start-using-ssh-keys) to authorize the key on the SSH host, but set the `PUBKEYPATH` to the `id_ed25519-remote-ssh.pub` file instead.

3. In VS Code, run **Remote-SSH: Open Configuration File...** in the Command Palette (`kbstyle(F1)`), select an SSH config file, and add (or modify) a host entry as follows:

    ```yaml
    Host name-of-ssh-host-here
    User your-user-name-on-host
    HostName host-fqdn-or-ip-goes-here
    IdentityFile ~/.ssh/id_ed25519-remote-ssh
    ```

    > **Tip:** You can use `/` for Windows paths as well. If you use `\` you will need to use two slashes. For example, `C:\\path\\to\\my\\id_ed25519`.

### Reusing a key generated in PuTTYGen

If you used PuTTYGen to set up SSH public key authentication for the host you are connecting to, you need to convert your private key so that other SSH clients can use it. To do this:

1. Open PuTTYGen **locally** and load the private key you want to convert.
2. Select **Conversions > Export OpenSSH key** from the application menu. Save the converted key to a **local** location under the`.ssh` directory in your user profile folder (for example `C:\Users\youruser\.ssh`).
3. Validate that this new **local** file is owned by you and no other user has permissions to access it.
4. In VS Code, run **Remote-SSH: Open Configuration File...** in the Command Palette (`kbstyle(F1)`), select the SSH config file you want to change, and add (or modify) a host entry in the config file as follows to point to the file:

    ```yaml
    Host name-of-ssh-host-here
    User your-user-name-on-host
    HostName host-fqdn-or-ip-goes-here
    IdentityFile ~/.ssh/exported-keyfile-from-putty
    ```

### Improving security on multi-user servers

The Remote - SSH extension installs and maintains the "VS Code Server". The server is started with a randomly generated key, and any new connection to the server needs to provide the key. The key is stored on the remote's disk, readable only by the current user. There is one HTTP path that is available without authentication at `/version`.

By default, the server listens to `localhost` on a random TCP port that is then forwarded to your local machine. If you are connecting to a **Linux or macOS** host, you can switch to using Unix sockets that are locked down to a particular user. This socket is then forwarded instead of the port.

> **Note:** This setting **disables connection multiplexing** so configuring [public key authentication](#configuring-key-based-authentication) is recommended.

To configure it:

1. Ensure you have a **local OpenSSH 6.7+ SSH client** on Windows, macOS, or Linux and an **OpenSSH 6.7+ Linux or macOS Host** (Windows does not support this mode).

2. Switch Remote - SSH into socket mode by enabling **Remote.SSH: Remote Server Listen On Socket** in your **local** VS Code [User settings](/docs/getstarted/settings.md).

    ![Listen on socket VS Code setting](images/ssh/ssh-listen-on-socket.png)

3. If you've already connected to the SSH Host, select **Remote-SSH: Kill VS Code Server on Host...** from the Command Palette (`kbstyle(F1)`) so the setting takes effect.

If you encounter an error when connecting, you may need to enable socket forwarding on your SSH Host's [sshd config](https://www.ssh.com/ssh/sshd_config/). To do so:

1. Open `/etc/ssh/sshd_config` in a text editor (like vi, nano, or pico) on the **SSH host** (not locally).
2. Add the setting `AllowStreamLocalForwarding yes`.
3. Restart the SSH server. (On Ubuntu, run `sudo systemctl restart sshd`.).
4. Retry.

### Troubleshooting hanging or failing connections

If you are running into problems with VS Code hanging while trying to connect (and potentially timing out), there are a few things you can do to try to resolve the issue.

**General troubleshooting: Remove the server**

One command helpful to troubleshoot a variety of Remote-SSH issues is **Remote-SSH: Kill VS Code Server on Host**. This will remove the server, which can fix a wide range of issues and error messages you may see, such as "Could not establish connection to `server_name`: The VS Code Server failed to start."

**See if VS Code is waiting on a prompt**

Enable the `remote.SSH.showLoginTerminal` [setting](/docs/getstarted/settings.md) in VS Code and retry. If you are prompted to input a password or token, see [Enabling alternate SSH authentication methods](#enabling-alternate-ssh-authentication-methods) for details on reducing the frequency of prompts.

If you are still having trouble, set the following properties in `settings.json` and retry:

```json
"remote.SSH.showLoginTerminal": true,
"remote.SSH.useLocalServer": false
```

**Work around a bug with some versions of Windows OpenSSH server**

Due to a bug in certain versions of OpenSSH server for Windows, the default check to determine if the host is running Windows may not work properly. This does not occur with OpenSSH server that ships with Windows 1909 and below.

Fortunately, you can work around this problem by specifically telling VS Code if your SSH host is running Windows by adding the following to `settings.json`:

```json
"remote.SSH.useLocalServer": false
```

You can also force VS Code to identify a particular host as Windows using the following property:

```json
"remote.SSH.remotePlatform": {
    "host-in-ssh-config-or-fqdn": "windows"
}
```

A fix has been merged so this problem should be resolved in a version of the server greater than 8.1.0.0.

**Enable TCP Forwarding on the remote host**

Remote - SSH extension makes use of an SSH tunnel to facilitate communication with the host. In some cases, this may be disabled on your SSH server. To see if this is the problem, open the **Remote - SSH** category in the output window and check for the following message:

```
open failed: administratively prohibited: open failed
```

If you do see that message, follow these steps to update your SSH server's [sshd config](https://www.ssh.com/ssh/sshd_config/):

1. Open `/etc/ssh/sshd_config` or `C:\ProgramData\ssh\sshd_config` in a text editor (like Vim, nano, Pico, or Notepad) on the **SSH host** (not locally).
2. Add the setting `AllowTcpForwarding yes`.
3. Restart the SSH server. (On Ubuntu, run `sudo systemctl restart sshd`. On Windows, in an admin PowerShell run, `Restart-Service sshd`).
4. Retry.

**Set the ProxyCommand parameter in your SSH config file**

If you are behind a proxy and are unable to connect to your SSH host, you may need to use the `ProxyCommand` parameter for your host in a **local** [SSH config file](https://linux.die.net/man/5/ssh_config). You can read this [SSH ProxyCommand article](https://www.cyberciti.biz/faq/linux-unix-ssh-proxycommand-passing-through-one-host-gateway-server/) for an example of its use.

**Ensure the remote machine has internet access**

The remote machine must have internet access to be able to download the VS Code Server and extensions from the Marketplace. See the [FAQ for details](/docs/remote/faq.md#what-are-the-connectivity-requirements-for-vs-code-server) on connectivity requirements.

**Set HTTP_PROXY / HTTPS_PROXY on the remote host**

If your remote host is behind a proxy, you may need to set the HTTP_PROXY or HTTPS_PROXY environment variable on the **SSH host**. Open your `~/.bashrc` file add the following (replacing `proxy.fqdn.or.ip:3128` with the appropriate hostname / IP and port):

```bash
export HTTP_PROXY=http://proxy.fqdn.or.ip:3128
export HTTPS_PROXY=$HTTP_PROXY

# Or if an authenticated proxy
export HTTP_PROXY=http://username:password@proxy.fqdn.or.ip:3128
export HTTPS_PROXY=$HTTP_PROXY
```

**Work around `/tmp` mounted with `noexec`**

Some remote servers are set up to disallow executing scripts from `/tmp`. VS Code writes its install script to the system temp directory and tries to execute it from there. You can work with your system administrator to determine whether this can be worked around.

**Check whether a different shell is launched during install**

Some users launch a different shell from their `.bash_profile` or other startup script on their **SSH host** because they want to use a different shell than the default. This can break VS Code's remote server install script and isn't recommended. Instead, use `chsh` to change your default shell on the remote machine.

**Connecting to systems that dynamically assign machines per connection**

Some systems will dynamically route an SSH connection to one node from a cluster each time an SSH connection is made. This is an issue for VS Code because it makes two connections to open a remote window: the first to install or start the VS Code Server (or find an already running instance) and the second to create the SSH port tunnel that VS Code uses to talk to the server. If VS Code is routed to a different machine when it creates the second connection, it won't be able to talk to the VS Code server.

One workaround for this is to use the `ControlMaster` option in OpenSSH (macOS/Linux clients only), described in [Enabling alternate SSH authentication methods](#enabling-alternate-ssh-authentication-methods), so that VS Code's two connections will be multiplexed through a single SSH connection to the same node.

**Contact your system administrator for configuration help**

SSH is a very flexible protocol and supports many configurations. If you see other errors, in either the login terminal or the **Remote-SSH** output window, they could be due to a missing setting.

Contact your system administrator for information about the required settings for your SSH host and client. Specific command-line arguments for connecting to your SSH host can be added to an [SSH config file](https://linux.die.net/man/5/ssh_config).

To access your config file, run **Remote-SSH: Open Configuration File...** in the Command Palette (`kbstyle(F1)`). You can then work with your admin to add the necessary settings.

### Enabling alternate SSH authentication methods

If you are connecting to an SSH remote host and are either:

-   Connecting with two-factor authentication
-   Using password authentication
-   Using an SSH key with a passphrase when the [SSH Agent](#setting-up-the-ssh-agent) is not running or accessible

then VS Code should automatically prompt you to enter needed information. If you do not see the prompt, enable the `remote.SSH.showLoginTerminal` [setting](/docs/getstarted/settings.md) in VS Code. This setting displays the terminal whenever VS Code runs an SSH command. You can then enter your authentication code, password, or passphrase when the terminal appears.

If you are still having trouble, you may need to add the following properties in `settings.json` and retry:

```json
"remote.SSH.showLoginTerminal": true,
"remote.SSH.useLocalServer": false
```

If you are on macOS and Linux and want to reduce how often you have to enter a password or token, you can enable the `ControlMaster` feature on your **local machine** so that OpenSSH runs multiple SSH sessions over a single connection.

To enable `ControlMaster`:

1. Add an entry like this to your SSH config file:

    ```yaml
    Host *
    ControlMaster auto
    ControlPath  ~/.ssh/sockets/%r@%h-%p
    ControlPersist  600
    ```

2. Then run `mkdir -p ~/.ssh/sockets` to create the sockets folder.

### Setting up the SSH Agent

If you are connecting to an SSH host using a key with a passphrase, you should ensure that the [SSH Agent](https://www.ssh.com/ssh/agent) is running **locally**. VS Code will automatically add your key to the agent so you don't have to enter your passphrase every time you open a remote VS Code window.

To verify that the agent is running and is reachable from VS Code's environment, run `ssh-add -l` in the terminal of a local VS Code window. You should see a listing of the keys in the agent (or a message that it has no keys). If the agent is not running, follow these instructions to start it. After starting the agent, be sure to restart VS Code.

**Windows:**

To enable SSH Agent automatically on Windows, start a **local Administrator PowerShell** and run the following commands:

```powershell
# Make sure you're running as an Administrator
Set-Service ssh-agent -StartupType Automatic
Start-Service ssh-agent
Get-Service ssh-agent
```

Now the agent will be started automatically on login.

**Linux:**

To start the SSH Agent in the background, run:

```bash
eval "$(ssh-agent -s)"
```

To start the SSH Agent automatically on login, add these lines to your `~/.bash_profile`:

```bash
if [ -z "$SSH_AUTH_SOCK" ]; then
   # Check for a currently running instance of the agent
   RUNNING_AGENT="`ps -ax | grep 'ssh-agent -s' | grep -v grep | wc -l | tr -d '[:space:]'`"
   if [ "$RUNNING_AGENT" = "0" ]; then
        # Launch a new instance of the agent
        ssh-agent -s &> .ssh/ssh-agent
   fi
   eval `cat .ssh/ssh-agent`
fi
```

**macOS:**

The agent should be running by default on macOS.

### Making local SSH Agent available on the remote

An SSH Agent on your local machine allows the Remote - SSH extension to connect to your chosen remote system without repeatedly prompting for a passphrase, but tools like Git that run on the remote, don't have access to your locally-unlocked private keys.

You can see this by opening the integrated terminal on the remote and running `ssh-add -l`. The command should list the unlocked keys, but instead reports an error about not being able to connect to the authentication agent. Setting `ForwardAgent yes` makes the local SSH Agent available in the remote environment, solving this problem.

You can do this by editing your `.ssh/config` file (or whatever `Remote.SSH.configFile` is set to - use the **Remote-SSH: Open SSH Configuration File...** command to be sure) and adding:

```ssh-config
Host *
    ForwardAgent yes
```

Note that you might want to be more restrictive and only set the option for particular named hosts.

### Fixing SSH file permission errors

SSH can be strict about file permissions and if they are set incorrectly, you may see errors such as "WARNING: UNPROTECTED PRIVATE KEY FILE!". There are several ways to update file permissions in order to fix this, which are described in the sections below.

### Local SSH file and folder permissions

**macOS / Linux:**

On your local machine, make sure the following permissions are set:

| Folder / File                             | Permissions                       |
| ----------------------------------------- | --------------------------------- |
| `.ssh` in your user folder                | `chmod 700 ~/.ssh`                |
| `.ssh/config` in your user folder         | `chmod 600 ~/.ssh/config`         |
| `.ssh/id_ed25519.pub` in your user folder | `chmod 600 ~/.ssh/id_ed25519.pub` |
| Any other key file                        | `chmod 600 /path/to/key/file`     |

**Windows:**

The specific expected permissions can vary depending on the exact SSH implementation you are using. We recommend using the out of box [Windows 10 OpenSSH Client](https://learn.microsoft.com/windows-server/administration/openssh/openssh_overview).

In this case, make sure that all of the files in the `.ssh` folder for your remote user on the SSH host is owned by you and no other user has permissions to access it. See the [Windows OpenSSH wiki](https://github.com/PowerShell/Win32-OpenSSH/wiki/Security-protection-of-various-files-in-Win32-OpenSSH) for details.

For all other clients, consult your client's documentation for what the implementation expects.

### Server SSH file and folder permissions

**macOS / Linux:**

On the remote machine you are connecting to, make sure the following permissions are set:

| Folder / File                                            | Linux / macOS Permissions          |
| -------------------------------------------------------- | ---------------------------------- |
| `.ssh` in your user folder on the server                 | `chmod 700 ~/.ssh`                 |
| `.ssh/authorized_keys` in your user folder on the server | `chmod 600 ~/.ssh/authorized_keys` |

Note that only Linux hosts are currently supported, which is why permissions for macOS and Windows 10 have been omitted.

**Windows:**

See the [Windows OpenSSH wiki](https://github.com/PowerShell/Win32-OpenSSH/wiki/Security-protection-of-various-files-in-Win32-OpenSSH) for details on setting the appropriate file permissions for the Windows OpenSSH server.

### Installing a supported SSH client

| OS                                        | Instructions                                                                                                                      |
| ----------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| Windows 10 1803+ / Server 2016/2019 1803+ | Install the [Windows OpenSSH Client](https://learn.microsoft.com/windows-server/administration/openssh/openssh_install_firstuse). |
| Earlier Windows                           | Install [Git for Windows](https://git-scm.com/download/win).                                                                      |
| macOS                                     | Comes pre-installed.                                                                                                              |
| Debian/Ubuntu                             | Run `sudo apt-get install openssh-client`                                                                                         |
| RHEL / Fedora / CentOS                    | Run `sudo yum install openssh-clients`                                                                                            |

VS Code will look for the `ssh` command in the PATH. Failing that, on Windows it will attempt to find `ssh.exe` in the default Git for Windows install path. You can also specifically tell VS Code where to find the SSH client by adding the `remote.SSH.path` property to `settings.json`.

### Installing a supported SSH server

| OS                                        | Instructions                                                                                                                                                                      | Details                                                                                                                                                    |
| ----------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Debian 8+ / Ubuntu 16.04+                 | Run `sudo apt-get install openssh-server`                                                                                                                                         | See the [Ubuntu SSH](https://help.ubuntu.com/community/SSH?action=show) documentation for details.                                                         |
| RHEL / CentOS 7+                          | Run `sudo yum install openssh-server && sudo systemctl start sshd.service && sudo systemctl enable sshd.service`                                                                  | See the [RedHat SSH](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/deployment_guide/ch-openssh) documentation for details. |
| SuSE 12+ / openSUSE 42.3+                 | In Yast, go to Services Manager, select "sshd" in the list, and click **Enable**. Next go to Firewall, select the **Permanent** configuration, and under services check **sshd**. | See the [SuSE SSH](https://en.opensuse.org/OpenSSH) documentation for details.                                                                             |
| Windows 10 1803+ / Server 2016/2019 1803+ | Install the [Windows OpenSSH Server](https://learn.microsoft.com/windows-server/administration/openssh/openssh_install_firstuse).                                                 |
| macOS 10.14+ (Mojave)                     | Enable [Remote Login](https://support.apple.com/guide/mac-help/allow-a-remote-computer-to-access-your-mac-mchlp1066/mac).                                                         |                                                                                                                                                            |

### Resolving hangs when doing a Git push or sync on an SSH host

If you clone a Git repository using SSH and your SSH key has a passphrase, VS Code's pull and sync features may hang when running remotely.

Either use an SSH key without a passphrase, clone using HTTPS, or run `git push` from the command line to work around the issue.

### Using SSHFS to access files on your remote host

[SSHFS](https://en.wikipedia.org/wiki/SSHFS) is a secure remote filesystem access protocol that builds up from SFTP. It provides advantages over something like a CIFS / Samba share in that all that is required is SSH access to the machine.

> **Note:** For performance reasons, SSHFS is best used for single file edits and uploading/downloading content. If you need to use an application that bulk reads/write to many files at once (like a local source control tool), [rsync](#using-rsync-to-maintain-a-local-copy-of-your-source-code) is a better choice.

**macOS / Linux**:

On Linux, you can use your distribution's package manager to install SSHFS. For Debian/Ubuntu: `sudo apt-get install sshfs`

> **Note:** WSL 1 does not support FUSE or SSHFS, so the instructions differ for Windows currently. **WSL 2 does include FUSE and SSHFS support**, so this will change soon.

On macOS, you can install SSHFS using [Homebrew](https://brew.sh/):

```bash
brew install --cask macfuse
brew install gromgit/fuse/sshfs-mac
brew link --overwrite sshfs-mac
```

In addition, if you would prefer not to use the command line to mount the remote filesystem, you can also install [SSHFS GUI](https://github.com/dstuecken/sshfs-gui).

To use the command line, run the following commands from a local terminal (replacing `user@hostname` with the remote user and hostname / IP):

```bash
export USER_AT_HOST=user@hostname
# Make the directory where the remote filesystem will be mounted
mkdir -p "$HOME/sshfs/$USER_AT_HOST"
# Mount the remote filesystem
sshfs "$USER_AT_HOST:" "$HOME/sshfs/$USER_AT_HOST" -ovolname="$USER_AT_HOST" -p 22  \
    -o workaround=nonodelay -o transform_symlinks -o idmap=user  -C
```

This will make your home folder on the remote machine available under the `~/sshfs`. When you are done, you can unmount it using your OS's Finder / file explorer or by using the command line:

```bash
umount "$HOME/sshfs/$USER_AT_HOST"
```

**Windows:**

Follow these steps:

1. On Linux, add `.gitattributes` file to your project to **force consistent line endings** between Linux and Windows to avoid unexpected issues due to CRLF/LF differences between the two operating systems. See [Resolving Git line ending issues](#resolving-git-line-ending-issues-in-wsl-resulting-in-many-modified-files) for details.

2. Next, install [SSHFS-Win](https://github.com/billziss-gh/sshfs-win) using [Chocolatey](https://chocolatey.org/): `choco install sshfs`

3. Once you've installed SSHFS for Windows, you can use the File Explorer's **Map Network Drive...** option with the path `\\sshfs\user@hostname`, where `user@hostname` is your remote user and hostname / IP. You can script this using the command prompt as follows: `net use /PERSISTENT:NO X: \\sshfs\user@hostname`

4. Once done, disconnect by right-clicking on the drive in the File Explorer and selecting **Disconnect**.

### Connect to a remote host from the terminal

Once a host has been configured, you can connect to it directly from the terminal by passing a remote URI.

For example, to connect to `remote_server` and open the `/code/my_project` folder, run:

```bash
code --remote ssh-remote+remote_server /code/my_project
```

We need to do some guessing on whether the input path is a file or a folder. If it has a file extension, it is considered a file.

To force that a folder is opened, add slash to the path or use:

`code --folder-uri vscode-remote://ssh-remote+remote_server/code/folder.with.dot`

To force that a file is opened, add `--goto` or use:

`code --file-uri vscode-remote://ssh-remote+remote_server/code/fileWithoutExtension`

### Using rsync to maintain a local copy of your source code

An alternative to [using SSHFS to access remote files](#using-sshfs-to-access-files-on-your-remote-host) is to [use `rsync`](https://rsync.samba.org/) to copy the entire contents of a folder on remote host to your local machine. The `rsync` command will determine which files need to be updated each time it is run, which is far more efficient and convenient than using something like `scp` or `sftp`. This is primarily something to consider if you really need to use multi-file or performance intensive local tools.

The `rsync` command is available out of box on macOS and can be installed using Linux package managers (for example `sudo apt-get install rsync` on Debian/Ubuntu). For Windows, you'll need to either use [WSL](https://learn.microsoft.com/windows/wsl/install) or [Cygwin](https://www.cygwin.com/) to access the command.

To use the command, navigate to the folder you want to store the synched contents and run the following replacing `user@hostname` with the remote user and hostname / IP and `/remote/source/code/path` with the remote source code location.

On **macOS, Linux, or inside WSL**:

```bash
rsync -rlptzv --progress --delete --exclude=.git "user@hostname:/remote/source/code/path" .
```

Or using **WSL from PowerShell on Windows**:

```powershell
wsl rsync -rlptzv --progress --delete --exclude=.git "user@hostname:/remote/source/code/path" "`$(wslpath -a '$PWD')"
```

You can rerun this command each time you want to get the latest copy of your files and only updates will be transferred. The `.git` folder is intentionally excluded both for performance reasons and so you can use local Git tools without worrying about the state on the remote host.

To push content, reverse the source and target parameters in the command. However, **on Windows** you should add a `.gitattributes` file to your project to **force consistent line endings** before doing so. See [Resolving Git line ending issues](#resolving-git-line-ending-issues-in-wsl-resulting-in-many-modified-files) for details.

```bash
rsync -rlptzv --progress --delete --exclude=.git . "user@hostname:/remote/source/code/path"
```

### Cleaning up the VS Code Server on the remote

The SSH extension provides a command for cleaning up the VS Code Server from the remote machine, **Remote-SSH: Uninstall VS Code Server from Host...**. The command does two things: it kills any running VS Code Server processes and it deletes the folder where the server was installed.

If you want to run these steps manually, or if the command isn't working for you, you can run a script like this:

```bash
# Kill server processes
kill -9 $(ps aux | grep vscode-server | grep $USER | grep -v grep | awk '{print $2}')
# Delete related files and folder
rm -rf $HOME/.vscode-server # Or ~/.vscode-server-insiders
```

The VS Code Server was previously installed under `~/.vscode-remote` so you can check that location too.

### SSH into a remote WSL 2 host

You may want to use SSH to connect to a WSL distro running on your remote machine. Check out [this guide](https://www.hanselman.com/blog/the-easy-way-how-to-ssh-into-bash-and-wsl2-on-windows-10-from-an-external-machine) to learn how to SSH into Bash and WSL 2 on Windows 10 from an external machine.
