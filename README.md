wintersmith-jade
================

A plugin to enable jade to be used as a content page (not just a template).

## Usage

Create a `.jade` file in your content directory. Wintersmith would usually ignore those without this plugin. With the wintersmith-jade plugin, Wintersmith will now pick up those as content and render the Jade as HTML like any other plugin.

To provide Wintersmith with metadata, use the following as a formatting example.

	title = 'Title'
	subtitle = 'Subtitle'
	date = '2013/10/12'
	teaser = 'Here is a sample teaser.'
	template = 'standard.jade'

	p Content here.