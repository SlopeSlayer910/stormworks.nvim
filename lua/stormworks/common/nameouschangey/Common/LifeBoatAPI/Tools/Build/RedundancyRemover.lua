-- Author: Nameous Changey
-- GitHub: https://github.com/nameouschangey/STORMWORKS_VSCodeExtension
-- Workshop: https://steamcommunity.com/id/Bilkokuya/myworkshopfiles/?appid=573090
--- Developed using LifeBoatAPI - Stormworks Lua plugin for VSCode - https://code.visualstudio.com/download (search "Stormworks Lua with LifeboatAPI" extension)
--- If you have any issues, please report them here: https://github.com/nameouschangey/STORMWORKS_VSCodeExtension/issues - by Nameous Changey

require("stormworks.common.nameouschangey.Common.LifeBoatAPI.Tools.Utils.Base")
require("stormworks.common.nameouschangey.Common.LifeBoatAPI.Tools.Utils.TableUtils")
require("stormworks.common.nameouschangey.Common.LifeBoatAPI.Tools.Utils.StringBuilder")
require("stormworks.common.nameouschangey.Common.LifeBoatAPI.Tools.Utils.StringUtils")

-- Format accepted:
-- "---@section EXACT|PARTIAL Identifier 2 SectionName"
-- "---@section Identifier 2 SectionName"
-- "---@section Identifier"
-- With corresponding end section:
-- "---@endsection SectionName"
-- "---@endsection"
-- care must be taken not to share one endsection between two section labels, otherwise you'll break it
-- care must also be taken not to incorrectly overlap two sections - overlaps must be handled nested; otherwise removal will break things
-- failing to do this will mean code lingers, but will not throw errors - as such the resulting lua size will be larger than you could have managed

---@class CodeSection : BaseClass
---@field startIndex number
---@field endIndex number
---@field identifier string
---@field instances number
---@field sectionName string
LifeBoatAPI.Tools.CodeSection = {
  ---@param cls CodeSection
  ---@param match StringMatch
  ---@return CodeSection
  new = function(cls, match, text)
    local this = LifeBoatAPI.Tools.BaseClass.new(cls)
    this.startIndex = match.startIndex

    local captures = LifeBoatAPI.Tools.StringUtils.split(match.captures[1], "%s")
    this:_init_from_captures(captures)

    local endings = LifeBoatAPI.Tools.StringUtils.find(
      text,
      "%-%-%-@endsection[^%S\n]-" .. this.sectionName .. "[^%S\n]-\n",
      match.endIndex
    )
    this.endIndex = endings[1] and endings[1].endIndex or match.endIndex -- if no end was found, this section does nothing

    return this
  end,

  _init_from_captures = function(this, args)
    local index = 1

    -- 1. first arg can be one of two constants - EXACT or PATTERN to specify the match type
    --  otherwise EXACT matching is used
    this.exact = true
    if args[index] == "EXACT" then
      this.exact = true
      index = index + 1
    elseif args[index] == "PATTERN" then
      this.exact = false
      index = index + 1
    end

    -- 2. next argument is the identifier to search for
    this.identifier = args[index] or "_LB_SECTION_MISSING_IDENTIFIER_"
    index = index + 1
    -- exact matching (default) means we expect this to be the entire word, and not made of any pattern stuff
    -- PATTERN matching (non-exact) means we trust the user comes up with a relevant pattern themself
    if this.exact then
      this.identifier = "[^%a%d_]" .. LifeBoatAPI.Tools.StringUtils.escape(this.identifier) .. "[^%a%d_]"
    end

    -- 3. if given the next argument is the count
    this.instances = 1
    if args[index] and tonumber(args[index]) then
      this.instances = tonumber(args[index])
      index = index + 1
    end

    --- 4. final argument, if given, is the section name
    this.sectionName = ""
    if args[index] then
      this.sectionName = args[index]
      index = index + 1
    end
  end,

  --Checks if the amount of calls to the identifier outside the section tags is less than the instances required to include it
  ---@param this CodeSection
  isRemovable = function(this, text)
    local textBefore, textAfter = this:_textOutsideSection(text)
    local countBefore, countAfter =
      LifeBoatAPI.Tools.StringUtils.count(textBefore, this.identifier),
      LifeBoatAPI.Tools.StringUtils.count(textAfter, this.identifier)
    return countBefore + countAfter < this.instances
  end,

  --Joins the parts of the text before and after the section, ommitting the section
  ---@param this CodeSection
  stripFromText = function(this, text)
    local textBefore, textAfter = this:_textOutsideSection(text)
    return textBefore .. textAfter
  end,

  ---@param this CodeSection
  _textOutsideSection = function(this, text)
    local textBefore = text:sub(1, this.startIndex - 1)
    local textAfter = text:sub(this.endIndex + 1, #text)
    return textBefore, textAfter
  end,
}
LifeBoatAPI.Tools.Class(LifeBoatAPI.Tools.CodeSection)

---@class RedundancyRemover : BaseClass
LifeBoatAPI.Tools.RedundancyRemover = {

  ---@param this RedundancyRemover
  removeRedundantCode = function(this, text)
    local reducedText, foundRemovable = text, false
    repeat
      reducedText, foundRemovable = this:attemptDeletionPass(reducedText)
    until not foundRemovable

    return reducedText
  end,

  --this is run until we can't find any more removable sections
  -- we can only strip one each time, and then need to re-pass the entire file
  -- it's a slow process; but it's the only way to do this reasonable safely without a lot of thinking
  ---@param this RedundancyRemover
  ---@return string text the string that has been searched
  ---@return boolean foundRemovable did we find any removable sections
  attemptDeletionPass = function(this, text)
    ---@type CodeSection[]
    local sections = LifeBoatAPI.Tools.StringUtils.find(text, "%-%-%-@section%s-([^\n]+)\n")

    --mustate the table of results to a table of CodeSections
    sections = LifeBoatAPI.Tools.TableUtils.iselect(sections, function(v)
      return LifeBoatAPI.Tools.CodeSection:new(v, text)
    end)

    sections = LifeBoatAPI.Tools.TableUtils.iorderBy(sections, function(a, b)
      return a.endIndex > b.endIndex
    end)

    local lastStartIndex = math.huge
    local foundRemovable = false
    
    --loop through all those CodeSections from the bottom up and attempt to strip them (bottom up means that a single pass can strip more)
    for i= 1, #sections, 1 do
      local section = sections[i]
      if section.startIndex > lastStartIndex then 
        if section:isRemovable(text) then
          text = section:stripFromText(text)
          lastStartIndex = section.startIndex
          foundRemovable = true
        end
      else
        --if the startIndex is not after the lastStart index then the section has been removed and should not be checked
      end
    end
    return text, foundRemovable
  end,
}
LifeBoatAPI.Tools.Class(LifeBoatAPI.Tools.RedundancyRemover)