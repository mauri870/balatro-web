--[[
This file is part of "love.js" by 2dengine.
https://2dengine.com/doc/lovejs.html

MIT License

Copyright (c) 2022 2dengine LLC

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

-- normalizem.lua is a series of hacks which ensure that
-- any optional love.js modules behave as expected

if love.window then
  local DEFAULT_W = 1280
  local DEFAULT_H = 720

  -- Bootstrap: if the window was opened 0x0, set a real size now (before love.load).
  if love.graphics and love.graphics.getWidth() == 0 then
    love.window.setMode(DEFAULT_W, DEFAULT_H, {fullscreen = false, resizable = true})
  end

  local _setMode    = love.window.setMode
  local _updateMode = love.window.updateMode

  local function sanitize(w, h, flags)
    flags = flags or {}
    w = (w and w > 0) and w or DEFAULT_W
    h = (h and h > 0) and h or DEFAULT_H
    flags.fullscreen     = false
    flags.fullscreentype = nil
    return w, h, flags
  end

  love.window.setMode = function(w, h, flags)
    return _setMode(sanitize(w, h, flags))
  end

  love.window.updateMode = function(w, h, flags)
    return _updateMode(sanitize(w, h, flags))
  end
end

-- WebGL 1.0 does not support mipmaps on non-power-of-two textures (NPOT), so force mipmaps=false
if love.graphics then
  local _newImage = love.graphics.newImage
  love.graphics.newImage = function(src, settings)
    settings = settings or {}
    settings.mipmaps = false
    return _newImage(src, settings)
  end
end

if love.event then
  local _love_event_push = love.event.push
  function love.event.push(event, action, ...)
    if event == 'quit' and action == 'reload' then
      love.system.js('reload')
      return
    end
    return _love_event_push(event, action, ...)
  end
end

-- Shim for LuaJIT's 'bit' library using normal Lua arithmetic
if not package.preload['bit'] then
  package.preload['bit'] = function()
    local function tobit(n)
      n = n % 2^32
      if n >= 2^31 then n = n - 2^32 end
      return n
    end

    local function bnot(a)
      return tobit(-(a + 1))
    end

    local function band(a, b)
      local r, bit = 0, 1
      for _ = 1, 32 do
        local ab, bb = a % 2, b % 2
        if ab + bb == 2 then r = r + bit end
        a, b, bit = (a - ab) / 2, (b - bb) / 2, bit * 2
      end
      return tobit(r)
    end

    local function bor(a, b)
      local r, bit = 0, 1
      for _ = 1, 32 do
        local ab, bb = a % 2, b % 2
        if ab + bb >= 1 then r = r + bit end
        a, b, bit = (a - ab) / 2, (b - bb) / 2, bit * 2
      end
      return tobit(r)
    end

    local function bxor(a, b)
      local r, bit = 0, 1
      for _ = 1, 32 do
        local ab, bb = a % 2, b % 2
        if ab ~= bb then r = r + bit end
        a, b, bit = (a - ab) / 2, (b - bb) / 2, bit * 2
      end
      return tobit(r)
    end

    local function lshift(a, n)
      n = n % 32
      return tobit((a % 2^32) * 2^n)
    end

    local function rshift(a, n)
      n = n % 32
      return math.floor((a % 2^32) / 2^n)
    end

    local function arshift(a, n)
      n = n % 32
      a = a % 2^32
      local r = math.floor(a / 2^n)
      if a >= 2^31 then r = r + 2^(32-n) - 1 end -- sign-extend
      return tobit(r)
    end

    local function rol(a, n)
      n = n % 32
      a = a % 2^32
      return tobit((a * 2^n) % 2^32 + math.floor(a / 2^(32-n)))
    end

    local function ror(a, n)
      return rol(a, 32 - n % 32)
    end

    local function bswap(a)
      a = a % 2^32
      local b0 = a % 256
      local b1 = math.floor(a / 256) % 256
      local b2 = math.floor(a / 65536) % 256
      local b3 = math.floor(a / 16777216) % 256
      return tobit(b0 * 16777216 + b1 * 65536 + b2 * 256 + b3)
    end

    local function tohex(a, n)
      n = n or 8
      a = a % 2^32
      if n < 0 then
        return string.format('%'..(-n)..'X', a)
      end
      return string.format('%0'..n..'x', a)
    end

    local function vararg_op(fn, a, ...)
      for i = 1, select('#', ...) do
        a = fn(a, (select(i, ...)))
      end
      return a
    end

    return {
      tobit   = tobit,
      bnot    = bnot,
      band    = function(a, ...) return vararg_op(band, a, ...) end,
      bor     = function(a, ...) return vararg_op(bor,  a, ...) end,
      bxor    = function(a, ...) return vararg_op(bxor, a, ...) end,
      lshift  = lshift,
      rshift  = rshift,
      arshift = arshift,
      rol     = rol,
      ror     = ror,
      bswap   = bswap,
      tohex   = tohex,
    }
  end
end

if love.audio then
  local playing = {}
  local function _cleanup_playing()
    for s in pairs(playing) do
      if not s:isPlaying() then
        playing[s] = nil
      end
    end
  end
  local _love_audio_play = love.audio.play
  function love.audio.play(...)
    _cleanup_playing()
    -- track currently playing
    for i = 1, select("#", ...) do
      local s = select(i, ...)
      playing[s] = true
    end
    return _love_audio_play(...)
  end

  local _love_audio_stop = love.audio.stop
  function love.audio.stop(source, ...)
    if source then
      return _love_audio_stop(source, ...)
    end
    for s in pairs(playing) do
      s:stop()
      playing[s] = nil
    end
  end

  local reg = debug.getregistry()
  if reg then
    local _Source_play = reg.Source.play
    reg.Source.play = function(source, ...)
      _cleanup_playing()
      playing[source] = true
      return _Source_play(source, ...)
    end
  end
end

