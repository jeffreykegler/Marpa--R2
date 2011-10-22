use 5.010;
use warnings;
use strict;

use English qw( -no_match_vars );

use Marpa::XS::Perl;

my $blog_arg = shift // '';
my $is_for_blog = $blog_arg eq 'blog';

my $ib = '{42;{1,2,3;4}}';
my $ih = '{42;{1,2,3,4}}';
my $eb = '{42;{;1,2,3;4}}';
my $eh = '{42;+{1,2,3,4}}';

my %closure = (
    'anon_hash'  => \&do_hashblock,
        'block'  => \&do_codeblock,
        'mblock' => \&do_codeblock,
);

sub gen_closure {
    my ( $lhs, $rhs, $action ) = @_;
    my $closure = $closure{$action};
    return $closure // \&do_default;
}

sub do_hashblock {
    shift;
    return '[hash=]' . join q{}, grep {$_} @_;
}

sub do_codeblock {
    shift;
    return '[code=]' . join q{}, grep {$_} @_;
}

sub do_default {
    shift;
    return join q{}, grep {$_} @_;
}

my $parser = Marpa::XS::Perl->new( \&gen_closure );

TEST: for my $test ( $ib, $ih, $eb, $eh ) {
    if ($is_for_blog) {
        require Data::Dumper;
        require Perl::Tidy;
        say '=' x 60;
        say "* TEST of $test";
        SCALAR_EVAL: {
            no warnings 'void';
            my $v = eval $test;
            use warnings;
            if ( defined $v ) {
                local $Data::Dumper::Indent = 0;
                local $Data::Dumper::Terse  = 1;
                say '* Evaled to: ', Data::Dumper::Dumper( \$v );
                last SCALAR_EVAL;
            }
            print "* Eval Error:\n$EVAL_ERROR";
        } ## end SCALAR_EVAL:
        ARRAY_EVAL: {
            no warnings 'void';
            my @v = eval $test;
            use warnings;
            if ( defined $v[0] ) {
                local $Data::Dumper::Indent = 0;
                local $Data::Dumper::Terse  = 1;
                say '* Evaled in Array context to: ',
                    Data::Dumper::Dumper( \@v );
                last ARRAY_EVAL;
            } ## end if ( defined $v )
            print "* Eval Error in Array context: \n$EVAL_ERROR";
        } ## end ARRAY_EVAL:
        my $output;
        my @perltidy_argv = ( '--noprofile', '-bt=2', '-bbt=1' );
        Perl::Tidy::perltidy(
            source      => \$test,
            destination => \$output,
            argv        => \@perltidy_argv
        );
        print "* perltidy ", ( join q{ }, @perltidy_argv ), ":\n", $output;
    } ## end if ($is_for_blog)
    my @values = $parser->parse( \$test );
    if ( not scalar @values ) {
        say '* No parse';
        next TEST;
    }
    for my $value_ix ( 0 .. $#values ) {
        say "* $value_ix: ", $values[$value_ix];
    }
} ## end for my $test ( $ib, $ih, $eb, $eh )

