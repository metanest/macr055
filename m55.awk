#
BEGIN {
	m55_do_expr_cmd = "/usr/bin/bc > " m55_do_expr_fifo
	m55_util_ord_init()
	m55_main()
	exit
}

# main

function m55_main(		tokens1, tokens2, tokens3, token, tmp, in_quote) {
	# globals/input
	m55_input_buf = ""

	# globals/stack
	m55_stack_sp = 0
	split("", m55_stack)

	# globals/macroenv
	m55_macroenv_args_idx = -1
	split("", m55_macroenv_defs)
	split("", m55_macroenv_locals)
	split("", m55_macroenv_defs_bkup)

	# tags
	M55_USRTYPE = " "

	M55_DEFTYPE = "df"
	M55_VALTYPE = "vl"
	M55_DNLTYPE = "dn"
	M55_ESYTYPE = "es"
	M55_EXPTYPE = "ex"
	M55_WRTTYPE = "wr"

	M55_ALSTYPE = "al"

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
	m55_macroenv_def("m55_define", M55_DEFTYPE)
	m55_macroenv_def("m55_val", M55_VALTYPE)
	m55_macroenv_def("m55_dnl", M55_DNLTYPE)
	m55_macroenv_def("m55_esyscmd", M55_ESYTYPE)
	m55_macroenv_def("m55_expr", M55_EXPTYPE)
	m55_macroenv_def("m55_write", M55_WRTTYPE)

	m55_macroenv_def("m55_alias", M55_ALSTYPE)

	m55_macroenv_def("m55_changequote", M55_CHQTYPE)
	m55_macroenv_def("m55_changecom", M55_CHCTYPE)
	m55_macroenv_def("m55_changebracket", M55_CHBTYPE)
	m55_macroenv_def("m55_changesep", M55_CHSTYPE)
	m55_macroenv_def("m55_changepre", M55_CHPTYPE)

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
				m55_macroenv_enter()
			} else if (token == M55_QUOTE_BRA) {
				in_quote = 1
				delete tmp
				tmp[M55_QUOTE_BRA] = 0
				tmp[M55_QUOTE_KET] = 0
				for (;;) {
					if ((token = m55_input_get(tmp)) != "") {
						if (token == M55_QUOTE_BRA) {
							++in_quote
						} else if (token == M55_QUOTE_KET) {
							if (--in_quote == 0) {
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
		} else if (m55_macroenv_inmacro() && ((token = m55_input_get(tokens2)) != "")) {
			if (token == M55_MACRO_SEP) {
				m55_macroenv_newarg()
			} else if (token == M55_MACRO_KET) {
				m55_leave_expand()
			} else {
				m55_error("assert false")
			}
		} else if (( ! m55_macroenv_inmacro()) && ((token = m55_input_get(tokens3)) != "")) {
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

	if (m55_macroenv_inmacro()) {
		m55_error("EOF in macro")
	}

	exit 0
}

function m55_leave_expand(		args, locals, macroname, body, buf, c, n, d) {
	m55_macroenv_leave(args, locals)

	macroname = args[0]

	if (macroname in locals) {
		body = locals[macroname]
	} else if (macroname in m55_macroenv_defs) {
		body = m55_macroenv_defs[macroname]
	} else {
		m55_error("unknown macro name \"" macroname "\"")
	}

	# search pre-defined (built-in) macros
	if (body == M55_DEFTYPE) {
		m55_do_define(args)
	} else if (body == M55_DNLTYPE) {
		m55_do_dnl(args)
	} else if (body == M55_ESYTYPE) {
		m55_do_esyscmd(args)
	} else if (body == M55_EXPTYPE) {
		m55_do_expr(args)
	} else if (body == M55_WRTTYPE) {
		m55_do_write(args)
	} else if (body == M55_VALTYPE) {
		macroname = args[1]
		if (macroname in locals) {
			body = locals[macroname]
		} else if (macroname in m55_macroenv_defs) {
			body = m55_macroenv_defs[macroname]
		} else {
			m55_error("m55_val: unknown macro name \"" macroname "\"")
		}
		m55_output(substr(body, 2, length(body)-1))
	} else if (body == M55_ALSTYPE) {
		m55_do_alias(args)
	} else if (body == M55_CHQTYPE) {
		m55_do_changequote(args)
	} else if (body == M55_CHCTYPE) {
		m55_do_changecom(args)
	} else if (body == M55_CHBTYPE) {
		m55_do_changebracket(args)
	} else if (body == M55_CHSTYPE) {
		m55_do_changesep(args)
	} else if (body == M55_CHPTYPE) {
		m55_do_changepre(args)
	}
	# others (user macros)
	else {
		if (substr(body, 1, 1) != M55_USRTYPE) {
			m55_error("BUG: unknown pre-defined macro tag '" substr(body, 1, 1) "'")
		}
		body = substr(body, 2, length(body)-1)
		buf = ""
		while (body != "") {
			c = substr(body, 1, 1)
			body = substr(body, 2, length(body)-1)
			if (c == M55_PARAM_PREFIX) {
				n = substr(body, 1, 1)
				body = substr(body, 2, length(body)-1)
				if (m55_util_ord(n) == m55_util_ord(M55_PARAM_PREFIX)-1) {
					d = 0
					while (d in args) {
						++d
					}
					buf = buf d
				} else if (m55_util_ord(n) == m55_util_ord(M55_PARAM_PREFIX)+1) {
					d = args[0]
					delete args[0]
					buf = buf m55_util_join(args, M55_MACRO_SEP, 1)
					args[0] = d
				} else if (n == M55_PARAM_PREFIX) {
					buf = buf M55_PARAM_PREFIX
				} else {
					buf = buf args[m55_util_ord(n)-48]
				}
			} else {
				buf = buf c
			}
		}
		m55_input_pushback(buf)
	}
}

# routines for pre-defined macros

function m55_do_define(args) {
	m55_macroenv_def(args[1], M55_USRTYPE args[2])
}

function m55_do_dnl(args,		c) {
	do {
		c = m55_input_getchar()
	} while ((c != "") && (c != "\n"))
}

function m55_do_esyscmd(args,		cmd, result) {
	cmd = args[1]
	cmd | getline
	result = $0
	close(cmd)
	m55_input_pushback(result)
}

function m55_do_expr(args,		expr) {
	expr = args[1]
	print expr | m55_do_expr_cmd
	getline < m55_do_expr_fifo
	# must not close
	m55_input_pushback($0)
}

function m55_do_write(args) {
	printf("%s", args[1])
}

function m55_do_alias(args) {
	if ( ! (args[2] in m55_macroenv_defs)) {
		m55_error("no such command " args[2] " in alias")
	}
	m55_macroenv_def(args[1], m55_macroenv_defs[args[2]])
}

function m55_do_changequote(args) {
	M55_QUOTE_BRA = args[1]
	M55_QUOTE_KET = args[2]
}

function m55_do_changecom(args) {
	M55_COMMENT_BRA = args[1]
	M55_COMMENT_KET = args[2]
}

function m55_do_changebracket(args) {
	M55_MACRO_BRA = args[1]
	M55_MACRO_KET = args[2]
}

function m55_do_changesep(args) {
	M55_MACRO_SEP = args[1]
}

function m55_do_changepre(args) {
	M55_PARAM_PREFIX = args[1]
}

# output module

function m55_output(s) {
	if (m55_macroenv_inmacro()) {
		m55_macroenv_appendlastarg(s)
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

function m55_stack_dump() {
	print "m55_stack_sp == " m55_stack_sp
	m55_util_dumparray(m55_stack)
}

# macroenv module

# globals:
#   m55_macroenv_args, m55_macroenv_args_idx, m55_macroenv_lastarg
#   m55_macroenv_defs, m55_macroenv_locals, m55_macroenv_defs_bkup

function m55_macroenv_enter(		i, name) {
	# save old args
	for (i = 0; i < m55_macroenv_args_idx; ++i) {
		m55_stack_push(m55_macroenv_args[i])
	}
	m55_stack_push(m55_macroenv_lastarg)
	m55_stack_push(m55_macroenv_args_idx)
	# setup new args
	delete m55_macroenv_args
	m55_macroenv_args_idx = 0
	m55_macroenv_lastarg = ""

	# save old defs_bkup
	i = 0
	for (name in m55_macroenv_defs_bkup) {
		m55_stack_push(length(name) " " name m55_macroenv_defs_bkup[name])
		++i
	}
	m55_stack_push(i)
	delete m55_macroenv_defs_bkup

	# save old locals
	i = 0
	for (name in m55_macroenv_locals) {
		m55_stack_push(name)
		++i
	}
	m55_stack_push(i)
	delete m55_macroenv_locals
}

function m55_macroenv_leave(args, locals,		i, n, tmp, buf) {
	# copy args
	for (i in m55_macroenv_args) {
		args[i] = m55_macroenv_args[i]
	}
	args[m55_macroenv_args_idx] = m55_macroenv_lastarg

	# copy locals
	for (n in m55_macroenv_locals) {
		locals[n] = m55_macroenv_defs[n]
	}

	# restore defs
	for (tmp in m55_macroenv_locals) {
		delete m55_macroenv_defs[tmp]
	}
	for (tmp in m55_macroenv_defs_bkup) {
		m55_macroenv_defs[tmp] = m55_macroenv_defs_bkup[tmp]
	}

	# load old locals
	delete m55_macroenv_locals
	n = m55_stack_pop()
	for (i = n-1; i >= 0; --i) {
		m55_macroenv_locals[m55_stack_pop()] = 1
	}

	# load old defs_bkup
	delete m55_macroenv_defs_bkup
	n = m55_stack_pop()
	for (i = n-1; i >= 0; --i) {
		tmp = m55_stack_pop()
		m55_macroenv_split(tmp, buf)
		m55_macroenv_defs_bkup[buf[0]] = buf[1]
	}

	# load old args
	delete m55_macroenv_args
	m55_macroenv_args_idx = m55_stack_pop()
	m55_macroenv_lastarg = m55_stack_pop()
	for (i = m55_macroenv_args_idx-1; i >= 0; --i) {
		m55_macroenv_args[i] = m55_stack_pop()
	}
}

function m55_macroenv_newarg() {
	m55_macroenv_args[m55_macroenv_args_idx] = m55_macroenv_lastarg
	++m55_macroenv_args_idx
	m55_macroenv_lastarg = ""
}

function m55_macroenv_inmacro() {
	return m55_macroenv_args_idx >= 0
}

function m55_macroenv_appendlastarg(s) {
	m55_macroenv_lastarg = m55_macroenv_lastarg s
}

function m55_macroenv_def(name, body) {
	if (( ! (name in m55_macroenv_locals)) && (name in m55_macroenv_defs)) {
		m55_macroenv_defs_bkup[name] = m55_macroenv_defs[name]
	}
	m55_macroenv_defs[name] = body
	m55_macroenv_locals[name] = 1
}

function m55_macroenv_split(n_name_body, buf,		tmp, n) {
	if ( ! match(n_name_body, /^[1-9][0-9]* /)) {
		m55_error("assert false")
	}
	n = substr(n_name_body, 1, RLENGTH-1) - 0
	tmp = substr(n_name_body, RLENGTH+1, length(n_name_body)-RLENGTH)
	buf[0] = substr(tmp, 1, n)
	buf[1] = substr(tmp, n+1, length(tmp)-n)
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

function m55_util_join(arr, sep, origin,
		tmp, next_of_last, i) {
	next_of_last = origin
	while (next_of_last in arr) {
		++next_of_last
	}
	tmp = ""
	for (i = origin; i < (next_of_last-1); ++i) {
		tmp = tmp arr[i] sep
	}
	tmp = tmp arr[i]
	return tmp
}

function m55_util_dumparray(arr,
		i) {
	for (i = 1; i in arr; ++i) {
		print i ": " arr[i]
	}
}

function m55_util_dumparray2(arr,
		key) {
	for (key in arr) {
		print "[" key "]=" arr[key]
	}
}

function m55_error(s) {
	print s > "/dev/stderr"
	exit 2
}

# ord/chr

function m55_util_ord_init(		i) {
	delete M55_ORD_TBL_
	for (i = 0; i < 256; ++i) {
		M55_ORD_TBL_[sprintf("%c", i)] = i
	}
}

function m55_util_ord(c) {
	return M55_ORD_TBL_[substr(c, 1, 1)]
}

function m55_util_chr(c) {
	return sprintf("%c", c - 0)
}
