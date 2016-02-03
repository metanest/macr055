Macr055
=======

## What is this?

Macr055 (m55) is a macro processor. Basic consepts are like m4, but concrete syntax is not.

## Samples

sample 1 input

    {m55_define|HELLO|hello, world}
    {HELLO}

sample 1 output

    (blank line)
    hello, world

sample 2 input

    {m55_define|foo|bar}{m55_dnl}
    {m55_define|barbaz|quux}{m55_dnl}
    {{foo}baz}

sample 2 output

    quux

sample 3 input

    {m55_define|foo|`{bar}'}{m55_dnl}
    {m55_define|bar|`{baz}'}{m55_dnl}
    {m55_define|baz|quux}{m55_dnl}
    {foo}

sample 3 output

    quux

sample 4 input

    {m55_define|foo|bar}{m55_dnl}
    {m55_define|bar|baz}{m55_dnl}
    {m55_define|baz|quux}{m55_dnl}
    {{{foo}}}

sample 4 output

    quux

sample 5 input

    {m55_define|rev3|$3 $2 $1}{m55_dnl}
    {rev3|foo|bar|baz}

sample 5 output

    baz bar foo

## ifelse macro trick (based on paper of C. Strachey's GPM)

sample input

    {m55_define|ifelse|`{$1|
      {m55_define|$1|$4}
      {m55_define|$2|$3}}'}{m55_dnl}
    {ifelse|foo|foo|equql|not-equal}
    {ifelse|foo|bar|equql|not-equal}

sample output

    equal
    not-equal

## number of arguments sample

sample input

    {m55_define|a|$#}{m55_dnl}
    {a}{a|}{a||}{a|||}
    {m55_changepre|@}{m55_dnl}
    {m55_define|b|@?}{m55_dnl}
    {b}{b|}{b||}{b|||}

sample output

    1234
    1234

( chr(ord(prefix_char) - 1) )

## Changes

2016/Jan/31 remove m55_ifelse primitive
2016/Feb/3 spec of number of arguments is changed

## Any lexical elements customizable!

For example,

    {m55_changequote|[|]} # {comment}
    {m55_changecom|[/*]|[*/]} /* {comment} */
    {m55_changebracket|[<]|[>]}
    <m55_changesep|[,]>
    <m55_changepre,[@]>
    
    <m55_define,[cat],[[@1@2@3@4@5@6@7@8@9]]>
    <cat,foo,bar,baz>
