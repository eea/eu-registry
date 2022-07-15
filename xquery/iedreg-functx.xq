(:~

 : --------------------------------
 : The FunctX XQuery Function Library
 : --------------------------------

 : Copyright (C) 2007 Datypic

 : This library is free software; you can redistribute it and/or
 : modify it under the terms of the GNU Lesser General Public
 : License as published by the Free Software Foundation; either
 : version 2.1 of the License.

 : This library is distributed in the hope that it will be useful,
 : but WITHOUT ANY WARRANTY; without even the implied warranty of
 : MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 : Lesser General Public License for more details.

 : You should have received a copy of the GNU Lesser General Public
 : License along with this library; if not, write to the Free Software
 : Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

 : For more information on the FunctX XQuery library, contact contrib@functx.com.

 : @version 1.0
 : @see     http://www.xqueryfunctions.com
 :)
module namespace functx = "http://www.functx.com";

declare function functx:capitalize-first
($arg as xs:string?) as xs:string? {

    concat(upper-case(substring($arg, 1, 1)),
            substring($arg, 2))
};

declare function functx:get-matches-and-non-matches
($string as xs:string?,
        $regex as xs:string) as element()* {

    let $iomf := functx:index-of-match-first($string, $regex)
    return
        if (empty($iomf))
        then <non-match>{$string}</non-match>
        else
            if ($iomf > 1)
            then (<non-match>{substring($string, 1, $iomf - 1)}</non-match>,
            functx:get-matches-and-non-matches(
                    substring($string, $iomf), $regex))
            else
                let $length :=
                    string-length($string) -
                            string-length(functx:replace-first($string, $regex, ''))
                return (<match>{substring($string, 1, $length)}</match>,
                if (string-length($string) > $length)
                then functx:get-matches-and-non-matches(
                        substring($string, $length + 1), $regex)
                else ())
};

declare function functx:index-of-match-first
($arg as xs:string?,
        $pattern as xs:string) as xs:integer? {

    if (matches($arg, $pattern))
    then string-length(tokenize($arg, $pattern)[1]) + 1
    else ()
};

declare function functx:index-of-node($seq as node()*, $search as node()) as xs:integer* {
    fn:filter(
            1 to fn:count($seq),
            function($i as xs:integer) as xs:boolean {$seq[$i] is $search}
    )
};

declare function functx:non-distinct-values
($seq as xs:anyAtomicType*) as xs:anyAtomicType* {

    for $val in distinct-values($seq)
    return $val[count($seq[. = $val]) > 1]
};

declare function functx:replace-first
($arg as xs:string?,
        $pattern as xs:string,
        $replacement as xs:string) as xs:string {

    replace($arg, concat('(^.*?)', $pattern),
            concat('$1', $replacement))
};

declare function functx:escape-for-regex
  ( $arg as xs:string? )  as xs:string {

   replace($arg,
           '(\.|\[|\]|\\|\||\-|\^|\$|\?|\*|\+|\{|\}|\(|\))','\\$1')
 } ;

declare function functx:substring-before-last-match
($arg as xs:string?,
        $regex as xs:string) as xs:string? {

    replace($arg, concat('^(.*)', $regex, '.*'), '$1')
};

declare function functx:substring-after-last
  ( $arg as xs:string? ,
    $delim as xs:string )  as xs:string {

   replace ($arg,concat('^.*',functx:escape-for-regex($delim)),'')
 } ;

declare function functx:value-except
( $arg1 as xs:anyAtomicType* ,
        $arg2 as xs:anyAtomicType* ) as xs:anyAtomicType* {

    distinct-values($arg1[not(.=$arg2)])
};

declare function functx:if-empty(
    $arg as item()? ,
    $value as item()*
) as item()* {
    if (string($arg) != '')
    then data($arg)
    else $value
};

declare function functx:value-intersect
  ( $arg1 as xs:anyAtomicType* ,
    $arg2 as xs:anyAtomicType* )  as xs:anyAtomicType* {

  distinct-values($arg1[.=$arg2])
 } ;

declare function functx:is-node-in-sequence-deep-equal
  ( $node as node()? ,
    $seq as node()* )  as xs:boolean {

   some $nodeInSeq in $seq satisfies deep-equal($nodeInSeq,$node)
 } ;

declare function functx:distinct-deep
  ( $nodes as node()* )  as node()* {

    for $seq in (1 to count($nodes))
    return $nodes[$seq][not(functx:is-node-in-sequence-deep-equal(
                          .,$nodes[position() < $seq]))]
 } ;

declare function functx:trim
  ( $arg as xs:string? )  as xs:string {

   replace(replace($arg,'\s+$',''),'^\s+','')
 } ;