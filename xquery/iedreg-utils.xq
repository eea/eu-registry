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

module namespace utils = "iedreg-utils";

declare namespace gml = "http://www.opengis.net/gml/3.2";
declare namespace xlink = "http://www.w3.org/1999/xlink";

import module namespace functx = "http://www.functx.com" at "iedreg-functx.xq";
import module namespace scripts = "iedreg-scripts" at "iedreg-scripts.xq";
import module namespace scripts3 = "iedreg-qa3-scripts" at "iedreg-qa3-scripts.xq";
import module namespace common = "iedreg-common" at "iedreg-common.xq";

declare variable $utils:checksHistoricalData := (
    'C3.1',
    'C4.5', 'C4.6', 'C4.7','C4.8', 'C4.9', 'C4.10', 'C4.11', 'C4.12',
    'C5.6',
    'C6.2', 'C6.4',
    'C7.5',
    'C9.3',
    'C10.5', 'C10.6', 'C10.7',
    'C13.4'
);

declare variable $utils:checks2018 := (
    'C1.1',
    'C9.5', 'C9.6',
    'C10.2'
);
declare variable $utils:skipCountries := map {
    'BE': ('C0'),
    'CH': ('C4.9', 'C4.10', 'C4.11', 'C4.12'),
    'NO': ('C0'),
    'RS': ('C0'),
    'SK': ('C0')
};
declare variable $utils:run2018checks := true();

(: These checks are active when the script is triggered inside an envelope :)
declare variable $utils:envelopeChecks := (
    'C2.5',
    'C4.1', 'C4.2', 'C4.3','C4.4',
    'C4.5', 'C4.6', 'C4.7','C4.8', 'C4.9', 'C4.10', 'C4.11', 'C4.12',
    'C5.1', 'C5.2', 'C5.3', 'C5.4', 'C5.6', 'C5.7', 'C5.8',
    'C6.2', 'C6.4',
    'C7.1', 'C7.5',
    'C8.1',
    'C9.3',
    'C13.4', 'C13.5'
);
(:

:)

(:
-----------------------------
 : Lookup tables functions
-----------------------------
:)

declare function utils:getLookupTableByFilename(
    $fileName as xs:string
) as document-node() {
    let $location := 'https://databridge.eionet.europa.eu/remote.php/dav/files/'
    let $userEnv := 'XQueryUser'
    let $passwordEnv := 'XQueryPassword'

    let $user := environment-variable($userEnv)
    let $password := environment-variable($passwordEnv)
    let $url := concat($location, $user, '/721/', $fileName)

    let $response := http:send-request(
            <http:request method='get'
                auth-method='Basic'
                send-authorization='true'
                username='{$user}'
                password='{$password}'
                override-media-type='text/xml'/>,
            $url
    )

    return $response[2]
};

declare function utils:getLookupTable(
    $countryCode as xs:string,
    $featureName as xs:string
) as document-node() {
    let $fileName := concat($countryCode, '_', $featureName, '.xml')

    (:return utils:getLookupTableByFilename($fileName):)
    return utils:getLookupTableSVN($countryCode,$featureName)
    
};

declare function utils:getLookupTableSVN(
    $countryCode as xs:string,
    $featureName as xs:string
) as document-node() {
    (:let $location := 'https://svn.eionet.europa.eu/repositories/Reportnet/Dataflows/IndustrialSitesEURegistry/xquery/lookup-tables/':)
    let $location := './lookup-tables/'

    let $fileName := concat($countryCode, '_', $featureName, '.xml')
    let $url := concat($location, $featureName, '/', $fileName)

    return fn:doc($url)
};

(:~
 : --------------
 : Util functions
 : --------------
 :)

declare function utils:getNoDetails(
) as element(div)* {
    <div class="iedreg">
        <div class="iedreg inner msg gray mnone">
            <span class="iedreg nowrap header">Not implemented yet</span>
            <br/>
            <span class="iedreg">This check is still under development</span>
        </div>
    </div>
};

declare function utils:getNotActive(
) as element(div)* {
    <div class="iedreg">
        <div class="iedreg inner msg gray mnone">
            <span class="iedreg nowrap header">Not active</span>
            <br/>
            <span class="iedreg">This check is active from 2018 reporting year onwards</span>
        </div>
    </div>
};

declare function utils:getNotApplicable(
) as element(div)* {
    <div class="iedreg">
        <div class="iedreg inner msg gray mnone">
            <span class="iedreg nowrap header">Not applicable</span>
            <br/>
            <span class="iedreg">This check is not applicable to your country</span>
        </div>
    </div>
};

declare function utils:getNotAvailableEnvelope(
) as element(div)* {
    <div class="iedreg">
        <div class="iedreg inner msg gray mnone">
            <span class="iedreg nowrap header">Envelope not available</span>
            <br/>
            <span class="iedreg">This check is not applicable because envelope XML is not available.</span>
        </div>
    </div>
};

declare function utils:getErrorDetails(
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

declare function utils:renderResult(
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

declare function utils:notYet(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $details := utils:getNoDetails()
    return utils:renderResult($refcode, $rulename, 'none', $details)
};

declare function utils:notActive(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $details := utils:getNotActive()
    return utils:renderResult($refcode, $rulename, 'none', $details)
};

declare function utils:notApplicable(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $details := utils:getNotApplicable()
    return utils:renderResult($refcode, $rulename, 'none', $details)
};

declare function utils:notAvailableEnvelope(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $details := utils:getNotAvailableEnvelope()
    return utils:renderResult($refcode, $rulename, 'none', $details)
};

declare function utils:failsafeWrapper(
        $lookupTables as map(*),
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element(),
        $checkFunc as function(map(*), xs:string, xs:string, element()) as element()*
) as element()* {
    try {
        (:~ let $asd := trace($refcode, '- ') ~:)
        let $reportingYear := $root//*:reportingYear/xs:float(.)
        let $countryCode := tokenize($root//*:countryId/@xlink:href, '/+')[last()]

        let $envelope-url := data($root/gml:metaDataProperty/attribute::xlink:href)
        let $envelope-available := fn:doc-available($envelope-url)
                (:~ and fn:not(fn:contains($envelope-url, 'converters')) ~:)

        return
        
        if ($refcode="C9.3") then $checkFunc($lookupTables, $refcode, $rulename, $root)
           else if($refcode = $utils:envelopeChecks and fn:not($envelope-available))
                then utils:notAvailableEnvelope($refcode, $rulename, $root)
            else if($countryCode = map:keys($utils:skipCountries)
                    and $refcode = $utils:skipCountries?($countryCode))
                then utils:notApplicable($refcode, $rulename, $root)
            else if(($refcode = $utils:checks2018 or $refcode = $utils:checksHistoricalData)
                    and (not($utils:run2018checks) or $reportingYear < 2018))
                then utils:notActive($refcode, $rulename, $root)
            (:else $checkFunc($lookupTables, $refcode, $rulename, $root):)
    } catch * {
        let $details := utils:getErrorDetails($err:code, $err:description)
        return utils:renderResult($refcode, $rulename, 'failed', $details)
    }
};
