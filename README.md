# crocket_example

This is an example usage of [Crocket][crocket].

## Installation

Install the following dependencies:

- libao
- libmpg123

On macOS, this can be done using Homebrew like this:

```sh
brew install libao mpg123
```

## Usage

```sh
# Build the example in edit mode
shards build

# Start the editor with a .rocket file loaded, and start the built binary:
./bin/crocket_example

# Press space in the editor to start the playback of the pattern.
# This example quits once it reaches a row higher than 128 and then saves the
# resulting tracks to `./data/sync_*.track`.

# Now, close the editor and recompile the example in demo mode.
shards build -Dsync_player

# Finally, run the example.
./bin/crocket_example
```

## Development

TODO: Write development instructions here

## Contributing

1. Fork it (<https://github.com/nilsding/crocket_example/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Georg Gadinger](https://github.com/nilsding) - creator and maintainer

[crocket]: https://github.com/nilsding/crocket
