This document is about troubleshooting and filing issue reports for Remote-SSH.

**To learn more about Remote - SSH, see the [documentation on `code.visualstudio.com`](https://code.visualstudio.com/docs/remote/remote-overview).**

**Please also see [SSH Tips & Tricks](https://code.visualstudio.com/docs/remote/troubleshooting#_ssh-tips) for many common workarounds and configuration tips.**

Going through these steps before submitting an issue is **required** as it may get address your issue or help us to narrow it down.

## Troubleshooting Steps

1. **Find the log** at View > Output > Remote-SSH. Skim it for obvious errors. For example, if ssh reported an error while connecting, and the extension didn't surface it to the VS Code UI, you may notice it in here. **Always include this full log when filing an issue.**

 <img width="753" alt="image" src="https://github.com/microsoft/vscode-remote-release/assets/323878/890155fc-89a4-4014-be30-680f3256edf6">

2. Search the log for `Running ssh connection command` and copy the command directly after. This is the exact ssh command that the extension attempted to use. Try running this command in an external terminal to check that you are able to connect to your host. If you are unable to connect to your remote machine from the command line this means you likely have an issue with your SSH configuration.
3. Now try running this command but add `echo "echo hello" |` to the beginning to confirm that we can execute a script on your remote by piping it into SSH. This is essentially how we run a script over ssh to install the VS Code Server on your remote, and some advanced configurations break this.
4. Try connecting using both values of the `remote.SSH.useLocalServer` setting. This setting is described in more detail below.
5. If `remote.SSH.useExecServer` is enabled on your machine, try disabling it and see whether that is successful. This setting is described in more detail below.

### `remote.SSH.useLocalServer` - Connection Mode

The Remote-SSH extension has a setting called `remote.SSH.useLocalServer` which provides two different modes for connecting. The default value is `true` which is called "Local Server Mode" and when `false` it is "Terminal Mode". This setting by default is disabled on Windows, and to enable it on Windows you **must** enable it directly in your settings.json, not through the settings UI. The two options are described below:

-   `true`: "Local Server Mode": The Remote-SSH extension spawns an SSH process which will then be reused by all VS Code windows connected to that remote.
-   `false`: "Terminal Mode": In this mode, the Remote-SSH extension runs the SSH connection command in a hidden terminal. This means that each VS Code window has its own connection. For example, if you enter a password when connecting, you will have to enter it for each window, or for each time a window reloads.

### `remote.SSH.useExecServer` - Exec Server Mode

The Remote-SSH extension can establish itself by bootstrapping with a minimal control server before launching the full VS Code Server. This enables other functionality such as connecting to Dev Containers or WSL over SSH. This is gradually being enabled by default for users.

## Other Suggestions

1. Run the command "Kill VS Code Server on Host..." from the command palette. This will kill running VS Code Server processes on your remote machine and remove server files from the remote.
2. If the log implies that the SSH connection was established successfully, use Help > Toggle Developer Tools > Console and check for other errors that may have come from the VS Code window.
3. Some issues may be caused by the VS Code Server failing to start on your remote, you may find more details in the server log. The location differs depending on the value of `remote.SSH.useExecServer`. It will be printed in the log when starting the server.
    - `false`: `~/.vscode-server[-insiders]/.<hash>.log`
    - `true`: `~/.vscode-server[-insiders]/cli/servers/*/log.txt`
4. If you think a recent regression was introduced to VS Code core, using the [vscode-bisect](https://github.com/microsoft/vscode-bisect) tool to narrow down the specific version is very helpful in a bug report.

## Performance Issues

If you are seeing issues involving processes using high CPU/RAM on your _local_ machine, see the [Performance Issues wiki page](https://github.com/microsoft/vscode/wiki/Performance-Issues) on the vscode repo.

If you are seeing this with processes on the remote machine that Remote-SSH has connected to, there are a few things you can do to narrow down the problem. See the [VS Code Remote Development Overview](https://code.visualstudio.com/docs/remote/remote-overview) doc page for a description of what these processes are.

First, you should determine exactly which process is having the issue. Use the built-in Process Explorer (Help > Open Process Explorer) or a separate command like `ps -eo pid,%cpu,%mem,command` to find the full command arguments of the process having the issue. If the process is the extension-host process, or a child process belonging to an extension, then it's likely that an extension you installed is misbehaving. Try reloading the window with extensions disabled, or run the command "Start Extension Bisect" to determine which extension is causing the issue. This is the most likely issue.

If the issue is with the VS Code Server process (`server-main.js`) you can follow the steps described in [Profiling Remote Processes](https://github.com/microsoft/vscode-remote-release/wiki/Profiling-Remote-Processes) to get a profile to include in an issue.

## Native Extension Host Crashes

If it appears through logs that the remote extension host process is exiting unexpected, it may be helpful to capture a coredump and include that in an issue. An example error with signal `SIGSEGV` is shown below.

```
2024-01-01 12:00:00.000 [info] [<unknown>][111a1aa1][ExtensionHostConnection] <12345> Extension Host Process exited with code: null, signal: SIGSEGV.
```

Please see https://github.com/microsoft/vscode/wiki/Native-Crash-Issues#remote-extension-host-crashes for more information.

## Filing a bug

Still have questions after reading this wiki, or think you're hitting a bug in the extension. Please use [this issue template](https://github.com/microsoft/vscode-remote-release/issues/new?template=a_remote_ssh_bug_form.yml) to open an issue on this repo.
