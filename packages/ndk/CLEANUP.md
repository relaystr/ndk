# Notes on cleanup commits by franzaps

## Filesystem

 - Remove ios folder - why was it there? This no longer depends on Flutter
 - Remove Isar - should not belong to the core ndk
 - Renamed bad file names with all uppercase words

## Code warnings

 - Removed `public_member_api_docs` from the linter, at the very least until there is interest to actually perform the task (over 500 warnings gone)
 - Refactored string interpolations
 - Refactored all enums for proper casing
 - Constants start with lowercase k in Dart, refactored all those
 - Left `TODO`s throughout the codebase but clarified several of them, they should be kept actionable and descriptive and if it's an important issue moved to an issue tracker

## Comment on variable modifiers and names

Types in Dart are inferred, not only using them on the left hand of the assignment makes them redundant (e.g. `ZapReceipt receipt = ZapReceipt.fromEvent(event)` looks mega redundant) but it discourages thinking about proper descriptive variable names:

`List<NwcConnection> list = something.toList();`

Should in my opinion be:

`final nwcConnections = something.toList();`

Now every time you see `nwcConnections` it's clearer than `list`. While developing you can anyways always hover over to get the type.

On top of that, it sometimes causes to forget the final modifier. Always prefer finals, this helps reduce mutation bugs which are common.

`String test = "mystring"` -> `final testString = "mystring"`

## Other minor questions

 - Is it `readme.md` or `README.md` - what is the convention?
 - Not right to have static ints, it creates issues when subclassing for example: `static const kZapRequestKind = 9734;` can't be called `kKind` as it shadows that of `Nip01Event`
 - Can we name directories just `domain` vs `domain_layer`? it is sort of obvious that directories are used as layers