=head1 NAME

EPrints::Plugin::Screen::EPrint::HiddenDocument::Remove

=cut

package EPrints::Plugin::Screen::EPrint::HiddenDocument::Remove;

our @ISA = ( 'EPrints::Plugin::Screen::EPrint::HiddenDocument' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{icon} = "action_remove.png";

	$self->{appears} = [
		{
			place => "hidden_document_item_actions",
			position => 1600,
		},
	];
	
	$self->{actions} = [qw/ remove cancel /];

	$self->{ajax} = "interactive";

	return $self;
}

sub allow_remove { shift->can_be_viewed( @_ ) }
sub allow_cancel { 1 }

sub render
{
	my( $self ) = @_;

	my $doc = $self->{processor}->{document};

	my $frag = $self->{session}->make_doc_fragment;

	my $div = $self->{session}->make_element( "div", class=>"ep_block" );
	$frag->appendChild( $div );

	$div->appendChild( $self->render_document( $doc ) );

	$div = $self->{session}->make_element( "div", class=>"ep_block" );
	$frag->appendChild( $div );

	$div->appendChild( $self->{session}->html_phrase( "Plugin/InputForm/Component/HiddenDocuments:delete_document_confirm" ) );
	
	my %buttons = (
		cancel => $self->{session}->phrase(
				"lib/submissionform:action_cancel" ),
		remove => $self->{session}->phrase(
				"lib/submissionform:action_remove" ),
		_order => [ "remove", "cancel" ]
	);

	my $form = $self->render_form;
	$form->appendChild( $self->{session}->render_action_buttons( %buttons ) );
	$div->appendChild( $form );

	return( $frag );
}	

sub action_remove
{
	my( $self ) = @_;

	$self->{processor}->{redirect} = $self->{processor}->{return_to}
		if !$self->wishes_to_export;

	if( $self->{processor}->{document} && $self->{processor}->{document}->remove )
	{
		push @{$self->{processor}->{docids}}, $self->{processor}->{document}->id;
		$self->{processor}->add_message( "message", $self->html_phrase( "item_removed" ) );
	}
}

1;
