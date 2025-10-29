=head1 NAME

EPrints::Plugin::Screen::EPrint::HiddenDocument

=cut

package EPrints::Plugin::Screen::EPrint::HiddenDocument;

our @ISA = ( 'EPrints::Plugin::Screen::EPrint::Document' );

use strict;

sub json
{
	my( $self ) = @_;

	my %json = ( documents => [], messages => [] );

	foreach my $doc ($self->{processor}->{eprint}->get_all_hidden_documents)
	{
		push @{$json{documents}}, {
			id => $doc->id,
			placement => $doc->value( "placement" ),
		};
	}

	my $messages = $self->{processor}->render_messages;
	foreach my $content ($messages->childNodes)
	{
		push @{$json{messages}}, $content->toString();
	}
	$self->{repository}->xml->dispose( $messages );

	return \%json;
}

sub properties_from
{
	my( $self ) = @_;

	$self->SUPER::properties_from;

	my $uri = URI->new( $self->{session}->current_url( host => 1 ) );
	$uri->query( $self->{session}->param( "return_to" ) );
	$self->{processor}->{return_to} = $uri;

	my $doc = $self->{session}->dataset( "hidden_document" )->dataobj(
			$self->{session}->param( "documentid" )
		);
	if( $doc && $doc->value( "eprintid" ) == $self->{processor}->{eprint}->id )
	{
		$self->{processor}->{document} = $doc;
	}
}

1;
