CodeMirror.defineMode("mysql",function(e){function r(e){return new RegExp("^(?:"+e.join("|")+")$","i")}function u(e,t){var r=e.next();n=null;if(r=="$"||r=="?")return e.match(/^[\w\d]*/),"variable-2";if(r=="<"&&!e.match(/^[\s\u00a0=]/,!1))return e.match(/^[^\s\u00a0>]*>?/),"atom";if(r=='"'||r=="'")return t.tokenize=a(r),t.tokenize(e,t);if(r=="`")return t.tokenize=f(r),t.tokenize(e,t);if(/[{}\(\),\.;\[\]]/.test(r))return n=r,null;if(r!="-"){if(o.test(r))return e.eatWhile(o),null;if(r==":")return e.eatWhile(/[\w\d\._\-]/),"atom";e.eatWhile(/[_\w\d]/);if(e.eat(":"))return e.eatWhile(/[\w\d_\-]/),"atom";var u=e.current(),l;return i.test(u)?null:s.test(u)?"keyword":"variable"}ch2=e.next();if(ch2=="-")return e.skipToEnd(),"comment"}function a(e){return function(t,n){var r=!1,i;while((i=t.next())!=null){if(i==e&&!r){n.tokenize=u;break}r=!r&&i=="\\"}return"string"}}function f(e){return function(t,n){var r=!1,i;while((i=t.next())!=null){if(i==e&&!r){n.tokenize=u;break}r=!r&&i=="\\"}return"variable-2"}}function l(e,t,n){e.context={prev:e.context,indent:e.indent,col:n,type:t}}function c(e){e.indent=e.context.indent,e.context=e.context.prev}var t=e.indentUnit,n,i=r(["str","lang","langmatches","datatype","bound","sameterm","isiri","isuri","isblank","isliteral","union","a"]),s=r(["ACCESSIBLE","ALTER","AS","BEFORE","BINARY","BY","CASE","CHARACTER","COLUMN","CONTINUE","CROSS","CURRENT_TIMESTAMP","DATABASE","DAY_MICROSECOND","DEC","DEFAULT","DESC","DISTINCT","DOUBLE","EACH","ENCLOSED","EXIT","FETCH","FLOAT8","FOREIGN","GRANT","HIGH_PRIORITY","HOUR_SECOND","IN","INNER","INSERT","INT2","INT8","INTO","JOIN","KILL","LEFT","LINEAR","LOCALTIME","LONG","LOOP","MATCH","MEDIUMTEXT","MINUTE_SECOND","NATURAL","NULL","OPTIMIZE","OR","OUTER","PRIMARY","RANGE","READ_WRITE","REGEXP","REPEAT","RESTRICT","RIGHT","SCHEMAS","SENSITIVE","SHOW","SPECIFIC","SQLSTATE","SQL_CALC_FOUND_ROWS","STARTING","TERMINATED","TINYINT","TRAILING","UNDO","UNLOCK","USAGE","UTC_DATE","VALUES","VARCHARACTER","WHERE","WRITE","ZEROFILL","ALL","AND","ASENSITIVE","BIGINT","BOTH","CASCADE","CHAR","COLLATE","CONSTRAINT","CREATE","CURRENT_TIME","CURSOR","DAY_HOUR","DAY_SECOND","DECLARE","DELETE","DETERMINISTIC","DIV","DUAL","ELSEIF","EXISTS","FALSE","FLOAT4","FORCE","FULLTEXT","HAVING","HOUR_MINUTE","IGNORE","INFILE","INSENSITIVE","INT1","INT4","INTERVAL","ITERATE","KEYS","LEAVE","LIMIT","LOAD","LOCK","LONGTEXT","MASTER_SSL_VERIFY_SERVER_CERT","MEDIUMINT","MINUTE_MICROSECOND","MODIFIES","NO_WRITE_TO_BINLOG","ON","OPTIONALLY","OUT","PRECISION","PURGE","READS","REFERENCES","RENAME","REQUIRE","REVOKE","SCHEMA","SELECT","SET","SPATIAL","SQLEXCEPTION","SQL_BIG_RESULT","SSL","TABLE","TINYBLOB","TO","TRUE","UNIQUE","UPDATE","USING","UTC_TIMESTAMP","VARCHAR","WHEN","WITH","YEAR_MONTH","ADD","ANALYZE","ASC","BETWEEN","BLOB","CALL","CHANGE","CHECK","CONDITION","CONVERT","CURRENT_DATE","CURRENT_USER","DATABASES","DAY_MINUTE","DECIMAL","DELAYED","DESCRIBE","DISTINCTROW","DROP","ELSE","ESCAPED","EXPLAIN","FLOAT","FOR","FROM","GROUP","HOUR_MICROSECOND","IF","INDEX","INOUT","INT","INT3","INTEGER","IS","KEY","LEADING","LIKE","LINES","LOCALTIMESTAMP","LONGBLOB","LOW_PRIORITY","MEDIUMBLOB","MIDDLEINT","MOD","NOT","NUMERIC","OPTION","ORDER","OUTFILE","PROCEDURE","READ","REAL","RELEASE","REPLACE","RETURN","RLIKE","SECOND_MICROSECOND","SEPARATOR","SMALLINT","SQL","SQLWARNING","SQL_SMALL_RESULT","STRAIGHT_JOIN","THEN","TINYTEXT","TRIGGER","UNION","UNSIGNED","USE","UTC_TIME","VARBINARY","VARYING","WHILE","XOR","FULL","COLUMNS","MIN","MAX","STDEV","COUNT"]),o=/[*+\-<>=&|]/;return{startState:function(e){return{tokenize:u,context:null,indent:0,col:0}},token:function(e,t){e.sol()&&(t.context&&t.context.align==null&&(t.context.align=!1),t.indent=e.indentation());if(e.eatSpace())return null;var r=t.tokenize(e,t);r!="comment"&&t.context&&t.context.align==null&&t.context.type!="pattern"&&(t.context.align=!0);if(n=="(")l(t,")",e.column());else if(n=="[")l(t,"]",e.column());else if(n=="{")l(t,"}",e.column());else if(/[\]\}\)]/.test(n)){while(t.context&&t.context.type=="pattern")c(t);t.context&&n==t.context.type&&c(t)}else n=="."&&t.context&&t.context.type=="pattern"?c(t):/atom|string|variable/.test(r)&&t.context&&(/[\}\]]/.test(t.context.type)?l(t,"pattern",e.column()):t.context.type=="pattern"&&!t.context.align&&(t.context.align=!0,t.context.col=e.column()));return r},indent:function(e,n){var r=n&&n.charAt(0),i=e.context;if(/[\]\}]/.test(r))while(i&&i.type=="pattern")i=i.prev;var s=i&&r==i.type;return i?i.type=="pattern"?i.col:i.align?i.col+(s?0:1):i.indent+(s?0:t):0}}}),CodeMirror.defineMIME("text/x-mysql","mysql")