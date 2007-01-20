use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'          => 'StateMachine::Statemap',
    'VERSION_FROM'  => 'Statemap.pm',
    'ABSTRACT'      => 'SMC runtime',
    'PREREQ_PM'     => {},
    'PM'            => {
                        'Statemap.pm'    => '$(INST_LIBDIR)/Statemap.pm',
    },
    'AUTHOR'        => "Francois PERRAD (francois.perrad\@gadz.org)",
    'dist'          => {
                        'COMPRESS'      => 'gzip',
                        'SUFFIX'        => '.gz',
    },
);

