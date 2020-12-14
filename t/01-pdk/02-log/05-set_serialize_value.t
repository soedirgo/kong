use strict;
use warnings FATAL => 'all';
use Test::Nginx::Socket::Lua;
use t::Util;

plan tests => repeat_each() * (blocks() * 3);

run_tests();

__DATA__

=== TEST 1: kong.log.set_serialize_value() rejects parameters with the wrong format
--- http_config eval: $t::Util::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local PDK = require "kong.pdk"
            local pdk = PDK.new()

            local ok, err = pcall(pdk.log.set_serialize_value, 1)
            pdk.log.info("key ", ok, " ", err)

            -- invalid value (functions not allowed)
            ok, err = pcall(pdk.log.set_serialize_value, "valid key", function() end)
            pdk.log.info("value1 ", ok, " ", err)

            -- invalid value (tables should only have numbers, strings or booleans)
            ok, err = pcall(pdk.log.set_serialize_value, "valid key", { f = function() end })
            pdk.log.info("value2 ", ok, " ", err)

            -- valid value, no error
            ok, err = pcall(pdk.log.set_serialize_value, "valid key", { x = { a=1, b="hello", c=true } })
            pdk.log.info("value3 ", ok, " ", err)

            ok, err = pcall(pdk.log.set_serialize_value, "valid key", 1, { mode = "invalid" })
            pdk.log.info("mode ", ok, " ", err)

        }
    }

--- request
GET /t
--- no_response_body
--- error_log
false key must be a string
value1 false value must be a number, string, boolean or a table made with only numbers, string and booleans,
value2 false value must be a number, string, boolean or a table made with only numbers, string and booleans,
value3 true nil
mode false mode must be 'set', 'add' or 'replace'
--- no_error_log
[error]


=== TEST 2: kong.log.set_serialize_value() sets, adds and replaces new values
--- http_config eval: $t::Util::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local PDK = require "kong.pdk"
            local pdk = PDK.new()

            pdk.log.set_serialize_value("val1", 1)
            local s = pdk.log.serialize()
            pdk.log.info("val1.1=", s.val1)

            pdk.log.set_serialize_value("val1", 2)
            local s = pdk.log.serialize()
            pdk.log.info("val1.2=", s.val1)

            pdk.log.set_serialize_value("val1", 2, { mode = "replace" })
            local s = pdk.log.serialize()
            pdk.log.info("val1.2=", s.val1)


            -- invalid value (functions not allowed)
            ok, err = pcall(pdk.log.set_serialize_value, "valid key", function() end)
            pdk.log.info("value1 ", ok, " ", err)

            -- invalid value (tables should only have numbers, strings or booleans)
            ok, err = pcall(pdk.log.set_serialize_value, "valid key", { f = function() end })
            pdk.log.info("value2 ", ok, " ", err)

            -- valid value, no error
            ok, err = pcall(pdk.log.set_serialize_value, "valid key", { x = { a=1, b="hello", c=true } })
            pdk.log.info("value3 ", ok, " ", err)

            ok, err = pcall(pdk.log.set_serialize_value, "valid key", 1, { mode = "invalid" })
            pdk.log.info("mode ", ok, " ", err)

        }
    }

--- request
GET /t
--- no_response_body
--- error_log
false key must be a string
value1 false value must be a number, string, boolean or a table made with only numbers, string and booleans,
value2 false value must be a number, string, boolean or a table made with only numbers, string and booleans,
value3 true nil
mode false mode must be 'set', 'add' or 'replace'
--- no_error_log
[error]


