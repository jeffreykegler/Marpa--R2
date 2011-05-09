
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
