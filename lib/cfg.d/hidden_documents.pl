$c->add_trigger( EP_TRIGGER_URL_REWRITE, sub
{
    my( %args ) = @_;

	my( $uri, $rc, $request ) = @args{ qw( uri return_code request ) };
    my $repository = $EPrints::HANDLE->current_repository();
    # /id/eprint/<eprint_id>/hidden/<pos>/filename
    if( $uri =~ s! ^/([1-9][0-9]*)/hidden/([1-9][0-9]*)/(\b) !!x )
    {
        my $eprintid = $1;
        my $pos = $2;
        my $filename = $uri;

        # do we have such an eprint?
        my $eprint = $repository->dataset( "eprint" )->dataobj( $eprintid );
        if( !defined $eprint )
        {
            ${$rc} = Apache2::Const::NOT_FOUND;
            return EP_TRIGGER_DONE;
        }

        my $doc = EPrints::DataObj::Document::HiddenDocument::doc_with_eprintid_and_pos( $repository, $eprintid, $pos );
        if( !defined $doc )
        {
            ${$rc} = Apache2::Const::NOT_FOUND;
            return EP_TRIGGER_DONE;
        }

        ${$rc} = Apache2::Const::OK; # the doc was found so we're OK

        $request->pnotes( eprint => $eprint );
        $request->pnotes( document => $doc );
        $request->pnotes( dataobj => $doc );
        $request->pnotes( filename => $filename );

        $request->handler('perl-script');

        # no real file to map to
        $request->set_handlers(PerlMapToStorageHandler => sub { Apache2::Const::OK } );

        $request->push_handlers(PerlAccessHandler => [
            \&EPrints::Apache::Auth::authen_doc,
            \&EPrints::Apache::Auth::authz_doc
        ] );
        $request->set_handlers(PerlResponseHandler => \&EPrints::Apache::Storage::handler );

        $request->pool->cleanup_register(\&EPrints::Apache::LogHandler::document, $request);
        my $method = eval {$request->method};
        if( $method eq "HEAD" ) # we want to skip doing any document processing, this is just a HEAD request
        {
            return EP_TRIGGER_DONE;
        }
    }
    return EP_TRIGGER_OK;
}, priority => 100 );


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
