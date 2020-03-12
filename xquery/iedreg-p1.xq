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
import module namespace utils = "iedreg-utils" at "iedreg-utils.xq";

(:~
   1. DATA CONTROL CHECKS
:)

declare function iedreg:runChecks01($root as element(), $lookupTables) as element()* {
    let $rulename := '1. DATA CONTROL CHECKS'

    return
        <div class="iedreg header">{$rulename}</div>,
    <div class="iedreg table parent">{
        (: new DONE :) utils:failsafeWrapper($lookupTables, "C1.1", "2017 reporting year versus 2018 and later reporting years", $root, scripts:check2018year#4),
        (: new DONE :) utils:failsafeWrapper($lookupTables, "C1.2", "Facility Type", $root, scripts:checkFacilityType#4),
        (: new DONE :) utils:failsafeWrapper($lookupTables, "C1.3", "Installation Type", $root, scripts:checkInstallationType#4)
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
        utils:failsafeWrapper($lookupTables, "C2.1", "EPRTRAnnexIActivity mainActivity consistency", $root, scripts:checkMainEPRTRAnnexIActivity#4),
        utils:failsafeWrapper($lookupTables, "C2.2", "EPRTRAnnexIActivity otherActivity consistency", $root, scripts:checkOtherEPRTRAnnexIActivity#4),
        utils:failsafeWrapper($lookupTables, "C2.3", "IEDAnnexIActivity mainActivity consistency", $root, scripts:checkMainIEDAnnexIActivity#4),
        utils:failsafeWrapper($lookupTables, "C2.4", "IEDAnnexIActivity otherActivity consistency", $root, scripts:checkOtherIEDAnnexIActivity#4),
        utils:failsafeWrapper($lookupTables, "C2.5", "CountryId consistency", $root, scripts:checkCountryId#4),
        utils:failsafeWrapper($lookupTables, "C2.6", "reasonValue consistency", $root, scripts:checkReasonValue#4),
        (: new DONE :) utils:failsafeWrapper($lookupTables, "C2.7", "FacilityType consistency", $root, scripts:checkFacilityTypeVocab#4),
        (: new DONE :) utils:failsafeWrapper($lookupTables, "C2.8", "InstallationType consistency", $root, scripts:checkInstallationTypeVocab#4),
        (: new DONE :) utils:failsafeWrapper($lookupTables, "C2.9", "BaselineReport consistency", $root, scripts:checkBaselineReportTypeVocab#4),
        (: new DONE :) utils:failsafeWrapper($lookupTables, "C2.10", "BATConclusion consistency", $root, scripts:checkBATConclusionTypeVocab#4),
        (: new DONE :) utils:failsafeWrapper($lookupTables, "C2.11", "BATAEL consistency", $root, scripts:checkBATAELTypeVocab#4),
        (: QA3 :) utils:failsafeWrapper($lookupTables, "C2.12", "Article51 consistency", $root, scripts3:checkSpecificConditions#4),
        (: QA3 :) utils:failsafeWrapper($lookupTables, "C2.13", "ConditionOfFacility consistency", $root, scripts3:checkStatusType#4),
        (: QA3 :) utils:failsafeWrapper($lookupTables, "C2.14", "Derogation consistency", $root, scripts3:checkDerogations#4),
        (: QA3 :) utils:failsafeWrapper($lookupTables, "C2.15", "PlantType consistency", $root, scripts3:checkPlantType#4),
        (: QA3 :) utils:failsafeWrapper($lookupTables, "C2.16", "RelevantChapter consistency", $root, scripts3:checkOtherRelevantChapters#4),
        (: QA3 :) utils:failsafeWrapper($lookupTables, "C2.17", "Activity consistency", $root, scripts3:checkActCoreActivity#4)
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
        utils:failsafeWrapper($lookupTables, "C3.1", "High proportion of new inspireIds", $root, scripts:checkAmountOfInspireIds#4),
        utils:failsafeWrapper($lookupTables, "C3.2", "ProductionSite inspireId uniqueness", $root, scripts:checkProductionSiteUniqueness#4),
        utils:failsafeWrapper($lookupTables, "C3.3", "ProductionFacility inspireId uniqueness", $root, scripts:checkProductionFacilityUniqueness#4),
        utils:failsafeWrapper($lookupTables, "C3.4", "ProductionInstallation inspireId uniqueness", $root, scripts:checkProductionInstallationUniqueness#4),
        utils:failsafeWrapper($lookupTables, "C3.5", "ProductionInstallationPart inspireId uniqueness", $root, scripts:checkProductionInstallationPartUniqueness#4),
        utils:failsafeWrapper($lookupTables, "C3.6", "InspireId blank check", $root, scripts:checkInspireIdBlank#4)
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
        utils:failsafeWrapper($lookupTables, "C4.1", "Identification of ProductionSite duplicates", $root, scripts:checkProductionSiteDuplicates#4),
        utils:failsafeWrapper($lookupTables, "C4.2", "Identification of ProductionFacility duplicates", $root, scripts:checkProductionFacilityDuplicates#4),
        utils:failsafeWrapper($lookupTables, "C4.3", "Identification of ProductionInstallation duplicates", $root, scripts:checkProductionInstallationDuplicates#4),
        utils:failsafeWrapper($lookupTables, "C4.4", "Identification of ProductionInstallationPart duplicates", $root, scripts:checkProductionInstallationPartDuplicates#4),
        utils:failsafeWrapper($lookupTables, "C4.5", "Identification of ProductionSite duplicates within the database", $root, scripts:checkProductionSiteDatabaseDuplicates#4),
        utils:failsafeWrapper($lookupTables, "C4.6", "Identification of ProductionFacility duplicates within the database", $root, scripts:checkProductionFacilityDatabaseDuplicates#4),
        utils:failsafeWrapper($lookupTables, "C4.7", "Identification of ProductionInstallation duplicates within the database", $root, scripts:checkProductionInstallationDatabaseDuplicates#4),
        utils:failsafeWrapper($lookupTables, "C4.8", "Identification of ProductionInstallationPart duplicates within the database", $root, scripts:checkProductionInstallationPartDatabaseDuplicates#4),
        utils:failsafeWrapper($lookupTables, "C4.9", "ProductionSite and Facility Continuity", $root, scripts:checkMissingProductionSites#4),
        utils:failsafeWrapper($lookupTables, "C4.10", "Missing ProductionFacilities, previous submissions", $root, scripts:checkMissingProductionFacilities#4),
        utils:failsafeWrapper($lookupTables, "C4.11", "Missing ProductionInstallations, previous submissions", $root, scripts:checkMissingProductionInstallations#4),
        utils:failsafeWrapper($lookupTables, "C4.12", "Missing ProductionInstallationsParts, previous submissions", $root, scripts:checkMissingProductionInstallationParts#4)
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
        iedreg:runChecks01($root, $lookupTables),
        iedreg:runChecks02($root, $lookupTables),
        iedreg:runChecks03($root, $lookupTables),
        iedreg:runChecks04($root, $lookupTables)
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
