# dlcache 4 CMake

A simple download cache for single files/urls.

Uses the file system as a database. Not too efficient for huge amounts of tiny files, but quite optimal for your typical source code tar ball.

Please refer to the [source code](dlcache.cmake) and to the [parent meta repository](https://github.com/jjYBdx4IL/dlcache).

Supports sha256 atm. No DLCACHEDIR env var support.
