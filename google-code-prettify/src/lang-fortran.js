// Copyright (C) 2010 Nicky Sandhu.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.


/**
 * @fileoverview
 * Registers a language handler for Fortran code
 * <p>
 * This file could be used by google code to allow syntax highlighting. 
 * Use <pre class="prettyprint lang-fortran"> inject fortran code here <pre>
 * <p>
 * Known Limitations
 * <ol>
 * <li> Cannot handle case of comments on first line of file. The reason is that it matches
 * for an end of line followed by a character to indicate comment (fortran reserves the first 6 columns
 * for special meaning) </li>
 * </ol>
 * @author karajdaar@gmail.com
 */

PR.registerLangHandler(
    PR.createSimpleLexer(
        [
         // A single quoted string
         [PR.PR_STRING, /^'([^\'\\]|\\[\s\S])*(?:\'|$)/, null, '\''],
        ],
        [
         // A line comment that starts with after a new line with *,c or ! or ! anywhere on the line and ends on end of line
         [PR.PR_COMMENT, /^(([\n]+([*|c|!]))|[!]).*(?=[\n]*)/i],
         // A number is a hex integer literal, a decimal real literal, or in scientific notation.                                                                                                                       
         [PR.PR_LITERAL, /^[+\-]?(?:0x[\da-f]+|(?:(?:\.\d+|\d+(?:\.\d*)?)(?:[e|d][+\-]?\d+)?))/i],
         // a boolean literal
         [PR.PR_LITERAL, /^([\.](TRUE|FALSE)[\.])/i],         
         // type keywords
         [PR.PR_TYPE, /^(?:\s)+(CHARACTER|COMPLEX|DATA|DIMENSION|DOUBLE|DOUBLEPRECISION|EQUIVALENCE|EXTERNAL|INTEGER|INTRINSIC|PARAMETER|POINTER|PRECISION|LOGICAL|PURE|REAL)(\*(\d+))?(?:(\s|\(|$))/i,null],
         // reserved keywords
         [PR.PR_KEYWORD, /^(?:\s)(ALLOCATABLE|ALLOCATE|ASSIGNMENT|BACKSPACE|BLOCK|BLOCKDATA|CALL|CASE|CLOSE|COMMON|COMPLEX|CONTAINS|CONTINUE|CYCLE|DATA|DEALLOCATE|DEFAULT|DIMENSION|DO|ELEMENTAL|ELSE|ELSEIF|ELSEWHERE|END(BLOCK(DATA)?|FILE|FORALL|FUNCTION|IF|INTERFACE|MODULE|PROGRAM|SELECT|SUBROUTINE|TYPE|WHERE)?|ENTRY|EQUIVALENCE|ERR|EXIT|EXTERNAL|FOR(ALL|MAT)|GO(TO)?|IF|IMPLICIT|INCLUDE|INQUIRE|INTENT|INTERFACE|INTRINSIC|MODULE|NAMELIST|NONE|NULL(IFY)?|ONLY|OPEN|OPERATOR|OPTIONAL|PRECISION|PRINT|PRIVATE|PROCEDURE|PROGRAM|PUBLIC|READ|RECURSIVE|RESULT|RETURN|REWIND|SAVE|SELECT|SELECTCASE|SEQUENCE|STOP|SUBROUTINE|TARGET|THEN|TO|TYPE|USE|WHERE|WHILE|WRITE)(?=[^\w-]|$)/i,null],
         // continuation marker
         [PR.PR_PUNCTUATION, /^([\n]+[ ]{5}[\&])/],
        ]),
    ['fortran']);
 