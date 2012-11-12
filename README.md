# Purpose

A simulation of a router using memory-buffers to represent raw data streams.

The following protocols will be implemented:
* IP - RFC791
* UDP
* TCP

If time permits, application level protocols will be implemented as well.
* FTP

# Testing

Unit-tests for individual modules may be run by invoking the script,
"unittest.sh".  The unit tests present in each major module also serve
as an example to developers on how each class is used.

Usage:
  $ ./unittest.sh