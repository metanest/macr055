macr055
=======

## What is this?

Macr055 (m55) is a macro processor. Basic consepts is like m4, but concrete syntax is not.

## Samples

    - input(1) -
    {m55_define|HELLO|hello, world}
    {HELLO}

    - output(1) -
    
    hello, world

    - input(2) -
    {m55_define|foo|bar}{m55_dnl}
    {m55_define|barbaz|quuz}{m55_dnl}
    {{foo}baz}

    - output(2) -
    quuz

    - input(3) -
    {m55_define|foo|`{bar}'}{m55_dnl}
    {m55_define|bar|`{baz}'}{m55_dnl}
    {m55_define|baz|quuz}{m55_dnl}
    {foo}

    - output(3) -
    quuz

    - input(4) -
    {m55_define|foo|bar}{m55_dnl}
    {m55_define|bar|baz}{m55_dnl}
    {m55_define|baz|quuz}{m55_dnl}
    {{{foo}}}

    - output(4) -
    quuz
