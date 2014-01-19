package Data::DynamicValidator::Path;
{
  $Data::DynamicValidator::Path::VERSION = '0.01';
}

use strict;
use warnings;

use Carp;
use Scalar::Util qw/looks_like_number/;

use overload fallback => 1, q/""/ => sub { $_[0]->to_string };

use constant DEBUG => $ENV{DATA_DYNAMICVALIDATOR_DEBUG} || 0;

sub new {
    my ($class, $path) = @_;
    my $self = { };
    bless $self => $class;
    $self->_build_components($path);
    return $self;
}

sub _build_components {
    my ($self, $path) = @_;
    my @elements = split('/', $path);
    for my $i (0..@elements-1) {
        my @parts = split(':', $elements[$i]);
        if (@parts > 1) {
            $elements[$i] = $parts[1];
            $self->{_labels}->{ $parts[0] } = $i;
        }
    }
    $self->{_components} = \@elements;
}

sub components { shift->{_components} }

sub to_string { join('/', @{ shift->{_components} })}

sub labels {
    my $self = shift;
    my $labels = $self->{_labels};
    sort { $labels->{$a} <=> $labels->{$b} } keys %$labels;
}

sub named_route {
    my ($self, $label) = @_;
    croak("No label '$label' in path '$self'")
        unless exists $self->{_labels}->{$label};
    return $self->_clone_to($self->{_labels}->{$label});
}

sub named_component {
    my ($self, $label) = @_;
    croak("No label '$label' in path '$self'")
        unless exists $self->{_labels}->{$label};
    my $idx = $self->{_labels}->{$label};
    return $self->{_components}->[$idx];
}

sub _clone_to {
    my ($self, $index) = @_;
    my @components;
    for my $i (0 .. $index) {
        push @components, $self->{_components}->[$i]
    }
    while ( my ($name, $idx) = each(%{ $self->{_labels} })) {
        $components[$idx] = join(':', $name, $components[$idx])
            if( $idx <= $index);
    }
    my $path = join('/', @components);
    return Data::DynamicValidator::Path->new($path);
}

sub value {
    my ($self, $data, $label) = @_;
    croak("No label '$label' in path '$self'")
        if(defined($label) && !exists $self->{_labels}->{$label});
    my $idx = defined($label)
        ? $self->{_labels}->{$label}
        : @{ $self->{_components} } - 1;
    my $value = $data;
    for my $i (1 .. $idx) {
        my $element = $self->{_components}->[$i];
        if (ref($value) && ref($value) eq 'HASH' && exists $value->{$element}) {
            $value = $value->{$element};
            next;
        }
        elsif (ref($value) && ref($value) eq 'ARRAY'
            && looks_like_number($element) && $element < @$value) {
            $value = $value->[$element];
            next;
        }
        croak "I don't know how to get element#$i ($element) at $self";
    }
    warn "-- value for $self is $value\n" if DEBUG;
    return $value;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::DynamicValidator::Path

=head1 VERSION

version 0.01

=head1 AUTHOR

Ivan Baidakou <dmol@gmx.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Ivan Baidakou.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
