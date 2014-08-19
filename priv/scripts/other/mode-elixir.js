/* The MIT License (MIT)
 *
 * Copyright (c) 2014 Alexei Sholik <alcosholik@gmail.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

"use strict";

ace.define('ace/mode/elixir', ['require', 'exports', 'module', 'ace/lib/oop', 'ace/mode/text', 'ace/mode/elixir_highlight_rules'], function(require, exports, module) {

var oop = require("../lib/oop");
var TextMode = require("./text").Mode;
var ElixirHighlightRules = require("./elixir_highlight_rules").ElixirHighlightRules;

var Mode = function() {
    this.HighlightRules = ElixirHighlightRules;
};
oop.inherits(Mode, TextMode);

(function() {
    this.lineCommentStart = "#";
    this.$id = "ace/mode/elixir";
}).call(Mode.prototype);

exports.Mode = Mode;
});


var token_heredoc = 'string';
var token_symbol = 'constant.other.symbol.ruby';
var token_punctuation = 'text';
var token_attribute = 'variable';
var token_interpol = token_punctuation;

function format(str) {
    var args = Array.prototype.slice.call(arguments, 1);
    return str.replace(/{(\d+)}/g, function(match, number) {
        return typeof args[number] !== 'undefined' ? args[number] : match;
    });
}

function escape_regex(string) {
  return string.replace(/([.*+?^${}()|\[\]\/\\])/g, "\\$1");
}

function map(array, f) {
    var new_array = [];
    for (var i = 0; i < array.length; i++) {
        new_array.push(f(array[i]));
    }
    return new_array;
}

function merge(ob1, ob2) {
    for (var key in ob2) {
        if (ob2.hasOwnProperty(key)) {
            ob1[key] = ob2[key];
        }
    }
    return ob1;
}

function include(state) {
    return {include: state};
}

function push_multi(array) {
    return function(currentState, stack) {
        for (var i = 0; i < array.length; i++) {
            stack.unshift(array[i]);
        }
        return array[array.length-1];
    };
}

function gen_elixir_string_rules(name, symbol, token) {
    var states = {};
    states['string_' + name] = [
        {
            token: token,
            regex: format('[^#{0}\\\\]+', symbol),
        },
        include('escapes'),
        {
            token: token,
            regex: '\\\\.',
        },
        {
            token: [token],
            regex: format('({0})', symbol),
            next: "pop",
        },
        include('interpol')
    ]
    return states;
}

function gen_elixir_sigstr_rules(term, token, interpol) {
    if (interpol === undefined) interpol = true;
    if (interpol) {
        return [
            {
                token: token,
                regex: format('[^#{0}\\\\]+', term),
            },
            include('escapes'),
            {
                token: token,
                regex: '\\\\.',
            },
            {
                token: token,
                regex: format('{0}[a-zA-Z]*', term),
                next: 'pop',
            },
            include('interpol')
        ];
    } else {
        return [
            {
                token: token,
                regex: format('[^{0}\\\\]+', term),
            },
            {
                token: token,
                regex: '\\\\.',
            },
            {
                token: token,
                regex: format('{0}[a-zA-Z]*', term),
                next: 'pop',
            },
        ];
    }
}

function gen_elixir_sigil_rules() {
    // all valid sigil terminators (excluding heredocs)
    var terminators = [
        ['\\{', '\\}', 'cb'],
        ['\\[', '\\]', 'sb'],
        ['\\(', '\\)', 'pa'],
        ['\\<', '\\>', 'ab'],
        ['/', '/', 'slas'],
        ['\\|', '\\|', 'pipe'],
        ['"', '"', 'quot'],
        ["'", "'", 'apos'],
    ];

    // heredocs have slightly different rules
    var triquotes = [['"""', 'triquot'], ["'''", 'triapos']];

    var token = 'string';
    var sigil_rules = [];
    var states = {};

    for (var i = 0; i < triquotes.length; i++) {
        var term = triquotes[i][0];
        var name = triquotes[i][1];

        sigil_rules = sigil_rules.concat([
            {
                token: [token, token_heredoc],
                regex: format('(~[a-z])({0})', term),
                next: push_multi([name + '-end', name + '-intp']),
            },
            {
                token: [token, token_heredoc],
                regex: format('(~[A-Z])({0})', term),
                next: push_multi([name + '-end', name + '-no-intp']),
            },
        ]);

        states[name +'-end'] = [{
            token: token,
            regex: '[a-zA-Z]*',
            next: 'pop'
        }];
        states[name +'-intp'] = [
            {
                token: token_heredoc,
                regex: '^\\s*' + term,
                next: 'pop',
            },
            include('heredoc_interpol'),
        ];
        states[name +'-no-intp'] = [
            {
                token: token_heredoc,
                regex: '^\\s*' + term,
                next: 'pop',
            },
            include('heredoc_no_interpol'),
        ];
    }

    for (var i = 0; i < terminators.length; i++) {
        var lterm = terminators[i][0];
        var rterm = terminators[i][1];
        var name = terminators[i][2];

        sigil_rules = sigil_rules.concat([
            {
                token: token,
                regex: '~[a-z]' + lterm,
                push: name + '-intp',
            },
            {
                token: token,
                regex: '~[A-Z]' + lterm,
                push: name + '-no-intp',
            },
        ]);
        states[name +'-intp'] = gen_elixir_sigstr_rules(rterm, token);
        states[name +'-no-intp'] = gen_elixir_sigstr_rules(rterm, token, false);
    }

    states['sigils'] = sigil_rules;
    return states;
}


ace.define('ace/mode/elixir_highlight_rules', ['require', 'exports', 'module', 'ace/lib/oop', 'ace/mode/text_highlight_rules'], function(require, exports, module) {

var ElixirHighlightRules = function() {

    var KEYWORD = ['fn', 'do', 'end', 'after', 'else', 'rescue', 'catch'];
    var KEYWORD_OPERATOR = ['not', 'and', 'or', 'when', 'in'];
    var BUILTIN = [
        'case', 'cond', 'for', 'if', 'unless', 'try', 'receive', 'raise',
        'quote', 'unquote', 'unquote_splicing', 'throw', 'super'
    ];
    var BUILTIN_DECLARATION = [
        'def', 'defp', 'defmodule', 'defprotocol', 'defmacro', 'defmacrop',
        'defdelegate', 'defexception', 'defstruct', 'defimpl', 'defcallback'
    ];

    var BUILTIN_NAMESPACE = ['import', 'require', 'use', 'alias'];
    var CONSTANT = ['nil', 'true', 'false'];

    var PSEUDO_VAR = ['_', '__MODULE__', '__DIR__', '__ENV__', '__CALLER__'];

    var OPERATORS3 = ['<<<', '>>>', '|||', '&&&', '^^^', '~~~', '===', '!=='];
    var OPERATORS2 = [
        '==', '!=', '<=', '>=', '&&', '||', '<>', '++', '--', '|>', '=~',
        '->', '<-', '|', '.', '='
    ];
    var OPERATORS1 = ['<', '>', '+', '-', '*', '/', '!', '^', '&'];

    var PUNCTUATION = [
        '\\\\', '<<', '>>', '=>', '(', ')', ':', ';', ',', '[', ']'
    ];

    var keywordMapper = this.$keywords = this.createKeywordMapper({
        "keyword": KEYWORD.concat(KEYWORD_OPERATOR).concat(BUILTIN).join("|"),
        "constant.language": CONSTANT.join("|"),
        "variable.language": PSEUDO_VAR.join("|"),
        "support.function": BUILTIN_NAMESPACE.concat(BUILTIN_DECLARATION).join("|"),
    }, "identifier");

    var op3_re = map(OPERATORS3, escape_regex).join("|");
    var op2_re = map(OPERATORS2, escape_regex).join("|");
    var op1_re = map(OPERATORS1, escape_regex).join("|");
    var ops_re = format('(?:{0}|{1}|{2})', op3_re, op2_re, op1_re);
    var punctuation_re = map(PUNCTUATION, escape_regex).join("|");
    var alnum = '[A-Za-z_0-9]';
    var name_re = format('[a-z_]{0}*[!\\?]?', alnum);
    var modname_re = format('[A-Z]{0}*(?:\\.[A-Z]{0}*)*', alnum);
    var complex_name_re = format('(?:{0}|{1}|{2})', name_re, modname_re, ops_re);
    var special_atom_re = '(?:\\.\\.\\.|<<>>|%{}|%|{})';

    var long_hex_char_re = '(\\\\x{)([\\da-fA-F]+)(})';
    var hex_char_re = '(\\\\x[\\da-fA-F]{1,2})';
    var escape_char_re = '(\\\\[abdefnrstv])';

    this.$rules = {
        'start': [
            {
                token: 'text',
                regex: '\\s+',
            },
            {
                token: 'comment',  // single-line comment
                regex: '#.*$',
            },

            // Various kinds of characters
            {
                token: ['constant.character', 'constant.character.escape', 'constant.integer', 'constant.character.escape'],
                regex: '(\\?)' + long_hex_char_re,
            },
            {
                token: ['constant.character', 'constant.character.escape'],
                regex: '(\\?)' + hex_char_re,
            },
            {
                token: ['constant.character', 'constant.character.escape'],
                regex: '(\\?)' + escape_char_re,
            },
            {
                token: 'constant.character',
                regex: '\\?\\\\?.',
            },

            // '::' has to go before atoms
            {
                token: token_symbol,
                regex: ':::',
            },
            {
                token: 'keyword.operator',
                regex: '::',
            },

            // atoms
            {
                token: token_symbol,
                regex: ':' + special_atom_re,
            },
            {
                token: token_symbol,
                regex: ':' + complex_name_re,
            },
            {
                token: token_symbol,
                regex: ':"',
                push: 'string_double_atom',
            },
            {
                token: token_symbol,
                regex: ":'",
                push: 'string_single_atom',
            },

            // [keywords: ...]
            {
                token: [token_symbol, token_punctuation],
                regex: format('({0}|{1})(:)(?=\\s|\\n)', special_atom_re, complex_name_re),
            },

            // @attributes
            {
                token: token_attribute,
                regex: '@' + name_re,
            },

            // operators and punctuation
            {
                token: 'keyword.operator',
                regex: op3_re,
            },
            {
                token: 'keyword.operator',
                regex: op2_re,
            },
            {
                token: token_punctuation,
                regex: punctuation_re,
            },
            {
                token: 'constant.character.entity',
                regex: '&\\d',  // anon func arguments
            },
            {
                token: 'keyword.operator',
                regex: op1_re,
            },

            // identifiers
            {
                token: keywordMapper,
                regex: name_re,
            },
            {
                token: [token_punctuation, 'support.class'],
                regex: format('(%?)({0})', modname_re),
            },

            // numbers
            {
                token: 'constant.integer',  // binary
                regex: '0b[01]+',
            },
            {
                token: 'constant.integer',  // octal
                regex: '0o[0-7]+',
            },
            {
                token: 'constant.integer',  // hexadecimal
                regex: '0x[\\da-fA-F]+',
            },
            {
                token: 'constant.numeric',  // float
                regex: '\\d(_?\\d)*\\.\\d(_?\\d)*([eE][-+]?\\d(_?\\d)*)?',
            },
            {
                token: 'constant.integer',  // integer
                regex: '\\d(_?\\d)*',
            },

            // strings and heredocs
            {
                token: token_heredoc,
                regex: '"""\\s*',
                push: 'heredoc_double',
            },
            {
                token: token_heredoc,
                regex: "'''\\s*$",
                push: 'heredoc_single',
            },
            {
                token: 'string',
                regex: '"',
                push: 'string_double',
            },
            {
                token: 'string',
                regex: "'",
                push: 'string_single',
            },

            include('sigils'),

            {
                token: token_punctuation,
                regex: '%{',
                push: 'map_key',
            },
            {
                token: token_punctuation,
                regex: '{',
                push: 'tuple',
            },
        ],
        'heredoc_double': [
            {
                token: token_heredoc,
                regex: '^\\s*"""',
                next: 'pop',
            },
            include('heredoc_interpol'),
        ],
        'heredoc_single': [
            {
                token: token_heredoc,
                regex: "^\\s*'''",
                next: 'pop',
            },
            include('heredoc_interpol'),
        ],
        'heredoc_interpol': [
            {
                token: token_heredoc,
                regex: '[^#\\\\\n]+',
            },
            include('escapes'),
            {
                token: token_heredoc,
                regex: '\\\\.',
            },
            {
                token: token_heredoc,
                regex: '\n+',
            },
            include('interpol'),
        ],
        'heredoc_no_interpol': [
            {
                token: token_heredoc,
                regex: '[^\\\\\n]+',
            },
            {
                token: token_heredoc,
                regex: '\\\\.',
            },
            {
                token: token_heredoc,
                regex: '\n+',
            },
        ],
        'escapes': [
            {
                token: ['constant.character.escape', 'constant.integer', 'constant.character.escape'],
                regex: long_hex_char_re,
            },
            {
                token: 'constant.character.escape',
                regex: hex_char_re,
            },
            {
                token: 'constant.character.escape',
                regex: escape_char_re,
            },
        ],
        'interpol': [
            {
                token: token_interpol,
                regex: '#{',
                push: 'interpol_string',
            },
        ],
        'interpol_string' : [
            {
                token: token_interpol,
                regex: '}',
                next: "pop",
            },
            include('start')
        ],
        'map_key': [
            include('start'),
            {
                token: token_punctuation,
                regex: ':',
                push: 'map_val',
            },
            {
                token: token_punctuation,
                regex: '=>',
                push: 'map_val',
            },
            {
                token: token_punctuation,
                regex: '}',
                next: 'pop',
            },
        ],
        'map_val': [
            include('start'),
            {
                token: token_punctuation,
                regex: ',',
                next: 'pop',
            },
            {
                token: token_punctuation,
                regex: '(?=})',
                next: 'pop',
            },
        ],
        'tuple': [
            include('start'),
            {
                token: token_punctuation,
                regex: '}',
                next: 'pop',
            },
        ],
    };
    this.$rules = merge(this.$rules, gen_elixir_string_rules('double', '"', 'string'));
    this.$rules = merge(this.$rules, gen_elixir_string_rules('single', "'", 'string'));
    this.$rules = merge(this.$rules, gen_elixir_string_rules('double_atom', '"', token_symbol));
    this.$rules = merge(this.$rules, gen_elixir_string_rules('single_atom', "'", token_symbol));
    this.$rules = merge(this.$rules, gen_elixir_sigil_rules());

    this.normalizeRules();
};

var oop = require("../lib/oop");
var TextHighlightRules = require("./text_highlight_rules").TextHighlightRules;
oop.inherits(ElixirHighlightRules, TextHighlightRules);

exports.ElixirHighlightRules = ElixirHighlightRules;
});
