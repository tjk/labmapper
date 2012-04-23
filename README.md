LabMapper
=========

![LabMapper screenshot](https://github.com/tjeezy/labmapper/raw/master/screenshot.png "LabMapper screenshot")

A baby project.

Installation
------------

    $ git clone https://tjeezy@github.com/tjeezy/labmapper.git
    $ rvm use 1.9.2@labmapper --create  # local ruby+gems container
    $ bundle install                    # grab dependencies

Usage
-----

    $ ./bin/poller                      # initial poll (creates socket.json)
    $ ./bin/web                         # http://localhost:4567

Then create a CRON job to run ./bin/poller every [n] minutes.

TODO
----

- make images same size and use background instead of img tag
