package WWW::Challonge::Match::Attachment;

use 5.010;
use strict;
use warnings;
use Carp qw/carp/;
use JSON qw/to_json from_json/;

sub __args_are_valid;
sub __is_kill;

=head1 NAME

WWW::Challonge::Match::Attachment - A class representing a single match
attachement within a Challonge tournament.

=head1 VERSION

Version 0.20

=cut

our $VERSION = '0.20';

=head1 SUBROUTINES/METHODS

=head2 new

Takes a hashref representing the match attachment, the tournament id, the API
key and the REST client and turns it into an object. This is mostly used by the
module itself. To see how to create a match attachment, see
L<WWW::Challonge::Match/create>.

	my $ma = WWW::Challonge::Match::Attachment->new($match, $id, $key, $client);

=cut

sub new
{
	my $class = shift;
	my $attachment = shift;
	my $tournament = shift;
	my $key = shift;
	my $client = shift;

	my $ma =
	{
		client => $client,
		attachment => $attachment->{match_attachment},
		tournament => $tournament,
		key => $key,
		alive => 1,
	};
	bless $ma, $class;
}

=head2 update

Updates the attributes of the match attachment. Takes the same arguments as
L<WWW::Challonge::Match/create>.

	$ma->update({ url => "https://www.example.com/example2.png" });

=cut

sub update
{
	my $self = shift;
	my $args = shift;

	# Do not operate on a dead attachment:
	return __is_kill unless($self->{alive});

	# Get the key, REST client, tournament url and id:
	my $key = $self->{key};
	my $client = $self->{client};
	my $url = $self->{tournament};
	my $match_id = $self->{attachment}->{match_id};
	my $id = $self->{attachment}->{id};

	# Check the arguments are valid:
	return undef
		unless(WWW::Challonge::Match::Attachment::__args_are_valid($args));

	# Make the PUT call:
	my $params = { api_key => $key, match_attachment => $args };
	$client->PUT("/tournaments/$url/matches/$match_id/attachments/$id.json",
		to_json($params), { "Content-Type" => 'application/json' });

	# Check if it was successful:
	if($client->responseCode > 300)
	{
		print $client->responseCode, "\n";
		print $client->responseContent, "\n";
		my $errors = from_json($client->responseContent)->{errors};
		for my $error(@{$errors})
		{
			carp "$error" . " (" . $client->responseCode . ")";
		}
		return undef;
	}

	# If so, set the object's attributes to the updated version:
	$self->{attachment} =
		from_json($client->responseContent)->{match_attachment};
}

=head2 destroy

Deletes the match attachment from the attached match.

	$ma->destroy;

	# $ma still contains the attachment, but any future operations will fail:
	$ma->update({ url => "https://example.com" }); # ERROR!

=cut

sub destroy
{
	my $self = shift;

	# Do not operate on a dead attachment:
	return __is_kill unless($self->{alive});

	# Get the key, REST client, tournament url and id:
	my $key = $self->{key};
	my $client = $self->{client};
	my $url = $self->{tournament};
	my $match_id = $self->{attachment}->{match_id};
	my $id = $self->{attachment}->{id};

	# Make the DELETE call:
	$client->DELETE(
		"/tournaments/$url/matches/$match_id/attachments/$id.json?api_key=$key");

	# Check if it was successful:
	if($client->responseCode > 300)
	{
		my $errors = from_json($client->responseContent)->{errors};
		for my $error(@{$errors})
		{
			carp "$error" . " (" . $client->responseCode . ")";
		}
		return undef;
	}

	# If so, mark the oject as dead:
	$self->{alive} = 0;
}

=head2 attributes

Returns a hashref of all the attributes of the match attachment. Contains the
following fields.

=over 4

=item asset_content_type

=item asset_file_name

=item asset_file_size

=item asset_url

=item created_at

=item description

=item id

=item match_id

=item original_file_name

=item updated_at

=item url

=item user_id

=back

	my $attr = $m->attributes;
	print $attr->{description}, "\n";

=cut

sub attributes
{
	my $self = shift;

	# Do not operate on a dead attachment:
	return __is_kill unless($self->{alive});

	# Get the key, REST client, tournament url and id:
	my $key = $self->{key};
	my $client = $self->{client};
	my $url = $self->{tournament};
	my $match_id = $self->{attachment}->{match_id};
	my $id = $self->{attachment}->{id};

	# Get the most recent version:
	$client->GET(
		"/tournaments/$url/matches/$match_id/attachments/$id.json?api_key=$key");

	# Check if it was successful:
	if($client->responseCode > 300)
	{
		my $errors = from_json($client->responseContent)->{errors};
		for my $error(@{$errors})
		{
			carp "$error" . " (" . $client->responseCode . ")";
		}
		return undef;
	}

	# If so, save the most recent and return it:
	$client->{attachment} =
		from_json($client->responseContent)->{match_attachment};
	return $client->{attachment};
}

=head2 __args_are_valid

Checks if the passed arguments and values are valid for updating a match
attachment.

=cut

sub __args_are_valid
{
	my $args = shift;

	for my $arg(keys %{$args})
	{
		if($arg eq "asset")
		{
#			if(! -f $args->{$arg})
#			{
#				carp "No such file: '" . $args->{$arg} . "'";
				carp "Asset uploading is currently unsupported";
				return undef;
#			}
		}
		elsif($arg eq "url")
		{
			if($args->{$arg} !~ m{^(?:https?|ftp)://})
			{
				carp "URL must start with 'http://', 'https://' or 'ftp://'";
				return undef;
			}
		}
		elsif($arg ne "description")
		{
			carp "Ignoring unrecognised argument '" . $args->{$arg} . "'";
		}
	}

	return 1;
}

=head2 __is_kill

Checks the attachment has not been deleted from Challonge with
L<WWW::Challonge::Match::Attachment/destroy>.

=cut

sub __is_kill
{
	carp "Attachment has been destroyed";
	return undef;
}

=head1 AUTHOR

Alex Kerr, C<< <kirby at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-challonge at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Challonge::Match>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Challonge::Match::Attachment

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Challonge>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Challonge>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Challonge>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Challonge/>

=back

=head1 SEE ALSO

=over 4

=item L<WWW::Challonge>

=item L<WWW::Challonge::Tournament>

=item L<WWW::Challonge::Participant>

=item L<WWW::Challonge::Match>

=back

=head1 ACKNOWLEDGEMENTS

Everyone on the L<Challonge|http://challonge.com> team for making such a great
service.

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Alex Kerr.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of WWW::Challonge::Match::Attachment
