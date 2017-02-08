
Global $server = Runcmd()
startServer()

global $sim = Runcmd()
startSimulation()

global $m11 = Runcmd()
startMaestro11()

global $user = Runcmd()
startUser()

;closeAll()

Func Runcmd()
    Local $iPID = Run('cmd.exe /K "cd C:\sites\maestro"', "")

    Sleep(1000)
	return $iPID

EndFunc

Func startServer()
	send("tclsh server.tcl")
	sleep(50)
	send("{ENTER}")
EndFunc

Func startMaestro11()

	send("tclsh maestro.tcl")
	sleep(50)
	send("{ENTER}")
	sleep(50)
	send("1.1")
	sleep(50)
	send("{ENTER}")
	sleep(50)
	send("user")
	sleep(50)
	send("{ENTER}")
	sleep(50)
	send("s.1")
	sleep(50)
	send("{ENTER}")
EndFunc


Func startSimulation()

	send("cd simulations")
	sleep(50)
	send("{ENTER}")
	sleep(50)
	send("tclsh numberline.tcl")
	sleep(50)
	send("{ENTER}")
	sleep(50)
	send("s.1")
	sleep(50)
    send("{ENTER}")
	sleep(50)
	send("1.1")
	sleep(50)
	send("{ENTER}")

EndFunc

Func startUser()

	send("tclsh user.tcl")
	sleep(50)
	send("{ENTER}")
	sleep(50)
	;send("acts 1 2 3 4")
    ;sleep(50)
	;send("{ENTER}")
	;sleep(50)
	;send("explore")
EndFunc



Func closeAll()
	ProcessClose($server)
	ProcessClose($n11)
	ProcessClose($n12)
	ProcessClose($n10)
	ProcessClose($n21)
	ProcessClose($sim)
	ProcessClose($user)
EndFunc

