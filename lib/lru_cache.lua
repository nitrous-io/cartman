-- Adopted from https://raw.github.com/stephan-hof/mysql-proxy-in-memory-lru-cache/master/in_memory_lru_cache.lua
--
-- The LRU-Cache is a table which maintains the insertion order of
-- values with a doubled linked list. Each new value is placed at the front of
-- this list. So the oldest values are found at the back/tail of this list.
-- A 'value' is the real data, which is going to be cached.
-- Each 'value' is wrapped by a 'entry' object.
-- This 'entry' keeps the pointers for the doubled linked list and also the lifetime.

local setmetatable = setmetatable

local _M = {}

local mt = { __index = _M }

function _M.new(self, maxsize, max_age)
  local lru_cache = {
    -- Number of current cache entries
    current_items = 0,
    -- Number of maximum cache entries
    maxsize = maxsize,
    -- Number of seconds how long a cache entry should be valid
    max_age = max_age,
    head = {key = "head", next_ = nil, prev_ = nil},
    tail = {key = "tail", next_ = nil, prev_ = nil},
    -- Stores the cache entries
    data = {}
  }
  -- head/tail are nodes in the linked list, which are never be dropped.
  -- They are sentinels which make the operations on the linked list easier
  lru_cache.head.prev_ = lru_cache.tail
  lru_cache.tail.next_ = lru_cache.head
  return setmetatable(lru_cache, mt)
end

function _M.print_linked_list(self)
  local cur = self.tail
  while cur ~= nil do
    print(cur.key)
    cur = cur.next_
  end
end

function _M.add_entry(self, entry)
  self.head.prev_.next_ = entry
  entry.prev_ = self.head.prev_

  self.head.prev_ = entry
  entry.next_ = self.head

  self.current_items = self.current_items + 1
  self.data[entry.key] = entry
end

function _M.remove_entry(self, entry)
  self.current_items = self.current_items - 1
  self.data[entry.key] = nil

  entry.prev_.next_ = entry.next_
  entry.next_.prev_ = entry.prev_
end

function _M.del_last_entry(self)
  if self.current_items ~= 0 then
    self.remove_entry(self, self.tail.next_)
  end
end

function _M.set(self, key, value)
  local entry = {
    -- If 'self.del_last_entry' is called the key is needed to remove
    -- the entry from self.data
    key = key,
    value = value,
    max_age = os.time() + self.max_age,
    next_ = nil,
    prev_ = nil
  }
  if self.current_items > self.maxsize then
    _M.del_last_entry(self)
  end
  _M.add_entry(self, entry)
end

function _M.get(self, key)
  local entry = self.data[key]

  if entry == nil then
    return nil
  elseif entry.max_age > os.time() then
    --for implementing the LRU, we should move the current entry to the head of list
    --otherwise, it will like FIFO but not LRU
    _M.remove_entry(self, entry)
    _M.add_entry(self, entry)
    -- Entry is there + young enough => Cache hit
    return entry.value
  else
    -- auto delete the entry because its too old to be kept
    _M.remove_entry(self, entry)
    return nil
  end
end

return _M
