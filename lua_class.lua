-- test lua

redis.replicate_commands()

-- 常量定义
local COMPANY_KEY_PREFIX = 'company:'
local COMPANY_VERSION_FIELD = 'company:ver:'
local COMPANY_ID_FIELD = 'company:id:'
local COMPANY_MONEY_FIELD = 'company:money:'
local COMPANY_DEBTS_FIELD = 'company:debts:'
local COMPANY_TIME_FIELD = 'company:time:'
local SERIAL_KEY_PREFIX = 'company_seri:'

--函数: 封装的to_number函数，不存在返回0
--返回值: 返回to_number的结果
local function redis_to_number(number)
    local count = tonumber(number)
    if not count then
        count = 0
    end
    return count
end

-- 第一种类定义方法
local company_info_len_v1 = 1 + 4 + 8 + 4 + 8
local CompanyInfo = 
{
    _version = 1,                           -- int8, 版本号，用于兼容处理
    _company_id = 0,                        -- int32, 
    _money = 0,                             -- int64, 
    _debts = 0,                             -- int32, 
    _modify_time_us = 0,                    -- uint64, 

    new = function(self)
        local o =
        {
        }
        setmetatable(o, self)
        self.__index = self
        return o
    end,

    -- 序列化
    serialize = function(self)
        if self._version == 1 then
            return struct.pack("<i1i4I8i4I8", 
                self._version,
                self._company_id,
                self._money,
                self._debts,
                self._modify_time_us)
        end
    end,

    -- 反序列化函数
    unserialize = function(self, buf)
        if #buf < 1 then
            return false
        end
        local pos = 1
        self._version, pos = struct.unpack("<i1", buf, pos)

        if self._version == 1 then
            if #buf < company_info_len_v1 then
                return false
            end

            self._company_id, pos = struct.unpack("<i4", buf, pos)
            self._money, pos = struct.unpack("<I8", buf, pos)
            self._debts, pos = struct.unpack("<i4", buf, pos)
            self._modify_time_us, pos = struct.unpack("<I8", buf, pos)
        else
            -- 暂不支持其他版本号
            return false
        end

        return true
    end,

    -- 初始化
    init = function(self, company_id)
        local company_key = COMPANY_KEY_PREFIX..company_id
        local attr_field_list = redis.call('hmget', company_key, COMPANY_ID_FIELD, COMPANY_MONEY_FIELD, COMPANY_DEBTS_FIELD, COMPANY_TIME_FIELD)
        
        self._company_id = redis_to_number(attr_field_list[1])
        self._money = redis_to_number(attr_field_list[2])
        self._debts = redis_to_number(attr_field_list[3])
        self._modify_time_us = redis_to_number(attr_field_list[4])
    end
};

-- 第二种类的写法，在类外部定义成员函数
local Rectangle = {area = 0, length = 0, breadth = 0}

function Rectangle:new (o,length,breadth)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  self.length = length or 0
  self.breadth = breadth or 0
  self.area = length*breadth;
  return o
end

function Rectangle:printArea ()
  print("矩形面积为 ",self.area)
end


-- interface
local function set_company_info(company_info)
    local seri_key = SERIAL_KEY_PREFIX..(company_info._company_id)
    redis.call('set', seri_key, company_info:serialize())
end

local function query_company_info(company_info, redis_key)
    local field_list = redis.call('get', redis_key)
    if not field_list then
        return true
    elseif not company_info:unserialize(field_list) then
        return false
    end
    return true
end

local function construct_return_info(return_code, company_info)
    local return_info = {}
    table.insert(return_info, return_code)
    table.insert(return_info, company_info._company_id)
    table.insert(return_info, company_info._money)
    table.insert(return_info, company_info._debts)
    table.insert(return_info, company_info._modify_time_us)

    return return_info
end

local company_id = ARGV[1] 

local redis_time = redis.call('time')
local current_time_us = redis_to_number(redis_time[1])*1000000 + redis_to_number(redis_time[2])

local company_info = CompanyInfo:new()
local return_code = 0
local company_key = COMPANY_KEY_PREFIX..company_id

company_info:init(company_id)

set_company_info(company_info)

local company_info_new = CompanyInfo:new()
local seri_key = SERIAL_KEY_PREFIX..company_id
if query_company_info(company_info_new, seri_key) then
    return_code = 0
else
    return_code = 100
end

company_info_new._modify_time_us = current_time_us

local r = Rectangle:new(nil, 10, 20)
r:printArea()

return construct_return_info(return_code, company_info_new)
