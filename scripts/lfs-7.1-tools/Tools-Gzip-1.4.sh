PACKAGE='gzip-1.4'

configure_commands()
{ :
	./configure --prefix=/tmp/tools
}

make_commands()
{ :
	make
}

check_commands()
{ :
	make check
}

install_commands()
{ :
	make install
}

run_command unpack configure make check install clean
