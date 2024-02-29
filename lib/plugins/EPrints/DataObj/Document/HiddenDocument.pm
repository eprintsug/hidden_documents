######################################################################
#
# EPrints::DataObj::Document::HiddenDocument
#
######################################################################

package EPrints::DataObj::Document::HiddenDocument;

@ISA = ( 'EPrints::DataObj::Document' );

use EPrints;
use EPrints::Search;

use File::Copy;
use File::Find;
use Cwd;
use Fcntl qw(:DEFAULT :seek);

use URI::Heuristic;
use Data::Dumper;
use strict;

# Field to use for unsupported formats (if repository allows their deposit)
$EPrints::DataObj::Document::OTHER = "OTHER";

# The new method can simply return the constructor of the super class (Dataset)
sub new
{
    return shift->SUPER::new( @_ );
}

sub create
{
    my( $session, $eprint ) = @_;

    return EPrints::DataObj::Document->create_from_data(
        $session,
        {
            _parent => $eprint,
            eprintid => $eprint->get_id
        },
        $session->dataset( "hidden_document" ) );
}

sub get_system_field_info
{
	my( $class ) = @_;

    my @new_system_field_info = ( 
        { name=>"hiddendocid", type=>"counter", required=>1, import=>0, show_in_html=>0, can_clone=>0,
		    sql_counter=>"hiddendocumentid" },
    );

    # tweak existing fields from the document class
    for my $sf ( $class->SUPER::get_system_field_info() )
    {   
        if( $sf->{name} eq "license" )
        {
            $sf->{set_name} = "hidden_licenses";
        }

        unless ( $sf->{name} eq "docid" || $sf->{name} eq "date_embargo" || $sf->{name} eq "security" )
        {
           push @new_system_field_info, $sf;
        }
    }   
    return @new_system_field_info;
}

sub get_dataset_id
{
    my ($self) = @_;
    return "hidden_document";
}

sub get_defaults
{
    my( $class, $session, $data, $dataset ) = @_;

    # eprints is hard coded to treat regular documents differently so we need to account for that here too (see create_subdataobj in perl_lib/EPrints/DataObj.pm)
    $data->{eprintid} = $data->{_parent}->id;

    $class->SUPER::get_defaults( $session, $data, $dataset );

    # actually get the hidden doc pos, the above will have returned us the doc pos
    $data->{pos} = $class->next_hidden_doc_pos( $session->get_database, $data->{eprintid} );

    $data->{placement} = $data->{pos};

    return $data;
}


sub doc_with_eprintid_and_pos
{
    my( $repository, $eprintid, $pos ) = @_;

    my $dataset = $repository->dataset( "hidden_document" );

    my $results = $dataset->search(
        filters => [
            {
                meta_fields => [qw( eprintid )],
                value => $eprintid
            },
            {
                meta_fields => [qw( pos )],
                value => $pos
            },
        ]);

    return $results->item( 0 );
}

sub next_hidden_doc_pos
{
    my( $self, $db, $eprintid ) = @_; 

    if( $eprintid ne $eprintid + 0 )
    {
        EPrints::abort( "next_hidden_doc_pos got odd eprintid: '$eprintid'" );
    }

    my $Q_table = $db->quote_identifier( "hidden_document" );
    my $Q_eprintid = $db->quote_identifier( "eprintid" );
    my $Q_pos = $db->quote_identifier( "pos" );

    my $sql = "SELECT MAX($Q_pos) FROM $Q_table WHERE $Q_eprintid=$eprintid";
    my @row = $db->{dbh}->selectrow_array( $sql );
    my $max = $row[0] || 0;

    return $max + 1;
}

sub local_path
{
    my( $self ) = @_;

    my $eprint = $self->get_parent();

    if( !defined $eprint )
    {
        $self->{session}->get_repository->log(
            "Document ".$self->get_id." has no eprint (eprintid is ".$self->get_value( "eprintid" )."!" );
        return( undef );
    }
    
    return( $eprint->local_path()."/hidden_docs/".sprintf( "%02d", $self->get_value( "pos" ) ) );

}

sub permit
{
    my( $self, $priv, $user ) = @_;
   
    my $eprint = $self->get_eprint();

    # we at the very least need a user
    if( defined $user )
    {
        if( $user->has_role( "admin" ) ) # admins can view hidden docs
        {
            return 1;
        }

        # ...as can the user who deposited it...
        if( $eprint->has_owner( $user ) )
        {
            return 1;
        }  
    }
    else
    {
        return 0;
    }
}

1;
