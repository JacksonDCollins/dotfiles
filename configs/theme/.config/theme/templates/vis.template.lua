-- Generated from vis.template.lua; edit that template or theme.json.
local lexers = vis.lexers

lexers.STYLE_DEFAULT = 'fore:{{text}},back:{{base}}'
lexers.STYLE_NOTHING = ''
lexers.STYLE_IDENTIFIER = 'fore:{{text}}'
lexers.STYLE_WHITESPACE = 'fore:{{surface1}}'
lexers.STYLE_COMMENT = 'fore:{{overlay0}},italics'
lexers.STYLE_KEYWORD = 'fore:{{mauve}}'
lexers.STYLE_TYPE = 'fore:{{yellow}}'
lexers.STYLE_CLASS = lexers.STYLE_TYPE
lexers.STYLE_FUNCTION = 'fore:{{blue}}'
lexers.STYLE_DEFINITION = lexers.STYLE_FUNCTION
lexers.STYLE_VARIABLE = 'fore:{{text}}'
lexers.STYLE_CONSTANT = 'fore:{{peach}}'
lexers.STYLE_NUMBER = lexers.STYLE_CONSTANT
lexers.STYLE_STRING = 'fore:{{green}}'
lexers.STYLE_REGEX = 'fore:{{pink}}'
lexers.STYLE_OPERATOR = 'fore:{{sky}}'
lexers.STYLE_ATTRIBUTE = 'fore:{{mauve}}'
lexers.STYLE_LABEL = 'fore:{{sapphire}}'
lexers.STYLE_PREPROCESSOR = 'fore:{{pink}}'
lexers.STYLE_TAG = 'fore:{{blue}}'
lexers.STYLE_ERROR = 'fore:{{red}},underlined'
lexers.STYLE_EMBEDDED = 'fore:{{text}},back:{{surface0}}'

lexers.STYLE_LINENUMBER = 'fore:{{overlay0}},back:{{base}}'
lexers.STYLE_LINENUMBER_CURSOR = 'fore:{{lavender}},back:{{base}},bold'
lexers.STYLE_CURSOR = 'fore:{{base}},back:{{lavender}}'
lexers.STYLE_CURSOR_PRIMARY = 'fore:{{base}},back:{{rosewater}}'
lexers.STYLE_CURSOR_LINE = 'back:{{surface0}},keep_attribute'
lexers.STYLE_COLOR_COLUMN = 'back:{{surface0}}'
lexers.STYLE_SELECTION = 'back:{{surface2}},keep_attribute'
lexers.STYLE_STATUS = 'fore:{{subtext0}},back:{{mantle}}'
lexers.STYLE_STATUS_FOCUSED = 'fore:{{mauve}},back:{{surface0}},bold'
lexers.STYLE_SEPARATOR = 'fore:{{surface1}},back:{{base}}'
lexers.STYLE_INFO = 'fore:{{text}},back:{{mantle}}'
lexers.STYLE_EOF = 'fore:{{surface1}}'

lexers.MODAL_STYLES = {
  [vis.modes.NORMAL] = {
    REGULAR = 'fore:{{base}},back:{{yellow}}',
    INVERTED = 'fore:{{yellow}},back:{{base}}',
  },
  [vis.modes.INSERT] = {
    REGULAR = 'fore:{{base}},back:{{green}}',
    INVERTED = 'fore:{{green}},back:{{base}}',
  },
  [vis.modes.VISUAL] = {
    REGULAR = 'fore:{{base}},back:{{mauve}}',
    INVERTED = 'fore:{{mauve}},back:{{base}}',
  },
  [vis.modes.REPLACE] = {
    REGULAR = 'fore:{{base}},back:{{blue}}',
    INVERTED = 'fore:{{blue}},back:{{base}}',
  },
  [vis.modes.VISUAL_LINE] = {
    REGULAR = 'fore:{{base}},back:{{mauve}}',
    INVERTED = 'fore:{{mauve}},back:{{base}}',
  },
  [vis.modes.OPERATOR_PENDING] = {
    REGULAR = 'fore:{{base}},back:{{blue}}',
    INVERTED = 'fore:{{blue}},back:{{base}}',
  },
  [vis.modes.TERMINAL] = {
    REGULAR = 'fore:{{base}},back:{{peach}}',
    INVERTED = 'fore:{{peach}},back:{{base}}',
  },
  UNFOCUSED = {
    REGULAR = 'fore:{{subtext0}},back:{{mantle}}',
    INVERTED = 'fore:{{text}},back:{{base}}',
  },
}

lexers.STYLE_ADDITION = 'fore:{{green}}'
lexers.STYLE_DELETION = 'fore:{{red}}'
lexers.STYLE_CHANGE = 'fore:{{yellow}}'
lexers.STYLE_PROPERTY = 'fore:{{blue}}'
lexers.STYLE_PSEUDOCLASS = 'fore:{{yellow}}'
lexers.STYLE_PSEUDOELEMENT = lexers.STYLE_PSEUDOCLASS
lexers.STYLE_TAG_UNKNOWN = lexers.STYLE_ERROR
lexers.STYLE_TAG_SINGLE = lexers.STYLE_TAG
lexers.STYLE_TAG_DOCTYPE = lexers.STYLE_PREPROCESSOR
lexers.STYLE_ATTRIBUTE_UNKNOWN = lexers.STYLE_ATTRIBUTE
lexers.STYLE_COMMAND = lexers.STYLE_KEYWORD
lexers.STYLE_COMMAND_SECTION = lexers.STYLE_CLASS
lexers.STYLE_ENVIRONMENT = lexers.STYLE_TYPE
lexers.STYLE_ENVIRONMENT_MATH = lexers.STYLE_NUMBER
lexers.STYLE_TARGET = lexers.STYLE_FUNCTION
lexers.STYLE_HEADING = 'fore:{{mauve}},bold'
for i = 1, 6 do lexers['STYLE_HEADING_H' .. i] = lexers.STYLE_HEADING end
lexers.STYLE_HR = 'fore:{{overlay0}}'
lexers.STYLE_BOLD = 'bold'
lexers.STYLE_ITALIC = 'italics'
lexers.STYLE_LIST = lexers.STYLE_KEYWORD
lexers.STYLE_LINK = 'fore:{{blue}},underlined'
lexers.STYLE_REFERENCE = lexers.STYLE_LINK
lexers.STYLE_CODE = lexers.STYLE_STRING
lexers.STYLE_FILENAME = lexers.STYLE_STRING
lexers.STYLE_LINE = lexers.STYLE_NUMBER
lexers.STYLE_COLUMN = lexers.STYLE_NUMBER
lexers.STYLE_MESSAGE = lexers.STYLE_IDENTIFIER
lexers.STYLE_KEYWORD_SOFT = lexers.STYLE_KEYWORD
lexers.STYLE_CDATA = lexers.STYLE_STRING
lexers.STYLE_ERROR_INDENT = 'fore:{{base}},back:{{red}}'
