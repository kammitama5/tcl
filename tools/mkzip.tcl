###
# Wrapper to allow access to Tcl's zvfs::mkzip command from Makefiles
###
source [file join [file dirname [file normalize [info script]]] .. library zvfstools zvfstools.tcl]
zvfs::mkzip {*}$argv