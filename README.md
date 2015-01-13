# Text area with tokens

Javascript control for editing equations that supports embedded tokens for
variables in the equations.

## Screenshots

![Example Equation](https://cloud.githubusercontent.com/assets/1896112/5730563/c08ae4d6-9b40-11e4-8d48-02357ed1c484.png)
![Example Equation](https://cloud.githubusercontent.com/assets/1896112/5730571/e52ed50e-9b40-11e4-9bbc-e4c034fbd549.png)

## Usage

### Installation

Add to your Gemfile and bundle:
    
    gem 'token-text-area', git: 'https://github.com/k1w1/token-text-area.git'

Include JavaScript in your `application.js` manifest:

    //= require token-text-area

Include CSS in your `application.css.less` manifest:

    *= require token-text-area

### Helper

In your view, use the `token_text_area` helper to create the token text area:

    token_text_area(equation, variables, options = {})

#### Options

* **equation** - an existing equation with which to populate the equation editor (use `nil` if no such equation exists)
* **variables** - an array of hashes representing variables in the equation, with hash attributes `id`, `name`, and `value`. For example: `[{id: 1, name: 'Business Value', value: 5}]`. If the equation is in readonly mode (see next bullet) and the value is present, it will be displayed after the variable name in the token.
* **options** - a hash of options. You may pass HTML or data attributes to be attached to the token text area. Options specific to token-text-area are `readonly` and `container_tag`. If `readonly` is set to true, the equation will be readonly- not editable with values shown if available. If `container_tag` is set, the given tag will be used for the editor; if not set, `:div` is the default.

### Initialize

You must initialize the editor in your JavaScript or CoffeeScript. The API accepts two methods: `onQuery` and `onChange`. 

* `onQuery` is triggered when typing in the text area and may be used to populate the autocomplete menu. Passing an array of JSON objects with `id` and `name` attributes to `callback(data);` will populate the autocomplete menu with those objects.
* `onChange` is triggered when the value of the text area changes, and may be used to save the equation value (or similar).

A complete example initialization:

    $("#editor").tokenTextArea({
      onQuery: function(query, callback) {
        $.ajax({
          type: 'GET',
          url: '/autocomplete/results/path/?query=' + query,
          dataType: 'json',
          success: function(data) {
            return callback(data);
          }
        });
      },
      onChange: function(equation) {
        $.ajax({
          type: 'PUT',
          url: '/some/save/path/',
          dataType: 'json',
          data: {
            equation: equation
          }
        });
      }
    });

### A Note about Variables

Variables in equations are automatically converted for server-side storage in the `onChange` event from `<span class="token"...` to `#variable_id#` placeholder notation, where variable_id is the ID attribute of the variable. In the `token_text_area` helper, variables are automatically converted from `#variable_id#` notation back to display-friendly `<span class="token"...` by looking up the variable ID in the `variables` array parameter.

## Running examples

    bundle install
    bundle exec rackup
    http://localhost:9292/examples/index.html
