module namespace common = "iedreg-common";

declare function common:css() as element()* {
    <style>
        <![CDATA[
pre.iedreg { display: inline }

div.iedreg { box-sizing: border-box; font-family: "Helvetica Neue",Helvetica,Arial,sans-serif; font-size: 14px; color: #333 }
div.iedreg.header { font-size: 16px; font-weight: 500; margin: 0.8em 0 0.4em 0 }

div.iedreg.table { display: table; width: 100%; border-collapse: collapse; }
div.iedreg.row { display: table-row; }
div.iedreg.col {
    min-width: 100px;
    display: table-cell;
    padding: 0.4em;
    border: 1pt solid #aaa
}

div.iedreg.inner {
    width: 90%;
    //margin-left: 2%;
    margin-top: 0.4em;
    margin-bottom: 0.6em
}
div.iedreg.outer { padding-bottom: 0; border: 1pt solid #888 }
div.iedreg.inner { border: 1pt solid #aaa }
div.iedreg.parent { margin-bottom: 1.5em }

div.iedreg.th { border-bottom: 2pt solid #000; font-weight: 600 }
div.iedreg.blocker { background-color: #fdf7f7; border-bottom: 2pt solid #d9534f }
div.iedreg.warning { background-color: #faf8f0; border-bottom: 2pt solid #f0ad4e }
div.iedreg.info { background-color: #f4f8fa; border-bottom: 2pt solid #5bc0de }

div.iedreg.red { background-color: #fdf7f7; color: #b94a48 }
div.iedreg.yellow { background-color: #faf8f0; color: #8a6d3b }
div.iedreg.blue { background-color: #f4f8fa; color: #34789a }
div.iedreg.gray { background-color: #eee; color: #555 }

div.iedreg.msg { margin-top: 1em; margin-bottom: 1em; padding: 1em 2em }
div.iedreg.msg.mblocker { border-color: #d9534f }
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

span.iedreg.nowrap {
    white-space: nowrap
}
span.iedreg.break {
    word-wrap: break-word
}
span.iedreg.top { vertical-align: top}
span.iedreg.link { cursor: pointer; cursor: hand; text-decoration: underline }

span.iedreg.big { padding: 0.1em 0.9em }
span.iedreg.medium { padding: 0.1em 0.5em }
span.iedreg.small { padding: 0.1em }

span.iedreg.header { display: block; font-size: 16px; font-weight: 600 }

span.iedreg.failed { color: #fff; background-color: #000000 }
span.iedreg.blocker { color: #fff; background-color: #d9534f }
span.iedreg.warning { color: #fff; background-color: #f0ad4e }
span.iedreg.info { color: #fff; background-color: #5bc0de }
span.iedreg.pass { color: #fff; background-color: #5cb85c }
span.iedreg.none { color: #fff; background-color: #999 }

ul.iedreg.error-summary {margin: 0}

.exportButton {padding: 1em 0.5em;float: right;}

.exportButton {
  background-color: #e1ecf4;
  border-radius: 3px;
  border: 1px solid #7aa7c7;
  box-shadow: rgba(255, 255, 255, .7) 0 1px 0 0 inset;
  box-sizing: border-box;
  color: #39739d;
  cursor: pointer;
  display: inline-block;
  font-family: -apple-system,system-ui,"Segoe UI","Liberation Sans",sans-serif;
  font-size: 13px;
  font-weight: 400;
  line-height: 1.15385;
  margin: 0;
  outline: none;
  
  position: relative;
  text-align: center;
  text-decoration: none;
  user-select: none;
  -webkit-user-select: none;
  touch-action: manipulation;
  vertical-align: baseline;
  white-space: nowrap;
}

.exportButton:hover,
.exportButton:focus {
  background-color: #b3d3ea;
  color: #2c5777;
}

.exportButton:focus {
  box-shadow: 0 0 0 4px rgba(0, 149, 255, .15);
}

.exportButton:active {
  background-color: #a0c7e4;
  box-shadow: none;
  color: #2c5777;
}
}
]]>
    </style>
};


declare function common:script() as element()* {

<script type="text/javascript" src="https://converters.eionet.europa.eu/xmlfile/export.js">
var wsdf;
</script>

};

declare function common:script2() as element()* {

<script type="text/javascript" src="https://bdr.eionet.europa.eu/european_registry/scripts/alasql.min.js">

var wsdf;
</script>

};


declare function common:script3() as element()* {

<script src="https://bdr.eionet.europa.eu/european_registry/scripts/xlsx.core.min.js">
var wsdf;
</script>

};

declare function common:header() as element()* {
    <h5>Please note that where an individual check identifies more than 1,000 errors, only the first 1,000 messages are shown in the results below.</h5>
};

declare function common:createSummaryRow(
        $allTypes as xs:string*,
        $errType as xs:string
) as element()? {
    let $countTypes := fn:count($allTypes[. = $errType])

    return if($countTypes > 0)
        then <li>
            <span style="font-weight:bold">{$countTypes}</span> checks are producing <span class="iedreg small {$errType}">{$errType}</span>
        </li>
        else ()
};

(:~
: JavaScript
:)
declare function common:getJS() as element(script) {

    let $js :=
        <script type="text/javascript">
            <![CDATA[
    function saveFile(refCode, numRecords, errorType) {
    var lista = [];
    var lista2 = [];
    var headers = "";
    var excelLine = "{\"";
    if ((document.getElementById(refCode + "-errorsHeader") != null) && document.getElementById(refCode + "-errorsHeader").value != "") {
        headers = document.getElementById(refCode + "-errorsHeader").value;
        var arrayHeaders = headers.split(',');
    }
    for (let i = 1; i <= numRecords; i++) {
        if ((document.getElementById(refCode + "-errorsTable_" + i + "_" + errorType) != null) && document.getElementById(refCode + "-errorsTable_" + i + "_" + errorType).value != "") {
            var row = document.getElementById(refCode + "-errorsTable_" + i + "_" + errorType).value;
            var arrayRow = row.split('#####');
            for (let j = 0; j < arrayHeaders.length; j++) {
                if (j + 1 == arrayHeaders.length) {
                    excelLine += arrayHeaders[j] + "\":\"" + arrayRow[j] + "\"}";
                }
                else {

                    excelLine += arrayHeaders[j] + "\":\"" + arrayRow[j] + "\",\"";
                }
            }
            if (i < numRecords) {
                excelLine += ",{\"";
            }
        }
    }
    JSONvalue = "[" + excelLine + "]";
    data1 = JSON.parse(JSONvalue);
    data2 = {
        sheetid: refCode,
        headers: true,
        column: {
            style: {
                Font: {
                    Bold: "1",
                    Color: "#3C3741",
                },
                Alignment: {
                    Horizontal: "Center"
                },
                Interior: {
                    Color: "#7CEECE",
                    Pattern: "Solid"
                }
            }
        }
    };
    lista.push(data1);
    lista2.push(data2);
    var opts = lista2;
    var res = alasql('SELECT * INTO XLSX("' + refCode + '_detailed_' + errorType + '.xlsx",?) FROM ?', [opts, lista]);
}
                ]]>
        </script>
    return
        <script type="text/javascript">{fn:normalize-space($js)}</script>
};

declare function common:feedback($records as element()*) as element(div) {
    let $all := $records//@class[starts-with(., 'iedreg medium')]/string()
    let $all := for $i in $all return tokenize($i, "\s+")
    let $status :=
            if ($all = "failed") then "failed"
            else if ($all = "blocker") then "blocker"
            else if ($all = "error") then "error"
            else if ($all = "warning") then "warning"
            else if ($all = "skipped") then "skipped"
            else if ($all = "info") then "info"
            else if ($all = "pass") then "ok"
            else ""
    (:$status => upper-case():)
    let $feedbackMessage :=
        if ($status = "failed") then
            "QA failed to execute."
        else if ($status = "blocker") then
            "QA completed but there were blocking errors."
        else if ($status = "error") then
            "QA completed but there were errors."
        else if ($status = "warning") then
            "QA completed with warnings."
        else if ($status = "info") then
            "QA completed without errors"
        else if ($status = "ok") then
            "QA completed without errors"
        else
            "QA status is unknown"

    let $errorSummary := (
        <div class="iedreg header">QA RESULT SUMMARY</div>,
        <ul class="iedreg error-summary">{
            common:createSummaryRow($all, 'failed'),
            common:createSummaryRow($all, 'blocker'),
            common:createSummaryRow($all, 'error'),
            common:createSummaryRow($all, 'warning'),
            common:createSummaryRow($all, 'info')
        }
        </ul>
    )

    return
        <div class="feedbacktext">
            {common:css()}
            {common:script2()}
            {common:script3()}
            <span id="feedbackStatus" class="{$status => upper-case()}" style="display:none">{$feedbackMessage}</span>
            {$errorSummary}
            {$records}
            {common:getJS()}
        </div>
};