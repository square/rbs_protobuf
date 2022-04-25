# CHANGELOG

## 1.0.0 (2022-04-25)

This is version 1.0.0. 🎉

It includes changes on `nil` handling on required fields. Passing `nil` to required fields is prohibited by default, but there is an option to allow it, define `$RBS_PROTOBUF_ACCEPT_NIL_ATTR_WRITER` env var.

* Stop accepting `nil` to required fields ([\#16](https://github.com/square/rbs_protobuf/pull/16))
* Add an option to let required fields accept `nil` ([\#27](https://github.com/square/rbs_protobuf/pull/27))
* Fix extension generator ([\#21](https://github.com/square/rbs_protobuf/pull/21))
* Use overload for field write types ([\#22](https://github.com/square/rbs_protobuf/pull/22))
* Generate helper types and use them ([\#24](https://github.com/square/rbs_protobuf/pull/24))

## 0.3.0 (2022-04-05)

* Put protobuf _options_ in RBS comment ([\#15](https://github.com/square/rbs_protobuf/pull/15))
* Add `!` methods type definitions ([\#14](https://github.com/square/rbs_protobuf/pull/14))

## 0.2.0 (2022-03-18)

This is a maintenance release to support the latest version of RBS.

* Update to the latest RBS ([#11](https://github.com/square/rbs_protobuf/pull/11))
* Type check with Steep ([#11](https://github.com/square/rbs_protobuf/pull/11))
* Drop Ruby 2.6 support ([#11](https://github.com/square/rbs_protobuf/pull/11))
