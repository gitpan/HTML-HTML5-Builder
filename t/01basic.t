use Test::More tests => 2;
BEGIN { use_ok('HTML::HTML5::Builder') };

HTML::HTML5::Builder->import(':standard');

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

is("$document",
	'<!DOCTYPE html><html lang=en><title lang=en-GB>Test</title><meta charset=utf-8><h1>Test</h1><p>This is a test.',
	'Works.');
