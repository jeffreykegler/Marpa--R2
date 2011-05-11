if ($Marpa::USE_XS) {
    require Marpa::XS;
}
elsif ($Marpa::USE_PP) {
    require Marpa::PP;
}
elsif ( $Marpa::USE_XS and $Marpa::USE_PP ) {
    Carp::croak( "Both Marpa::USE_XS and Marpa::USE_PP were specified\n",
        "It must be one or the other\n" );
}
else {
    eval { require Marpa::XS; 1 } or require Marpa::PP;
}
return 1;
