-- because socket.url is another library
-- meh
local class = require 'ext.class'
local table = require 'ext.table'
local assert = require 'ext.assert'
local string = require 'ext.string'


local defaultescapechars = "!#$&'()*+,/:;=?@[]%"
local escapecharsets = {}
local function escape(s, escapechars)
	escapechars = escapechars or defaultescapechars 
	local escapecharset = escapecharsets[escapechars]
	if not escapecharset then
		escapecharset = string.split(escapechars):mapi(function(ch) return true, ch end):setmetatable(nil)
		escapecharsets[escapechars] = escapecharset 
	end
	return (s:gsub('.', function(ch)
		if escapecharset[ch] then
			return ('%%%02X'):format(ch:byte())
		end
		return ch	-- necessary?
	end))
end

local function unescape(s)
	return (s:gsub('%%%x%x', function(s)
		local n = tonumber(s:sub(2), 16)
		if not n then return s end
		local ch = string.char(n)
		if not ch then return s end
		return ch
	end))
end

local function parseKV(kvstr)
	-- also return in-order list
	local kvs = table()
	for _,kv in ipairs(string.split(kvstr, '&')) do
		local k,v = kv:match'^([^=]+)=(.*)$'
		-- what if there's no "=" ? then what?
		if not k then k,v = kv, true end

		k = unescape(k) or k
		v = unescape(v) or v

		kvs:insert{k, v}
		kvs[k] = v
	end
	return kvs
end

local URL = class()


--[[
args-from-url

args-from-table
	url = string,
	scheme = string,
	authority = string,
	path = string,
	params = string,
	query = string,
	fragment = string,
	userinfo = string,
	host = string,
	port = string,
	user = string,
	password = string
--]]
function URL:init(args)
	if type(args) == 'string' then
		local url = args
		
		-- <scheme>://<username>:<password>@<host>:<port>/<path>;<parameters>?<query>#<fragment>	
		-- [<scheme>://][<username>[:<password>]@]<host>[:<port>][/<path>][;<parameters>][?<query>][#<fragment>]

		-- parse scheme
		local scheme, rest = args:match'^([^:]+)://(.*)$'
		if not scheme then
			rest = url
		end
		self.scheme = scheme

		-- parse user+host vs path+query+params+fragment
		local userandhost, pathqueryparamsfragment = rest:match'^([^/;?#]+)[/;?#](.*)$'	-- expect host to end at /;?#
		userandhost = userandhost or rest

		local userandpass, hostandport = userandhost:match'^([^@]+)@(.*)$'
		if userandpass then
			local user, pass = userandpass:match'^([^:]*):(.*)$'
			if not user then
				user = userandpass
			end
			self.user = user
			self.pass = pass
		else
			hostandport = userandhost
		end
		
		local host, port = hostandport:match'^([^:]+):(.*)$'
		host = host or hostandport
		self.host = host
		self.port = port

		if pathqueryparamsfragment then
			-- /path;params?query#fragment
			-- what if you get ;abc/def?  then it's still the params
			local prevrest = pathqueryparamsfragment
			rest, self.fragment = prevrest:match'^([^#]+)#(.*)$'
			prevrest = rest or prevrest
			rest, self.query = prevrest:match'^([^?]+)?(.*)$'
			prevrest = rest or prevrest
			rest, self.params = prevrest:match'^([^;]+);(.*)$'
			prevrest = rest or prevrest
			self.path = prevrest
		
			if self.query then self.query = parseKV(self.query) end
			if self.params then self.params = parseKV(self.params) end
		end

	elseif type(args) == 'table' then
		for k,v in pairs(args) do self[k] = v end
	elseif type(args) == 'nil' then
	else
		error("idk how to build a URL from this")
	end
end

URL.__concat = string.concat

-- tostring or another function?
function URL:__tostring()
	local s = table()
	if self.scheme then
		s:insert(self.scheme)
		s:insert'://'
	end
	if self.user then
		s:insert(self.user)
		if self.pass then
			s:insert':'
			s:insert(self.pass)
		end
		s:insert'@'
	end
	s:insert(self.host)
-- TODO escape path?  except /'s ?
	if self.path then
		s:insert'/'
		s:insert(self.path)
	end
	if self.params then
		s:insert';'
		local sep
		for _,q in ipairs(self.params) do
			s:insert(sep)
			sep = '&'
			s:insert(escape(q[1], "!#$&'()*+,/:;=?@%"))	-- key doesn't need [] escaped ...
			s:insert'='
			s:insert(escape(q[2]))
		end
	end
	if self.query then
		s:insert'?'
		local sep
		for _,q in ipairs(self.query) do
			s:insert(sep)
			sep = '&'
			s:insert(escape(q[1], "!#$&'()*+,/:;=?@%"))	-- key doesn't need [] escaped ...
			s:insert'='
			s:insert(escape(q[2]))
		end
	end
	if self.fragment then
		s:insert'#'
		s:insert(self.fragment)
	end
	return s:concat()
end

return URL
