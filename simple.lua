--[[

ARGV[1]-keyid,

--]]
local function genrate_result(result, key, value)
   	local ret = {};
	table.insert(ret, result);
    table.insert(ret, key);
    table.insert(ret, value);
	
	return ret;
end



-- 错误码
local ET_OK = 0; -- 无错误
local ET_ERR_ARGS_COUNT = 1; -- 参数个数错误
local ET_ERR_ARGS_VALUE = 2; -- 参数值错误
local KEY_PREFIX = "tkey#"

local result = ET_OK;

if (#ARGV ~= 1) then
    local result = ET_ERR_ARGS_COUNT;
    return genrate_result(result, nil, nil);
end

local keyid = ARGV[1];
local tkey = KEY_PREFIX .. keyid


math.randomseed(1000000)

redis.log(redis.LOG_NOTICE, "key:", tkey, "keyid:", keyid)

redis.call('expire', tkey, math.random(1,24 * 3600));

redis.call('zadd', tkey, math.random(1,24 * 3600), 'aaa');
redis.call('zadd', tkey, math.random(1,24 * 3600), 'bbb');
redis.call('zadd', tkey, math.random(1,24 * 3600), 'ccc');
redis.call('zadd', tkey, math.random(1,24 * 3600), 'ddd');

local linking_list = redis.call('zrange', tkey, 0, -1, 'withscores');
local linking_list_count = #linking_list / 2;
for k,v in pairs(linking_list) do
    redis.log(redis.LOG_NOTICE, "k:", k, "v", v, "cnt", linking_list_count)
end

return genrate_result(result, tkey);


