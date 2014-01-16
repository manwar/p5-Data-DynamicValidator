package Data::DynamicValidator::Error;
# ABSTRACT: Class holds validation error: reason and location

use strict;
use warnings;

use overload fallback => 1, q/""/ => sub { $_[0]->to_string };

sub new {
    my ($class, $reason, $path) = @_;
    my $self = {
        _reason => $reason,
        _path   => $path,
    };
    bless $self => $class;
}

=method to_string

Stringizes to reason by default

=cut

sub to_string{ $_[0]->{_reason} };

sub reason { $_[0]->{_reason} };

sub path { $_[0]->{_path} }

1;
