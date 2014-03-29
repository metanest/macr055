#
BEGIN {
	m55_do_expr_cmd = "/usr/bin/bc > " m55_do_expr_fifo
	m55_main()
	exit
}

# main

function m55_main(		tokens1, tokens2, tokens3, token, tmp, depth, macroname, buf) {

	# globals/input
	m55_input_buf = ""

	# globals/stack
	m55_stack_sp = 0
	split("", m55_stack)

	# globals/frame
	m55_frame_fp = -1

	# globals/macro table
	split("", m55_macro_tbl)

	# tags
	M55_USRTYPE = " "

	M55_DEFTYPE = "df"
	M55_DNLTYPE = "dn"
	M55_IFETYPE = "ie"
	M55_ESYTYPE = "es"
	M55_EXPTYPE = "ex"

	M55_CHQTYPE = "cq"
	M55_CHCTYPE = "cc"
	M55_CHBTYPE = "cb"
	M55_CHSTYPE = "cs"
	M55_CHPTYPE = "cp"

	# defaults
	M55_MACRO_BRA = "{"
	M55_MACRO_SEP = "|"
	M55_MACRO_KET = "}"
	M55_QUOTE_BRA = "`"
	M55_QUOTE_KET = "'"
	M55_COMMENT_BRA = "#"
	M55_COMMENT_KET = "\n"

	M55_PARAM_PREFIX = "$"

	# pre-defined macros
	m55_macro_install("m55_define", M55_DEFTYPE)
	m55_macro_install("m55_dnl", M55_DNLTYPE)
	m55_macro_install("m55_ifelse", M55_IFETYPE)
	m55_macro_install("m55_esyscmd", M55_ESYTYPE)
	m55_macro_install("m55_expr", M55_EXPTYPE)

	m55_macro_install("m55_changequote", M55_CHQTYPE)
	m55_macro_install("m55_changecom", M55_CHCTYPE)
	m55_macro_install("m55_changebracket", M55_CHBTYPE)
	m55_macro_install("m55_changesep", M55_CHSTYPE)
	m55_macro_install("m55_changepre", M55_CHPTYPE)

	# main loop
	for (;;) {
		delete tokens1
		tokens1[M55_MACRO_BRA] = 0
		tokens1[M55_QUOTE_BRA] = 0
		delete tokens2
		tokens2[M55_MACRO_SEP] = 0
		tokens2[M55_MACRO_KET] = 0
		delete tokens3
		tokens3[M55_COMMENT_BRA] = 0

		if ((token = m55_input_get(tokens1)) != "") {
			if (token == M55_MACRO_BRA) {
				m55_frame_enter()
			} else if (token == M55_QUOTE_BRA) {
				depth = 1
				delete tmp
				tmp[M55_QUOTE_BRA] = 0
				tmp[M55_QUOTE_KET] = 0
				for (;;) {
					if ((token = m55_input_get(tmp)) != "") {
						if (token == M55_QUOTE_BRA) {
							++depth
						} else if (token == M55_QUOTE_KET) {
							if (--depth == 0) {
								break
							}
						}
					} else {
						if ((token = m55_input_getchar()) == "") {
							m55_error("EOF in quote")
						}
					}
					m55_output(token)
				}
			} else {
				m55_error("assert false")
			}
		} else if (m55_frame_inmacro() && ((token = m55_input_get(tokens2)) != "")) {
			if (m55_frame_inmacroname()) {
				macroname = m55_frame_getmacroarg(0)
				m55_macro_lookup(macroname, buf)
				if (0 in buf) {
					m55_frame_setmacrobody(buf[0])
				} else {
					m55_error("unknown macro name \"" macroname "\"")
				}
			}
			if (token == M55_MACRO_SEP) {
				m55_frame_newarg()
			} else if (token == M55_MACRO_KET) {
				m55_macro_expand()
				m55_frame_leave()
			} else {
				m55_error("assert false")
			}
		} else if (( ! m55_frame_inmacro()) && ((token = m55_input_get(tokens3)) != "")) {
			m55_output(token)
			delete tmp
			tmp[M55_COMMENT_KET] = 0
			for (;;) {
				if ((token = m55_input_get(tmp)) != "") {
					m55_output(token)
					break
				} else {
					if ((token = m55_input_getchar()) != "") {
						m55_output(token)
					} else {
						m55_error("EOF in comment")
					}
				}
			}
		} else if ((token = m55_input_getchar()) != "") {
			m55_output(token)
		} else {
			break
		}
	}

	if (m55_frame_inmacro()) {
		m55_error("EOF in macro")
	}

	exit 0
}

function m55_macro_expand(		body, tmp) {
	body = m55_frame_getmacrobody()

	# search pre-defined (built-in) macros
	if (body == M55_DEFTYPE) {
		m55_do_define()
	} else if (body == M55_DNLTYPE) {
		m55_do_dnl()
	} else if (body == M55_IFETYPE) {
		m55_do_ifelse()
	} else if (body == M55_ESYTYPE) {
		m55_do_esyscmd()
	} else if (body == M55_EXPTYPE) {
		m55_do_expr()
	} else if (body == M55_CHQTYPE) {
		m55_do_changequote()
	} else if (body == M55_CHCTYPE) {
		m55_do_changecom()
	} else if (body == M55_CHBTYPE) {
		m55_do_changebracket()
	} else if (body == M55_CHSTYPE) {
		m55_do_changesep()
	} else if (body == M55_CHPTYPE) {
		m55_do_changepre()
	}
	# others (user macros)
	else {
		if (substr(body, 1, 1) != M55_USRTYPE) {
			m55_error("BUG: unknown pre-defined macro tag")
		}
		body = substr(body, 2, length(body)-1)
		tmp = ""
		while (body != "") {
			c = substr(body, 1, 1)
			body = substr(body, 2, length(body)-1)
			if (c == M55_PARAM_PREFIX) {
				n = substr(body, 1, 1)
				body = substr(body, 2, length(body)-1)
				if (n == "#") {
					tmp = tmp m55_frame_getmacroargc()
				} else if (n == M55_PARAM_PREFIX) {
					tmp = tmp M55_PARAM_PREFIX
				} else {
					tmp = tmp m55_frame_getmacroarg(n)
				}
			} else {
				tmp = tmp c
			}
		}
		m55_input_pushback(tmp)
	}
}

# routines for pre-defined macros

function m55_do_define(		name, body) {
	name = m55_frame_getmacroarg(1)
	body = m55_frame_getmacroarg(2)
	m55_macro_install(name, M55_USRTYPE body)
}

function m55_do_dnl(		c) {
	do {
		c = m55_input_getchar()
	} while ((c != "") && (c != "\n"))
}

function m55_do_ifelse(		args, base) {
	m55_frame_getmacroargs(args)
	base = 1
	for (;;) {
		if (args[base+0] == args[base+1]) {
			m55_input_pushback(args[base+2])
			return
		}
		if ( ! ((base+4) in args)) {
			m55_input_pushback(args[base+3])
			return
		}
		base += 3
	}
}

function m55_do_esyscmd(		cmd, result) {
	cmd = m55_frame_getmacroarg(1)
	cmd | getline
	result = $0
	close(cmd)
	m55_input_pushback(result)
}

function m55_do_expr(		expr) {
	expr = m55_frame_getmacroarg(1)
	print expr | m55_do_expr_cmd
	getline < m55_do_expr_fifo
	# must not close
	m55_input_pushback($0)
}

function m55_do_changequote() {
	M55_QUOTE_BRA = m55_frame_getmacroarg(1)
	M55_QUOTE_KET = m55_frame_getmacroarg(2)
}

function m55_do_changecom() {
	M55_COMMENT_BRA = m55_frame_getmacroarg(1)
	M55_COMMENT_KET = m55_frame_getmacroarg(2)
}

function m55_do_changebracket() {
	M55_MACRO_BRA = m55_frame_getmacroarg(1)
	M55_MACRO_KET = m55_frame_getmacroarg(2)
}

function m55_do_changesep() {
	M55_MACRO_SEP = m55_frame_getmacroarg(1)
}

function m55_do_changepre() {
	M55_PARAM_PREFIX = m55_frame_getmacroarg(1)
}

# output module

function m55_output(s) {
	if (m55_frame_inmacro()) {
		m55_frame_setlastarg(m55_frame_getlastarg() s)
	} else {
		printf("%s", s)
	}
}

# stack module

# globals: m55_stack, m55_stack_sp

function m55_stack_push(item) {
	m55_stack[++m55_stack_sp] = item
}

function m55_stack_pop(		item) {
	item = m55_stack[m55_stack_sp]
	delete m55_stack[m55_stack_sp]
	--m55_stack_sp
	return item
}

function m55_stack_get(idx) {
	return m55_stack[idx]
}

function m55_stack_set(idx, item) {
	m55_stack[idx] = item
}

# frame module

# globals: m55_frame_fp

# フレームの構造は次のようになる
#
# ↓old-sp     fp       fp + 1     ...
#          | old-fp | macro body | macro name | arg1 | arg2 ...

function m55_frame_dump() {
	print "sp == " m55_stack_sp
	print "fp == " m55_frame_fp
	m55_util_dumparray(m55_stack)
}

function m55_frame_enter() {
	m55_stack_push(m55_frame_fp)
	m55_frame_fp = m55_stack_sp
	m55_stack_push(-1) # macro body
	m55_stack_push("") # macro name
}

function m55_frame_leave() {
	while (m55_stack_sp > m55_frame_fp) {
		m55_stack_pop()
	}
	m55_frame_fp = m55_stack_pop()
}

function m55_frame_inmacroname() {
	return m55_frame_inmacro() && (m55_stack_sp == m55_frame_fp+2)
}

#function m55_frame_inmacroarg() {
#	return m55_frame_inmacro() && (m55_stack_sp > m55_frame_fp+2)
#}

function m55_frame_inmacro() {
	return m55_frame_fp > 0
}

function m55_frame_newarg() {
	m55_stack_push("")
}

function m55_frame_getmacrobody() {
	return m55_frame_get(1)
}

function m55_frame_setmacrobody(s) {
	return m55_frame_set(1, s)
}

function m55_frame_getmacroarg(idx) {
	return m55_frame_get(2+idx)
}

function m55_frame_getlastarg() {
	return m55_stack_get(m55_stack_sp)
}

function m55_frame_setlastarg(s) {
	m55_stack_set(m55_stack_sp, s)
}

function m55_frame_getmacroargc() {
	return m55_stack_sp-(m55_frame_fp+2)
}

function m55_frame_getmacroargs(arr,
		n, i) {
	n = m55_frame_getmacroargc()
	for (i = 1; i <= n; ++i) {
		arr[i] = m55_frame_getmacroarg(i)
	}
}

# frame module locals

function m55_frame_get(offset) {
	return m55_stack_get(m55_frame_fp+offset)
}

function m55_frame_set(offset, item) {
	m55_stack_set(m55_frame_fp+offset, item)
}

# macro table module

# globals: m55_macro_tbl

function m55_macro_install(name, body) {
	m55_macro_tbl[name] = body
}

function m55_macro_lookup(name, buf) {
	delete buf
	if (name in m55_macro_tbl) {
		buf[0] = m55_macro_tbl[name]
	}
}

# input module

# globals: m55_input_buf

function m55_input_get(str_lst,
		t) {
	t = m55_input_check(str_lst)
	if (t != "") {
		m55_input_cut(length(t))
	}
	return t
}

# str_list の key のどれかに入力の先頭部分が一致したならその文字列、どれも
# 一致しないなら空文字列を返す。EOFなどでも空文字列を返す。入力は消費しない。
function m55_input_check(str_lst,
		s) {
	for (s in str_lst) {
		if (m55_input_check_s(s) != "") {
			return s
		}
	}
	return ""
}

# m55_input_check の下請け関数
function m55_input_check_s(s,
		tmp, status) {
	if (m55_util_is_starts(m55_input_buf, s)) {
		return s
	}
	do {
		if (m55_util_is_starts(s, m55_input_buf)) {
			# 入力バッファ全体が s の先頭部分の一部に一致している場合
			# (バッファが空の場合は常に一致する)
			# もっと読み込んで、一致するかどうか確かめる必要がある
			if ( ! m55_input_getline()) {
				return ""
			}
		} else {
			break
		}
	} while (length(m55_input_buf) < length(s))

	if (m55_util_is_starts(m55_input_buf, s)) {
		return s
	}
	return ""
}

# とにかく入力から1文字取って返す手続き。EOFの時は空文字列を返す
function m55_input_getchar() {
	if (m55_input_buf == "") {
		if ( ! m55_input_getline()) {
			return ""
		}
		if (m55_input_buf == "") {
			m55_error("result of getline is null str")
		}
	}
	return m55_input_cut(1)
}

# pushback
function m55_input_pushback(s) {
	m55_input_buf = s m55_input_buf
}

# input module locals

function m55_input_getline(		tmp, status) {
	status = getline tmp
	if (status == 1) {
		m55_input_buf = m55_input_buf tmp "\n"
		return 1
	} else if (status == 0) {
		return 0
	} else if (status == -1) {
		m55_error("read error in getline")
	} else {
		m55_error("unknown getline status")
	}
}

function m55_input_cut(len,
		tmp) {
	tmp = substr(m55_input_buf, 1, len)
	m55_input_buf = substr(m55_input_buf, len+1, length(m55_input_buf)-len)
	return tmp
}

# util functions, etc

function m55_util_is_starts(str, s) {
	return substr(str, 1, length(s)) == s
}

function m55_util_dumparray(arr,
		i) {
	for (i = 1; i in arr; ++i) {
		print i ": " arr[i]
	}
}

function m55_error(s) {
	print s > "/dev/stderr"
	exit 2
}
