Here's an approach I posted to the comp.cad.cadence news group a few years ago.

There are three parts:

Tcl script skillServer to act as a "server", listening for requests.  

#!/usr/bin/env tclsh
# 
# Author     A.D.Beckett
# Group      Custom IC, Cadence Design Systems Ltd
# Machine    SUN
# Date       Jun 13, 2003 
# Modified   
# By         
# 
# Simple server interface. Is started by DFII, using ipcBeginProcess(),
# see skillServer.il.
# 
# Opens a server socket, and listens for incoming connections.
# When data comes in on that incoming connection, it passes it through
# to DFII (via this process's stdout). Then DFII sends back the result
# to this process's stdin. The protocol is that the Tcl channel ID is
# sent as the first word on the data sent to DFII, and also, the channel
# ID is the first word of the result. This allows us to know where to send
# the result back to if multiple channels are open
#
# the UNIX env var $SKILLSERVPORT defines the port number, and defaults
# to 8123.
#

if [info exists env(SKILLSERVPORT)] {
  set port $env(SKILLSERVPORT)
  } else {
  set port 8123
  }

proc listener {channel addr port} {
  puts "$channel abSkillServerConnection(\"$addr\" \"$port\")"
  flush stdout
  fconfigure $channel -buffering line
  fileevent $channel readable [list sendToDFII $channel]
  }

proc sendToDFII {channel} {
  if {[eof $channel] || [catch {gets $channel line}]} {
    # end of file
    close $channel
    } else {
    puts "$channel $line"
    flush stdout
    }
  }
  
proc sendBack {} {
  gets stdin line
  regsub {^(\w+) .*$} $line {\1} channel
  regsub {^\w+ (.*)$} $line {\1} result

  if {![eof $channel]} {
    puts $channel $result
    }
  }

fconfigure stdin -buffering line
fileevent stdin readable sendBack

socket -server listener $port
vwait forever
SKILL code skillServer.il to launch the skillServer process, and process any output from skillServer as SKILL commands

abSkillServerDebug=nil
procedure(abSkillServerConnection(addr port)
    printf("Connection received from address %s, port %s\n" addr port)
    )

procedure(abSkillServerListener(ipcId data)
    let((channel command result)
	rexCompile("^\\([^ ]*\\) \\(.*\\)$")
	channel=rexReplace(data "\\1" 1)
	command=rexReplace(data "\\2" 1)
	when(abSkillServerDebug
	    printf("COMMAND: %L\n" command)
	)
	unless(errset(result=evalstring(command))
	    when(abSkillServerDebug
		printf("ERROR: %L\n" errset.errset)
	    )
	    ipcWriteProcess(ipcId sprintf(nil "%s ERROR %L\n" 
		channel errset.errset))
	) ; unless
	when(abSkillServerDebug
	    printf("RESULT: %L\n" result)
	)
	ipcWriteProcess(ipcId sprintf(nil "%s %L\n" channel result))
    )
)

abSkillServer=ipcBeginProcess("skillServer" "" 'abSkillServerListener)

Tcl script skillClient to send commands to the Virtuoso session (via skillServer)

#!/usr/bin/env tclsh
# 
# Author     A.D.Beckett
# Group      Custom IC, Cadence Design Systems Ltd
# Machine    SUN
# Date       Jun 13, 2003 
# Modified   
# By         
# 
# simple command interface which allows me to say
#
# skillClient machineName 8123 "skillFunction()"
#

set hostname [lindex $argv 0]
set port [lindex $argv 1]
set command [lindex $argv 2]

set sock [socket $hostname $port]
puts $sock $command
