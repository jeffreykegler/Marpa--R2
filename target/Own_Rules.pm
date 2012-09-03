package Marpa::R2::Sixish::Own_Rules;

$rules = [
           {
             'rhs' => [
                        '<first rule>',
                        '<more rules>'
                      ],
             'lhs' => '<top>',
             'action' => 'do_top'
           },
           {
             'rhs' => [
                        '<short rule>'
                      ],
             'lhs' => '<first rule>',
             'action' => 'do_array'
           },
           {
             'rhs' => [],
             'lhs' => '<more rules>',
             'action' => 'do_empty_array'
           },
           {
             'rhs' => [
                        '<rhs>'
                      ],
             'lhs' => '<short rule>',
             'action' => 'do_short_rule'
           },
           {
             'rhs' => [
                        '<concatenation>'
                      ],
             'lhs' => '<rhs>'
           },
           {
             'rhs' => [],
             'lhs' => '<concatenation>'
           },
           {
             'rhs' => [
                        '<concatenation>',
                        '<opt ws>',
                        '<quantified atom>'
                      ],
             'lhs' => '<concatenation>',
             'action' => 'do_remove_undefs'
           },
           {
             'rhs' => [],
             'lhs' => '<opt ws>',
             'action' => 'do_undef'
           },
           {
             'rhs' => [
                        '<opt ws>',
                        '<ws char>'
                      ],
             'lhs' => '<opt ws>',
             'action' => 'do_undef'
           },
           {
             'rhs' => [
                        '<atom>',
                        '<opt ws>',
                        '<quantifier>'
                      ],
             'lhs' => '<quantified atom>'
           },
           {
             'rhs' => [
                        '<atom>'
                      ],
             'lhs' => '<quantified atom>'
           },
           {
             'rhs' => [
                        '<quoted literal>'
                      ],
             'lhs' => '<atom>'
           },
           {
             'rhs' => [
                        '<single quote>',
                        '<single quoted char seq>',
                        '<single quote>'
                      ],
             'lhs' => '<quoted literal>'
           },
           {
             'min' => 0,
             'rhs' => [
                        '<single quoted char>'
                      ],
             'lhs' => '<single quoted char seq>'
           },
           {
             'rhs' => [
                        '<self>'
                      ],
             'lhs' => '<atom>'
           },
           {
             'rhs' => [
                        '\'<~~>\''
                      ],
             'lhs' => '<self>',
             'action' => 'do_self'
           },
           {
             'rhs' => [
                        '\'*\''
                      ],
             'lhs' => '<quantifier>'
           }
         ];

1;
