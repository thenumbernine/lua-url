#!/usr/bin/env luajit
local table = require 'ext.table'
local URL = require 'url'
local tolua = require 'ext.tolua'
print(tolua(URL'https://abc.com'))
print(tolua(URL'https://abc.com/def'))
print(tolua(URL'https://abc.com/def/ghi'))
print(tolua(URL'user@abc.com'))
print(tolua(URL'user:pass@abc.com'))
--print(tolua(URL'user@user:pass@abc.com'))	-- TODO false-positives
print(tolua(URL'user:pass:pass@abc.com'))
print(tolua(URL'abc.com'))
print(tolua(URL'abc.com/def'))
print(tolua(URL'abc.com/def/ghi'))
print(tolua(URL'abc.com/def/ghi?jkl'))
print(tolua(URL'abc.com/def/ghi;jkl'))
print(tolua(URL'abc.com/def/ghi#jkl'))
