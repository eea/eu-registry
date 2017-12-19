xquery version "3.1" encoding "utf-8";

(:~

 : -------------------------------------------
 : EU Registry on Industrial Sites QA/QC rules
 : -------------------------------------------

 : Copyright 2017 European Environment Agency (https://www.eea.europa.eu/)
 :
 : Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this permission notice appear in all copies.
 :
 : THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

 : Author: Spyros Ligouras <spyros@ligouras.com>
 : Date: October - December 2017

 :)

module namespace iedreg = "http://cdrtest.eionet.europa.eu/help/ied_registry";

declare namespace gml = "http://www.opengis.net/gml/3.2";
declare namespace xlink = "http://www.w3.org/1999/xlink";

import module namespace functx = "http://www.functx.com" at "iedreg-functx.xq";
import module namespace scripts = "iedreg-scripts" at "iedreg-scripts.xq";
import module namespace scripts3 = "iedreg-scripts-qa3" at "iedreg-scripts-qa3.xq";

(:~
 : --------------
 : Util functions
 : --------------
 :)

declare function iedreg:getNoDetails(
) as element(div)* {
    <div class="iedreg">
        <div class="iedreg inner msg gray mnone">
            <span class="iedreg nowrap header">Not implemented yet</span>
            <br/>
            <span class="iedreg">This check is still under development</span>
        </div>
    </div>
};

declare function iedreg:getErrorDetails(
        $code as xs:QName,
        $description as xs:string?
) as element(div)* {
    <div class="iedreg">
        <div class="iedreg inner msg red merror">
            <span class="iedreg nowrap header">Error <a href="https://www.w3.org/2005/xqt-errors/">{$code}</a></span>
            <br/>
            <span class="iedreg">{$description}</span>
        </div>
    </div>
};

declare function iedreg:renderResult(
        $refcode as xs:string,
        $rulename as xs:string,
        $type as xs:string,
        $details as element()*
) {
    let $id := random:integer(65536)

    let $label :=
        <label class="iedreg" for="toggle-{$id}">
            <span class="iedreg link">More...</span>
        </label>

    let $toggle :=
        <input class="iedreg toggle" id="toggle-{$id}" type="checkbox" />

    return
        <div class="iedreg row">
            <div class="iedreg col outer noborder">

                <!-- report table -->
                <div class="iedreg table">
                    <div class="iedreg row">
                        <div class="iedreg col ten center middle">
                            <span class="iedreg medium {$type}">{$refcode}</span>
                        </div>

                        <div class="iedreg col left middle">
                            <span class="iedreg">{$rulename}</span>
                        </div>

                        <div class="iedreg col quarter right middle">
                            {if ($type = 'error') then
                                <span class="iedreg nowrap">1 error</span>
                            else
                                <span class="iedreg nowrap">1 message</span>
                            }
                        </div>

                        <div class="iedreg col ten center middle">
                            {$label}
                        </div>
                    </div>
                </div>

                <!-- details table -->
                {$toggle, $details}
            </div>
        </div>
};

declare function iedreg:notYet(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $details := iedreg:getNoDetails()
    return iedreg:renderResult($refcode, $rulename, 'none', $details)
};

declare function iedreg:failsafeWrapper(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element(),
        $checkFunc as function(xs:string, xs:string, element()) as element()*
) as element()* {
    try {
        $checkFunc($refcode, $rulename, $root)
    } catch * {
        let $details := iedreg:getErrorDetails($err:code, $err:description)
        return iedreg:renderResult($refcode, $rulename, 'error', $details)
    }
};

(:~
 : --------------
 : html functions
 : --------------
 :)

declare function iedreg:css() as element()* {
    <style>
        <![CDATA[
pre.iedreg { display: inline }

div.iedreg { box-sizing: border-box; font-family: "Helvetica Neue",Helvetica,Arial,sans-serif; font-size: 14px; color: #333 }
div.iedreg.header { font-size: 16px; font-weight: 500; margin: 0.8em 0 0.4em 0 }

div.iedreg.table { display: table; width: 100%; border-collapse: collapse }
div.iedreg.row { display: table-row; }
div.iedreg.col { display: table-cell; padding: 0.4em; border: 1pt solid #aaa }

div.iedreg.inner { width: 80%; margin-left: 10%; margin-top: 0.4em; margin-bottom: 0.6em }
div.iedreg.outer { padding-bottom: 0; border: 1pt solid #888 }
div.iedreg.inner { border: 1pt solid #aaa }
div.iedreg.parent { margin-bottom: 1.5em }

div.iedreg.th { border-bottom: 2pt solid #000; font-weight: 600 }
div.iedreg.error { background-color: #fdf7f7; border-bottom: 2pt solid #d9534f }
div.iedreg.warning { background-color: #faf8f0; border-bottom: 2pt solid #f0ad4e }
div.iedreg.info { background-color: #f4f8fa; border-bottom: 2pt solid #5bc0de }

div.iedreg.red { background-color: #fdf7f7; color: #b94a48 }
div.iedreg.yellow { background-color: #faf8f0; color: #8a6d3b }
div.iedreg.blue { background-color: #f4f8fa; color: #34789a }
div.iedreg.gray { background-color: #eee; color: #555 }

div.iedreg.msg { margin-top: 1em; margin-bottom: 1em; padding: 1em 2em }
div.iedreg.msg.merror { border-color: #d9534f }
div.iedreg.msg.mwarning { border-color: #f0ad4e }
div.iedreg.msg.minfo { border-color: #5bc0de }
div.iedreg.msg.mnone { border-color: #ccc }

div.iedreg.nopadding { padding: 0 }
div.iedreg.nomargin { margin: 0 }
div.iedreg.noborder { border: 0 }

div.iedreg.left { text-align: left }
div.iedreg.center { text-align: center }
div.iedreg.right { text-align: right }

div.iedreg.top { vertical-align: top }
div.iedreg.middle { vertical-align: middle }
div.iedreg.bottom { vertical-align: bottom }

div.iedreg.ten { width: 10%; }
div.iedreg.quarter { width: 25%; }
div.iedreg.half { width: 50%; }

input[type=checkbox].iedreg { display:none }
input[type=checkbox].iedreg + div.iedreg { display:none }
input[type=checkbox].iedreg:checked + div.iedreg { display: block }

span.iedreg { display:inline-block }

span.iedreg.nowrap { white-space: nowrap }
span.iedreg.link { cursor: pointer; cursor: hand; text-decoration: underline }

span.iedreg.big { padding: 0.1em 0.9em }
span.iedreg.medium { padding: 0.1em 0.5em }
span.iedreg.small { padding: 0.1em }

span.iedreg.header { display: block; font-size: 16px; font-weight: 600 }

span.iedreg.error { color: #fff; background-color: #d9534f }
span.iedreg.warning { color: #fff; background-color: #f0ad4e }
span.iedreg.info { color: #fff; background-color: #5bc0de }
span.iedreg.pass { color: #fff; background-color: #5cb85c }
span.iedreg.none { color: #fff; background-color: #999 }
]]>
    </style>
};

(:~
 : 1. CODE LIST CHECKS
 :)

declare function iedreg:runChecks01($root as element()) as element()* {
    let $rulename := '1. CODE LIST CHECKS'

    return
        <div class="iedreg header">{$rulename}</div>,
    <div class="iedreg table parent">{
        iedreg:failsafeWrapper("C1.7", "otherRelevantChapters consistency", $root, scripts3:checkOtherRelevantChapters#3),
        iedreg:failsafeWrapper("C1.8", "statusType consistency", $root, scripts3:checkStatusType#3),
        iedreg:failsafeWrapper("C1.9", "plantType consistency", $root, scripts3:checkPlantType#3),
        iedreg:failsafeWrapper("C1.10", "derogations consistency", $root, scripts3:checkDerogations#3),
        iedreg:failsafeWrapper("C1.11", "specificConditions consistency", $root, scripts3:checkSpecificConditions#3)
    }</div>
};

(:~
 : 13. OTHER CHECKS
 :)

declare function iedreg:runChecks13($root as element()) as element()* {
    let $rulename := '13. OTHER CHECKS'

    return
        <div class="iedreg header">{$rulename}</div>,
    <div class="iedreg table parent">{
        iedreg:failsafeWrapper("C13.1", "reportData validity", $root, scripts3:checkReportData#3),
        iedreg:failsafeWrapper("C13.2", "hostingSite position validity", $root, scripts3:checkeHostingSite #3),
        iedreg:failsafeWrapper("C13.3", "hostingSite xlink:href validity", $root, scripts3:checkeHostingSiteHref#3),
        iedreg:failsafeWrapper("C13.4", "ProductionInstallation gml:id validity", $root, scripts3:checkGroupedInstallation#3),
        iedreg:failsafeWrapper("C13.5", "groupedInstallation xlink:href validity", $root, scripts3:checkGroupedInstallationHref#3),
        iedreg:failsafeWrapper("C13.6", "act-core:geometry validity", $root, scripts3:checkActCoreGeometry#3),
        iedreg:failsafeWrapper("C13.7", "act-core:activity validity", $root, scripts3:checkActCoreActivity#3),
        iedreg:failsafeWrapper("C13.8", "ProductionInstallationPart gml:id validity", $root, scripts3:checkGroupedInstallationPart#3),
        iedreg:failsafeWrapper("C13.9", "pf:groupedInstallationPart xlink:href validity", $root, scripts3:checkGroupedInstallationPartHref#3),
        iedreg:failsafeWrapper("C13.10", "pf:status validity", $root, scripts3:checkStatusNil#3),
        iedreg:failsafeWrapper("C13.11", "pf:pointGeometry validity", $root, iedreg:notYet#3)
    }</div>
};


declare function iedreg:runChecks($url as xs:string) as element()*
{
    let $doc := doc($url)
    let $root := $doc/child::gml:FeatureCollection

    let $envelopeURL := functx:substring-before-last-match($url, '/') || '/xml'

    let $add-envelope-url := %updating function ($root, $url ) {
insert node <gml:metaDataProperty xlink:href="{$url}"></gml:metaDataProperty> as first into $root
}

let $root := $root update (
updating $add-envelope-url(., $envelopeURL)
)

return (
iedreg:runChecks01($root),
iedreg:runChecks13($root)
)
} ;

declare function iedreg:check($url as xs:string) as element ()*
{
iedreg:css(), iedreg:runChecks($url)
};

(:~
 : vim: ts=2 sts=2 sw=2 et
 :)
