# This software is copyright (c) 2011 by Jeffrey Kegler
# This is free software; you can redistribute it and/or modify it
# under the same terms as the Perl 5 programming language system
# itself.

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
