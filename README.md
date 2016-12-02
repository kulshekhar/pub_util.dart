# pub_util [![Build Status](https://travis-ci.org/kulshekhar/pub_util.dart.svg?branch=master)](https://travis-ci.org/kulshekhar/pub_util.dart) [![Build status on windows](https://ci.appveyor.com/api/projects/status/j8nyrlexct8l1vrl?svg=true)](https://ci.appveyor.com/project/kulshekhar/pub-util-dart)

`pub_util` is a utility that can help list and update globally 
installed outdated Dart packages.

The hope is that this functionality will eventually be available in the 
standard `pub global` command.

### Installation

```
pub global activate pub_util
```

### Usage

`pub_util` can list all and outdated packages and update outdated packages.

1. List all globally installed packages

```
pub_util -l
```

2. List all outdated global packages

```
pub_util -o
```

3. Update all outdated global packages

```
pub_util -u
```

### Bugs, Fixes, Enhancements

All feedback, PRs and bug reports are welcome.
