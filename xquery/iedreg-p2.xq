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
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace functx = "http://www.functx.com" at "iedreg-functx.xq";
import module namespace scripts = "iedreg-scripts" at "iedreg-scripts.xq";
import module namespace scripts3 = "iedreg-qa3-scripts" at "iedreg-qa3-scripts.xq";
import module namespace common = "iedreg-common" at "iedreg-common.xq";
import module namespace utils = "iedreg-utils" at "iedreg-utils.xq";

(:~
 : 5. GEOGRAPHICAL AND COORDINATE CHECKS
 :)

declare function iedreg:runChecks05($root as element(), $lookupTables) as element()* {
    let $rulename := '5. GEOGRAPHICAL AND COORDINATE CHECKS'

    return
        <div class="iedreg header">{$rulename}</div>,
    <div class="iedreg table parent">{
        utils:failsafeWrapper($lookupTables, "C5.1", "ProductionSite radius", $root, scripts:checkProdutionSiteRadius#4),
        utils:failsafeWrapper($lookupTables, "C5.2", "ProductionFacility radius", $root, scripts:checkProdutionFacilityRadius#4),
        utils:failsafeWrapper($lookupTables, "C5.3", "ProductionInstallation radius", $root, scripts:checkProdutionInstallationRadius#4),
        utils:failsafeWrapper($lookupTables, "C5.4", "Coordinates to country comparison", $root, scripts:checkCountryBoundary#4),
        utils:failsafeWrapper($lookupTables, "C5.5", "Coordinate precision completeness", $root, scripts:checkCoordinatePrecisionCompleteness#4),
        utils:failsafeWrapper($lookupTables, "C5.6", "Coordinate continuity", $root, scripts:checkCoordinateContinuity#4),
        utils:failsafeWrapper($lookupTables, "C5.7", "ProductionSite to ProductionFacility coordinate comparison", $root, scripts:checkProdutionSiteBuffers#4),
        utils:failsafeWrapper($lookupTables, "C5.8", "ProductionInstallation to ProductionInstallationPart coordinate comparison", $root, scripts:checkProdutionInstallationPartCoords#4)

    }</div>
};

(:~
 : 6. ACTIVITY CHECKS
 :)

declare function iedreg:runChecks06($root as element(), $lookupTables) as element()* {
    let $rulename := '6. ACTIVITY CHECKS'

    let $reportingYear := $root//*:ReportData/*:reportingYear => fn:number()

    return
        
    if ($reportingYear ge 2021)then (

    <div class="iedreg header">{$rulename}</div>,
    <div class="iedreg table parent">{
        (: upd DONE :) utils:failsafeWrapper($lookupTables, "C6.1", "EPRTRAnnexIActivity uniqueness", $root, scripts:checkEPRTRAnnexIActivityUniqueness#4),
        utils:failsafeWrapper($lookupTables, "C6.2", "EPRTRAnnexIActivity continuity", $root, scripts:checkEPRTRAnnexIActivityContinuity#4),
        (: upd DONE :) utils:failsafeWrapper($lookupTables, "C6.3", "IEDAnnexIActivity uniqueness", $root, scripts:checkIEDAnnexIActivityUniqueness#4),
        utils:failsafeWrapper($lookupTables, "C6.4", "IEDAnnexIActivity continuity", $root, scripts:checkIEDAnnexIActivityContinuity#4),
        utils:failsafeWrapper($lookupTables, "C6.5", "NONEPRTR facility with EPRTRAnnexIActivity not null", $root, scripts:checkIEDAnnexIActivityNull#4),
        utils:failsafeWrapper($lookupTables, "C6.6", "EPRTR facilities with EPRTRAnnexIActivty = 1(c) but no LCP reported", $root, scripts:checkIEDAnnexIActivityValue#4),       
        utils:failsafeWrapper($lookupTables, "C6.7", "NONEPRTR functional facility with functional NONIED installation", $root, scripts:checkFacilityStatusType#4),
        utils:failsafeWrapper($lookupTables, "C6.8", "Chapter III and Chapter IV reporting", $root, scripts:checkChapters#4)
    }</div>)

    else (

    <div class="iedreg header">{$rulename}</div>,
    <div class="iedreg table parent">{
        (: upd DONE :) utils:failsafeWrapper($lookupTables, "C6.1", "EPRTRAnnexIActivity uniqueness", $root, scripts:checkEPRTRAnnexIActivityUniqueness#4),
        utils:failsafeWrapper($lookupTables, "C6.2", "EPRTRAnnexIActivity continuity", $root, scripts:checkEPRTRAnnexIActivityContinuity#4),
        (: upd DONE :) utils:failsafeWrapper($lookupTables, "C6.3", "IEDAnnexIActivity uniqueness", $root, scripts:checkIEDAnnexIActivityUniqueness#4),
        utils:failsafeWrapper($lookupTables, "C6.4", "IEDAnnexIActivity continuity", $root, scripts:checkIEDAnnexIActivityContinuity#4)
        
    }</div>)
};

(:~
 : 7. STATUS CHECKS
 :)

declare function iedreg:runChecks07($root as element(), $lookupTables) as element()* {
    let $rulename := '7. STATUS CHECKS'

    return
        <div class="iedreg header">{$rulename}</div>,
    <div class="iedreg table parent">{
        utils:failsafeWrapper($lookupTables, "C7.1", "Decommissioned StatusType comparison ProductionFacility and ProductionInstallation", $root, scripts:checkProductionFacilityDecommissionedStatus#4),
        utils:failsafeWrapper($lookupTables, "C7.2", "Decommissioned StatusType comparison ProductionInstallations and ProductionInstallationParts", $root, scripts:checkProductionInstallationDecommissionedStatus#4),
        utils:failsafeWrapper($lookupTables, "C7.3", "Disused StatusType comparison ProductionFacility and ProductionInstallation", $root, scripts:checkProductionFacilityDisusedStatus#4),
        utils:failsafeWrapper($lookupTables, "C7.4", "Disused StatusType comparison ProductionInstallations and ProductionInstallationParts", $root, scripts:checkProductionInstallationDisusedStatus#4),
        utils:failsafeWrapper($lookupTables, "C7.5", "Decommissioned to functional plausibility", $root, scripts:checkFunctionalStatusType#4)
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
        utils:failsafeWrapper($lookupTables, "C8.1", "dateOfStartOfOperation comparison", $root, scripts:checkDateOfStartOfOperation#4),
        utils:failsafeWrapper($lookupTables, "C8.2", "dateOfStartOfOperation LCP restriction", $root, scripts:checkDateOfStartOfOperationLCP#4),
        (: removed :) (:utils:failsafeWrapper($lookupTables, "C8.3", "dateOfStartOfOperation to dateOfGranting comparison", $root, scripts:checkDateOfGranting#4),:)
        (: upd DONE :) utils:failsafeWrapper($lookupTables, "C8.3", "dateOfGranting plausibility", $root, scripts:checkDateOfLastReconsideration#4)
        (: removed :) (:utils:failsafeWrapper($lookupTables, "C8.4", "dateOfLastReconsideration plausibility", $root, scripts:checkDateOfLastUpdate#4):)
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
        (: upd DONE :) utils:failsafeWrapper($lookupTables, "C9.1", "competentAuthorityInspections to inspections comparison", $root, scripts:checkInspections#4),
        utils:failsafeWrapper($lookupTables, "C9.2", "competentAuthorityPermits and permit field comparison", $root, scripts:checkPermit#4),
        (: utils:failsafeWrapper($lookupTables, "C9.3", "permitURL to dateOfGranting comparison", $root, scripts:checkDateOfGrantingPermitURL#4), :) (: C9.3 disabled because of Taskman #278339 :)
        utils:notApplicable("C9.3", "permitURL to dateOfGranting comparison", $root), (: C9.3 disabled because of Taskman #278339 :)
        (: new DONE :) utils:failsafeWrapper($lookupTables, "C9.5", "enforcementAction to permitGranted comparison", $root, scripts:checkEnforcementAction#4),
        (: new DONE :) utils:failsafeWrapper($lookupTables, "C9.6", "StricterPermitConditions", $root, scripts:checkStricterPermitConditions#4)
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
        utils:failsafeWrapper($lookupTables, "C10.1", "BATDerogationIndicator to permitGranted comparison", $root, scripts:checkBATPermit#4),
        (: new DONE :) utils:failsafeWrapper($lookupTables, "C10.2", "BATDerogation", $root, scripts:checkBATDerogation#4),
        (: removed :) (:utils:failsafeWrapper($lookupTables, "C10.2", "dateOfGranting to Transitional National Plan comparison", $root, scripts:checkArticle32#4),:)
        utils:failsafeWrapper($lookupTables, "C10.3", "Limited lifetime derogation to reportingYear comparison", $root, scripts:checkArticle33#4),
        utils:failsafeWrapper($lookupTables, "C10.4", "District heating plants derogation to reportingYear comparison", $root, scripts:checkArticle35#4),
        utils:failsafeWrapper($lookupTables, "C10.5", "Limited life time derogation continuity", $root, scripts:checkArticle33Continuity#4),
        utils:failsafeWrapper($lookupTables, "C10.6", "District heat plant derogation continuity", $root, scripts:checkArticle35Continuity#4),
        utils:failsafeWrapper($lookupTables, "C10.7", "Transitional National Plan derogation continuity", $root, scripts:checkArticle32Continuity#4)
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
        (: upd DONE :) utils:failsafeWrapper($lookupTables, "C11.1", "otherRelevantChapters to plantType comparison", $root, scripts:checkRelevantChapters#4),
        (: upd DONE :) utils:failsafeWrapper($lookupTables, "C11.2", "LCP plantType", $root, scripts:checkLCP#4),
        utils:failsafeWrapper($lookupTables, "C11.3", "totalRatedThermalInput plausibility", $root, scripts:checkRatedThermalInput#4),
        (: upd DONE :) utils:failsafeWrapper($lookupTables, "C11.4", "WI plantType", $root, scripts:checkWI#4),
        (: upd DONE :) utils:failsafeWrapper($lookupTables, "C11.5", "nominalCapacity plausibility", $root, scripts:checkNominalCapacity#4)
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
        utils:failsafeWrapper($lookupTables, "C12.1", "Confidentiality restriction", $root, scripts:checkConfidentialityRestriction#4),
        utils:failsafeWrapper($lookupTables, "C12.2", "Confidentiality overuse", $root, scripts:checkConfidentialityOveruse#4)
    }</div>
};

(:~
 : 13. OTHER IDENTIFIERS & MISCELLANEOUS CHECKS
 :)

declare function iedreg:runChecks13($root as element(), $lookupTables) as element()* {
    let $rulename := '13. OTHER IDENTIFIERS &amp; MISCELLANEOUS CHECKS'
    let $countryCode := scripts:getCountry($root)
    return
    if($countryCode != 'GB' and $countryCode != 'CH') then
   (
         <div class="iedreg header">{$rulename}</div>,
            <div class="iedreg table parent">{
                (: upd DONE :) utils:failsafeWrapper($lookupTables, "C13.1", "ETSIdentifier validity", $root, scripts:checkETSIdentifier#4),
                (: upd DONE :) utils:failsafeWrapper($lookupTables, "C13.2", "eSPIRSId validity", $root, scripts:checkeSPIRSIdentifier#4),
                utils:failsafeWrapper($lookupTables, "C13.3", "ProductionFacility facilityName to parentCompanyName comparison", $root, scripts:checkFacilityName#4),
                utils:failsafeWrapper($lookupTables, "C13.4", "nameOfFeature", $root, scripts:checkNameOfFeatureContinuity#4),
                utils:failsafeWrapper($lookupTables, "C13.5", "reportingYear plausibility", $root, scripts:checkReportingYear#4),
                utils:failsafeWrapper($lookupTables, "C13.6", "electronicMailAddress format", $root, scripts:checkElectronicMailAddressFormat#4),
                utils:failsafeWrapper($lookupTables, "C13.7", "Lack of facility address", $root, scripts:checkFacilityAddress#4),
                (: new DONE :) utils:failsafeWrapper($lookupTables, "C13.8", "DateOfStartOfOperation future year", $root, scripts:checkDateOfStartOfOperationFuture#4),
                (: removed :) (:utils:failsafeWrapper($lookupTables, "C13.8", "Character string space identification", $root, scripts:checkWhitespaces#4):)
                (: new :) utils:failsafeWrapper($lookupTables, "C13.9", "FeatureName blank check", $root, scripts:checkFeatureNameBlank#4),
                (: new :) utils:failsafeWrapper($lookupTables, "C13.10", "All fields blank check", $root, scripts:checkAllFieldsBlank#4),
                (: new :) utils:failsafeWrapper($lookupTables, "C13.11", "ETSIdentifier format check", $root, scripts:checkETSFormat#4),
                (: new :) utils:failsafeWrapper($lookupTables, "C13.12", "Namespaces check", $root, scripts:checkNamespaces#4)
            }</div>)
    else
    (
        <div class="iedreg header">{$rulename}</div>,
        <div class="iedreg table parent">{
            
            utils:failsafeWrapper($lookupTables, "C13.3", "ProductionFacility facilityName to parentCompanyName comparison", $root, scripts:checkFacilityName#4),
            utils:failsafeWrapper($lookupTables, "C13.4", "nameOfFeature", $root, scripts:checkNameOfFeatureContinuity#4),
            utils:failsafeWrapper($lookupTables, "C13.5", "reportingYear plausibility", $root, scripts:checkReportingYear#4),
            utils:failsafeWrapper($lookupTables, "C13.6", "electronicMailAddress format", $root, scripts:checkElectronicMailAddressFormat#4),
            utils:failsafeWrapper($lookupTables, "C13.7", "Lack of facility address", $root, scripts:checkFacilityAddress#4),
            (: new DONE :) utils:failsafeWrapper($lookupTables, "C13.8", "DateOfStartOfOperation future year", $root, scripts:checkDateOfStartOfOperationFuture#4),
            (: removed :) (:utils:failsafeWrapper($lookupTables, "C13.8", "Character string space identification", $root, scripts:checkWhitespaces#4):)
            (: new :) utils:failsafeWrapper($lookupTables, "C13.9", "FeatureName blank check", $root, scripts:checkFeatureNameBlank#4),
            (: new :) utils:failsafeWrapper($lookupTables, "C13.10", "All fields blank check", $root, scripts:checkAllFieldsBlank#4),
            (: new :) utils:failsafeWrapper($lookupTables, "C13.11", "ETSIdentifier format check", $root, scripts:checkETSFormat#4),
            (: new :) utils:failsafeWrapper($lookupTables, "C13.12", "Namespaces check", $root, scripts:checkNamespaces#4)
        }</div>
     )
};

(:~
 : 14. OTHER CHECKS QA3
 :)

declare function iedreg:runChecks14($root as element(), $lookupTables) as element()* {
    let $rulename := '14. GML Validation Checks'

    return
        <div class="iedreg header">{$rulename}</div>,
    <div class="iedreg table parent">{
        utils:failsafeWrapper($lookupTables, "C14.1", "reportData validity", $root, scripts3:checkReportData#4),
        utils:failsafeWrapper($lookupTables, "C14.2", "hostingSite position validity", $root, scripts3:checkeHostingSite #4),
        utils:failsafeWrapper($lookupTables, "C14.3", "hostingSite xlink:href validity", $root, scripts3:checkeHostingSiteHref#4),
        utils:failsafeWrapper($lookupTables, "C14.4", "ProductionInstallation gml:id validity", $root, scripts3:checkGroupedInstallation#4),
        utils:failsafeWrapper($lookupTables, "C14.5", "groupedInstallation xlink:href validity", $root, scripts3:checkGroupedInstallationHref#4),
        (: removed :)(:utils:failsafeWrapper($lookupTables, "C14.6", "act-core:geometry validity", $root, scripts3:checkActCoreGeometry#4),:)
        (: 2.17 :) (:utils:failsafeWrapper($lookupTables, "C14.7", "act-core:activity validity", $root, scripts3:checkActCoreActivity#4),:)
        utils:failsafeWrapper($lookupTables, "C14.8", "ProductionInstallationPart gml:id validity", $root, scripts3:checkGroupedInstallationPart#4),
        utils:failsafeWrapper($lookupTables, "C14.9", "pf:groupedInstallationPart xlink:href validity", $root, scripts3:checkGroupedInstallationPartHref#4)
        (: removed :)(:utils:failsafeWrapper($lookupTables, "C14.10", "pf:status validity", $root, scripts3:checkStatusNil#4),:)
        (: removed :)(:utils:failsafeWrapper($lookupTables, "C14.11", "pf:pointGeometry validity", $root, scripts3:checkePointGeometry#4):)
        (: 2.16 :) (:utils:failsafeWrapper($lookupTables, "C14.12", "otherRelevantChapters consistency", $root, scripts3:checkOtherRelevantChapters#4),:)
        (: 2.13 :) (:utils:failsafeWrapper($lookupTables, "C14.13", "statusType consistency", $root, scripts3:checkStatusType#4),:)
        (: 2.15 :) (:utils:failsafeWrapper($lookupTables, "C14.14", "plantType consistency", $root, scripts3:checkPlantType#4),:)
        (: 2.14 :) (:utils:failsafeWrapper($lookupTables, "C14.15", "derogations consistency", $root, scripts3:checkDerogations#4),:)
        (: 2.12 :) (:utils:failsafeWrapper($lookupTables, "C14.16", "specificConditions consistency", $root, scripts3:checkSpecificConditions#4):)
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
    let $reportingYear := $root//*:ReportData/*:reportingYear => fn:number()

    let $lookupTables := if($reportingYear ge 2018)
        then
            map {
                'ProductionFacility': utils:getLookupTable($countryCode, 'ProductionFacility'),
                'ProductionInstallation': utils:getLookupTable($countryCode, 'ProductionInstallation'),
                'ProductionSite': utils:getLookupTable($countryCode, 'ProductionSite'),
                'ProductionInstallationPart': utils:getLookupTable($countryCode, 'ProductionInstallationPart')
            }
        else
            map {}

    return common:feedback((
        common:header(),
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
