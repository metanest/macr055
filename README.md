macr055
=======

## What is this?

Macr055 (m55) is a macro processor. Basic consepts is like m4, but concrete syntax is not.

## Samples

  {m55_define|HELLO|hello, world}
  {HELLO}
↓
  
  hello, world

  {m55_define|foo|bar}{m55_dnl}
  {m55_define|barbaz|quuz}{m55_dnl}
  {{foo}baz}
↓
  quuz

  {m55_define|foo|`{bar}'}{m55_dnl}
  {m55_define|bar|`{baz}'}{m55_dnl}
  {m55_define|baz|quuz}{m55_dnl}
  {foo}
↓
  quuz

  {m55_define|foo|bar}{m55_dnl}
  {m55_define|bar|baz}{m55_dnl}
  {m55_define|baz|quuz}{m55_dnl}
  {{{foo}}}
↓
  quuz
