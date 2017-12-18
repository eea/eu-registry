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

module namespace scripts3 = "iedreg-scripts-qa3";
import module namespace scripts = "iedreg-scripts" at "iedreg-scripts.xq";

(:~
 : 1. CODE LIST CHECKS
 :)

(:
    C1.7 otherRelevantChapters consistency
:)
declare function scripts3:checkOtherRelevantChapters(
        $refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $featureName := "ProductionInstallation"
    let $activityName := "RelevantChapter"
    let $activityType := "otherRelevantChapters"
    let $seq := $root/descendant::*[local-name() = $activityType]

    return scripts:checkActivity($refcode, $rulename, $root, $featureName, $activityName, $activityType, $seq)
};

(:
    C1.8 pf:status consistency
:)

declare function scripts3:checkStatusType($refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $featureName := "ProductionFacility, ProductionInstallation or ProductionInstallationPart"
    let $activityName := "ConditionOfFacility"
    let $activityType := "statusType"
    let $seq := $root/descendant::*[local-name() = "status"]/descendant::*[local-name() = $activityType]

    return scripts:checkActivity($refcode, $rulename, $root, $featureName, $activityName, $activityType, $seq)
};

(:
    C1.9 plantType consistency
:)

declare function scripts3:checkPlantType($refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $featureName := "ProductionInstallationPart"
    let $activityName := "PlantType"
    let $activityType := "plantType"
    let $seq := $root/descendant::*[local-name() = $activityType]

    return scripts:checkActivity($refcode, $rulename, $root, $featureName, $activityName, $activityType, $seq)
};

(:
    C1.10 derogations consistency
:)

declare function scripts3:checkDerogations($refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $featureName := "ProductionInstallationPart"
    let $activityName := "Derogation"
    let $activityType := "derogations"
    let $seq := $root/descendant::*[local-name() = $activityType]

    return scripts:checkActivity($refcode, $rulename, $root, $featureName, $activityName, $activityType, $seq)
};

(:
    C1.11 derogations consistency
:)

declare function scripts3:checkSpecificConditions($refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $featureName := "ProductionInstallationPart"
    let $activityName := "Article51"
    let $activityType := "specificConditions"
    let $seq := $root/descendant::*[local-name() = $activityType]

    return scripts:checkActivity($refcode, $rulename, $root, $featureName, $activityName, $activityType, $seq)
};

(:
    C13.1 checkReportData
:)

declare function scripts3:checkReportData($refcode as xs:string,
        $rulename as xs:string,
        $root as element()
) as element()* {
    let $featureName := "ProductionInstallationPart"
    let $activityName := "Article51"
    let $activityType := "specificConditions"
    let $seq := $root/descendant::*[local-name() = $activityType]

    return scripts:checkActivity($refcode, $rulename, $root, $featureName, $activityName, $activityType, $seq)
};

(:~
 : vim: sts=2 ts=2 sw=2 et
 :)
