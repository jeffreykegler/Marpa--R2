# This software is copyright (c) 2011 by Jeffrey Kegler
# This is free software; you can redistribute it and/or modify it
# under the same terms as the Perl 5 programming language system
# itself.

build:
	(cd ..;perl Build.PL)
	(cd ..;./Build realclean)
	(cd ..;perl Build.PL)
	(cd ..;./Build)
	(cd ..;./Build distmeta)
	(cd ..;./Build test)
	(cd ..;./Build disttest)

update:
	(cd ..;perl Build.PL)
	(cd ..;./Build)
	(cd ..;./Build distmeta)
	(cd ..;./Build dist)
	(cd ..;perl Build.PL)
