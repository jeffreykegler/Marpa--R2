
.PHONY: dlib dummy

dummy: 

devlib:
	(cd pp; ./Build install --install_base ../devlib)
