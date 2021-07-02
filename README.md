# MacVM

macOS Monterey added support for virtualizing macOS with Apple silicon host.

This project provides an example project for the setup.

Currently on macOS 12.0 Beta 2, the installer may not work correctly unless you manually override the `AuthInstallSigningServerURL`.

You can do so with `defaults write com.apple.Virtualization.Installation AuthInstallSigningServerURL https://gs.apple.com`.
