# BarMagnet

[![No Maintenance Intended](http://unmaintained.tech/badge.svg)](http://unmaintained.tech/)

BarMagnet is a simple torrent remote controller for iOS 9 and above.

This project will eventually be superseded by [Magnetar](https://github.com/Qata/Magnetar), at which point this project will be considered end of life.

**BarMagnet features:**

* Support for Deluge, qBittorrent, ruTorrent (HTTPRPC plugin), rTorrent (XMLRPC), SeedStuff seedboxes, Synology, Transmission, Vuze (Remote UI plugin) and µTorrent.
* A query system that lets you easily search any torrent website that inserts the query into the URL, while also letting you add extra modifiers to automatically sort by whichever parameter you desire.
* A web browser (based on SVWebViewController) that lets you add torrents to your remote server just by clicking on the magnet link or torrent file link.
* Supports ordering by: completed, incomplete, download speed, upload speed, active, downloading, seeding, paused, name, size or ratio, but there's always room for more.

## Installation

After downloading, cd to the root folder and run `git submodule update --init --recursive` to initialise all submodules used by this project and by the projects that this project uses (dizzying, isn't it?).

You'll need a Mac running the latest Xcode to be able to build BarMagnet for your iOS device.

Alternatively you can use one of the [pre-built binaries](https://github.com/Qata/BarMagnet/releases) after resigning it with [iOS App Signer](https://dantheman827.github.io/ios-app-signer/).

## Credits

BarMagnet is brought to you by Charlotte Tortorella and [contributors to the project](https://github.com/Qata/BarMagnet/contributors). If you have feature suggestions or bug reports, feel free to help out by sending pull requests or by [creating new issues](https://github.com/Qata/BarMagnet/issues/new).
