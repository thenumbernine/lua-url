#!/usr/bin/env luajit
--[[
for facebook links
remove the url from the query
remove the fbclid from the url from the query
--]]
local table = require 'ext.table'
local URL = require 'url'
local tolua = require 'ext.tolua'

local u1str = assert(..., "expected url") 
local u1 = URL(u1str)
print(tolua(u1, {indent='always'}))
print()

print(u1str)
print(u1)
print(tostring(u1) == u1str)

print()
local u2 = URL(u1.query.u)
print(tolua(u2, {indent='always'}))
-- decode the fbclid?
print(URL(table(u2, {query=false})))
