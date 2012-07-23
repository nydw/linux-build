PACKAGE='dejagnu-1.5'

configure_commands()
{ :
	./configure --prefix=/tmp/tools
}

install_commands()
{ :
	make install
}

check_commands()
{ :
	make check
}

run_command unpack configure install check clean
