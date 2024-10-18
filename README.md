# Ux Flutter CLI

UxF-CLI is a command line tool for donwloading components from
[uxflutter.com](https://uxflutter.com)

1 - First create an account on [uxflutter.com](https://uxflutter.com)

2 - Install UxFlutter with `dart pub global activate uxf` command

On Windows, make sure to add
`C:\Users\<your_username>\AppData\Local\Pub\Cache\bin` into your systems
variables.

Follow the steps on this link:
[How to add folder to `Path` environment variable](https://stackoverflow.com/questions/44272416/how-to-add-a-folder-to-path-environment-variable-in-windows-10-with-screensho)

## Apply a subscription id

Go to [uxflutter.com](https://uxflutter.com) and copy your subscription ID (you
get a free one when creating an account).

Apply it by running: `uxf auth -s <subscription_id_here>`

## Installing a UxFlutter pacakge:

Now that you have ufx installed, you can add a new package with the following
command `uxf -p <package_name>`
