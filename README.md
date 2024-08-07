# Custom Wine Container Image

## Overview

This is a container image for a custom build of wine that includes my implementation
of the HttpSendResponseEntityBody. The image is fixed to the branch
`add-httpsendresponseentitybody` of the Wine git tree hosted at
https://gitlab.winehq.org/thelande/wine.git.

The main purpose of this container is to support running the Space Engineers
Dedicated Server via wine and have the remote API be functional.

## Usage

```console
docker run -it thelande/wine-custom:latest
```

or

```dockerfile
FROM thelande/wine-custom:latest

# ...
```