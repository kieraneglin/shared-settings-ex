## DSL ideas

```elixir
# Creation
SharedSettings.create(:name, :type, :default_value)
# Example
SharedSettings.create(:signup_bonus, :number, 10)
SharedSettings.create(:permitted_versions, :range, 3..7)
SharedSettings.create(:authentication_enabled, :boolean, true)

# Fetching
SharedSettings.get(:name)

# Querying
SharedSettings.exists?(:name)

# Updating
SharedSettings.update(:name, :new_value)

# Deletion
SharedSettings.delete(:name)

# Errors
SharedSettings.create(:signup_bonus, :number, "str") # returns {:error, term()}.  Doesn't set a value
SharedSettings.create!(:signup_bonus, :number, "str") # throws.  consider adding bang variants to all methods?
SharedSettings.update(:signup_bonus, "str") # returns {:error, term()}.  Retains the old value

# MPV Types
:number # probably pretty lax here - signed ints and floats are fair game.  might consider having :float as its own type
:string
:boolean
:range # again, probably floats and ints here.  keep it simple and copy what Ruby/Elixir already do

# Maybe/future types
:atom # or :symbol
:binary
list_of(:number) # For arrays of a given type. Would only accept 1 type to start
:object # Or hash or map or whatever.  JSON can be used in the :string type if needed in MVP

# Thoughts
# Should all types be nullable?  I don't think so.  The type should be the type
```

## Features/limitations
- This could do basic boolean feature flagging, but I don't think doing something crazy w/ actors and gates is in-scope
  - "Dumb" percentages can be implemented more manually by specifying a number here and the client code uses that to roll the dice
  - User-specific config is likely out of scope.  These should be more global settings
- Covers shared config that can be updated at runtime and that both Rails and Elixir can consume (start with Elixir)
- Doesn't provide anything at compile time
- The storage system should be easy to implement in all langs (so someone could write a Go adaptor if they wanted)
  - No lang-specific marshalling or structures (in a way that other langs couldn't parse out)
- Should provide multiple storage adaptors (SQL, redis, memcached, etc)
  - (consider) should leverage lang-specific caching when available (eg: ETS).  Source of truth should always be something sharable (redis, etc)
- The UI libs should be separate/optional
- (less important) should allow for easy plugin creation (eg: supporting new datatypes)

