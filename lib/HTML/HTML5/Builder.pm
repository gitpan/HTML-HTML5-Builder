package HTML::HTML5::Builder;

use 5.008;
use base qw[Exporter];
use common::sense;
use constant { FALSE => 0, TRUE => 1 };
use constant XHTML_NS => 'http://www.w3.org/1999/xhtml';
use utf8;

BEGIN {
	$HTML::HTML5::Builder::AUTHORITY = 'cpan:TOBYINK';
}
BEGIN {
	$HTML::HTML5::Builder::VERSION   = '0.001';
}

use Scalar::Util qw[blessed];
use XML::LibXML;

sub new
{
	my ($class, %options) = @_;
	bless \%options, $class;
}

our (@EXPORT_OK, @EXPORT, %EXPORT_TAGS);

BEGIN
{
	my @elements = qw{
		a abbr acronym address applet area article aside audio b base
		basefont bb bdo bgsound big blink blockquote body br button canvas
		caption center cite code col colgroup command datagrid datalist
		dd del details dfn dialog dir div dl dt em embed fieldset figure
		figcaption font footer form frame frameset h1 h2 h3 h4 h5 h6
		head header hgroup hr html i iframe img input ins isindex kbd
		keygen label legend li link listing map mark marquee menu meta
		meter nav nobr noembed noframes noscript object ol optgroup
		option output p param plaintext pre progress q rp rt ruby s
		samp script select section small source spacer span strike
		strong style sub sup summary table tbody td textarea tfoot th
		thead time title tr track tt u ul var video wbr xmp
		};
	
	my @conforming = qw{
		a abbr address area article aside audio b base bb bdo blockquote
		body br button canvas caption cite code col colgroup command
		datagrid datalist dd del details dfn dialog div dl dt em embed
		fieldset figure footer form h1 h2 h3 h4 h5 h6 head header hr html
		i iframe img input ins kbd label legend li link map mark menu
		meta meter nav noscript object ol optgroup option output p param
		pre progress q rp rt ruby samp script section select small source
		span strong style sub sup table tbody td textarea tfoot th thead
		time title tr ul var video
		};
	
	@EXPORT_OK   = @elements;
	@EXPORT      = ();
	%EXPORT_TAGS = (
		all      => \@elements,
		standard => \@conforming,
		default  => \@EXPORT,
		metadata => [qw(head title base link meta style)],
		sections => [qw(body div section nav article aside h1 h2 h3 h4 h5 h6 header footer address)],
		grouping => [qw(p hr br pre dialog blockquote ol ul li dl dt dd)],
		text     => [qw(a q cite em strong small mark dfn abbr time progress
			meter code var samp kbd sub sup span i b bdo ruby rt rp)],
		embedded => [qw(figure img iframe embed object param video audio source
			canvas map area)],
		tabular  => [qw(table thead tbody tfoot th td colgroup col caption)],
		form     => [qw(form fieldset label input button select datalist
			optgroup option textarea output)],
		);
	
	foreach my $el (@elements)
	{
		*{$el} = sub
		{
			shift if blessed($_[0]) && $_[0]->isa(__PACKAGE__);
			my @params = @_;
			
			my $EL = XML::LibXML::Element->new($el);
			$EL->setNamespace(XHTML_NS, undef, TRUE);
			
			PARAM: while (@params)
			{
				my $thing = shift @params;
				
				if (blessed($thing) and $thing->isa('XML::LibXML::Element'))
				{
					$EL->appendChild($thing);
				}
				elsif (blessed($thing) and $thing->isa('XML::LibXML::Attr'))
				{
					$EL->setAttribute($thing->nodeName, $thing->getValue);
				}
				elsif (ref $thing eq 'SCALAR')
				{
					$$thing = $EL;
				}
				elsif (ref $thing eq 'ARRAY')
				{
					unshift @params, map
						{ ref $_ ? $_ : XML::LibXML::Text->new($_); }
						@$thing;
				}
				elsif (ref $thing eq 'HASH')
				{
					while (my ($k, $v) = each %$thing)
					{
						unshift @params, "-${k}" => $v;
					}
				}
				elsif (!ref $thing and $thing =~ /^-(\S+)$/ and !ref $params[0])
				{
					my $attr  = $1;
					my $value = shift @params;
					$EL->setAttribute($attr, $value);					
				}
				elsif (!ref $thing and defined $thing)
				{
					$EL->appendText($thing);
				}
				elsif (!defined $thing)
				{
					next PARAM;
				}
				else
				{
					carp("Unrecognised parameter: $thing.");
				}
			}
			
			if ($el eq 'html')
			{
				my $doc = HTML::HTML5::Builder::Document->new('1.0', 'utf-8');
				$doc->setDocumentElement($EL);
				return $doc;
			}
			
			return $EL;
		};
	}
}

package HTML::HTML5::Builder::Document;

use 5.008;
use base qw[XML::LibXML::Document];
use common::sense;
use overload '""' => \&toStringHTML;
use utf8;

use HTML::HTML5::Writer;
use XML::LibXML;

sub new
{
	my ($class, @x) = @_;
	bless $class->SUPER::new(@x), $class;
}

sub toStringHTML
{
	my ($self, @x) = @_;
	return HTML::HTML5::Writer->new(@x)->document($self);
}

*serialize_html = \&toStringHTML;

1;

__END__

=head1 NAME

HTML::HTML5::Builder - erect some scaffolding for your documents

=head1 SYNOPSIS

	use HTML::HTML5::Builder qw[:standard];

	my $document = html(
		-lang => 'en',
		head(
			title('Test', \(my $foo)),
			meta(-charset => 'utf-8'),
		),
		body(
			h1('Test'),
			p('This is a test.')
		),
	);

	$foo->setAttribute('lang', 'en-GB');

	print $document;

=head1 DESCRIPTION

This module can export function names corresponding to any HTML5 element.

Each function returns an XML::LibXML::Element. (Except the C<html> function
itself, which returns an HTML::HTML5::Builder::Document element, which inherits
from XML::LibXML::Document.)

The arguments to each function are processed as a list. For each item on that
list:

=over

=item * if it's an XML::LibXML::Element, it's appended as a child of the returned element

=item * if it's an XML::LibXML::Attr, it's set on the returned element

=item * if it's a string starting with a hyphen, then this item and the next item on the list are used to set an attribute on the returned element

=item * otherwise, if it's a string, then it's appended to the returned element as a text node 

=item * if it's a hashref, it's used to set attributes on the returned element

=item * if it's an arrayref, then the items on it are treated as if they were on the argument list, except that the hyphen-attribute feature is ignored

=item * if it's a scalar reference, then the returned element is also assigned to it

=back

=head2 Exported Functions

None by default. Pretty much any HTML element you've ever dreamt of can be exported
on request though.

Export tags:

=over

=item C<:all> - all functions

=item C<:standard> - elements that are not obsolete in HTML5

=item C<:metadata> - head title base link meta style

=item C<:sections> - body div section nav article aside h1 h2 h3 h4 h5 h6 header footer address

=item C<:grouping> - p hr br pre dialog blockquote ol ul li dl dt dd

=item C<:text> - a q cite em strong small mark dfn abbr time progress meter code var samp kbd sub sup span i b bdo ruby rt rp

=item C<:embedded> - figure img iframe embed object param video audio source canvas map area

=item C<:tabular> - table thead tbody tfoot th td colgroup col caption

=item C<:form> - form fieldset label input button select datalist optgroup option textarea output

=back

=head2 Object Oriented Interface

You can also use these functions as methods of an object blessed into
the L<HTML::HTML5::Builder> package.

	my $b = HTML::HTML5::Builder->new;
	my $document = $b->html(
		-lang => 'en',
		$b->head(
			$b->title('Test', \(my $foo)),
			$b->meta(-charset => 'utf-8'),
		),
		$b->body(
			$b->h1('Test'),
			$b->p('This is a test.')
		),
	);

=head2 HTML::HTML5::Builder::Document

As mentioned above, C<< html() >> returns an C<HTML::HTML5::Builder::Document>
object. This inherits from C<XML::LibXML::Document>, but overloads
stringification using C<HTML::HTML5::Writer>.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=HTML-HTML5-Builder>.

=head1 SEE ALSO

L<XML::LibXML>,
L<HTML::HTML5::Writer>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2011 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

