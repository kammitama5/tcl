proc cat fname {
    set fname [open $fname r]
    set data [read $fname]
    close $fname
    return $data
}

proc pkgIndexDir {root fout d1} {

    puts [format {%*sIndexing %s} [expr {4 * [info level]}] {} \
	      [file tail $d1]]
    set idx [string length $root]
    foreach ftail [glob -directory $d1 -nocomplain -tails *] {
	set f [file join $d1 $ftail]
	if {[file isdirectory $f] && [string compare CVS $ftail]} {
	    pkgIndexDir $root $fout $f
	} elseif {[file tail $f] eq "pkgIndex.tcl"} {
	    puts $fout "set dir \$HERE[string range $d1 $idx end]"
	    puts $fout [cat $f]
	}
    }
}

###
# Script to build the VFS file system
###
proc copyDir {d1 d2} {

    puts [format {%*sCreating %s} [expr {4 * [info level]}] {} \
	      [file tail $d2]]

    file delete -force -- $d2
    file mkdir $d2

    foreach ftail [glob -directory $d1 -nocomplain -tails *] {
	set f [file join $d1 $ftail]
	if {[file isdirectory $f] && [string compare CVS $ftail]} {
	    copyDir $f [file join $d2 $ftail]
	} elseif {[file isfile $f]} {
	    file copy -force $f [file join $d2 $ftail]
	    if {$::tcl_platform(platform) eq {unix}} {
		file attributes [file join $d2 $ftail] -permissions 0644
	    } else {
		file attributes [file join $d2 $ftail] -readonly 1
	    }
	}
    }

    if {$::tcl_platform(platform) eq {unix}} {
	file attributes $d2 -permissions 0755
    } else {
	file attributes $d2 -readonly 1
    }
}

if {[llength $argv] < 4} {
    puts "Usage: VFS_ROOT TCLSRC_ROOT PLATFORM TCLDLL"
    exit 1
}
set VFSROOT        [lindex $argv 0]
set VERSION        [lindex $argv 1]
set TCLSRC_ROOT    [lindex $argv 2]
set PLATFORM       [lindex $argv 3]
set TCLDLL         [lindex $argv 4]

file mkdir [file join $VFSROOT bin]
file copy -force $TCLDLL [file join $VFSROOT bin $TCLDLL]

set TCL_SCRIPT_DIR [file join $VFSROOT tcl$VERSION]
puts "Building [file tail $TCL_SCRIPT_DIR] for $PLATFORM"
copyDir ${TCLSRC_ROOT}/library ${TCL_SCRIPT_DIR}

if {$PLATFORM == "windows"} {
    set ddedll [glob -nocomplain ${TCLSRC_ROOT}/win/tcldde*.dll]
    puts "DDE DLL $ddedll"
    if {$ddedll != {}} {
	file copy $ddedll ${TCL_SCRIPT_DIR}/dde
    }
    set regdll [glob -nocomplain ${TCLSRC_ROOT}/win/tclreg*.dll]
    puts "REG DLL $ddedll"
    if {$regdll != {}} {
	file copy $regdll ${TCL_SCRIPT_DIR}/reg
    }
} else {
    # Remove the dde and reg package paths
    file delete -force ${TCL_SCRIPT_DIR}/dde
    file delete -force ${TCL_SCRIPT_DIR}/reg
}

# For the following packages, cat their pkgIndex files to tclIndex
file attributes ${TCL_SCRIPT_DIR}/tclIndex -readonly 0
set fout [open ${TCL_SCRIPT_DIR}/tclIndex a]
puts $fout {#
# MANIFEST OF INCLUDED PACKAGES
#
set HERE $dir
}
pkgIndexDir ${TCL_SCRIPT_DIR} $fout ${TCL_SCRIPT_DIR}
close $fout
exit 0
puts $fout {
# Save Tcl the trouble of hunting for these packages
}
set ddedll [glob -nocomplain ${TCLSRC_ROOT}/win/tcldde*.dll]
puts "DDE DLL $ddedll"
if {$ddedll != {}} {
    puts $fout [cat ${TCL_SCRIPT_DIR}/dde/pkgIndex.tcl]
}
set regdll [glob -nocomplain ${TCLSRC_ROOT}/win/tclreg*.dll]
puts "REG DLL $ddedll"
if {$regdll != {}} {
    puts $fout [cat ${TCL_SCRIPT_DIR}/reg/pkgIndex.tcl]
}
close $fout
file attributes ${TCL_SCRIPT_DIR}/tclIndex -readonly 1