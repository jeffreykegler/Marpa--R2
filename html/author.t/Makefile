
.PHONY: all all_tests critic

all: all_tests

all_tests:
	-(cd ..; prove author.t/*.t ) 2>&1 | tee all.errs

critic:
	-(cd ..; prove author.t/critic.t) 2>&1 | tee critic.errs

display:
	-(cd ..; prove author.t/display.t)

pod:
	-(cd ..; prove author.t/pod.t)
