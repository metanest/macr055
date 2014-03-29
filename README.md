macr055
=======

## What is this?

Macr055 (m55) is a macro processor. Basic consepts is like m4, but concrete syntax is not.

## Samples

sample 1 input

    {m55_define|HELLO|hello, world}
    {HELLO}

sample 1 output

    (blank line)
    hello, world

sample 2 input

    {m55_define|foo|bar}{m55_dnl}
    {m55_define|barbaz|quuz}{m55_dnl}
    {{foo}baz}

sample 2 output

    quuz

sample 3 input

    {m55_define|foo|`{bar}'}{m55_dnl}
    {m55_define|bar|`{baz}'}{m55_dnl}
    {m55_define|baz|quuz}{m55_dnl}
    {foo}

sample 3 output

    quuz

sample 4 input

    {m55_define|foo|bar}{m55_dnl}
    {m55_define|bar|baz}{m55_dnl}
    {m55_define|baz|quuz}{m55_dnl}
    {{{foo}}}

sample 4 output

    quuz
