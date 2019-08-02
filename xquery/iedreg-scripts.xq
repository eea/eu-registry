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

module namespace scripts = "iedreg-scripts";

declare namespace act-core = 'http://inspire.ec.europa.eu/schemas/act-core/4.0';
declare namespace adms = "http://www.w3.org/ns/adms#";
declare namespace base = "http://inspire.ec.europa.eu/schemas/base/3.3";
declare namespace EUReg = 'http://dd.eionet.europa.eu/euregistryonindustrialsites';
declare namespace GML = "http://www.opengis.net/gml";
declare namespace gml = "http://www.opengis.net/gml/3.2";
declare namespace math = "http://www.w3.org/2005/xpath-functions/math";
declare namespace ogr = "http://ogr.maptools.org/";
declare namespace pf = "http://inspire.ec.europa.eu/schemas/pf/4.0";
declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace rest = "http://basex.org/rest";
declare namespace skos = "http://www.w3.org/2004/02/skos/core#";
declare namespace xlink = "http://www.w3.org/1999/xlink";

import module namespace functx = "http://www.functx.com" at "iedreg-functx.xq";
import module namespace database = "iedreg-database" at "iedreg-database.xq";
import module namespace geo = "http://expath.org/ns/geo";

declare variable $scripts:MSG_LIMIT as xs:integer := 1000;

declare variable $scripts:docProdFac as document-node() := fn:doc('https://svn.eionet.europa.eu/repositories/Reportnet/Dataflows/IndustrialSitesEURegistry/xquery/lookup-tables/ProductionFacility.xml');
declare variable $scripts:docProdInstall as document-node() := fn:doc('https://svn.eionet.europa.eu/repositories/Reportnet/Dataflows/IndustrialSitesEURegistry/xquery/lookup-tables/ProductionInstallation.xml');
declare variable $scripts:docProdInstallPart as document-node() := fn:doc('https://svn.eionet.europa.eu/repositories/Reportnet/Dataflows/IndustrialSitesEURegistry/xquery/lookup-tables/ProductionInstallationPart.xml');
declare variable $scripts:docProdSite as document-node() := fn:doc('https://svn.eionet.europa.eu/repositories/Reportnet/Dataflows/IndustrialSitesEURegistry/xquery/lookup-tables/ProductionSite.xml');

(:
--------------------
:   Global variables
--------------------
:)

(: The following checks will flag if the value is empty :)
declare variable $scripts:checksToFlagEmpty as xs:string+ := (
    'C2.5', 'C2.7', 'C2.8', 'C2.13', 'C2.15', 'C2.17', 'C3.6', 'C13.9'
);

(:~
 : --------------
 : Util functions
 : --------------
 :)

(: Flag empty/blank fields :)
declare function scripts:flagForEmpty(
    $refcode as xs:string,
    $node as element()?,
    $attribute as xs:string
) as xs:boolean {
    let $val :=
        if(functx:if-empty($attribute, '') = '')
        then $node/text()
        else $node/attribute::*[local-name() = $attribute]

    return $refcode = $scripts:checksToFlagEmpty
            and functx:if-empty($val, '') = ''
};


declare function scripts:getCountry(
        $root as element()
) as xs:string{
    let $country := $root//*:ReportData/*:countryId
    let $cntry := tokenize($country/attribute::xlink:href, '/+')[last()]

    return $cntry
};

declare function scripts:getLastYear(
        $root as element()
) as xs:string{
    let $reportingYear := $root//*:reportingYear/data()
    let $lastReportingYear := xs:string($reportingYear - 1)

    return $lastReportingYear
};

declare function scripts:normalize($url as xs:string) as xs:string {
(: replace($url, 'http://dd\.eionet\.europa\.eu/vocabulary[a-z]*/euregistryonindustrialsites/', '') :)
    replace($url, 'http://dd\.eionet\.europa\.eu/vocabulary[a-z]*/euregistryonindustrialsites/[a-zA-Z0-9]+/', '')
};

declare function scripts:is-empty($item as item()*) as xs:boolean {
    normalize-space(string-join($item)) = ''
};

declare function scripts:makePlural($names as xs:string*) as xs:string {
    let $res :=
        for $name in $names
            let $name := replace($name, 'Site$', 'Sites')
            let $name := replace($name, 'Facility$', 'Facilities')
            let $name := replace($name, 'Installation$', 'Installations')
            let $name := replace($name, 'InstallationPart$', 'InstallationParts')
            return $name
    return $res
};

declare function scripts:getPath($e as element()) as xs:string {
    $e/string-join(ancestor-or-self::*[not(fn:matches(local-name(), '^(FeatureCollection)|(featureMember)$'))]/local-name(.), ' / ')
};

declare function scripts:getParent($e as element()) as element() {
    $e/ancestor-or-self::*[fn:matches(local-name(), '^Production[a-zA-Z]')]
};

declare function scripts:getInspireId($e as element()) as element()* {
    let $parent := scripts:getParent($e)
    return $parent/*:inspireId//*:localId
};

declare function scripts:getGmlId($e as element()) as xs:string {
    let $id := $e/attribute::gml:id
    return if (scripts:is-empty($id)) then "–" else data($id)
};

declare function scripts:getValidConcepts($value as xs:string) as xs:string* {
    let $valid := "http://dd.eionet.europa.eu/vocabulary/datadictionary/status/valid"

    let $vocabulary := "http://dd.eionet.europa.eu/vocabulary/euregistryonindustrialsites/"
    let $vocabularyconcept := "http://dd.eionet.europa.eu/vocabularyconcept/euregistryonindustrialsites/"

    let $url := $vocabulary || $value || "/rdf"

    return
        data(doc($url)//skos:Concept[adms:status/@rdf:resource = $valid]/@rdf:about)
};

declare function scripts:getDetails(
        $msg as xs:string,
        $type as xs:string,
        $hdrs as (xs:string)*,
        $data as (map(*))*
) as element(div)* {
    let $msgClass := concat('inner msg',
            if ($type = 'blocker') then ' red mblocker'
            else if ($type = 'warning') then ' yellow mwarning'
            else if ($type = 'info') then ' blue minfo'
                else ()
    )

    return
        <div class="iedreg">

            <div class="iedreg {$msgClass}">{$msg}</div>

            {if (fn:count($data) > 0)
            then
                <div class="iedreg table inner">
                    <div class="iedreg row">
                        {for $h in $hdrs
                        return
                            <div class="iedreg col inner th"><span class="iedreg break">{$h}</span></div>
                        }
                    </div>
                    {for $d in $data
                    let $sort_index := if ('sort' = map:keys($d)) then $d?sort else 1
                    count $pos
                    where $pos <= $scripts:MSG_LIMIT
                    order by $d?data[$sort_index]
                    return
                        <div class="iedreg row">
                            {for $z at $i in $d('data')
                            let $x := if (fn:index-of($d('marks'), $i)) then <span class="iedreg top nowrap">{$z}</span> else <span class="iedreg top">{$z}</span>
                            return
                                <div class="iedreg col inner{if (fn:index-of($d('marks'), $i)) then ' ' || $type else ''}">{$x}</div>
                            }
                        </div>
                    }
                </div>
            else ()
            }
        </div>
};

declare function scripts:noPreviousYearWarning(
  $refcode as xs:string,
  $rulename as xs:string
){
    let $warnDb := "There are no data available for previous years."
    let $details := scripts:getDetails($warnDb, "warning", (), ())
    return scripts:renderResult($refcode, $rulename, 0, 1, 0, $details)
};

declare function scripts:noDbWarning(
  $refcode as xs:string,
  $rulename as xs:string
){
    let $warnDb := "The database is currently not available. Please try again later."
    let $details := scripts:getDetails($warnDb, "warning", (), ())
    return scripts:renderResult($refcode, $rulename, 0, 1, 0, $details)
};

(:~
 : --------------
 : html functions
 : --------------
 :)

declare function scripts:renderResult(
        $refcode as xs:string,
        $rulename as xs:string,
        $errors as xs:integer,
        $warnings as xs:integer,
        $messages as xs:integer,
        $details as element()*
) {
    let $id := random:integer(65536)

    let $label :=
        <label class="iedreg" for="toggle-{$id}">
            <span class="iedreg link">More...</span>
        </label>

    let $toggle :=
        <input class="iedreg toggle" id="toggle-{$id}" type="checkbox" />

    let $showRecords := ($errors + $warnings + $messages > 0)

    let $type :=
        if ($errors > 0) then
            'blocker'
        else if ($warnings > 0) then
            'warning'
        else if ($messages > 0) then
                'info'
            else
                'pass'

    let $errors := if($errors > 1000) then 1000 else $errors
    let $warnings := if($warnings > 1000) then 1000 else $warnings
    let $messages := if($messages > 1000) then 1000 else $messages

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
                            <span class="iedreg nowrap">{$errors} blockers</span>
                            <span class="iedreg nowrap">{$warnings} warnings</span>
                            {if ($messages > 0) then
                                <span class="iedreg nowrap">{$messages} messages</span>
                            else ()}
                        </div>

                        <div class="iedreg col ten center middle">
                            {if ($showRecords) then
                                $label
                            else ' '}
                        </div>
                    </div>
                </div>

                <!-- details table -->
                {if ($showRecords) then
                    ($toggle, $details)
                else
                    ()
                }
            </div>
        </div>
};

(:~
 : 2. CODE LIST CHECKS
 :)

declare function scripts:checkActivity(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element(),
        $featureName as xs:string,
        $activityName as xs:string,
        $activityType as xs:string,
        $seq as element()*
) as element()* {
    let $msg := "The " || $activityName || " specified in the " || $activityType || " field for the following " ||
                scripts:makePlural($featureName) || " is not recognised. Please use an activity listed in the " ||
                $activityName || "Value code list"
    let $type := "blocker"

    let $value := $activityName || "Value"
    let $valid := scripts:getValidConcepts($value)

    (:let $seq := $root//*[local-name() = $featureName]//*[local-name() = $activityType]:)

    let $data :=
        for $x in $seq
        let $parent := scripts:getParent($x)
        let $feature := $parent/local-name()
        let $id := scripts:getInspireId($parent)

        let $activity := replace($x/attribute::*:href, '/+$', '')

        let $p := scripts:getPath($x)
        let $v := scripts:normalize($activity)

        let $errMsg :=
            if(scripts:flagForEmpty($refcode, $x, 'href'))
            then 'Field cannot be empty'
            else if(not($activity = $valid) and not(functx:if-empty($activity, '') = ''))
            then 'Code is not valid'
            else ''

        where not($errMsg = '')
        return map {
        "marks" : (1, 5),
        "data" : ($errMsg, $feature, $id, <span class="iedreg break">{$p}</span>, $v)
        }

    let $hdrs := ("Message", "Feature", "Local ID", "Path", "Code list value")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, count($data), 0, 0, $details)
};

(:~
 : C2.1 EPRTRAnnexIActivity mainActivity consistency
 :)

declare function scripts:checkMainEPRTRAnnexIActivity(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $featureName := "ProductionFacility"
    let $activityName := "EPRTRAnnexIActivity"
    let $activityType := "mainActivity"
    let $seq := $root//*[local-name() = $activityName]//*[local-name() = $activityType]

    return scripts:checkActivity($refcode, $rulename, $root, $featureName, $activityName, $activityType, $seq)
};

(:~
 : C2.2 EPRTRAnnexIActivity otherActivity consistency
 :)

declare function scripts:checkOtherEPRTRAnnexIActivity(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $featureName := "ProductionFacility"
    let $activityName := "EPRTRAnnexIActivity"
    let $activityType := "otherActivity"
    let $seq := $root//*[local-name() = $activityName]//*[local-name() = $activityType]

    return scripts:checkActivity($refcode, $rulename, $root, $featureName, $activityName, $activityType, $seq)
};

(:~
 : C2.3 IEDAnnexIActivity mainActivity consistency
 :)

declare function scripts:checkMainIEDAnnexIActivity(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $featureName := "ProductionInstallation"
    let $activityName := "IEDAnnexIActivity"
    let $activityType := "mainActivity"
    let $seq := $root//*[local-name() = $activityName]//*[local-name() = $activityType]

    return scripts:checkActivity($refcode, $rulename, $root, $featureName, $activityName, $activityType, $seq)
};

(:~
 : C2.4 IEDAnnexIActivity otherActivity consistency
 :)

declare function scripts:checkOtherIEDAnnexIActivity(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $featureName := "ProductionInstallation"
    let $activityName := "IEDAnnexIActivity"
    let $activityType := "otherActivity"
    let $seq := $root//*[local-name() = $activityName]//*[local-name() = $activityType]

    return scripts:checkActivity($refcode, $rulename, $root, $featureName, $activityName, $activityType, $seq)
};

(:~
 : C2.5 CountryId consistency
 :)

declare function scripts:checkCountryId(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := "The CountryCodeValue specified in the CountryId field is not recognised. "
    let $type := "blocker"

    let $msgA := "Value is empty, please complete the CountryId."
    let $msgB := "Value must match the CountryId of the envelope."
    let $msgC := "Please use a valid CountryId listed in the CountryCodeValue code list."

    let $value := "CountryCodeValue"
    let $valid := scripts:getValidConcepts($value)

    let $url := data($root/gml:metaDataProperty/attribute::xlink:href)
    let $envelope := doc($url)/envelope
    let $envelopeCountry := $envelope/*:countrycode

    let $seq := $root//*:ReportData

    let $data :=
        for $rd in $seq
        let $feature := $rd/local-name()

        let $countries := $rd//*:countryId

        for $x in $countries
        let $country := $x/@xlink:href
        let $countryCode := scripts:getCountry($root)

        let $p := scripts:getPath($x)
        let $v := scripts:normalize(data($country))

        let $errorMsg :=
            if(functx:if-empty($country, '') = '')
                then $msgA
            else if(not($countryCode = $envelopeCountry))
                then $msgB
            else if(not($country = $valid))
                then $msgC
            else ()

        where not(functx:if-empty($errorMsg, '') = '')
        return map {
        "marks" : (1, 5),
        "data" : ($errorMsg, $feature, $p, $v)
        }

    let $hdrs := ("Message", "Feature", "Path", "CountryId")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, count($data), 0, 0, $details)
};

(:~
 : C2.6 reasonValue consistency
 :)

declare function scripts:checkReasonValue(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := "The ReasonValue supplied in the confidentialityReason field for the following spatial objects is not recognised. Please use a reason listed in the ReasonValue code list"
    let $type := "blocker"

    let $value := "ReasonValue"
    let $valid := scripts:getValidConcepts($value)

    let $seq := $root//*:confidentialityReason

    let $data :=
        for $r in $seq
        let $parent := scripts:getParent($r)
        let $feature := $parent/local-name()
        let $id := scripts:getInspireId($parent)

        let $reason := replace($r/attribute::xlink:href, '/+$', '')

        let $p := scripts:getPath($r)
        let $v := scripts:normalize(data($reason))

        where (not(empty($reason)) and not($reason = $valid))
        return map {
        "marks" : (4),
        "data" : ($feature, <span class="iedreg nowrap">{$id}</span>, $p, $v)
        }

    let $hdrs := ("Feature", "Local ID", "Path", "ReasonValue")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, count($data), 0, 0, $details)
};

(:~
    2.7 FacilityType consistency
:)
declare function scripts:checkFacilityTypeVocab(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $featureName := "ProductionFacility"
    let $activityName := "FacilityType"
    let $activityType := "facilityType"
    let $seq := $root//*[local-name() = $featureName]//*[local-name() = $activityType]

    return scripts:checkActivity($refcode, $rulename, $root, $featureName,
            $activityName, $activityType, $seq)
};

(:~
    2.8 InstallationType consistency
:)
declare function scripts:checkInstallationTypeVocab(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $featureName := "ProductionInstallation"
    let $activityName := "InstallationType"
    let $activityType := "installationType"
    let $seq := $root//*[local-name() = $featureName]//*[local-name() = $activityType]

    return scripts:checkActivity($refcode, $rulename, $root, $featureName, $activityName, $activityType, $seq)
};

(:~
    2.9 BaselineReport consistency
:)
declare function scripts:checkBaselineReportTypeVocab(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $featureName := "ProductionInstallation"
    let $activityName := "BaselineReport"
    let $activityType := "baselineReportIndicator"
    let $seq := $root//*[local-name() = $featureName]//*[local-name() = $activityType]

    return scripts:checkActivity($refcode, $rulename, $root, $featureName, $activityName, $activityType, $seq)
};

(:~
    2.10 BATConclusion consistency
:)
declare function scripts:checkBATConclusionTypeVocab(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $featureName := "ProductionInstallation"
    let $activityName := "BATConclusion"
    let $activityType := "BATConclusion"
    let $seq := $root//*[local-name() = $featureName]//*[local-name() = $activityType]

    return scripts:checkActivity($refcode, $rulename, $root, $featureName, $activityName, $activityType, $seq)
};

(:~
    2.11 BATAEL consistency
:)
declare function scripts:checkBATAELTypeVocab(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $featureName := "ProductionInstallation"
    let $activityName := "BATAEL"
    let $activityType := "BATAEL"
    let $seq := $root//*[local-name() = $featureName]//*[local-name() = $activityType]

    return scripts:checkActivity($refcode, $rulename, $root, $featureName, $activityName, $activityType, $seq)
};

(:~
 : 3. INSPIRE ID CHECKS
 :)

declare function scripts:checkInspireIdUniqueness(
        $root as element(),
        $refcode as xs:string,
        $feature as xs:string
) as element()* {
    let $rulename := $feature || " inspireId uniqueness"

    let $msg := "All inspireIds for " || scripts:makePlural($feature) || " should be unique. Please ensure all inspireIds are different"
    let $type := "blocker"

    let $seq := $root//*[local-name() = $feature]

    let $dups := functx:non-distinct-values($seq/scripts:getInspireId(.))

    let $data :=
        for $d in $dups
        for $x in $seq
        let $id := scripts:getInspireId($x)
        where scripts:getInspireId($x)/text() = $d
        return map {
        "marks" : (3),
        "data" : ($feature, <span class="iedreg nowrap">{$id}</span>, $d)
        }

    let $hdrs := ("Feature", "Local ID", "Local ID")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, count($data), 0, 0, $details)
};

(:~
 : C3.1 High proportion of new inspireIds
 :)

declare function scripts:checkAmountOfInspireIds(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $warn := "The amount of new inspireIds within this submission equals PERC,
        which exceeds 50%, please verify to ensure these are new entities reported for
        the first time."
    let $info := "The amount of new inspireIds within this submission equals PERC,
        which exceeds the ideal threshold of 20%, please verify to ensure these are
        new entities reported for the first time."

    let $cntry := scripts:getCountry($root)
    let $lastReportingYear := scripts:getLastYear($root)

    let $seq := $root//*:inspireId

    let $fromDB := (
        database:queryByYear($cntry, $lastReportingYear, $scripts:docProdFac, 'inspireId'),
        database:queryByYear($cntry, $lastReportingYear, $scripts:docProdInstall, 'inspireId'),
        database:queryByYear($cntry, $lastReportingYear, $scripts:docProdInstallPart, 'inspireId'),
        database:queryByYear($cntry, $lastReportingYear, $scripts:docProdSite, 'inspireId')
    )

    let $xIDs := $seq//base:localId
    let $yIDs := $fromDB//*:localId

    let $data :=
        for $id in $xIDs
        let $p := scripts:getParent($id)

        where not($id = $yIDs)
        return map {
        "marks": (2),
        "data": ($p/local-name(), <span class="iedreg nowrap">{$id/text()}</span>)
        }

    let $ratio := count($data) div count($yIDs)
    let $perc := round-half-to-even($ratio * 100, 1) || '%'

    let $hdrs := ("Feature", "Local ID")
    return
        if (not(database:dbAvailable($scripts:docProdFac))) then
            scripts:noDbWarning($refcode, $rulename)
        else
            if ($ratio gt 0.5) then
                let $msg := replace($warn, 'PERC', $perc)
                let $details := scripts:getDetails($msg, "warning", $hdrs, $data)
                return scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
            else if ($ratio gt 0.2) then
                let $msg := replace($info, 'PERC', $perc)
                let $details := scripts:getDetails($msg, "info", $hdrs, $data)
                return scripts:renderResult($refcode, $rulename, 0, 0, count($data), $details)
            else
                scripts:renderResult($refcode, $rulename, 0, 0, 0, ())
};

(:~
 : C3.2 ProductionSite inspireId uniqueness
 :)

declare function scripts:checkProductionSiteUniqueness(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $feature := "ProductionSite"

    return scripts:checkInspireIdUniqueness($root, $refcode, $feature)
};

(:~
 : C3.3 ProductionFacility inspireId uniqueness
 :)

declare function scripts:checkProductionFacilityUniqueness(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $feature := "ProductionFacility"

    return scripts:checkInspireIdUniqueness($root, $refcode, $feature)
};

(:~
 : C3.4 ProductionInstallation inspireId uniqueness
 :)

declare function scripts:checkProductionInstallationUniqueness(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $feature := "ProductionInstallation"

    return scripts:checkInspireIdUniqueness($root, $refcode, $feature)
};

(:~
 : C3.5 ProductionInstallationPart inspireId uniqueness
 :)

declare function scripts:checkProductionInstallationPartUniqueness(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $feature := "ProductionInstallationPart"

    return scripts:checkInspireIdUniqueness($root, $refcode, $feature)
};

(:~
 : C3.6 InspireId blank check
 :)

declare function scripts:checkInspireIdBlank(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $features := ('ProductionSite', 'ProductionFacility', 'ProductionInstallation',
        'ProductionInstallationPart')
    let $msg := "All local ID and namespace attributes for " || fn:string-join($features, ', ')
        || " feature types must be filled in. Please ensure all local ID and namespace attributes are completed."
    let $type := "blocker"

    let $seq := $root//*[local-name() = $features]

    let $data :=
        for $f in $seq
        let $localId := $f/*:inspireId//*:localId
        let $namespace := $f/*:inspireId//*:namespace

        let $gmlId := scripts:getGmlId($f)
        let $feature := $f/local-name()

        where functx:if-empty($localId, '') = '' or functx:if-empty($namespace, '') = ''

        return map {
        "marks" : (
            if(functx:if-empty($localId, '') = '') then 2 else (),
            if(functx:if-empty($namespace, '') = '') then 3 else ()
        ),
        "data" : (
            $feature,
            <span class="iedreg nowrap">{$localId}</span>,
            $namespace
        )}

    let $hdrs := ("Feature", "localId", "namespace")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, count($data), 0, 0, $details)

};

(:~
 : 4. DUPLICATE IDENTIFICATION CHECKS
 :)

declare function scripts:checkDuplicates(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element(),
        $featureNames as xs:string*,
        $stringNodes as xs:string+,
        $locationNode as xs:string?,
        $codelistNode as xs:string?
) as element()* {
    let $srsName :=
        for $srs in distinct-values($root//gml:*/attribute::srsName)
        return replace($srs, '^.*EPSG:+', 'http://www.opengis.net/def/crs/EPSG/0/')

    let $type := "warning"
    let $msg := "The similarity threshold has been exceeded, for the following "
        || scripts:makePlural($featureNames) => fn:string-join(', ') ||
        ". Please ammend the XML submission to ensure that there is no duplication"

    let $seq := $root//*[local-name() = $featureNames]
    let $norm := ft:normalize(? , map {'stemming' : true()})

    let $items :=
        for $node in $seq
            let $stringMain := $node//*[local-name() = $stringNodes]/data()
                => fn:string-join(' / ')
            let $codelistMain := $node//*[local-name() = $codelistNode]
                    //fn:tokenize(@xlink:href/data(), '/')[last()]
            let $codelistMainLev := fn:replace($codelistMain, '[\(\)\.]', '')
            let $locationMain := $node/*[local-name() = $locationNode]//gml:pos
            let $stringMainLev := (fn:replace($stringMain, ' / ', ''), $codelistMainLev)
                    => fn:string-join('')
            let $stringMain := ($stringMain, $codelistMain) => fn:string-join(' / ')

            return
                <item>
                    <string>{$stringMain}</string>
                    <location>{$locationMain/data()}</location>
                </item>

    let $distinct_items := functx:distinct-deep($items)

    let $data :=
        for $item at $ind in $distinct_items
            (:let $featureName := $node/local-name():)
            (:let $inspireId := scripts:getInspireId($node):)
            let $stringMain := $item/string => xs:string()
            let $stringLev := fn:replace($stringMain, ' / ', '')
            let $locationMain := $item/location => xs:string()

            for $sub in subsequence($distinct_items, $ind + 1)
                (:let $inspireIdSub := scripts:getInspireId($sub):)
                let $stringSub := $sub/string => xs:string()
                let $stringSubLev := fn:replace($stringSub, ' / ', '')
                let $locationSub := $sub/location => xs:string()

                let $levRatio := strings:levenshtein(
                        $norm($stringLev),
                        $norm($stringSubLev)
                )

                let $stringFlagged := $levRatio >= 0.9
                where $stringFlagged
                (:let $codelistFlagged := if(exists($codelistNode)):)
                    (:then $codelistMain = $codelistSub:)
                    (:else true():)
                (:where $codelistFlagged:)
                let $distance := if(exists($locationNode))
                    then
                        let $main_lat := substring-before($locationMain, ' ')
                        let $main_long := substring-after($locationMain, ' ')
                        let $main_point := <GML:Point srsName="{$srsName[1]}"><GML:coordinates>{$main_long},{$main_lat}</GML:coordinates></GML:Point>

                        let $sub_lat := substring-before($locationSub, ' ')
                        let $sub_long := substring-after($locationSub, ' ')
                        let $sub_point := <GML:Point srsName="{$srsName[1]}"><GML:coordinates>{$sub_long},{$sub_lat}</GML:coordinates></GML:Point>

                        let $dist := round-half-to-even(geo:distance($main_point, $sub_point) * 111319.9, 2)

                        return $dist
                    else
                        '-'

                let $locationFlagged := if(xs:string($distance) = '-')
                    then
                        true()
                    else
                        if($distance < 100) then true() else false()

                where $locationFlagged

                for $feat in $seq[fn:string-join(.//*[local-name() = $stringNodes]/data(),' / ')
                        = $stringMain and .//gml:pos/text() = $locationMain]
                    let $featureName := $feat/local-name()
                    let $inspireId := scripts:getInspireId($feat)

                    for $sub in $seq[fn:string-join(.//*[local-name() = $stringNodes]/data(),' / ')
                        = $stringSub and .//gml:pos/text() = $locationSub]

                    let $inspireIdSub := scripts:getInspireId($sub)

                    return map {
                    (:"sort": (7),:)
                    "marks" : (7),
                    "data" : (
                        $featureName,
                        $inspireId,
                        $inspireIdSub,
                        ($stringNodes, $codelistNode, $locationNode) => fn:string-join(' / '),
                        <span class="iedreg break">{($stringMain, $locationMain) => fn:string-join(' / ')}</span>,
                        <span class="iedreg break">{($stringSub, $locationSub) => fn:string-join(' / ')}</span>,
                        concat(round-half-to-even($levRatio * 100, 1) || '%', ' / ',
                                (if(xs:string($distance) = '-') then $distance else $distance || ' m')
                        )
                    )
                    }

    let $hdrs := ('Feature', 'Local ID', ' ', 'Attribute names', 'Attribute values', ' ', 'Similarity / Distance')

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
};

declare function scripts:checkDuplicates2(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element(),
        $featureNames as xs:string*,
        $stringNodes as xs:string+,
        $locationNode as xs:string?,
        $codelistNode as xs:string?
) as element()* {
    let $srsName :=
        for $srs in distinct-values($root//gml:*/attribute::srsName)
        return replace($srs, '^.*EPSG:+', 'http://www.opengis.net/def/crs/EPSG/0/')

    let $type := "warning"
    let $msg := "The similarity threshold has been exceeded, for the following "
        || scripts:makePlural($featureNames) => fn:string-join(', ') ||
        ". Please ammend the XML submission to ensure that there is no duplication"

    let $seq := $root//*[local-name() = $featureNames]
    let $norm := ft:normalize(? , map {'stemming' : true()})
    let $countFeatures := fn:count($seq)
    let $maxNrOfFeatures := 500

    let $data :=
        for $node at $ind in $seq
            let $stringMain := $node//*[local-name() = $stringNodes]/data()
                => fn:string-join(' / ')
            let $codelistMain := $node//*[local-name() = $codelistNode]
                    //fn:tokenize(@xlink:href/data(), '/')[last()]
            let $codelistMainLev := fn:replace($codelistMain, '[\(\)\.]', '')
            let $locationMain := $node/*[local-name() = $locationNode]//gml:pos
            let $stringMainLev := (fn:replace($stringMain, ' / ', ''), $codelistMainLev)
                    => fn:string-join('')
            let $stringMain := ($stringMain, $codelistMain) => fn:string-join(' / ')

            for $sub in subsequence($seq, $ind + 1)
                let $stringSub := $sub//*[local-name() = $stringNodes]/data()
                    => fn:string-join(' / ')
                (: compare only if the first character is the same:)
                where substring($stringMain, 1, 1) = substring($stringSub, 1, 1)

                let $codelistSub := $sub//*[local-name() = $codelistNode]
                    //fn:tokenize(@xlink:href/data(), '/')[last()]
                let $codelistSubLev := fn:replace($codelistSub, '[\(\)\.]', '')
                let $locationSub := $sub/*[local-name() = $locationNode]//gml:pos
                let $stringSubLev := (fn:replace($stringSub, ' / ', ''), $codelistSubLev)
                        => fn:string-join('')
                let $stringSub := ($stringSub, $codelistSub) => fn:string-join(' / ')

                (: compare with levenshtein only if there are less than 500 features :)
                let $levRatio :=
                    if($stringMainLev = $stringSubLev)
                    then 1
                    else if($ind gt $maxNrOfFeatures)
                        then 0
                        else strings:levenshtein($norm($stringMainLev), $norm($stringSubLev))

                let $stringFlagged := $levRatio >= 0.9
                where $stringFlagged

                let $distance := if(exists($locationNode))
                    then
                        let $dist :=
                            if($locationMain = $locationSub)
                            then 0
                            else if($ind gt $maxNrOfFeatures)
                                then 1000
                                else
                                    let $main_lat := substring-before($locationMain, ' ')
                                    let $main_long := substring-after($locationMain, ' ')
                                    let $main_point := <GML:Point srsName="{$srsName[1]}"><GML:coordinates>{$main_long},{$main_lat}</GML:coordinates></GML:Point>

                                    let $sub_lat := substring-before($locationSub, ' ')
                                    let $sub_long := substring-after($locationSub, ' ')
                                    let $sub_point := <GML:Point srsName="{$srsName[1]}"><GML:coordinates>{$sub_long},{$sub_lat}</GML:coordinates></GML:Point>

                                    return round-half-to-even(
                                            geo:distance($main_point, $sub_point) * 111319.9, 2
                                    )

                        return $dist
                    else
                        '-'

                let $locationFlagged := if(xs:string($distance) = '-')
                    then
                        true()
                    else
                        if($distance < 100) then true() else false()

                where $locationFlagged

                (:let $featureName := $node/local-name():)
                let $inspireId := scripts:getInspireId($node)
                let $inspireIdSub := scripts:getInspireId($sub)

                return map {
                (:"sort": (7),:)
                "marks" : (6),
                "data" : (
                    replace($inspireId, '\.', ' '),
                    replace($inspireIdSub, '\.', ' '),
                    ($stringNodes, $codelistNode, $locationNode) => fn:string-join(' / '),
                    <span class="iedreg break">{($stringMain, $locationMain) => fn:string-join(' / ')}</span>,
                    <span class="iedreg break">{($stringSub, $locationSub) => fn:string-join(' / ')}</span>,
                    concat(round-half-to-even($levRatio * 100, 1) || '%', ' / ',
                            (if(xs:string($distance) = '-') then $distance else $distance || ' m')
                    )
                )
                }

    let $hdrs := ('Local ID', ' ', 'Attribute names', 'Attribute values', ' ', 'Similarity / Distance')

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
};

(:~
 : C4.1 Identification of ProductionSite duplicates
 :)

declare function scripts:checkProductionSiteDuplicates(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $features := ('ProductionSite')
    (:let $nodes := ('nameOfFeature', 'location'):)
    (:let $attrs := ():)
    let $stringNodes := ('nameOfFeature')
    let $locationNode := ('location')
    let $codelistNode := ()

    return scripts:checkDuplicates2($refcode, $rulename, $root, $features,
            $stringNodes, $locationNode, $codelistNode)

    (:return scripts:checkDuplicates($refcode, $rulename, $root, $features, $nodes, $attrs):)
};

(:~
 : C4.2 Identification of ProductionFacility duplicates
 :)

declare function scripts:checkProductionFacilityDuplicates(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $features := ('ProductionFacility')
    (:let $nodes := ('geometry', 'facilityName', 'parentCompanyName'):)
    (:let $attrs := ('EPRTRAnnexIActivity'):)

    let $stringNodes := ('facilityName', 'parentCompanyName')
    let $locationNode := ('geometry')
    let $codelistNode := ('mainActivity')

    return scripts:checkDuplicates2($refcode, $rulename, $root, $features,
            $stringNodes, $locationNode, $codelistNode)

    (:return scripts:checkDuplicates($refcode, $rulename, $root, $features, $nodes, $attrs):)
};

(:~
 : C4.3 Identification of ProductionInstallation duplicates
 :)

declare function scripts:checkProductionInstallationDuplicates(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $features := ('ProductionInstallation')
    (:let $nodes := ('pointGeometry', 'installationName'):)
    (:let $attrs := ('IEDAnnexIActivity'):)

    let $stringNodes := ('installationName')
    let $locationNode := ('pointGeometry')
    let $codelistNode := ('mainActivity')

    return scripts:checkDuplicates2($refcode, $rulename, $root, $features,
            $stringNodes, $locationNode, $codelistNode)

    (:return scripts:checkDuplicates($refcode, $rulename, $root, $features, $nodes, $attrs):)
};

(:~
 : C4.4 Identification of ProductionInstallationPart duplicates
 :)

declare function scripts:checkProductionInstallationPartDuplicates(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $features := ('ProductionInstallationPart')
    (:let $nodes := ('installationPartName'):)
    (:let $attrs := ('plantType'):)

    let $stringNodes := ('installationPartName')
    let $locationNode := ()
    let $codelistNode := ('plantType')

    return scripts:checkDuplicates2($refcode, $rulename, $root, $features,
            $stringNodes, $locationNode, $codelistNode)


    (:return scripts:checkDuplicates($refcode, $rulename, $root, $features, $nodes, $attrs):)
};

declare function scripts:checkDatabaseDuplicates_old(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element(),
        $feature as xs:string,
        $docDB as document-node()
) as element()* {
    let $nameName := $feature || 'Name'
    let $featureName := 'Production' || functx:capitalize-first($feature)
    let $cntry := scripts:getCountry($root)
    let $lastReportingYear := scripts:getLastYear($root)

    let $msg := "The similarity threshold has been exceeded, for the following "
        || scripts:makePlural($featureName) || ". These " || scripts:makePlural($featureName)
        || " have similar " || scripts:makePlural($featureName) ||
        " already present in the master database. Please ensure that there is no duplication."
    let $type := "warning"

    let $seq := $root//*[local-name() = $featureName]//*[local-name() = $nameName]//*:nameOfFeature

    (: this is where we get the data from the database :)
    let $fromDB := database:queryByYear($cntry, $lastReportingYear, $docDB, $nameName)
    let $norm := ft:normalize(?, map {'stemming' : true()})

    let $data :=
        for $x in $seq
        let $p := scripts:getParent($x)
        let $id := scripts:getInspireId($p)

        for $y in $fromDB
        let $q := scripts:getParent($y)
        let $ic := scripts:getInspireId($q)

        where $id != $ic

        let $z := strings:levenshtein($norm($x/data()), $norm($y/data()))
        where $z >= 0.9
        return map {
        "marks" : (4, 5, 6),
        "data" : (
            $featureName,
            <span class="iedreg nowrap">{$id}</span>,
            <span class="iedreg nowrap">{$ic}</span>,
            '"' || $x/data() || '"', '"' || $y/data() || '"',
            round-half-to-even($z * 100, 1) || '%'
        )
        }

    let $hdrs := ('Feature', 'Local ID', 'Local ID (DB)', 'Feature name', 'Feature name (DB)', 'Similarity')

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        if (not(database:dbAvailable($docDB))) then
            scripts:noDbWarning($refcode, $rulename)
        else
            scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
};

declare function scripts:checkDatabaseDuplicates(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element(),
        $featureName as xs:string,
        $nodeNames as xs:string*,
        $attrs as xs:string*,
        $docDB as document-node()
) as element()* {
    let $type := "warning"
    let $pluralNames := scripts:makePlural($featureName) => fn:string-join(', ')

    let $msg := "The similarity threshold has been exceeded, for the following "
        || $pluralNames || ". These " || $pluralNames
        || " have similar " || $pluralNames ||
        " already present in the master database. Please ensure that there is no duplication."
    let $country := scripts:getCountry($root)
    let $lastYear := scripts:getLastYear($root)

    let $seq := $root//*[local-name() = $featureName]
    let $fromDB := database:queryByYearFeature($country, $lastYear, $docDB)
    let $norm := ft:normalize(? , map {'stemming' : true()})

    let $data :=
        for $node in $seq
            let $stringMain := $node//*[local-name() = $nodeNames]/data()
                => fn:string-join(' / ')
            let $stringMainAttrs := $node/*[local-name() = $attrs]
                    //fn:tokenize(@xlink:href/data(), '/')[last()]

            let $stringMain := ($stringMain, $stringMainAttrs) => fn:string-join(' / ')

            let $featureName := $node/local-name()
            let $p := scripts:getParent($node)
            let $id := scripts:getInspireId($p)


            for $sub in $fromDB
                let $q := scripts:getParent($sub)
                let $ic := scripts:getInspireId($q)

                where $id != $ic
                let $stringSub := $sub//*[local-name() = $nodeNames]/data()
                    => fn:string-join(' / ')
                let $stringSubAttrs := $sub/*[local-name() = $attrs]
                    //fn:tokenize(@xlink:href/data(), '/')[last()]
                let $stringSub := ($stringSub, $stringSubAttrs) => fn:string-join(' / ')

                let $levRatio := strings:levenshtein(
                        $norm(fn:replace($stringMain, ' / ', '')),
                        $norm(fn:replace($stringSub, ' / ', '')))

                where $levRatio >= 0.9

                return map {
                (:"sort": (7),:)
                "marks" : (5, 6, 7),
                "data" : (
                    $featureName,
                    <span class="iedreg nowrap">{$id}</span>,
                    <span class="iedreg nowrap">{$ic}</span>,
                    ($nodeNames, $attrs) => fn:string-join(' / '),
                    '"' || $stringMain || '"',
                    '"' || $stringSub || '"',
                    round-half-to-even($levRatio * 100, 1) || '%'
                )
                }

    let $hdrs := ('Feature', 'Local ID', 'Local ID (DB)', 'Attribute names',  'Attribute values', 'Attribute values (DB)', 'Similarity')

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
};

declare function scripts:checkDatabaseDuplicates2(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element(),
        $featureName as xs:string,
        $stringNodes as xs:string+,
        $locationNode as xs:string?,
        $codelistNode as xs:string?,
        $docDB as document-node()
) as element()* {
    let $srsName :=
        for $srs in distinct-values($root//gml:*/attribute::srsName)
        return replace($srs, '^.*EPSG:+', 'http://www.opengis.net/def/crs/EPSG/0/')

    let $type := "warning"
    let $pluralNames := scripts:makePlural($featureName) => fn:string-join(', ')

    let $msg := "The similarity threshold has been exceeded, for the following "
        || $pluralNames || ". These " || $pluralNames
        || " have similar " || $pluralNames ||
        " already present in the master database. Please ensure that there is no duplication."
    let $country := scripts:getCountry($root)
    let $lastYear := scripts:getLastYear($root)

    let $seq := $root//*[local-name() = $featureName]
    let $fromDB := database:queryByYearFeature($country, $lastYear, $docDB)
    let $norm := ft:normalize(? , map {'stemming' : true()})

    let $data :=
        for $node in $seq
            let $stringMain := $node//*[local-name() = $stringNodes]/data()
                => fn:string-join(' / ')
            let $codelistMain := $node//*[local-name() = $codelistNode]
                    //fn:tokenize(@xlink:href/data(), '/')[last()]
            let $codelistMainLev := fn:replace($codelistMain, '[\(\)\.]', '')
            let $locationMain := $node/*[local-name() = $locationNode]//gml:pos
            let $stringMainLev := (fn:replace($stringMain, ' / ', ''), $codelistMainLev)
                    => fn:string-join('')
            let $stringMain := ($stringMain, $codelistMain) => fn:string-join(' / ')

            (:let $featureName := $node/local-name():)
            let $p := scripts:getParent($node)
            let $id := scripts:getInspireId($p)

            for $sub in $fromDB
                let $q := scripts:getParent($sub)
                let $ic := scripts:getInspireId($q)

                where $id != $ic
                let $stringSub := $sub//*[local-name() = $stringNodes]/data()
                    => fn:string-join(' / ')
                let $codelistSub := $sub//*[local-name() = $codelistNode]
                    //fn:tokenize(@xlink:href/data(), '/')[last()]
                let $codelistSubLev := fn:replace($codelistSub, '[\(\)\.]', '')
                let $locationSub := $sub/*[local-name() = $locationNode]//gml:pos
                let $stringSubLev := (fn:replace($stringSub, ' / ', ''), $codelistSubLev)
                        => fn:string-join('')
                let $stringSub := ($stringSub, $codelistSub) => fn:string-join(' / ')

                let $levRatio := strings:levenshtein(
                    $norm($stringMainLev),
                    $norm($stringSubLev)
                )

                let $stringFlagged := $levRatio >= 0.9
                where $stringFlagged
                (:let $codelistFlagged := if(exists($codelistNode)):)
                    (:then $codelistMain = $codelistSub:)
                    (:else true():)
                (:where $codelistFlagged:)
                let $distance := if(exists($locationNode))
                    then
                        let $main_lat := substring-before($locationMain, ' ')
                        let $main_long := substring-after($locationMain, ' ')
                        let $main_point := <GML:Point srsName="{$srsName[1]}"><GML:coordinates>{$main_long},{$main_lat}</GML:coordinates></GML:Point>

                        let $sub_lat := substring-before($locationSub, ' ')
                        let $sub_long := substring-after($locationSub, ' ')
                        let $sub_point := <GML:Point srsName="{$srsName[1]}"><GML:coordinates>{$sub_long},{$sub_lat}</GML:coordinates></GML:Point>

                        let $dist := round-half-to-even(geo:distance($main_point, $sub_point) * 111319.9, 2)

                        return $dist
                    else
                        '-'

                let $locationFlagged := if(xs:string($distance) = '-')
                    then
                        true()
                    else
                        if($distance < 100) then true() else false()

                where $locationFlagged
                (:where $ic = '0014.FACILITY' and $id = ('0013.FACILITY', '10029.FACILITY', '10125.FACILITY'):)
                return map {
                (:"sort": (7),:)
                "marks" : (6),
                "data" : (
                    replace($id, '\.', ' '),
                    replace($ic, '\.', ' '),
                    ($stringNodes, $codelistNode, $locationNode) => fn:string-join(' / '),
                    <span class="iedreg break">{($stringMain, $locationMain) => fn:string-join(' / ')}</span>,
                    <span class="iedreg break">{($stringSub, $locationSub) => fn:string-join(' / ')}</span>,
                    concat(round-half-to-even($levRatio * 100, 1) || '%', ' / ',
                            (if(xs:string($distance) = '-') then $distance else $distance || 'm')
                    )
                )
                }

    let $hdrs := ('Local ID', 'Local ID (DB)', 'Attribute names',  'Attribute values', 'Attribute values (DB)', 'Similarity / Distance')

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
};

(:~
 : C4.5 Identification of ProductionSite duplicates within the database
 :)

declare function scripts:checkProductionSiteDatabaseDuplicates(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $feature := 'ProductionSite'
    (:let $nodes := ('siteName', 'location'):)
    (:let $attrs := ():)
    let $stringNodes := ('siteName')
    let $locationNode := ('location')
    let $codelistNode := ()
    let $docDB := $scripts:docProdSite

    return scripts:checkDatabaseDuplicates2($refcode, $rulename, $root, $feature,
            $stringNodes, $locationNode, $codelistNode, $docDB)
};

(:~
 : C4.6 Identification of ProductionFacility duplicates within the database
 :)

declare function scripts:checkProductionFacilityDatabaseDuplicates(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $feature := 'ProductionFacility'
    (:let $nodes := ('geometry', 'facilityName', 'parentCompanyName'):)
    (:let $attrs := ('EPRTRAnnexIActivity'):)
    let $stringNodes := ('facilityName', 'parentCompanyName')
    let $locationNode := ('geometry')
    let $codelistNode := ('mainActivity')
    let $docDB := $scripts:docProdFac

    (:return scripts:checkDatabaseDuplicates($refcode, $rulename, $root, $feature,:)
            (:$nodes, $attrs, $docDB):)
    return scripts:checkDatabaseDuplicates2($refcode, $rulename, $root, $feature,
            $stringNodes, $locationNode, $codelistNode, $docDB)
};

(:~
 : C4.7 Identification of ProductionInstallation duplicates within the database
 :)

declare function scripts:checkProductionInstallationDatabaseDuplicates(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $feature := 'ProductionInstallation'
    (:let $nodes := ('pointGeometry', 'installationName'):)
    (:let $attrs := ('IEDAnnexIActivity'):)
    let $stringNodes := ('installationName')
    let $locationNode := ('pointGeometry')
    let $codelistNode := ('mainActivity')

    let $docDB := $scripts:docProdInstall

    (:return scripts:checkDatabaseDuplicates($refcode, $rulename, $root, $feature,:)
            (:$nodes, $attrs, $docDB):)
    return scripts:checkDatabaseDuplicates2($refcode, $rulename, $root, $feature,
            $stringNodes, $locationNode, $codelistNode, $docDB)
};

(:~
 : C4.8 Identification of ProductionInstallationPart duplicates within the database
 :)

declare function scripts:checkProductionInstallationPartDatabaseDuplicates(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $feature := 'ProductionInstallationPart'
    (:let $nodes := ('installationPartName'):)
    (:let $attrs := ('plantType'):)
    let $stringNodes := ('installationPartName')
    let $locationNode := ()
    let $codelistNode := ('plantType')

    let $docDB := $scripts:docProdInstallPart

    (:return scripts:checkDatabaseDuplicates($refcode, $rulename, $root, $feature,:)
            (:$nodes, $attrs, $docDB):)
    return scripts:checkDatabaseDuplicates2($refcode, $rulename, $root, $feature,
            $stringNodes, $locationNode, $codelistNode, $docDB)
};

declare function scripts:checkMissing(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element(),
        $feature as xs:string,
        $allowed as xs:string*,
        $docDB as document-node()
) as element()* {
    let $featureName := 'Production' || functx:capitalize-first($feature)

    let $msg := "There are inspireIDs for " || scripts:makePlural($featureName) || " missing from this submission. Please verify to ensure that no " || scripts:makePlural($featureName) || " have been missed."
    let $type := "blocker"

    let $cntry := scripts:getCountry($root)
    let $lastReportingYear := scripts:getLastYear($root)

    let $seq := $root//*:inspireId
    let $fromDB := database:queryByYear($cntry, $lastReportingYear,
        $docDB, 'inspireId')

    let $data :=
        for $id in $fromDB
        where not($id//*:localId = $seq//*:localId)

        let $p := scripts:getParent($id)
        where $p/local-name() = $featureName

        let $id := $id//*:localId/text()

        let $status := $p//pf:statusType
        let $status := replace($status/@xlink:href, '/+$', '')
        let $status := if (scripts:is-empty($status)) then " " else scripts:normalize($status)

        where not($status = $allowed)
        return map {
        "marks" : (2),
        "data" : (
            $featureName,
            <span class="iedreg nowrap">{$id}</span>,
            $status
        )
        }

    let $hdrs := ('Feature', 'Local ID', 'Status')

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        if (not(database:dbAvailable($docDB))) then
            scripts:noDbWarning($refcode, $rulename)
        else if (empty($lastReportingYear)) then
            scripts:noPreviousYearWarning($refcode, $rulename)
        else
            scripts:renderResult($refcode, $rulename, count($data), 0, 0, $details)
};

(: TODO needs testing :)
declare function scripts:checkMissingSites(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element(),
        $featureName as xs:string,
        $allowed as xs:string*,
        $docDB as document-node()
) as element()* {
    let $msg1 := 'ProductionFacility associated with ProductionSite changed in comparison with the previous year'
    let $msg2 := "There are inspireIDs for " || scripts:makePlural($featureName)
        || " missing from this submission. Please verify to ensure that no "
        || scripts:makePlural($featureName) || " have been missed."
    let $type := "warning"

    let $country := scripts:getCountry($root)
    let $lastYear := scripts:getLastYear($root)

    let $seq := $root//*[local-name() = $featureName]
    let $fromDB := database:queryByYearFeature($country, $lastYear, $docDB)

    let $data1 :=
        for $facility in $seq
            let $inspireId := $facility/*:inspireId//*:localId/data()
            let $hostingSite := $facility/*[local-name() = 'hostingSite']
                    /@xlink:href/data() => functx:if-empty('')
            let $fromDBhostingSite := $fromDB/descendant-or-self::*:ProductionFacility
                [*:inspireId//*:localId = $inspireId]/hostingSite
                    /@xlink:href/data() => functx:if-empty('')

            where not($hostingSite = $fromDBhostingSite)

            return map {
            "marks" : (4),
            "data" : (
                $featureName,
                $inspireId,
                $hostingSite,
                $fromDBhostingSite (:'bla':)
            )
            }

    let $fromDBSite := database:queryByYearFeature($country, $lastYear, $scripts:docProdSite)
    let $data2 :=
        for $fromDbsite in $fromDBSite
            let $inspireIdFromDb := $fromDbsite/*:inspireId//*:localId
            let $inspireId := $root//*:ProductionSite/*:inspireId//*:localId

            let $status := $fromDbsite//pf:statusType
            let $status := replace($status/@xlink:href, '/+$', '')
            let $status := if (scripts:is-empty($status))
                then " "
                else scripts:normalize($status)


            where not($status = $allowed)
            where not($inspireIdFromDb = $inspireId)

            return map {
            "marks" : (2),
            "data" : (
                'InspireId is not found in the XML submission',
                'ProductionSite',
                $inspireIdFromDb
            )
            }

    (:let $data := ($data1, $data2):)
    let $data := $data1

    let $hdrs1 := ('Feature type', 'Local ID', 'Associated site', 'DB Associated site')
    let $hdrs2 := ('Message', 'Feature type', 'Local ID')

    let $details :=
        <div class="iedreg">{
            if (count($data1) gt 0) then scripts:getDetails($msg1, $type, $hdrs1, $data1) else ()
            (:if (count($data2) gt 0) then scripts:getDetails($msg2, $type, $hdrs2, $data2) else ():)
        }</div>
    (:let $details := ():)

    return
        if (not(database:dbAvailable($docDB))) then
            scripts:noDbWarning($refcode, $rulename)
        else if (empty($lastYear)) then
            scripts:noPreviousYearWarning($refcode, $rulename)
        else
            scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
};

(:~
 : C4.9 Missing ProductionSites, previous submissions
 :)

declare function scripts:checkMissingProductionSites(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $feature := 'ProductionFacility'
    let $allowed := ("decommissioned")
    let $docDB := $scripts:docProdFac

    return scripts:checkMissingSites($refcode, $rulename, $root, $feature, $allowed, $docDB)
};

(:~
 : C4.10 Missing ProductionFacilities, previous submissions
 :)

declare function scripts:checkMissingProductionFacilities(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $feature := 'facility'
    let $allowed := ("decommissioned", "notRegulated")
    let $docDB := $scripts:docProdFac

    return scripts:checkMissing($refcode, $rulename, $root, $feature, $allowed, $docDB)
};

(:~
 : C4.11 Missing ProductionInstallations, previous submissions
 :)

declare function scripts:checkMissingProductionInstallations(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $feature := 'installation'
    let $allowed := ("decommissioned", "notRegulated")
    let $docDB := $scripts:docProdInstall

    return scripts:checkMissing($refcode, $rulename, $root, $feature, $allowed, $docDB)
};

(:~
 : C4.12 Missing ProductionInstallationsParts, previous submissions
 :)

declare function scripts:checkMissingProductionInstallationParts(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $feature := 'installationPart'
    let $allowed := ("decommissioned", 'notRegulated')
    let $docDB := $scripts:docProdInstallPart

    return scripts:checkMissing($refcode, $rulename, $root, $feature, $allowed, $docDB)
};

(:~
 : 5. GEOGRAPHICAL AND COORDINATE CHECKS
 :)

declare function scripts:haversine(
        $lat1 as xs:float,
        $lon1 as xs:float,
        $lat2 as xs:float,
        $lon2 as xs:float
) as xs:float {
    let $dlat := ($lat2 - $lat1) * math:pi() div 180
    let $dlon := ($lon2 - $lon1) * math:pi() div 180
    let $rlat1 := $lat1 * math:pi() div 180
    let $rlat2 := $lat2 * math:pi() div 180
    let $a := math:sin($dlat div 2) * math:sin($dlat div 2) + math:sin($dlon div 2) * math:sin($dlon div 2) * math:cos($rlat1) * math:cos($rlat2)
    let $c := 2 * math:atan2(math:sqrt($a), math:sqrt(1 - $a))
    return xs:float($c * 6371.0)
};

declare function scripts:checkRadius(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element(),
        $data as (map(*))*,
        $parentFeature as xs:string,
        $childFeature as xs:string,
        $lowerLimit as xs:float,
        $upperLimit as xs:float
) as element()* {
    let $warn := "The coordinates supplied for the following " || scripts:makePlural($childFeature) || " are outside of a " || $upperLimit || "km radius, of the coordinates supplied for their associated " || scripts:makePlural($parentFeature) || ". Please ensure all coordinates have been inputted correctly."
    let $info := "The coordinates supplied for the following " || scripts:makePlural($childFeature) || " are outside the ideal " || $lowerLimit || "km radius of the coordinates supplied for their associated " || scripts:makePlural($parentFeature) || ". Please ensure all coordinates have been inputted correctly."

    let $yellow :=
        for $m in $data
        let $dist := $m("data")[7]
        where $dist gt $upperLimit
        return $m

    let $blue :=
        for $m in $data
        let $dist := $m("data")[7]
        where $dist le $upperLimit and $dist gt $lowerLimit
        return $m

    let $hdrs := ("Path", "Local ID", "Coordinate",
                "Path", "Local ID", "Coordinate", "Distance (km)")

    let $details :=
        <div class="iedreg">{
            if (count($yellow) gt 0) then scripts:getDetails($warn, "warning", $hdrs, $yellow) else (),
            if (count($blue) gt 0) then scripts:getDetails($info, "info", $hdrs, $blue) else ()
        }</div>

    return
        scripts:renderResult($refcode, $rulename, 0, count($yellow), count($blue), $details)
};

(:~
 : C5.1 ProductionSite radius
 :)

declare function scripts:checkProdutionSiteRadius(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $parentFeature := "ProductionSite"
    let $childFeature := "ProductionFacility"
    let $lowerLimit := 5.0
    let $upperLimit := 10.0

    let $data :=
        for $x in $root//*:ProductionSite
        let $x_id := scripts:getInspireId($x)
        let $x_location := $x/*:location
        let $x_path := scripts:getPath($x_location)

        for $x_coords in $x_location//gml:*/descendant-or-self::*[not(*)]
        let $x_lat := substring-before($x_coords, ' ')
        let $x_long := substring-after($x_coords, ' ')

        for $y in $root//*:ProductionFacility[pf:hostingSite[@xlink:href = '#_' || $x_id]]
        let $y_id := scripts:getInspireId($y)
        let $y_geometry := $y/act-core:geometry
        let $y_path := scripts:getPath($y_geometry)

        for $y_coords in $y_geometry//gml:*/descendant-or-self::*[not(*)]
        let $y_lat := substring-before($y_coords, ' ')
        let $y_long := substring-after($y_coords, ' ')

        let $dist := scripts:haversine(
                xs:float($x_lat), xs:float($x_long),
                xs:float($y_lat), xs:float($y_long)
        )

        return map {
        "marks" : (7),
        "data" : (
            $x_path,
            <span class="iedreg nowrap">{$x_id}</span>,
            $x_coords,
            $y_path,
            <span class="iedreg nowrap">{$y_id}</span>,
            $y_coords,
            $dist
        )
        }

    return
        scripts:checkRadius($refcode, $rulename, $root, $data, $parentFeature, $childFeature, $lowerLimit, $upperLimit)
};

(:~
 : C5.2 ProductionFacility radius
 :)

declare function scripts:checkProdutionFacilityRadius(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $parentFeature := "ProductionFacility"
    let $childFeature := "ProductionInstallation"
    let $lowerLimit := 1.0
    let $upperLimit := 5.0

    let $data :=
        for $x in $root//*:ProductionFacility
        let $x_id := scripts:getInspireId($x)
        let $x_geometry := $x/act-core:geometry
        let $x_path := scripts:getPath($x_geometry)

        for $x_coords in $x_geometry//gml:*/descendant-or-self::*[not(*)]
        let $x_lat := substring-before($x_coords, ' ')
        let $x_long := substring-after($x_coords, ' ')

        for $y_id in $x/pf:groupedInstallation/@xlink:href
        let $y_id := replace(data($y_id), "^#", "")

        for $y in $root//*:ProductionInstallation[@gml:id = $y_id]
        let $y_geometry := $y/pf:pointGeometry
        let $y_path := scripts:getPath($y_geometry)

        for $y_coords in $y_geometry//gml:*/descendant-or-self::*[not(*)]
        let $y_lat := substring-before($y_coords, ' ')
        let $y_long := substring-after($y_coords, ' ')

        let $dist := scripts:haversine(
                xs:float($x_lat), xs:float($x_long),
                xs:float($y_lat), xs:float($y_long)
        )

        return map {
        "marks" : (7),
        "data" : (
            (:$x/local-name(),:)
            $x_path,
            <span class="iedreg break">{replace($x_id, '\.', ' ')}</span>,
            $x_coords,
            (:$y/local-name(),:)
            $y_path,
            <span class="iedreg break">{replace(replace($y_id, '\.', ' '), '^_', '')}</span>,
            $y_coords,
            $dist)
        }

    return
        scripts:checkRadius($refcode, $rulename, $root, $data, $parentFeature, $childFeature, $lowerLimit, $upperLimit)
};

(:~
 : C5.3 ProductionInstallation radius
 :)

declare function scripts:checkProdutionInstallationRadius(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $parentFeature := "ProductionInstallation"
    let $childFeature := "ProductionInstallationPart"
    let $lowerLimit := 0.5
    let $upperLimit := 3.0

    let $data :=
        for $x in $root//*:ProductionInstallation
        let $x_id := scripts:getInspireId($x)
        let $x_geometry := $x/pf:pointGeometry
        let $x_path := scripts:getPath($x_geometry)

        for $x_coords in $x_geometry//gml:*/descendant-or-self::*[not(*)]
        let $x_lat := substring-before($x_coords, ' ')
        let $x_long := substring-after($x_coords, ' ')

        for $y_id in $x/pf:groupedInstallationPart/@xlink:href
        let $y_id := replace(data($y_id), "^#", "")

        for $y in $root//*:ProductionInstallationPart[@gml:id = $y_id]
        let $y_geometry := $y/pf:pointGeometry
        let $y_path := scripts:getPath($y_geometry)

        for $y_coords in $y_geometry//gml:*/descendant-or-self::*[not(*)]
        let $y_lat := substring-before($y_coords, ' ')
        let $y_long := substring-after($y_coords, ' ')

        let $dist := scripts:haversine(
                xs:float($x_lat), xs:float($x_long),
                xs:float($y_lat), xs:float($y_long)
        )

        return map {
        "marks" : (7),
        "data" : (
            (:$x/local-name(), :)
            $x_path,
            replace($x_id, '\.', ' '),
            $x_coords,
            (:$y/local-name(), :)
            $y_path,
            replace(replace($y_id, '\.', ' '), '^_', ''),
            $y_coords,
            $dist
        )
        }

    return
        scripts:checkRadius($refcode, $rulename, $root, $data, $parentFeature, $childFeature, $lowerLimit, $upperLimit)
};

(:~
 : C5.4 Coordinates to country comparison
 :)
declare function scripts:checkCountryBoundary(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := "The following respective fields for spatial objects contain coordinates
    that fall outside of the country's boundary (including territorial waters).
    Please verify and correct coordinates in these fields."
    let $type := 'warning'

    let $srsName :=
        for $srs in distinct-values($root//gml:*/attribute::srsName)
        return replace($srs, '^.*EPSG:+', 'http://www.opengis.net/def/crs/EPSG/0/')

    let $country := $root//*:ReportData/*:countryId/attribute::xlink:href
    let $cntry := tokenize($country, '/+')[last()]
    let $boundary := "boundary-" || lower-case($cntry) || ".gml"
    let $doc := doc("https://converterstest.eionet.europa.eu/xmlfile/" || $boundary)
    let $geom := $doc//GML:FeatureCollection/GML:featureMember/ogr:boundary/ogr:geometryProperty/*

    let $seq := (
        $root//*:location,
        $root//act-core:geometry,
        $root//pf:pointGeometry
    )
    let $distinct_coords := distinct-values($seq//gml:*/descendant-or-self::*[not(*)]/data())

    let $data :=
        for $coord in $distinct_coords
        order by $coord ascending

        let $lat := substring-before($coord, ' ')
        let $long := substring-after($coord, ' ')

        let $point :=
            <GML:Point srsName="{$srsName[1]}">
                <GML:coordinates>{$long},{$lat}</GML:coordinates>
            </GML:Point>

        where not(geo:within($point, $geom))

        let $coords := $seq//gml:pos[./text() = $coord]


        for $c in $coords

        count $count
        (:let $asd:= trace($count, 'count: '):)
        where $count < 1001

        let $parent := scripts:getParent($c)
        let $feature := $parent/local-name()
        let $id := scripts:getInspireId($c/parent::*)
        let $p := scripts:getPath($c)

        return map {
        'marks' : (4, 5),
        'data' : (
            $feature,
            <span class="iedreg nowrap">{$id}</span>,
            $p,
            replace($c/text(), ' ', ', '),
            $cntry)
        }

(: OLD
    let $data :=
        for $g in $seq
        let $parent := scripts:getParent($g)
        let $feature := $parent/local-name()

        for $coords in $g//gml:*/descendant-or-self::*[not(*)]
        let $id := scripts:getInspireId($coords/parent::*)

        let $p := scripts:getPath($coords)

        let $lat := substring-before($coords, ' ')
        let $long := substring-after($coords, ' ')

        let $point :=
            <GML:Point srsName="{$srsName[1]}">
                <GML:coordinates>{$long},{$lat}</GML:coordinates>
            </GML:Point>

        where not(geo:within($point, $geom))

        where not(geo:contains($geom, $point))
        return map {
        'marks' : (4, 5),
        'data' : (
            $feature,
            <span class="iedreg nowrap">{$id}</span>,
            $p,
            replace($coords/text(), ' ', ', '),
            $cntry)
        }
:)

    let $hdrs := ("Feature", "Local ID", "Path", "Coordinates", "Country")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
};

(:~
 : C5.5 Coordinate precision completeness
 :)

declare function scripts:checkCoordinatePrecisionCompleteness(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := "The coordinates are not consistent to 4 decimal places for the following fields. Please ensure all coordinates have been inputted correctly."
    let $type := 'warning'

    let $seq := (
        $root//*:location,
        $root//act-core:geometry,
        $root//pf:pointGeometry
    )

    let $data :=
        for $g in $seq
        let $parent := scripts:getParent($g)
        let $feature := $parent/local-name()

        for $coords in $g//gml:*/descendant-or-self::*[not(*)]
        let $id := scripts:getInspireId($coords/parent::*)

        let $p := scripts:getPath($coords)

        let $lat := substring-before($coords, ' ')
        let $long := substring-after($coords, ' ')
        let $errLat := if (string-length(substring-after($lat, '.')) lt 4) then (4) else ()
        let $errLong := if (string-length(substring-after($long, '.')) lt 4) then (5) else ()
        where (string-length(substring-after($long, '.')) lt 4) or (string-length(substring-after($lat, '.')) lt 4)

        order by $coords descending
        return map {
        'marks' : ($errLong, $errLat),
        'data' : ($feature, <span class="iedreg nowrap">{$id}</span>, $p, $lat, $long)
        }

    let $hdrs := ("Feature", "Local ID", "Path", "Latitude", "Longitude")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
};

(:~
 : C5.6 Coordinate continuity
 :)

declare function scripts:checkCoordinateContinuity(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $blocker := "The coordinates, for the following spatial objects, have changed by over 100m when compared to the master database. Changes in excess of 100m are considered as introducing poor quality data to the master database, please verify the coordinates and ensure they have been inputted correctly."
    let $warn := "The coordinates, for the following spatial objects, have changed by 30-100m compared to the master database. Please verify the coordinates and ensure that they have been inputted correctly."
    let $info := "The coordinates, for the following spatial objects, have changed by 10 -30m compared to the master database. Distance changes between 10-30m may represent coordinate refinement, however please verify the coordinates and ensure that they have been inputted correctly."

    let $srsName :=
        for $srs in distinct-values($root//gml:*/attribute::srsName)
        return replace($srs, '^.*EPSG:+', 'http://www.opengis.net/def/crs/EPSG/0/')

    let $cntry := scripts:getCountry($root)
    let $lastReportingYear := scripts:getLastYear($root)

    let $seq := (
        $root//*:location,
        $root//act-core:geometry,
        $root//pf:pointGeometry
    )

    let $fromDB := (
        database:queryByYear($cntry, $lastReportingYear, $scripts:docProdFac, 'geometry'),
        database:queryByYear($cntry, $lastReportingYear, $scripts:docProdInstall, 'pointGeometry'),
        database:queryByYear($cntry, $lastReportingYear, $scripts:docProdInstallPart, 'pointGeometry'),
        database:queryByYear($cntry, $lastReportingYear, $scripts:docProdSite, 'location')
    )
    let $data :=
        for $x_coords in $seq//gml:*/descendant-or-self::*[not(*)]
        let $p := scripts:getParent($x_coords)
        let $id := scripts:getInspireId($p)/text()
        let $path := scripts:getPath($x_coords)

        let $y_coords :=
            for $y in $fromDB//gml:*/descendant-or-self::*[not(*)]
            let $q := scripts:getParent($y)
            let $ic := scripts:getInspireId($q)/text()

            where $id = $ic

            return $y

        where not(empty($y_coords))

        let $x_lat := substring-before($x_coords, ' ')
        let $x_long := substring-after($x_coords, ' ')
        let $x_point := <GML:Point srsName="{$srsName[1]}"><GML:coordinates>{$x_lat},{$x_long}</GML:coordinates></GML:Point>

        let $y_lat := substring-before($y_coords, ' ')
        let $y_long := substring-after($y_coords, ' ')
        let $y_point := <GML:Point srsName="{$srsName[1]}"><GML:coordinates>{$y_lat},{$y_long}</GML:coordinates></GML:Point>

        let $dist := round-half-to-even(geo:distance($x_point, $y_point) * 111319.9, 2)

        return [
            $p/local-name(),
            $id,
            $path,
            string-join(($x_lat, $x_long), ", "),
            string-join(($y_lat, $y_long), ", "),
            $dist
        ]

    let $red :=
        for $x in $data
        where $x(6) gt 100
        return map {
        "marks" : (6),
        "data" : (
            $x(1),
            <span class="iedreg nowrap">{$x(2)}</span>,
            $x(3),
            <span class="iedreg nowrap">{$x(4)}</span>,
            <span class="iedreg nowrap">{$x(5)}</span>,
            $x(6)
        )
        }

    let $yellow :=
        for $x in $data
        where $x(6) gt 30 and $x(6) le 100
        return map {
        "marks" : (6),
        "data" : (
            $x(1),
            <span class="iedreg nowrap">{$x(2)}</span>,
            $x(3),
            <span class="iedreg nowrap">{$x(4)}</span>,
            <span class="iedreg nowrap">{$x(5)}</span>,
            $x(6)
        )
        }

    let $blue :=
        for $x in $data
        where $x(6) gt 10 and $x(6) le 30
        return map {
        "marks" : (6),
        "data" : (
            $x(1),
            <span class="iedreg nowrap">{$x(2)}</span>,
            $x(3),
            <span class="iedreg nowrap">{$x(4)}</span>,
            <span class="iedreg nowrap">{$x(5)}</span>,
            $x(6)
        )
        }

    let $hdrs := ("Feature", "Local ID", "Path", "Coordinates", "Previous coordinates (DB)", "Difference (meters)")

    let $details :=
        <div class="iedreg">{
            if (empty($red)) then () else scripts:getDetails($blocker, "blocker", $hdrs, $red),
            if (empty($yellow)) then () else scripts:getDetails($warn, "warning", $hdrs, $yellow),
            if (empty($blue)) then () else scripts:getDetails($info, "info", $hdrs, $blue)
        }</div>

    return
        if (not(database:dbAvailable($scripts:docProdSite)))
        then scripts:noDbWarning($refcode, $rulename)
        else if (empty($lastReportingYear))
        then scripts:noPreviousYearWarning($refcode, $rulename)
        else
            scripts:renderResult($refcode, $rulename, count($red), count($yellow), count($blue), $details)
};

(:~
 : C5.7 ProductionSite to ProductionFacility coordinate comparison
 :)

declare function scripts:checkProdutionSiteBuffers(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $warnRadius := 5
    let $infoRadius := 30

    let $warn := "The following ProductionFacilities have coordinates that are within a "
    || $warnRadius || "m radius of the coordinates provided for the associated ProductionSite.
    Please verify the coordinates and ensure that they have been inputted correctly."
    let $info := "The following ProductionFacilities have coordinates that are within a "
    || $infoRadius || "m radius of the coordinates provided for the associated ProductionSite.
    Please verify the coordinates and ensure that they have been inputted correctly."

    let $srsName :=
        for $srs in distinct-values($root//gml:*/attribute::srsName)
        return replace($srs, '^.*EPSG:+', 'http://www.opengis.net/def/crs/EPSG/0/')

    let $data :=
        for $x in $root//*:ProductionSite
        let $x_id := scripts:getInspireId($x)
        let $x_location := $x/*:location
        let $x_path := scripts:getPath($x_location)

        for $x_coords in $x_location//gml:*/descendant-or-self::*[not(*)]
        let $x_lat := substring-before($x_coords, ' ')
        let $x_long := substring-after($x_coords, ' ')

        let $x_point := <GML:Point srsName="{$srsName[1]}"><GML:coordinates>{$x_lat},{$x_long}</GML:coordinates></GML:Point>

        let $facilities :=
            for $y in $root//*:ProductionFacility[pf:hostingSite[@xlink:href = '#_' || $x_id]]
            let $y_id := scripts:getInspireId($y)
            let $y_geometry := $y/act-core:geometry
            let $y_path := scripts:getPath($y_geometry)

            for $y_coords in $y_geometry//gml:*/descendant-or-self::*[not(*)]
            let $y_lat := substring-before($y_coords, ' ')
            let $y_long := substring-after($y_coords, ' ')

            let $y_point := <GML:Point srsName="{$srsName[1]}"><GML:coordinates>{$y_lat},{$y_long}</GML:coordinates></GML:Point>

            return [
                $y/local-name(),
                $y_id,
                $y_point,
                $y_path
            ]

        return ([
            $x/local-name(),
            $x_id,
            $x_point,
            $facilities,
            $x_path
        ])

    let $yellow :=
        for $x in $data
        where not(empty($x(4)))

        let $x_buffer := geo:buffer($x(3), xs:double($warnRadius div 111319.9))

        for $y in $x(4)
        let $y_buffer := geo:buffer($y(3), xs:double($warnRadius div 111319.9))

        where geo:intersects($x_buffer, $y_buffer)
        let $dist := round-half-to-even(geo:distance($x(3), $y(3)) * 111319.9, 2)

        return map {
        "marks" : (7),
        "data" : (
            (:$x(1),:)
            $x(5),
            <span class="iedreg nowrap">{$x(2)}</span>,
            $x(3)/data(),
            (:$y(1),:)
            $y(4),
            <span class="iedreg nowrap">{$y(2)}</span>,
            $y(3)/data(),
            $dist
        )
        }

    let $seen :=
        for $z in $yellow
        return [$z('data')[2]/data(), $z('data')[5]/data()]

    let $blue :=
        for $x in $data
        where not(empty($x(4)))

        let $x_buffer := geo:buffer($x(3), xs:double($infoRadius div 111319.9))

        for $y in $x(4)
        where not([$x(2), $y(2)] = $seen)

        let $y_buffer := geo:buffer($y(3), xs:double($infoRadius div 111319.9))

        where geo:intersects($x_buffer, $y_buffer)
        let $dist := round-half-to-even(geo:distance($x(3), $y(3)) * 111319.9, 2)
        return map {
        "marks" : (7),
        "data" : (
            (:$x(1),:)
            $x(5),
            <span class="iedreg nowrap">{$x(2)}</span>,
            $x(3)/data(),
            (:$y(1),:)
            $y(4),
            <span class="iedreg nowrap">{$y(2)}</span>,
            $y(3)/data(),
            $dist
        )
        }

    let $hdrs := ("Path", "Local ID", "Coordinate",
                    "Path", "Local ID", "Coordinate", "Distance (meters)")

    let $details :=
        <div class="iedreg">{
            if (empty($yellow)) then () else scripts:getDetails($warn, "warning", $hdrs, $yellow),
            if (empty($blue)) then () else scripts:getDetails($info, "info", $hdrs, $blue)
        }</div>

    return
        scripts:renderResult($refcode, $rulename, 0, count($yellow), count($blue), $details)
};

(:~
 : C5.8 ProductionInstallation to ProductionInstallationPart coordinate comparison
 :)

declare function scripts:checkProdutionInstallationPartCoords(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := "The coordinates provided for the following ProductionInstallationParts are identical to the coordinates for the associated ProductionInstallation. Please verify the coordinates and ensure that they have been inputted correctly."
    let $type := "warning"

    let $data :=
        for $x in $root//*:ProductionInstallation
        let $x_id := scripts:getInspireId($x)
        let $x_geometry := $x/pf:pointGeometry
        let $x_path := scripts:getPath($x_geometry)

        where count($x/pf:groupedInstallationPart) gt 1

        for $x_coords in $x_geometry//gml:*/descendant-or-self::*[not(*)]
        for $y_id in $x/pf:groupedInstallationPart/@xlink:href
        let $y_id := replace(data($y_id), "^#", "")

        for $y in $root//*:ProductionInstallationPart[@gml:id = $y_id]
        let $y_geometry := $y/pf:pointGeometry
        let $y_path := scripts:getPath($y_geometry)

        for $y_coords in $y_geometry//gml:*/descendant-or-self::*[not(*)]

        where $x_coords/text() = $y_coords/text()
        return map {
        "marks" : (5),
        "data" : (
            (:$x/local-name(),:)
            $x_path,
            <span class="iedreg nowrap">{$x_id}</span>,
            (:$y/local-name(),:)
            $y_path,
            <span class="iedreg nowrap">{$y_id}</span>,
            replace($x_coords/text(), ' ', ', ')
        )
        }

    let $hdrs := ("Path", "Local ID",
                    "Path", "Local ID", "Coordinates")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
};

(:~
 : 6. ACTIVITY CHECKS
 :)

declare function scripts:checkActivityUniqueness(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element(),
        $featureName as xs:string,
        $activityName as xs:string
) as element()* {
    let $msg := "Each " || $activityName || " should be unique, the following " || scripts:makePlural($featureName) || " share the same main and other Activity. Please evaluate and ensure the inputs for these fields are unique to one another"
    let $type := "blocker"

    let $seq := $root//*[local-name() = $featureName]

    let $data :=
        for $node in $seq
        let $parent := scripts:getParent($node)
        (:let $inspireId := scripts:getInspireId($parent):)
        let $activity := $node//*[local-name() = $activityName]
        let $acts := $activity/descendant-or-self::*[not(*)]

        let $id := scripts:getInspireId($parent)

        let $dups :=
            for $a in functx:non-distinct-values($acts/attribute::*:href)
            return scripts:normalize(data($a))
        where $acts//local-name() => fn:distinct-values() => fn:count() = 2
        for $act in $dups
        return map {
        "marks" : (3),
        "data" : ($featureName, <span class="iedreg nowrap">{$id}</span>, $act)
        }

    let $hdrs := ("Feature", "Local ID", $activityName)

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, count($data), 0, 0, $details)
};

declare function scripts:checkActivityContinuity(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element(),
        $featureName as xs:string,
        $activityName as xs:string,
        $docDB as document-node()
) as element()* {
    let $warn := "There have been changes in the " || $activityName || " field,
      compared to the master database - this field should remain constant over time
      and seldom change, particularly between activity groups. Changes have been noticed
      in the following " || scripts:makePlural($featureName) || ".
      Please ensure all inputs are correct."
    let $info := "There have been changes in the " || $activityName || " field,
      compared to the master database - this field should remain constant over time
      and seldom change. Changes have been noticed in the following "
    || scripts:makePlural($featureName) || ". Please ensure all inputs are correct."

    let $cntry := scripts:getCountry($root)
    let $lastReportingYear := scripts:getLastYear($root)

    let $seq := $root//*[local-name() = $featureName]

    let $fromDB := database:queryByYearFeature($cntry, $lastReportingYear, $docDB)

    let $data :=
        for $feature in $seq
        let $idFeature := scripts:getInspireId($feature)

        for $featureDB in $fromDB
        let $idFeatureDB := scripts:getInspireId($featureDB)

        where $idFeature = $idFeatureDB

        let $featureActivity := $feature//*[local-name() = $activityName]
        let $featureDBActivity := $featureDB//*[local-name() = $activityName]

        for $act in $featureActivity/descendant-or-self::*[not(*)]
        let $pathFeature := scripts:getPath($feature)
        let $pathAct := scripts:getPath($act)

        let $xAct := replace($act/@xlink:href, '/+$', '')
        let $yAct := replace($featureDBActivity/descendant-or-self::*[not(*) and local-name() = $act/local-name()]/@xlink:href, '/+$', '')

        let $xAct :=
            if (scripts:is-empty($xAct)) then
                " "
            else $xAct

        where not(scripts:is-empty($yAct))
        where not($xAct = $yAct)
        where $activityName != 'EPRTRAnnexIActivity'
                or ($activityName = 'EPRTRAnnexIActivity' and $act/local-name() = 'mainActivity')
        return [$feature/local-name(), $idFeature/text(), $act/local-name(), scripts:normalize($xAct), scripts:normalize($yAct)]

    let $yellow :=
        for $x in $data
        where not(tokenize($x(4), "[.()]+")[1] = tokenize($x(5), "[.()]+")[1])
        return map {
        "marks" : (4, 5),
        "data" : ($x(1), $x(2), $x(3), $x(4), $x(5))
        }

    let $blue :=
        for $x in $data
        where tokenize($x(4), "[.()]+")[1] = tokenize($x(5), "[.()]+")[1]
        return map {
        "marks" : (4, 5),
        "data" : ($x(1), $x(2), $x(3), $x(4), $x(5))
        }

    let $hdrs := ("Feature", "Local ID", $activityName, "Value", "Value (DB)")

    let $details :=
        <div class="iedreg">{
            if (empty($yellow)) then () else scripts:getDetails($warn, "warning", $hdrs, $yellow),
            if (empty($blue)) then () else scripts:getDetails($info, "info", $hdrs, $blue)
        }</div>

    return
        if (not(database:dbAvailable($docDB))) then
            scripts:noDbWarning($refcode, $rulename)
        else
            scripts:renderResult($refcode, $rulename, 0, count($yellow), count($blue), $details)
};

(:~
 : C6.1 EPRTRAnnexIActivity uniqueness
 :)

declare function scripts:checkEPRTRAnnexIActivityUniqueness(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $featureName := "ProductionFacility"
    let $activityName := "EPRTRAnnexIActivity"

    return scripts:checkActivityUniqueness($refcode, $rulename, $root, $featureName, $activityName)
};

(:~
 : C6.2 EPRTRAnnexIActivity continuity
 :)

declare function scripts:checkEPRTRAnnexIActivityContinuity(
  $refcode as xs:string,
  $rulename as xs:string,
  $root as element()
) as element()* {
  let $featureName := "ProductionFacility"
  let $activityName := "EPRTRAnnexIActivity"
  let $docDB := $scripts:docProdFac

  return scripts:checkActivityContinuity($refcode, $rulename, $root, $featureName,
            $activityName, $docDB)
};

(:~
 : C6.3 IEDAnnexIActivity uniqueness
 :)

declare function scripts:checkIEDAnnexIActivityUniqueness(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $featureName := "ProductionInstallation"
    let $activityName := "IEDAnnexIActivity"

    return scripts:checkActivityUniqueness($refcode, $rulename, $root, $featureName, $activityName)
};

(:~
 : C6.4 IEDAnnexIActivity continuity
 :)

declare function scripts:checkIEDAnnexIActivityContinuity(
  $refcode as xs:string,
  $rulename as xs:string,
  $root as element()
) as element()* {
  let $featureName := "ProductionInstallation"
  let $activityName := "IEDAnnexIActivity"
  let $docDB := $scripts:docProdInstall

  return scripts:checkActivityContinuity($refcode, $rulename, $root, $featureName,
          $activityName, $docDB)
};

(:~
 : 7. STATUS CHECKS
 :)

declare function scripts:checkStatus(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element(),
        $type as xs:string,
        $parentName as xs:string,
        $childName as xs:string,
        $groupName as xs:string,
        $parentStatus as xs:string,
        $childStatus as xs:string*
) as element()* {
    let $warn := "The '" || $parentStatus || "' statuses, of the following " || scripts:makePlural($parentName) || ", are not consistent with the associated " || scripts:makePlural($childName) || ". Please verify inputs and ensure consistency when classifying a " || $parentName || " and its " || scripts:makePlural($childName) || " as '" || $parentStatus || "'."
    let $error := "The '" || $parentStatus || "' StatusTypes, of the following " || scripts:makePlural($parentName) || ", are not consistent with the associated " || scripts:makePlural($childName) || ". Please verify inputs and ensure consistency, classifying a " || $parentName || "'s " || scripts:makePlural($childName) || " as '" || string-join($childStatus, "' or '") || "' also."

    let $value := "ConditionOfFacilityValue"
    let $valid := scripts:getValidConcepts($value)

    let $data :=
        for $x in $root//*[local-name() = $parentName]
        let $x_id := scripts:getInspireId($x)

        let $x_status := $x/pf:status//pf:statusType
        let $p := scripts:getPath($x_status)

        let $x_status := replace($x_status/@xlink:href, '/+$', '')
        where $x_status = $valid

        let $x_status := scripts:normalize($x_status)
        where $x_status = $parentStatus

        let $children :=
            for $y_id in $x/*[local-name() = $groupName]/@xlink:href
            let $y_id := replace(data($y_id), "^#", "")

            for $y in $root//*[local-name() = $childName][@gml:id = $y_id]
            let $y_status := replace($y/pf:status//pf:statusType/@xlink:href, '/+$', '')
            where $y_status = $valid

            let $y_status := scripts:normalize($y_status)
            where not($y_status = $childStatus)
            return $y_status

        return
            if (not(empty($children))) then
                map {
                "marks" : (4),
                "data" : (
                    $parentName,
                    <span class="iedreg nowrap">{$x_id}</span>,
                    $p,
                    $x_status
                )
                }
            else ()

    let $hdrs := ("Feature", "Local ID", "Path", "Status")

    return
        if ($type = "warning") then
            let $details := scripts:getDetails($warn, $type, $hdrs, $data)
            return scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
        else if ($type = "blocker") then
            let $details := scripts:getDetails($error, $type, $hdrs, $data)
            return scripts:renderResult($refcode, $rulename, count($data), 0, 0, $details)
        else
            scripts:renderResult($refcode, $rulename, 0, 0, 0, ())
};

(:~
 : C7.1 Decommissioned StatusType comparison ProductionFacility and ProductionInstallation
 :)

declare function scripts:checkProductionFacilityDecommissionedStatus(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $parentName := "ProductionFacility"
    let $childName := "ProductionInstallation"
    let $groupName := "groupedInstallation"
    let $parentStatus := "decommissioned"
    let $childStatus := "decommissioned"

    return scripts:checkStatus($refcode, $rulename, $root, "warning", $parentName, $childName, $groupName, $parentStatus, $childStatus)
};

(:~
 : C7.2 Decommissioned StatusType comparison ProductionInstallations and ProductionInstallationParts
 :)

declare function scripts:checkProductionInstallationDecommissionedStatus(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $parentName := "ProductionInstallation"
    let $childName := "ProductionInstallationPart"
    let $groupName := "groupedInstallationPart"
    let $parentStatus := "decommissioned"
    let $childStatus := "decommissioned"

    return scripts:checkStatus($refcode, $rulename, $root, "warning", $parentName, $childName, $groupName, $parentStatus, $childStatus)
};

(:~
 : C7.3 Disused StatusType comparison ProductionFacility and ProductionInstallation
 :)

declare function scripts:checkProductionFacilityDisusedStatus(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $parentName := "ProductionFacility"
    let $childName := "ProductionInstallation"
    let $groupName := "groupedInstallation"
    let $parentStatus := "disused"
    let $childStatus := ("disused", "decommissioned")

    return scripts:checkStatus($refcode, $rulename, $root, "blocker", $parentName, $childName, $groupName, $parentStatus, $childStatus)
};

(:~
 : C7.4 Disused StatusType comparison ProductionInstallations and ProductionInstallationParts
 :)

declare function scripts:checkProductionInstallationDisusedStatus(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $parentName := "ProductionInstallation"
    let $childName := "ProductionInstallationPart"
    let $groupName := "groupedInstallationPart"
    let $parentStatus := "disused"
    let $childStatus := ("disused", "decommissioned")

    return scripts:checkStatus($refcode, $rulename, $root, "blocker", $parentName, $childName, $groupName, $parentStatus, $childStatus)
};

(:~
 : C7.5 Decommissioned to functional plausibility
 :)

declare function scripts:checkFunctionalStatusType(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := "The StatusType, of the following spatial objects, has changed from 'decomissioned' in the previous submission to 'functional' in this current submission. Please verify inputs and ensure consistency with the previous report."
    let $type := "blocker"

    let $cntry := scripts:getCountry($root)
    let $lastReportingYear := scripts:getLastYear($root)

    let $seq := $root//pf:statusType

    let $fromDB := (
        database:queryByYear($cntry, $lastReportingYear, $scripts:docProdFac, "statusType"),
        database:queryByYear($cntry, $lastReportingYear, $scripts:docProdInstall, "statusType"),
        database:queryByYear($cntry, $lastReportingYear, $scripts:docProdInstallPart, "statusType")
    )

    let $value := "ConditionOfFacilityValue"
    let $valid := scripts:getValidConcepts($value)

    let $data :=
        for $x in $seq
        let $p := scripts:getParent($x)
        let $id := scripts:getInspireId($p)

        let $xStatus := replace($x/@xlink:href, '/+$', '')

        where not(scripts:is-empty($xStatus)) and $xStatus = $valid
        let $xStat := scripts:normalize($xStatus)

        for $y in $fromDB
        let $q := scripts:getParent($y)
        let $ic := scripts:getInspireId($q)

        where $id = $ic

        let $yStatus := replace($y/@xlink:href, '/+$', '')

        where not(scripts:is-empty($yStatus)) and $yStatus = $valid
        let $yStat := scripts:normalize($yStatus)

        where $xStat = "functional"
        where $yStat = "decommissioned"

        return map {
        "marks" : (4, 5),
        "data" : (
            $p/local-name(),
            $id/text(),
            scripts:getPath($x),
            $xStat,
            $yStat
        )
        }

    let $hdrs := ("Feature", "Local ID", "Path", "StatusType", "StatusType (DB)")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        if (not(database:dbAvailable($scripts:docProdFac))) then
            scripts:noDbWarning($refcode, $rulename)
        else
            scripts:renderResult($refcode, $rulename, count($data), 0, 0, $details)
};

(:~
 : 8. DATE CHECKS
 :)

declare function scripts:queryDate(
        $root as element(),
        $parentName as xs:string,
        $childName as xs:string,
        $groupName as xs:string,
        $dateName as xs:string
) as (map(*))* {
    for $x in $root//*[local-name() = $parentName]
    let $x_id := scripts:getInspireId($x)
    let $x_date := $x/*[local-name() = $dateName]
    let $x_path := scripts:getPath($x_date)

    where not(scripts:is-empty($x_date))
    let $x_date := xs:date($x_date/text())

    for $y_id in $x/*[local-name() = $groupName]/@xlink:href
    let $y_id := replace(data($y_id), "^#", "")

    for $y in $root//*[local-name() = $childName][@gml:id = $y_id]
    let $y_date := $y/*[local-name() = $dateName]
    let $y_path := scripts:getPath($y_date)

    where not(scripts:is-empty($y_date))
    let $y_date := xs:date($y_date/text())

    where $x_date gt $y_date

    return map {
    "marks" : (3, 6),
    "data" : (
        (:$x/local-name(),:)
        $x_path,
        $x_id,
        $x_date,
        (:$y/local-name(),:)
        $y_path,
        replace($y_id, '^_', ''),
        $y_date
    )
    }
};

(:~
 : C8.1 dateOfStartOperation comparison
 :)

declare function scripts:checkDateOfStartOfOperation(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $dateName := "dateOfStartOfOperation"

    let $msg := "The " || $dateName || " field within the ProductionFacility, ProductionInstallation and ProductionInstallationPart have been queried against each other to check chronology. In the following cases, the ProductionFacility operational start date occurs after that of the associated productionInstallations and/or the ProductionInstallation operational start date occurs after that of the associated ProductionInstallationParts. Please verify all inputs are accurate before submitting."
    let $type := "warning"

    let $data := (
        scripts:queryDate($root, "ProductionFacility", "ProductionInstallation", "groupedInstallation", $dateName),
        scripts:queryDate($root, "ProductionInstallation", "ProductionInstallationPart", "groupedInstallationPart", $dateName)
    )

    let $hdrs := ("Path feature", "Local ID", "Feature date",
                   "Path feature child", "Local ID child", "Feature child date")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
};

(:~
 : C8.2 dateOfStartOperation LCP restriction
 :)

declare function scripts:checkDateOfStartOfOperationLCP(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $dateName := "dateOfStartOfOperation"

    let $msg := "The " || $dateName || " field for the following LCPs are blank. This is a mandatory requirement when reporting an LCP."
    let $type := "blocker"

    let $value := "PlantTypeValue"
    let $valid := scripts:getValidConcepts($value)

    let $seq := $root//*:ProductionInstallationPart/*:plantType

    let $data :=
        for $x in $seq
        let $parent := scripts:getParent($x)
        let $feature := $parent/local-name()
        let $id := scripts:getInspireId($parent)

        let $plant := $x/attribute::*:href
        let $date := $parent/*[local-name() = $dateName]
        let $path := scripts:getPath($date)

        let $p := scripts:getPath($x)
        let $v := scripts:normalize($plant)

        where (scripts:is-empty($date) and ($v = "LCP"))
        return map {
        "marks" : (4),
        "data" : (
            $feature,
            $id,
            $path,
            $date/data(),
            $v
        )
        }

    let $hdrs := ("Feature", "Local ID", "Path", 'Date of start of operation', "Plant type")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, count($data), 0, 0, $details)
};

(:
declare function scripts:checkDateOfGranting(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := "The dateOfGranting does not precede dateOfStartOfOperation for the following ProductionInstallations. It is anticipated that a valid permit will be granted prior to operation, especially when a new ProductionInstallation is reported. Please verify dates and ensure they are correct."
    let $type := "warning"

    let $seq := $root//*:ProductionInstallation/*:permit/*:PermitDetails

    let $asd:= trace($seq, 'seq: ')

    let $data :=
        for $permit in $seq
        let $parent := scripts:getParent($permit)
        let $feature := $parent/local-name()
        let $id := scripts:getGmlId($parent)

        let $p := scripts:getPath($permit)
        let $dateOfGranting := $permit/*:dateOfGranting/text() => xs:date()
        let $dateOfLastUpdate := $parent/*:dateOfLastUpdate/text() => xs:date()

        let $asd:= trace($dateOfGranting, 'dateOfGranting: ')
        let $asd:= trace($dateOfLastUpdate , 'dateOfLastUpdate : ')

        where not(scripts:is-empty($dateOfGranting)) and not(scripts:is-empty($dateOfLastUpdate))

        where $dateOfGranting gt $dateOfLastUpdate
        return map {
        "marks" : (3, 4),
        "data" : ($feature, <span class="iedreg nowrap">{$id}</span>,
            $dateOfGranting, $dateOfLastUpdate)
        }

    let $hdrs := ("Feature", "Local ID", "dateOfGranting", "dateOfStartOfOperation")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
};
:)

(:~
 : C8.3 dateOfStartOperation to dateOfGranting comparison
 :)
declare function scripts:checkPermitDates(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element(),
        $date1 as xs:string,  (: dateOfGranting :)
        $date2 as xs:string  (: dateOfLastUpdate :)
) as element()* {
    let $msg := "The " || $date1 || " does not precede " || $date2 || " for the following
        ProductionInstallations. Please verify dates and ensure they are correct."
    let $type := "warning"

    let $seq := $root//*:ProductionInstallation/*:permit/*:PermitDetails

    let $data :=
        for $permit in $seq
        let $parent := scripts:getParent($permit)
        let $feature := $parent/local-name()
        let $id := scripts:getInspireId($parent)

        let $p := scripts:getPath($permit)
        let $d1 := $permit/*[local-name() = $date1]/text() => xs:date()
        let $d2 := $permit/*[local-name() = $date2]/text() => xs:date()

        where (not(scripts:is-empty($d1)) and not(scripts:is-empty($d2)))

        where $d1 gt $d2
        return map {
        "marks" : (4, 5),
        "data" : ($feature, $id, $p, $d1, $d2)
        }

    let $hdrs := ("Feature", "Local ID", "Path", $date1, $date2)

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
};

(:~
 : C8.3 dateOfGranting plausibility
 :)

declare function scripts:checkDateOfLastReconsideration(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    scripts:checkPermitDates($refcode, $rulename, $root, "dateOfGranting", "dateOfLastUpdate")
};

(:~
 : C8.5 dateOfLastReconsideration plausibility
 :)

declare function scripts:checkDateOfLastUpdate(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    scripts:checkPermitDates($refcode, $rulename, $root, "dateOfLastReconsideration", "dateOfLastUpdate")
};

(:~
 : 9. PERMITS & COMPETENT AUTHORITY CHECKS
 :)

(:~
 : C9.1 competentAuthorityInspections to inspections comparison
 :)

declare function scripts:checkInspections(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := "The competentAuthorityInspections field has not been filled out
        for the following ProductionInstallations where the siteVisits field is
        greater than or equal to 1. Please verify to ensure the competent authority
        for these insepections has been specified in the appropriate fields."
    let $type := "warning"

    let $seq := $root//*:ProductionInstallation

    let $data :=
        for $installation in $seq
        let $feature := $installation/local-name()
        let $id := scripts:getInspireId($installation)

        let $siteVisits := $installation//*:siteVisits//*:siteVisitNumber => fn:number()
        let $authInspections := $installation//*:competentAuthorityInspections
                /*:CompetentAuthority/data() => string-join() => functx:if-empty('')

        where ($siteVisits >= 1) and string-length($authInspections) = 0

        return map {
            "marks" : (3),
            "data" : (
                $feature,
                <span class="iedreg nowrap">{$id}</span>,
                $authInspections,
                $siteVisits
            )
        }

    let $hdrs := ("Feature", "Local ID", "Competent authority inspections", "Site visits")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
};

(:~
 : C9.2 competentAuthorityPermits and permit field comparison
 :)

declare function scripts:checkPermit(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := "The competentAuthorityPermits field has not been filled out for the following ProductionInstallations where a permit action has been detailed. Please verify and ensure that the competent authority for these permits actions is specified."
    let $type := "info"

    let $seq := $root//*:ProductionInstallation

    let $data :=
        for $x in $seq
        let $feature := $x/local-name()
        let $id := scripts:getInspireId($x)

        let $permit := $x/*:permit
        let $authPermits := $x/*:competentAuthorityPermits

        where not(scripts:is-empty($permit)) and scripts:is-empty($authPermits)
        return map {
        "marks" : (3),
        "data" : (
            $feature,
            <span class="iedreg nowrap">{$id}</span>,
            $authPermits => string-join() => functx:if-empty('')
        )
        }

    let $hdrs := ("Feature", "Local ID", "Competent authority permits")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, 0, 0, count($data), $details)
};

(:~
 : C9.3 PermitURL to dateOfGranting comparison
 :)

declare function scripts:checkDateOfGrantingPermitURL(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := "The dateofGranting, for the following ProductionInstallations, has changed from the previous submission, but the PermitURL has remained the same. Please verify and ensure all required changes in the PermitURL field have been made."
    let $type := "info"

    let $docDB := $scripts:docProdInstall
    let $cntry := scripts:getCountry($root)

    let $lastReportingYear := scripts:getLastYear($root)

    let $seq := $root//*:ProductionInstallation

    let $fromDB := database:queryByYearFeature($cntry, $lastReportingYear, $docDB)

    let $data :=
        for $x in $seq
        let $id := scripts:getInspireId($x)

        let $xDate := $x/*:permit//*:dateOfGranting
        let $xUrl := $x/*:permit//*:permitURL

        for $y in $fromDB
        let $ic := scripts:getInspireId($y)

        where $id = $ic

        let $yDate := $y/*:permit//*:dateOfGranting
        let $yUrl := $y/*:permit//*:permitURL

        where not($xDate = $yDate)
        where ($xUrl = $yUrl) or (empty($xUrl) and empty($yUrl))

        let $url := if (scripts:is-empty($xUrl)) then " " else $xUrl/text()
        let $oldDate := if (scripts:is-empty($yDate/text())) then " " else xs:date($yDate/text())
        let $newDate := if (scripts:is-empty($xDate/text())) then " " else xs:date($xDate/text())

        return map {
        "marks" : (3, 5),
        "data" : (
            $x/local-name(),
            $id/text(),
            $newDate,
            $oldDate,
            $url
        )
        }

    let $hdrs := ("Feature", "Local ID", "dateofGranting", "dateofGranting (DB)", "permitURL")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        if (not(database:dbAvailable($docDB))) then
            scripts:noDbWarning($refcode, $rulename)
        else
            scripts:renderResult($refcode, $rulename, 0, 0, count($data), $details)
};

(:~
    9.5 enforcementAction to permitGranted comparison
:)

declare function scripts:checkEnforcementAction(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := "The enforcementAction attribute must be populated with a description
        of what enforcement action has been taken for the following ProductionInstallations."
    let $type := "warning"
    let $seq := $root//*:ProductionInstallation//*[local-name() = 'permit']

    let $data :=
        for $permit in $seq
            let $parent := scripts:getParent($permit)
            let $id := scripts:getInspireId($parent)
            let $permitGranted := $permit//*:permitGranted

            where $permitGranted = 'false'
            let $enforcement := $permit//*:enforcementAction => functx:if-empty('')
            where $enforcement = ''
            let $path := scripts:getPath($permit)

            return map {
                "marks": (5),
                "data": (
                    $parent/local-name(),
                    $id,
                    $path,
                    $enforcement,
                    $permitGranted
                )
            }

    let $hdrs := ("Feature", "Local ID", "Path", "Enforcement action", "Permit granted")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
};
(:~
    9.6 StricterPermitConditions
:)

declare function scripts:checkStricterPermitConditions(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := "The BATAEL attribute within the stricterPermitConditions data type
        must be populated for the following ProductionInstallations."
    let $type := "blocker"
    let $seq := $root//*:ProductionInstallation//*[local-name() = 'stricterPermitConditions']

    let $data :=
        for $stricterPermit in $seq
            let $parent := scripts:getParent($stricterPermit)
            let $id := scripts:getInspireId($parent)

            let $indicator := $stricterPermit//*:stricterPermitConditionsIndicator
            let $batael := $stricterPermit//*:BATAEL
            let $path := scripts:getPath($batael)

            where $indicator = 'true' and string-length($batael/@xlink:href) = 0

            return map {
                "marks": (5),
                "data": (
                    $parent/local-name(),
                    $id,
                    $path,
                    $indicator,
                    $batael/@xlink:href
                )
            }

    let $hdrs := ("Feature", "Local ID", "Path", "BATAEL", "Stricter permit conditions indicator")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, count($data), 0, 0, $details)
};


(:~
 : 10. DEROGATION CHECKS
 :)

(:~
 : C10.1 BATDerogationIndicitor to dateOfGranting comparison
 :)

declare function scripts:checkBATPermit(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := "When the BATDerogationIndicator Boolean is 'true', the Boolean for permitGranted should also be 'true'. The Boolean fields within the following ProductionInstallations are not consistent with this rule. Please verify and ensure all information is correct."
    let $type := "info"

    let $seq := $root//*:ProductionInstallation

    let $data :=
        for $x in $seq
        let $id := scripts:getInspireId($x)

        let $bat := $x//*:BATDerogationIndicator
        where $bat = 'true'
        let $permit := $x/*:permit//*:permitGranted
        where $permit = 'false'
        let $path := scripts:getPath($permit)

        return map {
            "marks" : (5),
            "data" : (
                $x/local-name(),
                $id,
                $path,
                $bat,
                $permit
)
        }

    let $hdrs := ("Feature", "Local ID", "Path", "permitGranted", "BATDerogationIndicator")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, 0, 0, count($data), $details)
};

(:~
    C10.2 BATDerogation
:)

declare function scripts:checkBATDerogation(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := "For the following ProductionInstallations the BATAEL or publicReasonURL
        attributes, within the BATDerogationType data type, must be populated."
    let $type := "blocker"

    let $seq := $root//*:ProductionInstallation/*:BATDerogation
    let $attrs := ('BATAEL', 'publicReasonURL')

    let $data :=
        for $batDerogation in $seq
        let $batDerogInd := $batDerogation//*:BATDerogationIndicator/data()

        where $batDerogInd = 'true'
        let $parent := scripts:getParent($batDerogation)
        let $id := scripts:getInspireId($parent)
        for $attr in $attrs
            let $attrValue := if($attr = 'BATAEL')
                then $batDerogation//*[local-name() = $attr]/@xlink:href
                else $batDerogation//*[local-name() = $attr]/data()
            where $attrValue => string-length() = 0
            let $path := scripts:getPath($batDerogation//*[local-name() = $attr])

            return map {
                "marks" : (4),
                "data" : (
                    $parent/local-name(),
                    $id,
                    $path,
                    $attr
                )
            }

    let $hdrs := ("Feature", "Local ID", "Path", "Attribute")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, count($data), 0, 0, $details)
};

(:~
 : C10.2(old) dateOfGranting to Transitional National Plan comparison
 :)

declare function scripts:checkArticle32(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := "The DerogationValue indicates the ProductionInstallation is subject to 'Article 32' of the IED, however the dateOfGranting contains a date that occurs after the 27th November 2002 for the following ProductionInstallationParts. This date is not applicable for the derogation reported. Please verify and ensure dates have been inputted correctly."
    let $type := "warning"

    let $value := "DerogationValue"
    let $valid := scripts:getValidConcepts($value)

    let $data :=
        for $x in $root//*:ProductionInstallation
        let $x_id := scripts:getInspireId($x)
        let $dateOfGranting := $x/*:permit//*:dateOfGranting

        where not(scripts:is-empty($dateOfGranting))
        let $dateOfGranting := xs:date($dateOfGranting/text())

        for $y_id in $x/pf:groupedInstallationPart/@xlink:href
        let $y_id := replace(data($y_id), "^#", "")

        for $y in $root//*:ProductionInstallationPart[@gml:id = $y_id]
        let $derogations := replace($y/*:derogations/@xlink:href, '/+$', '')

        where not(scripts:is-empty($derogations)) and $derogations = $valid
        let $derogations := scripts:normalize($derogations)

        where ($derogations = "Article32") and ($dateOfGranting gt xs:date("2002-11-27"))
        return map {
        "marks" : (4),
        "data" : ($y/local-name(), <span class="iedreg nowrap">{$y_id}</span>, $derogations, $dateOfGranting)
        }

    let $hdrs := ("Feature", "Local ID", "DerogationValue", "dateOfGranting")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
};

declare function scripts:checkDerogationsYear(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element(),
        $article as xs:string,
        $year as xs:integer
) as element()* {
    let $value := "DerogationValue"

    let $msg := "The " || $value || " indicates '" || $article || "' has been reported, however the reporting year is greater than " || $year || ". The derogation in the following fields is no longer valid in respect to the reporting year. Please verify and correct the inputs for these fields."
    let $type := "blocker"

    let $valid := scripts:getValidConcepts($value)

    let $reportingYear := $root//*:ReportData/*:reportingYear

    let $data :=
        for $derogation in $root//*:ProductionInstallationPart/*:derogations
        let $installationPart := scripts:getParent($derogation)
        let $id := scripts:getInspireId($installationPart)
        let $derogations := replace($derogation/@xlink:href, '/+$', '')

        where not(scripts:is-empty($derogations)) and $derogations = $valid
        let $derogations := scripts:normalize($derogations)

        where not(scripts:is-empty($reportingYear))
        let $reportingYear := xs:integer($reportingYear/text())

        where ($derogations = $article) and ($reportingYear gt $year)
        return map {
        "marks" : (4),
        "data" : ($installationPart/local-name(), <span class="iedreg nowrap">{$id}</span>, $derogations, $reportingYear)
        }

    let $hdrs := ("Feature", "Local ID", "DerogationValue", "reportingYear")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, count($data), 0, 0, $details)
};

(:~
 : C10.3 Limited lifetime derogation to reportingYear comparison
 :)

declare function scripts:checkArticle33(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $article := "Article33"
    let $year := 2023

    return scripts:checkDerogationsYear($refcode, $rulename, $root, $article, $year)
};

(:~
 : C10.4 District heating plants derogation to reportingYear comparison
 :)

declare function scripts:checkArticle35(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $article := "Article35"
    let $year := 2022

    return scripts:checkDerogationsYear($refcode, $rulename, $root, $article, $year)
};

declare function scripts:checkDerogationsContinuity(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element(),
        $msg as xs:string,
        $article as xs:string
) as element()* {
    let $cntry := scripts:getCountry($root)
    let $lastReportingYear := scripts:getLastYear($root)
    let $docDB := $scripts:docProdInstallPart
    let $seq := $root//*:derogations

    let $fromDB := database:queryByYear($cntry, $lastReportingYear,
            $docDB, "derogations")

    let $value := "DerogationValue"
    let $valid := scripts:getValidConcepts($value)

    let $data :=
        for $x in $seq
        let $path := scripts:getPath($x)
        let $p := scripts:getParent($x)
        let $id := scripts:getInspireId($p)

        let $xderogations := replace($x/@xlink:href, '/+$', '')

        where not(scripts:is-empty($xderogations)) and $xderogations = $valid
        let $xder := scripts:normalize($xderogations)

        for $y in $fromDB
        let $q := scripts:getParent($y)
        let $ic := scripts:getInspireId($q)

        where $id = $ic

        let $yderogations := replace($y/@xlink:href, '/+$', '')

        where not(scripts:is-empty($yderogations)) and $yderogations = $valid
        let $yder := scripts:normalize($yderogations)

        where $yder = $article
        where not($xder = $article)

        return map {
        "marks" : (4),
        "data" : (
            $p/local-name(),
            $id/text(),
            $path,
            $xder,
            $yder
        )
        }

    let $hdrs := ("Feature", "Local ID", "Path", "DerogationValue", "DerogationValue (DB)")

    let $details := scripts:getDetails($msg, "warning", $hdrs, $data)

    return
        if (not(database:dbAvailable($docDB))) then
            scripts:noDbWarning($refcode, $rulename)
        else
            scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
};

(:~
 : C10.5 Limited life time derogation continuity
 :)

declare function scripts:checkArticle33Continuity(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := "Under certain limited lifetime derogations, the derogation field for all ProductionInstallationParts within the XML submission are anticipated to be the same as ProductionInstallationPart, of the same InspireID, within the master database. The following ProductionInstallationParts do not have the same DerogationValue in the XML submission and the master database. Please verify and ensure all values are inputted correctly."
    let $article := "Article33"

    return scripts:checkDerogationsContinuity($refcode, $rulename, $root, $msg, $article)
};

(:~
 : C10.6 District heat plant derogation continuity
 :)

declare function scripts:checkArticle35Continuity(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := "Under the district heat plant derogation, the derogation field for all ProductionInstallationParts within the XML submission are anticipated to be the same as ProductionInstallationPart, of the same InspireID, within the master database. The following Installation Parts do not have the same DerogationValue in the XML submission and the master database. Please verify and ensure all values are inputted correctly."
    let $article := "Article35"


    return scripts:checkDerogationsContinuity($refcode, $rulename, $root, $msg, $article)
};

(:~
 : C10.7 Transitional National Plan derogation continuity
 :)

declare function scripts:checkArticle32Continuity(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := "Under Transitional National Plan derogation, the derogation field for all ProductionInstallationParts within the XML submission are anticipated to be the same as ProductionInstallationPart, of the same InspireID, within the master database. The following ProductionInstallationParts do not have the same DerogationValue in the XML submission and the master database. Please verify and ensure all values are inputted correctly."
    let $article := "Article32"

    return scripts:checkDerogationsContinuity($refcode, $rulename, $root, $msg, $article)
};

(:~
 : 11. LCP & WASTE INCINERATOR CHECKS
 :)

(:~
 : C11.1 otherRelevantChapters to plantType comparison
 :)

declare function scripts:checkRelevantChapters(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := "The following ProductionInstallations does not have at least one
    PlantTypeValues that is consistent with the chapter specified
    in the otherRelevantChapters field.
    Please verify and ensure where 'Chapter III' is referred to the PlantTypeValue is 'LCP',
    and where 'Chapter IV' is referred the PlantTypeValue is 'WI' or 'co-WI'."
    let $type := "warning"

    let $validChapters := scripts:getValidConcepts("RelevantChapterValue")
    let $validPlants := scripts:getValidConcepts("PlantTypeValue")

    let $seq := $root//*:ProductionInstallation

    let $data :=
        for $node in $seq

        let $gmlid := scripts:getInspireId($node)
        let $chapters := $node/*:otherRelevantChapters/@xlink:href

        for $chapter in $chapters
            let $chapter := replace($chapter, '/+$', '')

            where $chapter = $validChapters

            let $chapter := scripts:normalize($chapter)
            where $chapter = ('ChapterIII', 'ChapterIV')

            let $partTypes :=
                for $partid in $node/*:groupedInstallationPart/@xlink:href
                    let $partid := replace(data($partid), "^#", "")

                    for $part in $root//*:ProductionInstallationPart[@gml:id = $partid]
                        let $plant := replace($part/*:plantType/@xlink:href, '/+$', '')

                        where $plant = $validPlants
                        let $plant := scripts:normalize($plant)
                        return $plant

            let $partType := if($chapter = "ChapterIII")
                then ('LCP')
                else if($chapter = "ChapterIV")
                then ('WI', 'co-WI')
                else ''

            where ((
                    $chapter = "ChapterIII"
                    and functx:value-intersect($partTypes, $partType) => fn:count() = 0)
                or (
                    $chapter = "ChapterIV"
                    and functx:value-intersect($partTypes, $partType) => fn:count() = 0))
            return map {
            "sort" : (2),
            "marks" : (3, 4),
            "data" : (
                $node/local-name(),
                $gmlid,
                $chapter,
                fn:string-join($partType, ', ')
                )
            }

    let $hdrs := ("Feature", "Local ID", "Relevant Chapter", "Plant Type")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
};

(:~
 : C11.2 LCP plantType
 :)

declare function scripts:checkLCP(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := "When PlantTypeValue is 'LCP' the totalRatedThermalInput
    field should be populated, and nominalCapacity, specificConditions,
    HeatReleaseHazardousWaste, untreatedMunicipalWaste,
    publicDisclosure and publicDisclosureURL fields should not be populated.
    The populated fields for the following ProductionInstallationParts
    do not meet the above criteria. Please verify and ensure the correct
    fields have been populated."

    let $type := "warning"
    let $needed := ('totalRatedThermalInput')
    let $notNeeded := ('nominalCapacity', 'specificConditions',
        'HeatReleaseHazardousWaste', 'untreatedMunicipalWaste',
        'publicDisclosure', 'publicDisclosureURL')

    let $valid := scripts:getValidConcepts("PlantTypeValue")

    let $seq := $root//*:ProductionInstallationPart

    let $data :=
        for $part in $seq
            let $id := scripts:getInspireId($part)
            let $plant := replace($part/*:plantType/@xlink:href, '/+$', '')

            let $neededFound :=
                for $node in $needed
                    let $valuesCount := $part//*[local-name() = $node
                        and functx:if-empty(data(), '') != ''] => fn:count()
                    return if($valuesCount > 0)
                        then 1
                        else ()

            let $notNeededFound :=
                for $node in $notNeeded
                    let $valuesCount := $part//*[local-name() = $node
                        and functx:if-empty(data(), '') != ''] => fn:count()
                    return if($valuesCount > 0)
                        then 1
                        else ()

            where $plant = $valid
            let $plant := scripts:normalize($plant)

            where $plant = "LCP"
                and
                (
                    $neededFound => fn:count() != $needed => fn:count()
                    or $notNeededFound => fn:count() != 0
                )

            return map {
            "marks" : (),
            "data" : ($part/local-name(), <span class="iedreg nowrap">{$id}</span>)
            }

    let $hdrs := ("Feature", "Local ID")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
};

(:~
 : C11.3 totalRatedThermalInput plausibility
 :)

declare function scripts:checkRatedThermalInput(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := "The totalRatedThermalInput fields in this submission contain an integer
    less than 50 or an integer greater than 8500,
    meaning the spatial object is no longer considered an LCP.
    Please verify and ensure the values entered are correct."
    let $type := "warning"

    let $seq := $root//*:ProductionInstallationPart/*:totalRatedThermalInput

    let $data :=
        for $x in $seq
        let $parent := scripts:getParent($x)
        let $feature := $parent/local-name()
        let $id := scripts:getInspireId($parent)

        let $v := xs:float($x => functx:if-empty(0))
        where $v lt 50 or $v gt 8500

        return map {
        "marks" : (3),
        "data" : ($feature, <span class="iedreg nowrap">{$id}</span>, $v)
        }

    let $hdrs := ("Feature", "Local ID", "totalRatedThermalInput")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
};

(:~
 : C11.4 WI plantType
 :)

declare function scripts:checkWI(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $plantTypes := ('WI', 'co-WI')
    let $reportingYear := $root//*:reportingYear/data()
    let $needed2017 := ('nominalCapacity')
    let $needed2018 := ('heatReleaseHazardousWaste', 'untreatedMunicipalWaste',
        'publicDisclosure', 'publicDisclosureURL')
    let $notNeeded := ('totalRatedThermalInput', 'derogations')
    let $needed := if($reportingYear = 2017)
        then $needed2017
        else ($needed2017, $needed2018)

    let $msg := "When PlantTypeValue is 'WI' or 'co-WI' " || fn:string-join($needed, ', ') ||
        " fields should be populated, and " || fn:string-join($notNeeded, ', ') ||
        " fields should not be populated. The populated fields for the following
        ProductionInstallationParts do not meet the above criteria. Please verify
        and ensure the correct fields have been populated."
    let $type := "warning"

    let $valid := scripts:getValidConcepts("PlantTypeValue")

    let $seq := $root//*:ProductionInstallationPart

    let $data :=
        for $part in $seq
            let $id := scripts:getInspireId($part)
            let $plant := replace($part/*:plantType/@xlink:href, '/+$', '')

            let $neededFound :=
                for $node in $needed
                    let $valuesCount := $part//*[local-name() = $node
                        and (string-length(data()) > 0 or string-length(./@xlink:href) > 0)]
                            => fn:count()
                    return if($valuesCount > 0)
                        then 1
                        else ()

            let $notNeededFound :=
                for $node in $notNeeded
                    let $valuesCount := $part//*[local-name() = $node
                        and (string-length(data()) > 0 or string-length(./@xlink:href) > 0)]
                            => fn:count()
                    return if($valuesCount > 0)
                        then 1
                        else ()

            where $plant = $valid
            let $plant := scripts:normalize($plant)

            where $plant = $plantTypes
                and
                (
                    $neededFound => fn:count() != $needed => fn:count()
                    or $notNeededFound => fn:count() != 0
                )

            (:let $asd := trace($id, 'id:'):)
            (:let $asd := trace($neededFound => fn:count(), 'neededFound:'):)
            (:let $asd := trace($needed => fn:count(), 'needed:'):)
            (:let $asd := trace($notNeededFound => fn:count(), 'notNeededFound:'):)

            return map {
            "marks" : (),
            "data" : ($part/local-name(), <span class="iedreg nowrap">{$id}</span>)
            }

    let $hdrs := ("Feature", "Local ID")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
};

(:~
 : C11.5 nominalCapacity plausibility
 :)

declare function scripts:checkNominalCapacity(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $warn1 := "The integer supplied in the permittedCapacityHazardous
        or permittedCapacityNonHazardous field
        is greater than the integer supplied in the totalNominalCapacityAnyWasteType field,
        for the following ProductionInstallationParts.
        Please review and amend so the permittedCapacityHazardous/permittedCapacityNonHazardous
        field represents an integer less than or equal to the totalNominalCapacityAnyWasteType."

    let $warn2 := "The integer specified in the totalNominalCapacityAnyWasteType field
        exceeds the anticipated maximum threshold of 60. Please verify and ensure the integer
        supplied is correct."
    let $info := "The integer specified in the totalNominalCapacityAnyWasteType field
        is greater than the ideal threshold of 30.
        Please verify and ensure the integer supplied is correct."

    let $seq := $root//*:ProductionInstallationPart/*:nominalCapacity

    let $data :=
        for $node in $seq
            let $totalAnyWaste := $node//*:totalNominalCapacityAnyWasteType/xs:float(.)
            let $hazardous := $node//*:permittedCapacityHazardous/xs:float(.)
            let $nonHazardous := $node//*:permittedCapacityNonHazardous/xs:float(.)
            where $totalAnyWaste >= 30
                or $hazardous > $totalAnyWaste
                or $nonHazardous > $totalAnyWaste
            let $parent := scripts:getParent($node)
            let $feature := $parent/local-name()
            let $id := scripts:getInspireId($parent)

            return map {
            "marks" : (3, 4, 5),
            "data" : (
                $feature,
                $id,
                $hazardous,
                $nonHazardous,
                $totalAnyWaste
            )
            }

    let $yellow1 :=
        for $m in $data
        let $hazardous := $m("data")[3]
        let $nonHazardous := $m("data")[4]
        let $totalAnyWaste := $m("data")[5]
        where $hazardous > $totalAnyWaste or $nonHazardous > $totalAnyWaste
        let $mark1 := if($hazardous > $totalAnyWaste) then (3) else ()
        let $mark2 := if($nonHazardous > $totalAnyWaste) then (4) else ()

        return map {
            "marks" : ($mark1, $mark2),
            "data" : $m("data")
        }

    let $yellow2 :=
        for $m in $data
        let $totalAnyWaste := $m("data")[5]
        where $totalAnyWaste gt 60
        return map {
            "marks" : (5),
            "data" : $m("data")
        }

    let $blue :=
        for $m in $data
        let $totalAnyWaste := $m("data")[5]
        where $totalAnyWaste gt 30 and $totalAnyWaste le 60
        return map {
            "marks" : (5),
            "data" : $m("data")
        }

    let $hdrs := ("Feature", "Local ID", "Permitted hazardous capacity",
        "Permitted non-hazardous capacity", "Total nominal capacity AnyWasteType")

    let $details :=
        <div class="iedreg">{
            if (empty($yellow1)) then () else scripts:getDetails($warn1, "warning", $hdrs, $yellow1),
            if (empty($yellow2)) then () else scripts:getDetails($warn2, "warning", $hdrs, $yellow2),
            if (empty($blue)) then () else scripts:getDetails($info, "info", $hdrs, $blue)
        }</div>

    return
        scripts:renderResult($refcode, $rulename, 0, count(($yellow1, $yellow2)), count($blue), $details)
};

(:~
 : 12. CONFIDENTIALITY CHECKS
 :)

(:~
 : C12.1 Confidentiality restriction
 :)

declare function scripts:checkConfidentialityRestriction(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := "The following ProductionFacilities and/or ProductionInstallations, have claims for confidentiality for the competent authority address. The address details of a competent authority cannot be claimed as confidential. Please leave the confidentialityReason field unpopulated"
    let $type := "blocker"

    let $seq := $root//*:CompetentAuthority

    let $data :=
        for $s in $seq
        let $feature := $s/parent::*/parent::*
        let $reason := $s//*:AddressDetails/*:confidentialityReason

        let $id := scripts:getInspireId($feature)
        let $p := scripts:getPath($reason)
        let $rsn := scripts:normalize(data($reason/attribute::*:href))

        where (not(scripts:is-empty($reason)))
        return map {
        "marks" : (4),
        "data" : ($feature/local-name(), <span class="iedreg nowrap">{$id}</span>, $p, $rsn)
        }

    let $hdrs := ("Feature", "Local ID", "Path", "Confidentiality reason")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, count($data), 0, 0, $details)
};

(:~
 : C12.2 Confidentiality overuse
 :)

declare function scripts:checkConfidentialityOveruse(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) {
    let $warn := "The total amount of data types claiming confidentiality in the XML submission is PERC, which is greater than expected (10% of data types). Please evaluate to determine all inputs are correct and all cliams for confidentiality are necessary."
    let $info := "The total amount of data types claiming confidentiality in the XML submission is PERC, which is greater than ideally anticipated (5% of data types). Please evaluate to determine all inputs are correct and all claims for confidentiality are necessary."

    let $value := "ReasonValue"
    let $valid := scripts:getValidConcepts($value)

    let $seq := (
        $root//*:AddressDetails,
        $root//*:FeatureName,
        $root//*:ParentCompanyDetails
    )

    let $data :=
        for $r in $seq//*:confidentialityReason
        let $parent := scripts:getParent($r)
        let $feature := $parent/local-name()

        let $p := scripts:getPath($r)
        let $id := scripts:getInspireId($parent)

        let $reason := $r/attribute::xlink:href
        let $v := scripts:normalize(data($reason))

        return map {
        "marks" : (4),
        "data" : ($feature, <span class="iedreg nowrap">{$id}</span>, $p, $v)
        }

    let $ratio := count($data) div count($seq)
    let $perc := round-half-to-even($ratio * 100, 1) || '%'

    let $hdrs := ("Feature", "Local ID", "Path", "confidentialityReason")

    return
        if ($ratio gt 0.1) then
            let $msg := replace($warn, 'PERC', $perc)
            let $details := scripts:getDetails($msg, "warning", $hdrs, $data)
            return scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
        else if ($ratio gt 0.05) then
            let $msg := replace($info, 'PERC', $perc)
            let $details := scripts:getDetails($msg, "info", $hdrs, $data)
            return scripts:renderResult($refcode, $rulename, 0, 0, count($data), $details)
        else
            scripts:renderResult($refcode, $rulename, 0, 0, 0, ())
};

(:~
 : 13. OTHER IDENTIFIERS & MISCELLANEOUS CHECKS
 :)

declare function scripts:getIdentifier(
        $file as xs:string,
        $identifier as xs:string
) as element()* {
    let $url := "https://converterstest.eionet.europa.eu/xmlfile/" || $file
    return if (doc-available($url)) then
        doc($url)//*[local-name() = $identifier]
    else if (doc-available($file)) then
            doc($file)//*[local-name() = $identifier]
        else
            ()
};

declare function scripts:checkIdentifier(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element(),
        $feature as xs:string,
        $identifier as xs:string,
        $ids as xs:string*
) as element()* {
    let $msg := "The following " || scripts:makePlural($feature) || " have " || $identifier || " values that are not valid. Please verify an ensure all IDs are correct."
    let $type := "warning"

    let $seq := $root//*[local-name() = $feature]/*[local-name() = $identifier]

    let $data :=
        for $identifier in $seq
        let $parent := scripts:getParent($identifier)
        let $id := scripts:getInspireId($parent)

        let $value := $identifier/text() => functx:if-empty('')
        where $value != '' and not($value = $ids)

        return map {
        "marks" : (3),
        "data" : ($feature, <span class="iedreg nowrap">{$id}</span>, $value)
        }

    let $hdrs := ("Feature", "Local ID", $identifier)

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
};

(:~
 : C13.1 ETSIdentifier validity
 :)

declare function scripts:checkETSIdentifier(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) {
    let $feature := "ProductionInstallation"
    let $identifier := "ETSIdentifier"
    let $ids := scripts:getIdentifier('iedreg-ets.xml', $identifier)/text()

    return scripts:checkIdentifier($refcode, $rulename, $root, $feature, $identifier, $ids)
};

(:~
 : C13.2 eSPIRSId validity
 :)

declare function scripts:checkeSPIRSIdentifier(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) {
    let $feature := "ProductionInstallation"
    let $identifier := "eSPIRSIdentifier"
    let $ids := scripts:getIdentifier('iedreg-espirs.xml', $identifier)/text()

    return scripts:checkIdentifier($refcode, $rulename, $root, $feature, $identifier, $ids)
};

(:~
 : C13.3 ProductionFacility facilityName to parentCompanyName comparison
 :)

declare function scripts:checkFacilityName(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := "The facilityName fields and parentCompany fields are the same for the following ProductionFacilities. Please verify and consider refining either name so that each name is distinct."
    let $type := "info"

    let $seq := $root//*:ProductionFacility

    let $data :=
        for $x in $seq
        let $id := scripts:getInspireId($x)
        let $facilityName := $x/*:facilityName//*:nameOfFeature
        let $companyName := $x/*:parentCompany//*:parentCompanyName

        where not(scripts:is-empty($facilityName)) and not(scripts:is-empty($companyName))
        where ($facilityName/text() = $companyName/text())
        return map {
        "marks" : (3),
        "data" : ($x/local-name(), $id, <span class="iedreg nowrap">{$facilityName/text()}</span>)
        }

    let $hdrs := ("Feature", "Local ID", "facilityName")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, 0, 0, count($data), $details)
};

(:~
 : C13.4 nameOfFeature
 :)

declare function scripts:checkNameOfFeatureContinuity(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := "The names, provided in this XML submission, for the following spatial objects are not the same as the names within the master database. Please verify and ensure that all names have been inputted correctly."
    let $type := "info"

    let $cntry := scripts:getCountry($root)
    let $lastReportingYear := scripts:getLastYear($root)

    let $seq := $root//*:nameOfFeature

    let $fromDB := (
        database:queryByYear($cntry, $lastReportingYear, $scripts:docProdFac, 'nameOfFeature'),
        database:queryByYear($cntry, $lastReportingYear, $scripts:docProdInstall, 'nameOfFeature'),
        database:queryByYear($cntry, $lastReportingYear, $scripts:docProdInstallPart, 'nameOfFeature'),
        database:queryByYear($cntry, $lastReportingYear, $scripts:docProdSite, 'nameOfFeature')
    )

    let $data :=
        for $x in $seq
        let $p := scripts:getParent($x)
        let $id := scripts:getInspireId($p)
        let $path := scripts:getPath($x)

        for $y in $fromDB
        let $q := scripts:getParent($y)
        let $ic := scripts:getInspireId($q)

        where $id = $ic

        let $xName := normalize-space($x/text())
        let $yName := normalize-space($y/text())

        where not($xName = $yName)
        return map {
        "marks" : (4),
        "data" : (
            $p/local-name(),
            $id/text(),
            $path,
            $xName,
            $yName
        )
        }

    let $hdrs := ("Feature", "Local ID", "Path", "nameOfFeature", "nameOfFeature (DB)")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        if (not(database:dbAvailable($scripts:docProdFac))) then
            scripts:noDbWarning($refcode, $rulename)
        else
            scripts:renderResult($refcode, $rulename, 0, 0, count($data), $details)
};

(:~
 : C13.5 reportingYear plausibility
 :)

declare function scripts:checkReportingYear(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := "The XML submission has a different reportingYear to that of Reportnet's envelope year. Please verify and ensure the correct year has been inputted."
    let $type := "blocker"

    let $url := data($root/gml:metaDataProperty/attribute::xlink:href)
    let $envelope := doc($url)/envelope

(:
    let $error :=
        if (scripts:is-empty($envelope)) then
            error(xs:QName('err:FOER0000'), 'Failed to retrieve envelope metadata')
        else
            ()
:)
    let $envelopeYear := $envelope/*:year
    let $envelopeYear := xs:integer($envelopeYear/text())

    let $seq := $root//*:ReportData

    let $data :=
        for $x in $seq
        let $feature := $x/local-name()
        let $id := scripts:getGmlId($x)
        let $p := scripts:getPath($x/*:reportingYear)
        let $reportingYear := xs:integer($x/*:reportingYear/text())

        where not($reportingYear = $envelopeYear)

        return map {
        "marks" : (3, 4),
        "data" : (
            $feature,
            $p,
            $reportingYear,
            $envelopeYear
        )}

    let $hdrs := ("Feature", "Path", "reportingYear", "envelopeYear")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, count($data), 0, 0, $details)
};

(:~
 : C13.6 electronicMailAddress format
 :)

declare function scripts:checkElectronicMailAddressFormat(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := "The email address specified in the electronicMailAddress field, for the following ProductionFacility/ProductionInstallation, does not contain the at (@) symbol and at least one dot (.) after it (e.g. emailaddress@test.com). Please verify and ensure all email addresses are inputted correctly"
    let $type := "info"

    let $seq := $root//*:electronicMailAddress

    let $data :=
        for $r in $seq
        let $parent := scripts:getParent($r)
        let $feature := $parent/local-name()

        let $p := scripts:getPath($r)
        let $id := scripts:getInspireId($parent)
        let $email := $r/text()

        where (not(matches($r, '.+@.+\..{2,63}')))
        return map {
        "marks" : (4),
        "data" : ($feature, <span class="iedreg nowrap">{$id}</span>, $p, $email)
        }

    let $hdrs := ("Feature", "Local ID", "Path", "E-mail address")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, 0, 0, count($data), $details)
};

(:~
 : C13.7 Lack of facility address
 :)

declare function scripts:checkFacilityAddress(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $warn := "The number of ProductionFacilities without the address field populated equals PERC, which exceeds threshold limit 0.7%. Please verify and populate the required address fields."
    let $info := "The number of ProductionFacilities without the address field populated equals PERC, which exceeds recommended limit 0.1%. Please verify and populate the required address fields."

    let $seq := $root//*:ProductionFacility

    let $data :=
        for $f in $seq
        let $inspireId := scripts:getInspireId($f)

        let $p := scripts:getPath($f)
        let $id := scripts:getInspireId($f)

        where (string-length(string-join($f/*:address/*:AddressDetails/*, '')) = 0)
        return map {
        "marks" : (2),
        "data" : ($p, <span class="iedreg nowrap">{$id}</span>)
        }

    let $ratio := count($data) div count($seq)
    let $perc := round-half-to-even($ratio * 100, 1) || '%'

    let $hdrs := ("Path", "Local ID")

    return
        if ($ratio <= 0.001) then
            scripts:renderResult($refcode, $rulename, 0, 0, 0, ())
        else if ($ratio <= 0.007) then
            let $msg := replace($info, 'PERC', $perc)
            let $details := scripts:getDetails($msg, "info", $hdrs, $data)
            return scripts:renderResult($refcode, $rulename, 0, 0, count($data), $details)
        else
            let $msg := replace($warn, 'PERC', $perc)
            let $details := scripts:getDetails($msg, "warning", $hdrs, $data)
            return scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
};

(:~
    C13.8 DateOfStartOfOperation future year
:)

declare function scripts:checkDateOfStartOfOperationFuture(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := "For the following ProductionFacilities, ProductionInstallations
        , ProductionInstallationParts the dateOfStartOfOperation attribute is
        referring to a year which is a future year relative to the year specified
        in the reportingYear attribute."
    let $type := "blocker"
    let $reportingYear := $root//*:reportingYear/xs:float(.)

    let $seq := $root//*:dateOfStartOfOperation

    let $data :=
        for $date in $seq
            let $parent := scripts:getParent($date)
            let $id := scripts:getInspireId($parent)
            (:let $yearFromDate := fn:year-from-dateTime(xs:dateTime($date/data())):)
            let $yearFromDate := $date/data() => fn:substring(1, 4)
                => functx:if-empty(0) => fn:number()

            where $yearFromDate > $reportingYear

            return map {
                "marks": (3),
                "data": (
                    $parent/local-name(),
                    $id,
                    $date,
                    $reportingYear
                )
            }

    let $hdrs := ("Feature", "Local ID", "Date of start of operation", "Reporting year")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, count($data), 0, 0, $details)
};

(:~
 : C13.8(old) Character string space identification
 :)

declare function scripts:checkWhitespaces(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := "The first character, of the following spatial objects' characterStrings, represents a space. Please verify and ensure the CharacterString has been inputted correctly to prevent duplication"
    let $type := "warning"

    let $seq := $root//*

    let $data :=
        for $e in $seq
        let $p := scripts:getPath($e)
        let $whites := <whites>{functx:get-matches-and-non-matches($e/text(), '^\s+')}</whites>
        let $result := <span class="iedreg">&quot;<pre class="iedreg">{replace(replace(replace($whites/match/text(), '\t', '\\t'), '\r', '\\r'), '\n', '\\n')}</pre>{$whites/non-match/text()}&quot;</span>

        where ($e/text() and not($e/*) and not(normalize-space($e) = '') and not(empty($e/text())) and matches($e, '^\s+'))
        return map {
        "marks" : (2),
        "data" : ($p, $result)
        }

    let $hdrs := ("Path", "CharacterString")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
};

(:~
 : C13.9 FeatureName blank check(replaced by ALL fields blank check)
 :)

declare function scripts:checkFeatureNameBlank(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $features := ('site', 'facility', 'installation', 'installationPart')
    let $msg := "For the following ProductionSite, ProductionFacility, ProductionInstallation
and ProductionInstallationPart feature types the nameOfFeature attribute is empty.
Please ensure all mandatory inputs are completed."
    let $type := "blocker"

    let $data :=
        for $feat in $features
        let $featureName := 'Production' || functx:capitalize-first($feat)
        let $name := $feat || 'Name'
        let $seq := $root//*[local-name() = $featureName]
        for $feature in $seq
            let $id := scripts:getInspireId($feature)
            let $nameOfFeature := $feature/*[local-name() = $name]//*:nameOfFeature
                => functx:if-empty('')
            where $nameOfFeature = ''

            return map {
            "marks" : (3),
            "data" : ($featureName, $id, $nameOfFeature)
            }

    let $hdrs := ("Feature", 'Local ID', "Name of feature")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, count($data), 0, 0, $details)
};

(:~
 : C13.9 All fields blank check
 :)

declare function scripts:checkAllFieldsBlank(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $features := ('ProductionSite', 'ProductionInstallation',
        'ProductionFacility', 'ProductionInstallationPart')
    let $seq := $root//*[local-name() = $features]//*[not(*)]
    let $msg := "For following reported fields are empty. Please ensure all mandatory inputs are completed."
    let $type := "warning"
    let $regex := '[0-9a-zA-Z]'

    let $data :=
        for $elem in $seq
        let $feature := scripts:getParent($elem)
        let $id := scripts:getInspireId($feature)
        let $path := scripts:getPath($elem)
        let $value := $elem/data() => functx:if-empty('')
        let $attrValue := $elem/@xlink:href/data() => functx:if-empty('')

        where not(fn:matches($value, $regex) or fn:matches($attrValue, $regex)
                or $elem/@xsi:nil = "true")

        return map {
        "marks" : (4),
        "data" : ($id, $path, $elem/local-name(), $value)
        }

    let $hdrs := ('Local ID', "Path", "Element", "Value")

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, 0, count($data), 0, $details)
};

(:~
    C1.1 2017 reporting year versus 2018 and later reporting years
:)

declare function scripts:check2018year(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := 'The following attributes must be reported for an IED installation'
    let $type := 'blocker'
    let $iedVocab := 'http://dd.eionet.europa.eu/vocabulary/euregistryonindustrialsites/InstallationTypeValue/IED'

    let $mapAttrs := map {
        'ProductionInstallation': ('baselineReportIndicator', 'publicEmissionMonitoring',
            'BATConclusion'),
        'siteVisits': ('siteVisitURL'),
        'BATDerogation': ('publicReasonURL', 'BATAEL', 'derogationDurationStartDate'), (: 'derogationDurationEndDate':)
        'stricterPermitConditions': ('stricterPermitConditionsIndicator', 'article18',
            'article14.4', 'BATAEL')
    }

    let $seq := $root//*:ProductionInstallation

    let $data :=
        for $installation in $seq
            let $featureMain := $installation/local-name()
            let $inspireId := scripts:getInspireId($installation)
            let $installationType := $installation//*:installationType/@xlink:href
            where $installationType = $iedVocab

            for $feature in map:keys($mapAttrs)
                let $featureSubList := $installation/descendant-or-self::*
                        [local-name() = $feature]

                let $featureSubList := if(fn:empty($featureSubList))
                    then <empty/>
                    else $featureSubList

                for $featureSub in $featureSubList
                    let $batDerogInd := $featureSub//*:BATDerogationIndicator/data()
                    where $feature != 'BATDerogation' or
                        ($feature = 'BATDerogation' and $batDerogInd = 'true')

                    for $attr in $mapAttrs?($feature)
                        let $strictPermit := $featureSub//*:stricterPermitConditionsIndicator/data()
                        where $feature != 'stricterPermitConditions' or
                            ($feature = 'stricterPermitConditions' and $attr != 'BATAEL') or
                            ($feature = 'stricterPermitConditions' and $attr = 'BATAEL'
                                    and $strictPermit = 'true')

                        let $attrCount := $featureSub//*[local-name() = $attr
                            and (string-length(.) > 0 or string-length(./@xlink:href) > 0)] => fn:count()

                        where $attrCount = 0
                        return map {
                            "sort": (2),
                            "marks" : (4),
                            "data" : ($featureMain, $inspireId, $feature, $attr)
                        }

    let $hdrs := ('Feature main', 'Local ID', 'Feature sub', 'Attribute')

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, count($data), 0, 0, $details)
};

(:~
    C1.2 Facility Type
:)

declare function scripts:checkFacilityType(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := 'The following attributes must be reported'
    let $type := 'blocker'
    let $eprtrVocab := 'http://dd.eionet.europa.eu/vocabulary/euregistryonindustrialsites/FaciltyTypeValue/EPRTR'

    let $mapAttrs := map {
        'CompetentAuthority': ('organisationName', 'individualName',
            'electronicMailAddress', 'telephoneNo', 'streetName',
            'buildingNumber', 'city', 'postalCode'),
        'ParentCompanyDetails': ('parentCompanyName'),
        'EPRTRAnnexIActivity': ('mainActivity')
    }

    let $seq := $root//*:ProductionFacility

    let $data :=
        for $facility in $seq
            let $featureMain := $facility/local-name()
            let $inspireId := scripts:getInspireId($facility)
            let $facilityType := $facility//*:facilityType/@xlink:href
            where $facilityType = $eprtrVocab

            for $feature in map:keys($mapAttrs)
                let $featureSubList := $facility/descendant-or-self::*
                        [local-name() = $feature]

                let $featureSubList := if(fn:empty($featureSubList))
                    then <empty/>
                    else $featureSubList

                for $featureSub in $featureSubList

                    for $attr in $mapAttrs?($feature)

                        let $attrCount := $featureSub//*[local-name() = $attr
                            and (string-length(.) > 0 or string-length(./@xlink:href) > 0)] => fn:count()

                        where $attrCount = 0
                        return map {
                            "sort": 2,
                            "marks" : (4),
                            "data" : ($featureMain, $inspireId, $feature, $attr)
                        }

    let $hdrs := ('Feature main', 'Local ID', 'Feature sub', 'Attribute')

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, count($data), 0, 0, $details)
};

(:~
    C1.3 Installation Type
:)

declare function scripts:checkInstallationType(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $msg := 'The following attributes must be reported'
    let $type := 'blocker'
    let $installationVocab := 'http://dd.eionet.europa.eu/vocabulary/euregistryonindustrialsites/InstallationTypeValue/IED'

    let $mapAttrs2017 := map {
        'ProductionInstallation': ('baselineReportIndicator'),
        'CompetentAuthority': ('organisationName', 'individualName',
            'electronicMailAddress', 'telephoneNo'),
        'AddressDetails': ('streetName', 'buildingNumber', 'city', 'postalCode'),
        'siteVisits': ('siteVisitNumber'),
        'PermitDetails': ('permitGranted', 'permitReconsidered', 'permitUpdated'),
        'IEDAnnexIActivityType': ('mainActivity')
    }
    let $mapAttrs2018 := map {
        'ProductionInstallation': ('publicEmissionMonitoring', 'BATConclusion'),
        'stricterPermitConditions': ('stricterPermitConditionsIndicator', 'article18',
            'article14.4'),
        'siteVisits': ('siteVisitURL'),
        'BATDerogation': ('publicReasonURL', 'BATAEL', 'derogationDurationStartDate') (: 'derogationDurationEndDate' :)
    }

    let $reportingYear := $root//*:reportingYear/xs:float(.)

    let $seq := $root//*:ProductionInstallation

    let $data2017 :=
        for $installation in $seq
            let $featureMain := $installation/local-name()
            let $inspireId := scripts:getInspireId($installation)
            let $installationType := $installation//*:installationType/@xlink:href
            where $installationType = $installationVocab

            for $feature in map:keys($mapAttrs2017)
                let $featureSubList := $installation/descendant-or-self::*
                        [local-name() = $feature]

                let $featureSubList := if(fn:empty($featureSubList))
                    then <empty/>
                    else $featureSubList

                for $featureSub in $featureSubList

                    for $attr in $mapAttrs2017?($feature)

                        let $attrCount := $featureSub//*[local-name() = $attr
                            and (string-length(.) > 0 or string-length(./@xlink:href) > 0)] => fn:count()

                        where $attrCount = 0
                        return map {
                            "sort": 2,
                            "marks" : (4),
                            "data" : ($featureMain, $inspireId, $feature, $attr)
                        }

    let $data2018 := if($reportingYear < 2018)
        then ()
        else
        for $installation in $seq
            let $featureMain := $installation/local-name()
            let $inspireId := scripts:getInspireId($installation)
            let $installationType := $installation//*:installationType/@xlink:href
            where $installationType = $installationVocab

            for $feature in map:keys($mapAttrs2018)
                let $featureSubList := $installation/descendant-or-self::*
                        [local-name() = $feature]

                let $featureSubList := if(fn:empty($featureSubList))
                    then <empty/>
                    else $featureSubList

                for $featureSub in $featureSubList
                    let $batDerogInd := $featureSub//*:BATDerogationIndicator
                    where $feature != 'BATDerogation' or
                        ($feature = 'BATDerogation' and $batDerogInd = 'true')

                    for $attr in $mapAttrs2018?($feature)

                        let $attrCount := $featureSub//*[local-name() = $attr
                            and (string-length(.) > 0 or string-length(./@xlink:href) > 0)] => fn:count()

                        where $attrCount = 0
                        return map {
                            "sort": 2,
                            "marks" : (3),
                            "data" : ($featureMain, $inspireId, $feature, $attr)
                        }

    let $data := ($data2017, $data2018)

    let $hdrs := ('Feature main', 'Local ID', 'Feature sub', 'Attribute')

    let $details := scripts:getDetails($msg, $type, $hdrs, $data)

    return
        scripts:renderResult($refcode, $rulename, count($data), 0, 0, $details)
};
