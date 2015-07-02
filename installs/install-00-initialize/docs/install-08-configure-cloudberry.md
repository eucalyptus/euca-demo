# Setup CloudBerry Explorer to access Eucalyptus Regions

### Overview
Some quick and dirty instructions to setup CloudBerry so that Eucalyptus regions are supported.
These instructions assume the SSL reverse-proxy instrucitons were used to expose Eucalyptus via
SSL on the standard port.

The latest version of cloudBerry supports Walrus, so we only have to add new Walrus Accounts!

### Install CloudBerry Explorer (Windows)

Download: http://www.cloudberrylab.com/download-thanks.aspx?prod=cbes3free&src=ms 

When this document was written, the version downloaded was: CloudBerryExplorerSetup_v4.0.8.38_netv4.0.exe

Install CloudBerry by double-clicking the installer.


### Add new Walrus Account

This provides the details for adding the test region: `hp-gol01-f1`. This faststart demo
environment is rebuilt often, so the credentials shown are likely out of date. New 
credentials can be obtained from the appropriate user eucarc file. For this region, that
is located here: `odc-f-32:/root/.euca/hp-gol01-f1/eucalyptus/admin/eucarc`

```
Menu: File > S3 Compatible > Walrus
```

```
Dialog: Account Registration
  Tab: Walrus
    Press: Add Button
```

```
Dialog: Add New Walrus Account
  Enter Display name: **hp-gol01-f1**
  Enter Service point: **objectstorage.hp-gol01-f1.mjc.prc.eucalyptus-systems.com/services/objectstorage**
  Enter Query ID: **AKIO1BU6J3NCXKVHYY2I**
  Enter Secret key: **ZI3ilTW9bfIMV0RuuKJ7JBPtJYFVHJGIlEAdYT0F**
  Check: Use SSL
  Press: Test Connection Button
  Press: OK Button
```

