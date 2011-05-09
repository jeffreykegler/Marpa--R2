
.PHONY: devlib dummy

dummy: 

devlib:
	(cd pp; ./Build install --install_base ../devlib)

xs_tests:
	cp pp/t/pp/*.t xs/t/common/
