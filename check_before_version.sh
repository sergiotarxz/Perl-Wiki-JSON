#!/bin/bash
error() {
    echo Fase failed
    exit 1;
}

echo 'Installing deps current perl';
perl Build.PL || error
./Build installdeps || error
echo 'Installing deps minimum perl';
perlbrew exec --with perl-5.16.3 perl Build.PL || error
echo ./Build installdeps || error
perlbrew exec --with perl-5.16.3 ./Build installdeps || error
echo "Testing current perl";
prove || error
echo "Testing 5.16.3";
perlbrew exec --with perl-5.16.3 prove || error
perl -e '
    use v5.38.2;
    use Path::Tiny;
    say "Checking version in Changelog";
    my ($version) = path("lib/Wiki/JSON.pm")->slurp_utf8 =~ /\$VERSION\s+=\s+"(.*?)"/;
    say "version=$version";
    if (path("Changes")->slurp_utf8 !~ /$version/) {
        exit 1;
    }
    say "Version $version Present";
' || error
pod2markdown < lib/Wiki/JSON.pm > README.md || error
pod2markdown < lib/Wiki/JSON/Contributing.pm > CONTRIBUTING.md || error
./Build dist
