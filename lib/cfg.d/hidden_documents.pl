package EPrints::DataObj::EPrint;

no warnings;

use strict;

our @ISA = qw/ EPrints::DataObj /;

sub get_all_hidden_documents
{
    my( $self ) = @_;

    my @docs;

    # Filter out any documents that are volatile versions
    foreach my $doc (@{($self->value( "hidden_documents" ))})
    {
        next if $doc->has_relation( undef, "isVolatileVersionOf" );
        push @docs, $doc;
    }

    my @sdocs = sort { ($a->get_value( "placement" )||0) <=> ($b->get_value( "placement" )||0) || $a->id <=> $b->id } @docs;
    return @sdocs;
}
