=head1 NAME

EPrints::Plugin::Screen::EPrint::UploadMethod::HiddenURL

=cut

package EPrints::Plugin::Screen::EPrint::UploadMethod::HiddenURL;

use EPrints::Plugin::Screen::EPrint::UploadMethod::File;

@ISA = qw( EPrints::Plugin::Screen::EPrint::UploadMethod::File );

use strict;

sub new
{
	my( $class, %opts ) = @_;

	my $self = $class->SUPER::new( %opts );

	$self->{actions} = [qw( add_format )];
	$self->{appears} = [
		{ place => "hidden_upload_methods", position => 300 },
	];

	return $self;
}

sub allow_add_format { shift->can_be_viewed }

sub action_add_format
{
	my( $self ) = @_;

	my $session = $self->{session};
	my $processor = $self->{processor};
	my $ffname = join('_', $self->{prefix}, "url");
	my $eprint = $processor->{eprint};

	my $url = Encode::decode_utf8( $session->param( $ffname ) );

	my $document = $eprint->create_subdataobj( "hidden_documents", {
		format => "other",
	});
	if( !defined $document )
	{
		$processor->add_message( "error", $self->{session}->html_phrase( "Plugin/InputForm/Component/HiddenUpload:create_failed" ) );
		return;
	}
	my $success = $document->upload_url( $url );
	if( !$success )
	{
		$document->remove();
		$processor->add_message( "error", $self->{session}->html_phrase( "Plugin/InputForm/Component/HiddenUpload:upload_failed" ) );
		return;
	}

	$document->commit;

	$processor->{notes}->{upload_plugin}->{to_unroll}->{$document->get_id} = 1;
}


sub render
{
	my( $self ) = @_;

	my $f = $self->{session}->make_doc_fragment;

	my $ffname = join('_', $self->{prefix}, "url");

    my $label = $self->{session}->make_element( "label" );
    $label->appendChild( $self->{session}->html_phrase( "Plugin/InputForm/Component/HiddenUpload:new_from_url" ) );
    
    my $file_button = $self->{session}->make_element( "input",
		name => $ffname,
		size => "30",
		id => $ffname,
		);
	my $add_format_button = $self->{session}->render_button(
		value => $self->{session}->phrase( "Plugin/InputForm/Component/HiddenUpload:add_format" ), 
		class => "ep_form_internal_button",
		name => "_internal_".$self->{prefix}."_add_format" );
	$label->appendChild( $file_button );
    $f->appendChild( $label );
	$f->appendChild( $self->{session}->make_text( " " ) );
	$f->appendChild( $add_format_button );
	
	return $f; 
}

1;
