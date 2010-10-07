DistribuStream
==============

DistribuStream is a fully open peercasting system which allows on-demand
or live streaming media to be delivered at a fraction of the normal cost. 

This README covers the initial public release, known issues, and a general
development roadmap.

Usage
-----

The DistribuStream gem includes three config files that can be located in
the conf directory of the gem:

example.yml  - A standard example file, configuring for 5kB chunks
debug.yml    - Same as example.yml, but configured for additional debug info
bigchunk.yml - An example config file, using 250kB chunks

Chunk size controls how large the segments which are exchanged between peers
are.  Larger chunk sizes reduce the amount of control traffic the server
sends, but increase the probability of errors.

To begin, copy one of these config file and edit it to your choosing.  Be
sure to set the host address to bind to and optionally the vhost you wish
to identify as.

Next, start the DistribuStream server:

distribustream --conf myconfig.yml

The DistribuStream server manages traffic on the peer network.  It also handles
the checksumming of files.  

You can see what's going on through the web interface, which runs one port
above the port you configured the server to listen on.  If the server is
listening on the default port of 6086, you can reach the web interface at:

http://myserver.url:6087/

To populate the server with files, you need to attach the DistribuStream
seed.  This works off of the same config file as the server, and must
be run on the same system:

dsseed --conf myconfig.yml

At this point your server is ready to go.

To test your server, use the DistribuStream client:

dsclient --url pdtp://myserver.url/file.ext

This will download file.ext from your DistribuStream server.

While you can't control the output filename at this point, the client supports
non-seekable output such as pipes.  To play streaming media as it downloads,
you can:

mkfifo file.ext
dsclient --url pdtp://myserver.url/file.ext &
mediaplayer file.ext

Known Issues
------------

The client presently stores incoming data in a memory buffer.  This causes
the client to consume massive amounts of memory as the file downloads.
Subsequent releases will fix this by improving the design of the memory
buffer, moving to a disk-backed buffer and/or discarding some of the
downloaded data after it's been played back.

The protocol facilitates allowing clients to have a moving window of data
in a stream, so they need not retain data which has already been displayed
to the user.

Seeds are presently not authenticated in any way, thus anyone can attach
a seed and populate the server with any files of their choosing.  However,
since file checksumming is done by the server itself, this means that only
seeds running on the same system as the server will actually work.

This will be resolved by either incorporating the seed directly into the
DistribuStream server, or adding both authentication and commands for
checksumming to the server <-> seed protocol.

Development Roadmap
-------------------

The immediate goal is to improve the performance of the client, which presently
consumes far too much RAM for practical use with large media files.  Another
immediate goal is solving the above problems with seeds.

DistribuStream uses an assemblage of various tools which do not work together
particularly well.  These include the EventMachine Ruby gem, which provides
the I/O layer for the DistribuStream server, and the Mongrel web server, which
runs independently of EventMachine and uses threads.

Initial work will focus on converting the existing implementation to a fully
EventMachine-based approach which eliminates the use of threads.

Subsequent work will focus on improving the APIs provided by the various
components so that the client and server can both

Long-term goals include a move to UDP to reduce protocol latency and overhead
as well as encrypting all traffic to ensure privacy and security of the
data being transmitted.
