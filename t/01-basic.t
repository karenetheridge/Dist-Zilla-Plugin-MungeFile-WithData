use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Warnings;

use Test::DZil;

# create a dist with a boring dist.ini
# and GatherDir
# and our plugin
# create an inline file
# with a template and a __DATA__ section

# the test consists of reading the file out of the build dir
# and seeing that the content was transformed.

my $tzil = Builder->from_config(
    { dist_root => 't/corpus/basic' },
    {
        add_files => {
            'source/dist.ini' => simple_ini(
                [ GatherDir => ],
                [ 'MungeFile::WithData' => { finder => ':MainModule' } ],
            ),
            'source/lib/Module.pm' => <<'MODULE'
package Module;

my $DATA;
my $string = # start template...{{
    $DATA ?
    do {
"\n" . '"our list of items are: '
. join(', ', split(' ', $DATA))   # awk-style emulation
. "\n" . 'And that\'s just great!\n";';
}
: ()
# end template
#}}
;
1;
__DATA__
dog
cat
pony
__END__
This is content that should not be in the DATA section.
MODULE
        },
    },
);

$tzil->build;

my $content = $tzil->slurp_file('build/lib/Module.pm');

is(
    $content,
    <<'NEW_MODULE',
package Module;

my $DATA;
my $string = # start template...
"our list of items are: dog, cat, pony
And that's just great!\n";
;
1;
__DATA__
dog
cat
pony
__END__
This is content that should not be in the DATA section.
NEW_MODULE
    'module content is transformed',
);

done_testing;
