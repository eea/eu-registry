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
import module namespace scripts3 = "iedreg-qa3-scripts" at "iedreg-qa3-scripts.xq";
import module namespace common = "iedreg-common" at "iedreg-common.xq";

declare variable $iedreg:checksHistoricalData := (
    'C3.1',
    'C4.5', 'C4.6', 'C4.7','C4.8', 'C4.9', 'C4.10', 'C4.11', 'C4.12',
    'C5.6',
    'C6.2', 'C6.4',
    'C7.5',
    'C9.3',
    'C10.5', 'C10.6', 'C10.7',
    'C13.4'
);

declare variable $iedreg:checks2018 := (
    'C1.1',
    'C9.5', 'C9.6',
    'C10.2'
);
declare variable $iedreg:skipCountries := map {
    'CH': ('C4.9', 'C4.10', 'C4.11', 'C4.12')
};
declare variable $iedreg:run2018checks := true();

(: These checks are active when the script is triggered inside an envelope :)
declare variable $iedreg:envelopeChecks := (
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

declare function iedreg:getLookupTable(
    $countryCode as xs:string,
    $featureName as xs:string
) as document-node() {
    let $location := 'https://staging-datashare.devel5cph.eionet.europa.eu/remote.php/dav/files/'
    let $userEnv := 'XQueryUser'
    let $passwordEnv := 'XQueryPassword'

    let $user := environment-variable($userEnv)
    let $password := environment-variable($passwordEnv)
    let $fileName := concat($countryCode, '_', $featureName, '.xml')
    let $url := concat($location, $user, '/', $fileName)

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

    (:let $status_code := $response[1]/@status:)

    (:return:)
        (:if($status_code = '200'):)
        (:then $response[2]:)
        (:else ():)
};

declare function iedreg:getLookupTableSNV(
    $countryCode as xs:string,
    $featureName as xs:string
) as document-node() {
    let $location := 'https://svn.eionet.europa.eu/repositories/Reportnet/Dataflows/IndustrialSitesEURegistry/xquery/lookup-tables/'

    let $fileName := concat($countryCode, '_', $featureName, '.xml')
    let $url := concat($location, $featureName, '/', $fileName)

    return fn:doc($url)
};

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

declare function iedreg:getNotActive(
) as element(div)* {
    <div class="iedreg">
        <div class="iedreg inner msg gray mnone">
            <span class="iedreg nowrap header">Not active</span>
            <br/>
            <span class="iedreg">This check is active from 2018 reporting year onwards</span>
        </div>
    </div>
};

declare function iedreg:getNotApplicable(
) as element(div)* {
    <div class="iedreg">
        <div class="iedreg inner msg gray mnone">
            <span class="iedreg nowrap header">Not applicable</span>
            <br/>
            <span class="iedreg">This check is not applicable for your country</span>
        </div>
    </div>
};

declare function iedreg:getNotAvailableEnvelope(
) as element(div)* {
    <div class="iedreg">
        <div class="iedreg inner msg gray mnone">
            <span class="iedreg nowrap header">Envelope not available</span>
            <br/>
            <span class="iedreg">This check is not applicable because envelope XML is not available.</span>
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

declare function iedreg:notActive(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $details := iedreg:getNotActive()
    return iedreg:renderResult($refcode, $rulename, 'none', $details)
};

declare function iedreg:notApplicable(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $details := iedreg:getNotApplicable()
    return iedreg:renderResult($refcode, $rulename, 'none', $details)
};

declare function iedreg:notAvailableEnvelope(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $details := iedreg:getNotAvailableEnvelope()
    return iedreg:renderResult($refcode, $rulename, 'none', $details)
};

declare function iedreg:failsafeWrapper(
        $lookupTables as map(*),
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element(),
        $checkFunc as function(map(*), xs:string, xs:string, element()) as element()*
) as element()* {
    try {
        (:let $asd := trace($refcode, '- '):)
        let $reportingYear := $root//*:reportingYear/xs:float(.)
        let $countryCode := tokenize($root//*:countryId/@xlink:href, '/+')[last()]

        let $envelope-url := data($root/gml:metaDataProperty/attribute::xlink:href)
        let $envelope-available := fn:doc-available($envelope-url)
                and fn:not(fn:contains($envelope-url, 'converters'))

        return
            if($refcode = $iedreg:envelopeChecks and fn:not($envelope-available))
                then iedreg:notAvailableEnvelope($refcode, $rulename, $root)
            else if($countryCode = map:keys($iedreg:skipCountries)
                    and $refcode = $iedreg:skipCountries?($countryCode))
                then iedreg:notApplicable($refcode, $rulename, $root)
            else if(($refcode = $iedreg:checks2018 or $refcode = $iedreg:checksHistoricalData)
                    and (not($iedreg:run2018checks) or $reportingYear < 2018))
                then iedreg:notActive($refcode, $rulename, $root)
            else $checkFunc($lookupTables, $refcode, $rulename, $root)
    } catch * {
        let $details := iedreg:getErrorDetails($err:code, $err:description)
        return iedreg:renderResult($refcode, $rulename, 'failed', $details)
    }
};

(:~
   1. DATA CONTROL CHECKS
:)

declare function iedreg:runChecks01($root as element(), $lookupTables) as element()* {
    let $rulename := '1. DATA CONTROL CHECKS'

    return
        <div class="iedreg header">{$rulename}</div>,
    <div class="iedreg table parent">{
        (: new DONE :) iedreg:failsafeWrapper($lookupTables, "C1.1", "2017 reporting year versus 2018 and later reporting years", $root, scripts:check2018year#4),
        (: new DONE :) iedreg:failsafeWrapper($lookupTables, "C1.2", "Facility Type", $root, scripts:checkFacilityType#4),
        (: new DONE :) iedreg:failsafeWrapper($lookupTables, "C1.3", "Installation Type", $root, scripts:checkInstallationType#4)
    }</div>
};


(:~
 : 2. CODE LIST CHECKS
:)

declare function iedreg:runChecks02($root as element(), $lookupTables) as element()* {
    let $rulename := '2. CODE LIST CHECKS'

    return
        <div class="iedreg header">{$rulename}</div>,
    <div class="iedreg table parent">{
        iedreg:failsafeWrapper($lookupTables, "C2.1", "EPRTRAnnexIActivity mainActivity consistency", $root, scripts:checkMainEPRTRAnnexIActivity#4),
        iedreg:failsafeWrapper($lookupTables, "C2.2", "EPRTRAnnexIActivity otherActivity consistency", $root, scripts:checkOtherEPRTRAnnexIActivity#4),
        iedreg:failsafeWrapper($lookupTables, "C2.3", "IEDAnnexIActivity mainActivity consistency", $root, scripts:checkMainIEDAnnexIActivity#4),
        iedreg:failsafeWrapper($lookupTables, "C2.4", "IEDAnnexIActivity otherActivity consistency", $root, scripts:checkOtherIEDAnnexIActivity#4),
        iedreg:failsafeWrapper($lookupTables, "C2.5", "CountryId consistency", $root, scripts:checkCountryId#4),
        iedreg:failsafeWrapper($lookupTables, "C2.6", "reasonValue consistency", $root, scripts:checkReasonValue#4),
        (: new DONE :) iedreg:failsafeWrapper($lookupTables, "C2.7", "FacilityType consistency", $root, scripts:checkFacilityTypeVocab#4),
        (: new DONE :) iedreg:failsafeWrapper($lookupTables, "C2.8", "InstallationType consistency", $root, scripts:checkInstallationTypeVocab#4),
        (: new DONE :) iedreg:failsafeWrapper($lookupTables, "C2.9", "BaselineReport consistency", $root, scripts:checkBaselineReportTypeVocab#4),
        (: new DONE :) iedreg:failsafeWrapper($lookupTables, "C2.10", "BATConclusion consistency", $root, scripts:checkBATConclusionTypeVocab#4),
        (: new DONE :) iedreg:failsafeWrapper($lookupTables, "C2.11", "BATAEL consistency", $root, scripts:checkBATAELTypeVocab#4),
        (: QA3 :) iedreg:failsafeWrapper($lookupTables, "C2.12", "Article51 consistency", $root, scripts3:checkSpecificConditions#4),
        (: QA3 :) iedreg:failsafeWrapper($lookupTables, "C2.13", "ConditionOfFacility consistency", $root, scripts3:checkStatusType#4),
        (: QA3 :) iedreg:failsafeWrapper($lookupTables, "C2.14", "Derogation consistency", $root, scripts3:checkDerogations#4),
        (: QA3 :) iedreg:failsafeWrapper($lookupTables, "C2.15", "PlantType consistency", $root, scripts3:checkPlantType#4),
        (: QA3 :) iedreg:failsafeWrapper($lookupTables, "C2.16", "RelevantChapter consistency", $root, scripts3:checkOtherRelevantChapters#4),
        (: QA3 :) iedreg:failsafeWrapper($lookupTables, "C2.17", "Activity consistency", $root, scripts3:checkActCoreActivity#4)
    }</div>
};

(:~
 : 3. INSPIRE ID CHECKS
 :)

declare function iedreg:runChecks03($root as element(), $lookupTables) as element()* {
    let $rulename := '3. INSPIRE ID CHECKS'

    return
        <div class="iedreg header">{$rulename}</div>,
    <div class="iedreg table parent">{
        iedreg:failsafeWrapper($lookupTables, "C3.1", "High proportion of new inspireIds", $root, scripts:checkAmountOfInspireIds#4),
        iedreg:failsafeWrapper($lookupTables, "C3.2", "ProductionSite inspireId uniqueness", $root, scripts:checkProductionSiteUniqueness#4),
        iedreg:failsafeWrapper($lookupTables, "C3.3", "ProductionFacility inspireId uniqueness", $root, scripts:checkProductionFacilityUniqueness#4),
        iedreg:failsafeWrapper($lookupTables, "C3.4", "ProductionInstallation inspireId uniqueness", $root, scripts:checkProductionInstallationUniqueness#4),
        iedreg:failsafeWrapper($lookupTables, "C3.5", "ProductionInstallationPart inspireId uniqueness", $root, scripts:checkProductionInstallationPartUniqueness#4),
        iedreg:failsafeWrapper($lookupTables, "C3.6", "InspireId blank check", $root, scripts:checkInspireIdBlank#4)
    }</div>
};

(:~
 : 4. DUPLICATE IDENTIFICATION CHECKS
 :)

declare function iedreg:runChecks04($root as element(), $lookupTables) as element()* {
    let $rulename := '4. DUPLICATE IDENTIFICATION CHECKS'

    return
        <div class="iedreg header">{$rulename}</div>,
    <div class="iedreg table parent">{
        (: upd DONE:) iedreg:failsafeWrapper($lookupTables, "C4.1", "Identification of ProductionSite duplicates", $root, scripts:checkProductionSiteDuplicates#4),
        (: upd DONE:) iedreg:failsafeWrapper($lookupTables, "C4.2", "Identification of ProductionFacility duplicates", $root, scripts:checkProductionFacilityDuplicates#4),
        (: upd DONE:) iedreg:failsafeWrapper($lookupTables, "C4.3", "Identification of ProductionInstallation duplicates", $root, scripts:checkProductionInstallationDuplicates#4),
        (: upd DONE:) iedreg:failsafeWrapper($lookupTables, "C4.4", "Identification of ProductionInstallationPart duplicates", $root, scripts:checkProductionInstallationPartDuplicates#4),
        (: upd DONE :) iedreg:failsafeWrapper($lookupTables, "C4.5", "Identification of ProductionSite duplicates within the database", $root, scripts:checkProductionSiteDatabaseDuplicates#4),
        (: upd DONE :) iedreg:failsafeWrapper($lookupTables, "C4.6", "Identification of ProductionFacility duplicates within the database", $root, scripts:checkProductionFacilityDatabaseDuplicates#4),
        (: upd DONE :) iedreg:failsafeWrapper($lookupTables, "C4.7", "Identification of ProductionInstallation duplicates within the database", $root, scripts:checkProductionInstallationDatabaseDuplicates#4),
        (: upd DONE :) iedreg:failsafeWrapper($lookupTables, "C4.8", "Identification of ProductionInstallationPart duplicates within the database", $root, scripts:checkProductionInstallationPartDatabaseDuplicates#4),
        (: upd :) iedreg:failsafeWrapper($lookupTables, "C4.9", "ProductionSite and Facility Continuity", $root, scripts:checkMissingProductionSites#4),
        (: upd DONE :) iedreg:failsafeWrapper($lookupTables, "C4.10", "Missing ProductionFacilities, previous submissions", $root, scripts:checkMissingProductionFacilities#4),
        (: upd DONE :) iedreg:failsafeWrapper($lookupTables, "C4.11", "Missing ProductionInstallations, previous submissions", $root, scripts:checkMissingProductionInstallations#4),
        (: upd DONE :) iedreg:failsafeWrapper($lookupTables, "C4.12", "Missing ProductionInstallationsParts, previous submissions", $root, scripts:checkMissingProductionInstallationParts#4)
    }</div>
};

(:~
 : 5. GEOGRAPHICAL AND COORDINATE CHECKS
 :)

declare function iedreg:runChecks05($root as element(), $lookupTables) as element()* {
    let $rulename := '5. GEOGRAPHICAL AND COORDINATE CHECKS'

    return
        <div class="iedreg header">{$rulename}</div>,
    <div class="iedreg table parent">{
        iedreg:failsafeWrapper($lookupTables, "C5.1", "ProductionSite radius", $root, scripts:checkProdutionSiteRadius#4),
        iedreg:failsafeWrapper($lookupTables, "C5.2", "ProductionFacility radius", $root, scripts:checkProdutionFacilityRadius#4),
        iedreg:failsafeWrapper($lookupTables, "C5.3", "ProductionInstallation radius", $root, scripts:checkProdutionInstallationRadius#4),
        iedreg:failsafeWrapper($lookupTables, "C5.4", "Coordinates to country comparison", $root, scripts:checkCountryBoundary#4),
        iedreg:failsafeWrapper($lookupTables, "C5.5", "Coordinate precision completeness", $root, scripts:checkCoordinatePrecisionCompleteness#4),
        iedreg:failsafeWrapper($lookupTables, "C5.6", "Coordinate continuity", $root, scripts:checkCoordinateContinuity#4),
        iedreg:failsafeWrapper($lookupTables, "C5.7", "ProductionSite to ProductionFacility coordinate comparison", $root, scripts:checkProdutionSiteBuffers#4),
        iedreg:failsafeWrapper($lookupTables, "C5.8", "ProductionInstallation to ProductionInstallationPart coordinate comparison", $root, scripts:checkProdutionInstallationPartCoords#4)
    }</div>
};

(:~
 : 6. ACTIVITY CHECKS
 :)

declare function iedreg:runChecks06($root as element(), $lookupTables) as element()* {
    let $rulename := '6. ACTIVITY CHECKS'

    return
        <div class="iedreg header">{$rulename}</div>,
    <div class="iedreg table parent">{
        (: upd DONE :) iedreg:failsafeWrapper($lookupTables, "C6.1", "EPRTRAnnexIActivity uniqueness", $root, scripts:checkEPRTRAnnexIActivityUniqueness#4),
        iedreg:failsafeWrapper($lookupTables, "C6.2", "EPRTRAnnexIActivity continuity", $root, scripts:checkEPRTRAnnexIActivityContinuity#4),
        (: upd DONE :) iedreg:failsafeWrapper($lookupTables, "C6.3", "IEDAnnexIActivity uniqueness", $root, scripts:checkIEDAnnexIActivityUniqueness#4),
        iedreg:failsafeWrapper($lookupTables, "C6.4", "IEDAnnexIActivity continuity", $root, scripts:checkIEDAnnexIActivityContinuity#4)
    }</div>
};

(:~
 : 7. STATUS CHECKS
 :)

declare function iedreg:runChecks07($root as element(), $lookupTables) as element()* {
    let $rulename := '7. STATUS CHECKS'

    return
        <div class="iedreg header">{$rulename}</div>,
    <div class="iedreg table parent">{
        iedreg:failsafeWrapper($lookupTables, "C7.1", "Decommissioned StatusType comparison ProductionFacility and ProductionInstallation", $root, scripts:checkProductionFacilityDecommissionedStatus#4),
        iedreg:failsafeWrapper($lookupTables, "C7.2", "Decommissioned StatusType comparison ProductionInstallations and ProductionInstallationParts", $root, scripts:checkProductionInstallationDecommissionedStatus#4),
        iedreg:failsafeWrapper($lookupTables, "C7.3", "Disused StatusType comparison ProductionFacility and ProductionInstallation", $root, scripts:checkProductionFacilityDisusedStatus#4),
        iedreg:failsafeWrapper($lookupTables, "C7.4", "Disused StatusType comparison ProductionInstallations and ProductionInstallationParts", $root, scripts:checkProductionInstallationDisusedStatus#4),
        iedreg:failsafeWrapper($lookupTables, "C7.5", "Decommissioned to functional plausibility", $root, scripts:checkFunctionalStatusType#4)
    }</div>
};

(:~
 : 8. DATE CHECKS
 :)

declare function iedreg:runChecks08($root as element(), $lookupTables) as element()* {
    let $rulename := '8. DATE CHECKS'

    return
        <div class="iedreg header">{$rulename}</div>,
    <div class="iedreg table parent">{
        iedreg:failsafeWrapper($lookupTables, "C8.1", "dateOfStartOfOperation comparison", $root, scripts:checkDateOfStartOfOperation#4),
        iedreg:failsafeWrapper($lookupTables, "C8.2", "dateOfStartOfOperation LCP restriction", $root, scripts:checkDateOfStartOfOperationLCP#4),
        (: removed :) (:iedreg:failsafeWrapper($lookupTables, "C8.3", "dateOfStartOfOperation to dateOfGranting comparison", $root, scripts:checkDateOfGranting#4),:)
        (: upd DONE :) iedreg:failsafeWrapper($lookupTables, "C8.3", "dateOfGranting plausibility", $root, scripts:checkDateOfLastReconsideration#4)
        (: removed :) (:iedreg:failsafeWrapper($lookupTables, "C8.4", "dateOfLastReconsideration plausibility", $root, scripts:checkDateOfLastUpdate#4):)
    }</div>
};

(:~
 : 9. PERMITS & COMPETENT AUTHORITY CHECKS
 :)

declare function iedreg:runChecks09($root as element(), $lookupTables) as element()* {
    let $rulename := '9. PERMITS &amp; COMPETENT AUTHORITY CHECKS'

    return
        <div class="iedreg header">{$rulename}</div>,
    <div class="iedreg table parent">{
        (: upd DONE :) iedreg:failsafeWrapper($lookupTables, "C9.1", "competentAuthorityInspections to inspections comparison", $root, scripts:checkInspections#4),
        iedreg:failsafeWrapper($lookupTables, "C9.2", "competentAuthorityPermits and permit field comparison", $root, scripts:checkPermit#4),
        iedreg:failsafeWrapper($lookupTables, "C9.3", "permitURL to dateOfGranting comparison", $root, scripts:checkDateOfGrantingPermitURL#4),
        (: new DONE :) iedreg:failsafeWrapper($lookupTables, "C9.5", "enforcementAction to permitGranted comparison", $root, scripts:checkEnforcementAction#4),
        (: new DONE :) iedreg:failsafeWrapper($lookupTables, "C9.6", "StricterPermitConditions", $root, scripts:checkStricterPermitConditions#4)
    }</div>
};

(:~
 : 10. DEROGATION CHECKS
 :)

declare function iedreg:runChecks10($root as element(), $lookupTables) as element()* {
    let $rulename := '10. DEROGATION CHECKS'

    return
        <div class="iedreg header">{$rulename}</div>,
    <div class="iedreg table parent">{
        iedreg:failsafeWrapper($lookupTables, "C10.1", "BATDerogationIndicator to permitGranted comparison", $root, scripts:checkBATPermit#4),
        (: new DONE :) iedreg:failsafeWrapper($lookupTables, "C10.2", "BATDerogation", $root, scripts:checkBATDerogation#4),
        (: removed :) (:iedreg:failsafeWrapper($lookupTables, "C10.2", "dateOfGranting to Transitional National Plan comparison", $root, scripts:checkArticle32#4),:)
        iedreg:failsafeWrapper($lookupTables, "C10.3", "Limited lifetime derogation to reportingYear comparison", $root, scripts:checkArticle33#4),
        iedreg:failsafeWrapper($lookupTables, "C10.4", "District heating plants derogation to reportingYear comparison", $root, scripts:checkArticle35#4),
        iedreg:failsafeWrapper($lookupTables, "C10.5", "Limited life time derogation continuity", $root, scripts:checkArticle33Continuity#4),
        iedreg:failsafeWrapper($lookupTables, "C10.6", "District heat plant derogation continuity", $root, scripts:checkArticle35Continuity#4),
        iedreg:failsafeWrapper($lookupTables, "C10.7", "Transitional National Plan derogation continuity", $root, scripts:checkArticle32Continuity#4)
    }</div>
};

(:~
 : 11. LCP & WASTE INCINERATOR CHECKS
 :)

declare function iedreg:runChecks11($root as element(), $lookupTables) as element()* {
    let $rulename := '11. LCP &amp; WASTE INCINERATOR CHECKS'

    return
        <div class="iedreg header">{$rulename}</div>,
    <div class="iedreg table parent">{
        (: upd DONE :) iedreg:failsafeWrapper($lookupTables, "C11.1", "otherRelevantChapters to plantType comparison", $root, scripts:checkRelevantChapters#4),
        (: upd DONE :) iedreg:failsafeWrapper($lookupTables, "C11.2", "LCP plantType", $root, scripts:checkLCP#4),
        iedreg:failsafeWrapper($lookupTables, "C11.3", "totalRatedThermalInput plausibility", $root, scripts:checkRatedThermalInput#4),
        (: upd DONE :) iedreg:failsafeWrapper($lookupTables, "C11.4", "WI plantType", $root, scripts:checkWI#4),
        (: upd DONE :) iedreg:failsafeWrapper($lookupTables, "C11.5", "nominalCapacity plausibility", $root, scripts:checkNominalCapacity#4)
    }</div>
};

(:~
 : 12. CONFIDENTIALITY CHECKS
 :)

declare function iedreg:runChecks12($root as element(), $lookupTables) as element()* {
    let $rulename := "12. CONFIDENTIALITY CHECKS"

    return
        <div class="iedreg header">{$rulename}</div>,
    <div class="iedreg table parent">{
        iedreg:failsafeWrapper($lookupTables, "C12.1", "Confidentiality restriction", $root, scripts:checkConfidentialityRestriction#4),
        iedreg:failsafeWrapper($lookupTables, "C12.2", "Confidentiality overuse", $root, scripts:checkConfidentialityOveruse#4)
    }</div>
};

(:~
 : 13. OTHER IDENTIFIERS & MISCELLANEOUS CHECKS
 :)

declare function iedreg:runChecks13($root as element(), $lookupTables) as element()* {
    let $rulename := '13. OTHER IDENTIFIERS &amp; MISCELLANEOUS CHECKS'

    return
        <div class="iedreg header">{$rulename}</div>,
    <div class="iedreg table parent">{
        (: upd DONE :) iedreg:failsafeWrapper($lookupTables, "C13.1", "ETSIdentifier validity", $root, scripts:checkETSIdentifier#4),
        (: upd DONE :) iedreg:failsafeWrapper($lookupTables, "C13.2", "eSPIRSId validity", $root, scripts:checkeSPIRSIdentifier#4),
        iedreg:failsafeWrapper($lookupTables, "C13.3", "ProductionFacility facilityName to parentCompanyName comparison", $root, scripts:checkFacilityName#4),
        iedreg:failsafeWrapper($lookupTables, "C13.4", "nameOfFeature", $root, scripts:checkNameOfFeatureContinuity#4),
        iedreg:failsafeWrapper($lookupTables, "C13.5", "reportingYear plausibility", $root, scripts:checkReportingYear#4),
        iedreg:failsafeWrapper($lookupTables, "C13.6", "electronicMailAddress format", $root, scripts:checkElectronicMailAddressFormat#4),
        iedreg:failsafeWrapper($lookupTables, "C13.7", "Lack of facility address", $root, scripts:checkFacilityAddress#4),
        (: new DONE :) iedreg:failsafeWrapper($lookupTables, "C13.8", "DateOfStartOfOperation future year", $root, scripts:checkDateOfStartOfOperationFuture#4),
        (: removed :) (:iedreg:failsafeWrapper($lookupTables, "C13.8", "Character string space identification", $root, scripts:checkWhitespaces#4):)
        (: new :) iedreg:failsafeWrapper($lookupTables, "C13.9", "FeatureName blank check", $root, scripts:checkFeatureNameBlank#4),
        (: new :) iedreg:failsafeWrapper($lookupTables, "C13.10", "All fields blank check", $root, scripts:checkAllFieldsBlank#4)
    }</div>
};

(:~
 : 14. OTHER CHECKS QA3
 :)

declare function iedreg:runChecks14($root as element(), $lookupTables) as element()* {
    let $rulename := '14. GML Validation Checks'

    return
        <div class="iedreg header">{$rulename}</div>,
    <div class="iedreg table parent">{
        iedreg:failsafeWrapper($lookupTables, "C14.1", "reportData validity", $root, scripts3:checkReportData#4),
        iedreg:failsafeWrapper($lookupTables, "C14.2", "hostingSite position validity", $root, scripts3:checkeHostingSite #4),
        iedreg:failsafeWrapper($lookupTables, "C14.3", "hostingSite xlink:href validity", $root, scripts3:checkeHostingSiteHref#4),
        iedreg:failsafeWrapper($lookupTables, "C14.4", "ProductionInstallation gml:id validity", $root, scripts3:checkGroupedInstallation#4),
        iedreg:failsafeWrapper($lookupTables, "C14.5", "groupedInstallation xlink:href validity", $root, scripts3:checkGroupedInstallationHref#4),
        (: removed :)(:iedreg:failsafeWrapper($lookupTables, "C14.6", "act-core:geometry validity", $root, scripts3:checkActCoreGeometry#4),:)
        (: 2.17 :) (:iedreg:failsafeWrapper($lookupTables, "C14.7", "act-core:activity validity", $root, scripts3:checkActCoreActivity#4),:)
        iedreg:failsafeWrapper($lookupTables, "C14.8", "ProductionInstallationPart gml:id validity", $root, scripts3:checkGroupedInstallationPart#4),
        iedreg:failsafeWrapper($lookupTables, "C14.9", "pf:groupedInstallationPart xlink:href validity", $root, scripts3:checkGroupedInstallationPartHref#4)
        (: removed :)(:iedreg:failsafeWrapper($lookupTables, "C14.10", "pf:status validity", $root, scripts3:checkStatusNil#4),:)
        (: removed :)(:iedreg:failsafeWrapper($lookupTables, "C14.11", "pf:pointGeometry validity", $root, scripts3:checkePointGeometry#4):)
        (: 2.16 :) (:iedreg:failsafeWrapper($lookupTables, "C14.12", "otherRelevantChapters consistency", $root, scripts3:checkOtherRelevantChapters#4),:)
        (: 2.13 :) (:iedreg:failsafeWrapper($lookupTables, "C14.13", "statusType consistency", $root, scripts3:checkStatusType#4),:)
        (: 2.15 :) (:iedreg:failsafeWrapper($lookupTables, "C14.14", "plantType consistency", $root, scripts3:checkPlantType#4),:)
        (: 2.14 :) (:iedreg:failsafeWrapper($lookupTables, "C14.15", "derogations consistency", $root, scripts3:checkDerogations#4),:)
        (: 2.12 :) (:iedreg:failsafeWrapper($lookupTables, "C14.16", "specificConditions consistency", $root, scripts3:checkSpecificConditions#4):)
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

    (:let $asd:= trace('Getting lookup tables'):)

    let $countryCode := scripts:getCountry($root)
    let $lookupTables := map {
        'ProductionFacility': iedreg:getLookupTableSNV($countryCode, 'ProductionFacility'),
        'ProductionInstallation': iedreg:getLookupTableSNV($countryCode, 'ProductionInstallation'),
        'ProductionSite': iedreg:getLookupTableSNV($countryCode, 'ProductionSite'),
        'ProductionInstallationPart': iedreg:getLookupTableSNV($countryCode, 'ProductionInstallationPart')
    }

    return common:feedback((
        common:header(),
        iedreg:runChecks01($root, $lookupTables),
        iedreg:runChecks02($root, $lookupTables),
        iedreg:runChecks03($root, $lookupTables),
        iedreg:runChecks04($root, $lookupTables),
        iedreg:runChecks05($root, $lookupTables),
        iedreg:runChecks06($root, $lookupTables),
        iedreg:runChecks07($root, $lookupTables),
        iedreg:runChecks08($root, $lookupTables),
        iedreg:runChecks09($root, $lookupTables),
        iedreg:runChecks10($root, $lookupTables),
        iedreg:runChecks11($root, $lookupTables),
        iedreg:runChecks12($root, $lookupTables),
        iedreg:runChecks13($root, $lookupTables)
        (:iedreg:runChecks14($root):)
    ))
};

declare function iedreg:check($url as xs:string) as element ()*
{
    (:iedreg:css(), :)
    iedreg:runChecks($url)
};

(:~
 : vim: ts=2 sts=2 sw=2 et
 :)
