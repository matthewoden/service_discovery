# Ipfinder

Creates a `.hosts.erlang` dotfile in the current user's home directory. Using a supplied broadcast ip address, it pings the current subnet, and builds the file from the result.

Example:

``` bash
$ ipfinder --count 2 --broadcast 192.168.1.255 --ignore 192.168.1.255,255.255.255.255 app queue
```

The above would ping the broadcast ip of 192.169.1.255, and ignore results from the the broadcast and broadcast host results. If only one address is found, say, (192.168.0.1), then the command would output a file in the current user's home directory. The contents would be the following:

```
'app@192.168.0.1'.
'queue@192.168.0.1'.
```
This file is could then be used with modules like :net_adm.world to connect to erlang and elixir apps that are using a resolved name (--name) set to app@192.168.0.1 or queue@192.168.0.1

Options: 
``` bash
    --count     - the number of seconds to ping the network. 
                  Defaults to #{@defaults[:count]}
                  
    --broadcast - the broadcast ip of the current network. 
                  Defaults to #{@defaults[:broadcast]}
                  
    --ignore    - comma delimited list of ip addresses to ignore on this subnet. 
                  Defaults to #{@defaults[:ignore]}
                  
    --out       - the output directory for the .host.erlang file. 
                  Defaults to #{@defaults[:out]}
                  
    --help      - displays this screen.
```
