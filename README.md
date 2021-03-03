# Shared Settings

Shared Settings is a simple library for managing runtime settings in Elixir with optional support for encryption and Ruby.

Heavily inspired by [Fun with Flags][fwf] and [Flipper][flipper].

## Installation

```elixir
def deps do
  [
    {:shared_settings, "~> 0.2.0"},
    # Optional
    {:shared_settings_ui, "~> 0.2.0"}
  ]
end
```

Once installed, you need to add the following to your config:

```elixir
config :shared_settings,
  cache_ttl: 300, # Set to 0 to disable
  cache_adapter: SharedSettings.Cache.EtsStore,
  storage_adapter: SharedSettings.Persistence.Redis,
  encryption_key: "..." # Optional - can be generated with `mix SharedSettings.CreateKey`
  redis: [ # Can also take a URI string
    host: "localhost",
    port: 6379,
    database: 0
  ]
```

To use the optional UI, check out the [Shared Settings UI Elixir][ss-ui-ex] library.  Ruby support is provided by the [shared-settings][ss-rb] Gem.

## Why "shared" settings?

The intention for this library is to also create an accompanying Ruby Gem which uses the same storage adapter, format, and UI found here.

This means that a Rails app could change a runtime setting in an Elixir app and vice-versa.  They would also share a single UI dashboard if configured, allowing a one-stop location to manage parallel apps or to help migration efforts. Of course, this library could be used with Elixir or Ruby individually.

The API/storage conventions are designed to be simple enough that additional libraries in other languages (eg: Go) could be created to allow further interop between applications as long as there was a shared data source.

## Design goals

SharedSettings is not intended to be a fully-blown feature flagging library. It's fine for simple boolean setting or for "dumb" percentage-based flagging like so:

```elixir
def show_updated_onboarding? do
  {:ok, percentage} = SharedSettings.get(:updated_onboarding_percentage)

  Enum.random(0..100) < percentage
end
```

But if you need more complete feature flagging, check out [Fun with Flags][fwf].

Instead, this library came from a personal need to share runtime settings between a Rails and Elixir app while migrating our codebases.  Having a single admin interface to allow non-devs to update features of one or both apps was ideal, but other benefits like allowing synchronization of maintenance modes between all servers/apps were considered.

Storage was made to be simple so creating custom adapters would be trivial.  Currently only a Redis adapter is shipped, but creating a SQL or NoSQL adapter would be simple.  There is some documentation around this in the `SharedSettings.Store` module.

## Encryption

Encryption is implemented as AES256.  If you choose to provide an encryption key, specified setting values within your storage adapter will be encrypted.  Nothing else about the setting, including its name, will be encrypted.  Once an encrypted setting is requested via `get/1` it's automatically decrypted so the plaintext value is returned.

```elixir
{:ok, _} = SharedSettings.put(:client_id, "supersecret", encrypt: true)
{:ok, "supersecret"} = SharedSettings.get(:client_id)
```

## Usage

The API is quite simple.  For most cases, you have `put/2`, `get/1`, `delete/1`, and `exists?/1`.  

There is also `get_all/0` which returns all raw settings, but this is primarily to support UI.

### Supported Types

At a high level, the currently supported types are `string`, `boolean`, `number`, and `range`. `number` includes negative numbers as well as floats. `range`s are inclusive.

All types are serialized as strings to be held within the storage adapter.

### Put

`put/2` takes a name as well as a value with a supported type. It returns a tuple of `{:ok, setting_name}` where `setting_name` is a string.

```elixir
{:ok, _} = SharedSettings.put(:signups_enabled, true)
{:ok, _} = SharedSettings.put(:referral_bonus, 52, encrypt: true)
```

`put` will overwrite old settings if the provided name already exists.  This means there's no method for updating - replacement is the way to go:

```elixir
{:ok, _} = SharedSettings.put(:confusing_setting, true)
{:ok, _} = SharedSettings.put(:confusing_setting, 2..7)
```

### Get

`get/1` takes the name of a setting and returns `{:ok, original_value}`.  `{:error, :not_found}` is returned if the setting doesn't exist.

```elixir
{:ok, 0..5} = SharedSettings.get(:permitted_ranks)
{:error, :not_found} = SharedSettings.get(:not_real)
```

### Delete

`delete/1` takes the name of a setting and removes it from cache and storage.  `:ok` is retuned no matter what so it's safe to call delete on settings that may not exist.

```elixir
:ok = SharedSettings.delete(:contrived_example)
:ok = SharedSettings.delete(:not_real)
```

### Exists?

`exists?/1` takes the name of a setting and returns a boolean reflecting its existence.

```elixir
true = SharedSettings.exists?(:signups_enabled)
false = SharedSettings.exists?(:not_real)
```

### Get all

`get_all/0` returns all stored settings in their raw form.  This is mainly used by the accompanying UI library but it could also be used to ensure all needed flags exist at boot time.

```elixir
{:ok, [Setting.t()]} = SharedSettings.get_all()
```

## License

MIT License

Copyright 2021

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

[fwf]: https://github.com/tompave/fun_with_flags
[flipper]: https://github.com/jnunemaker/flipper
[ss-rb]: https://github.com/kieraneglin/shared-settings-rb
[ss-ui-ex]: https://github.com/kieraneglin/shared-settings-ui-ex
