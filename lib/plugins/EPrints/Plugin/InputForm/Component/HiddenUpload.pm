=head1 NAME

EPrints::Plugin::InputForm::Component::HiddenUpload

=cut

package EPrints::Plugin::InputForm::Component::HiddenUpload;

use EPrints::Plugin::InputForm::Component;
@ISA = ( "EPrints::Plugin::InputForm::Component::Upload" );

use strict;

sub new
{
	my( $class, %opts ) = @_;

	my $self = $class->SUPER::new( %opts );
	
	$self->{name} = "HiddenUpload";
	$self->{visible} = "all";
	# a list of documents to unroll when rendering, 
	# this is used by the POST processing, not GET

	return $self;
}

# only returns a value if it belongs to this component
sub update_from_form
{
	my( $self, $processor ) = @_;

	my $session = $self->{session};
	my $eprint = $self->{workflow}->{item};

	if( $session->internal_button_pressed )
	{
		my $internal = $self->get_internal_button;
		my @screen_opts = $self->{processor}->list_items(
			"hidden_upload_methods",
			params => {
				processor => $self->{processor},
				parent => $self,
			},
		);
		my @methods = map { $_->{screen} } @screen_opts;
		my $method_ok = 0;
		foreach my $plugin (@methods)
		{
			my $method = $plugin->get_id;
			next if $internal !~ /^$method\_([^:]+)$/;
			my $action = $1;
			$method_ok = 1;
			local $self->{processor}->{action} = $action;
			$plugin->{prefix} = join '_', $self->{prefix}, $plugin->get_id;
			$plugin->from();
			$self->{processor}->{notes}->{upload_plugin}->{plugin} = $plugin;
			$self->{processor}->{notes}->{upload_plugin}->{ctab} = $method;
			$self->{processor}->{notes}->{upload_plugin}->{state_params} = $plugin->get_state_params;
			last;
		}
	}

	return;
}

sub get_state_params
{
	my( $self, $processor ) = @_;

	my @params;

	my $tounroll = {};
	if( $processor->{notes}->{upload_plugin}->{to_unroll} )
	{
		$tounroll = $processor->{notes}->{upload_plugin}->{to_unroll};
	}
	if( $self->{session}->internal_button_pressed )
	{
		my $internal = $self->get_internal_button;
		# modifying existing document
		if( $internal && $internal =~ m/^doc(\d+)_(.*)$/ )
		{
			$tounroll->{$1} = 1;
		}
	}
	my $ctab = $processor->{notes}->{upload_plugin}->{ctab};
	if( $ctab )
	{
		push @params, $self->{prefix}."_tab", $ctab;
	}

	my $uri = URI->new( 'http:' );
	$uri->query_form( @params );

	my $params = $uri->query ? '&' . $uri->query : '';
	if( $processor->{notes}->{upload_plugin}->{state_params} )
	{
		$params .= $processor->{notes}->{upload_plugin}->{state_params};
	}

	return $params;
}

sub get_fields_handled
{
	my( $self ) = @_;

	return ( "hidden_documents" );
}

sub render_content
{
	my( $self, $surround ) = @_;
	
	my $session = $self->{session};
	
	my @screen_opts = $self->{processor}->list_items( 
			"hidden_upload_methods",
			params => {
				processor => $self->{processor},
				parent => $self,
			},
		);
	my @methods = map { $_->{screen} } @screen_opts;

	my $html = $session->make_doc_fragment;

	# no upload methods so don't do anything
	return $html if @screen_opts == 0;

	my $ctab = $self->{session}->param( $self->{prefix} . "_tab" );
	$ctab = '' if !defined $ctab;

	my @labels;
	my @tabs;
	my $current;
	for(my $i = 0; $i < @methods; ++$i)
	{
		my $plugin = $methods[$i];
		$plugin->{prefix} = join '_', $self->{prefix}, $plugin->get_id;
		push @labels, $plugin->render_title();
		my $div = $session->make_element( "div", class => "ep_block" );
		push @tabs, $div;
		$div->appendChild( $plugin->render( $self->{prefix} ) );
		$current = $i if $ctab eq $plugin->get_id;
	}

	$html->appendChild( $self->{session}->xhtml->tabs( \@labels, \@tabs,
		basename => $self->{prefix},
		current => $current,
	) );

	return $html;
}

sub doc_fields
{
	my( $self, $document ) = @_;

	my $ds = $self->{session}->get_repository->get_dataset('hidden_document');
	my @fields = @{$self->{config}->{doc_fields}};

	my %files = $document->files;
	if( scalar keys %files > 1 )
	{
		push @fields, $ds->get_field( "main" );
	}
	
	return @fields;
}

sub parse_config
{
	my( $self, $config_dom ) = @_;

	my @uploadmethods = $config_dom->getElementsByTagName( "upload-methods" );
	if( defined $uploadmethods[0] )
	{
		$self->{config}->{methods} = [];

		my @methods = $uploadmethods[0]->getElementsByTagName( "method" );
	
		foreach my $method_tag ( @methods )
		{	
			my $method = EPrints::XML::to_string( EPrints::XML::contents_of( $method_tag ) );
			push @{$self->{config}->{methods}}, $method;
		}
	}
}

1;
