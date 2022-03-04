function saveFile(refCode,numRecords) {

    var lista = [];
    var lista2 = [];
    var headers ="";
    var excelLine="{\"";

    if ((document.getElementById(refCode+"-errorsHeader") != null) && document.getElementById(refCode+"-errorsHeader").value != "") 
    {
    	headers=document.getElementById(refCode+"-errorsHeader").value;
    	var arrayHeaders = headers.split(',');
    }

    for (let i = 1; i <= numRecords; i++) {
       if ((document.getElementById(refCode+"-errorsTable_"+i) != null) && document.getElementById(refCode+"-errorsTable_"+i).value != "")
       {

       	var row= document.getElementById(refCode+"-errorsTable_"+i).value;
       	var arrayRow = row.split(',');
       	//console.log(row);

       	for (let j=0 ; j < arrayHeaders.length; j++){
       		
	       		if (j+1==arrayHeaders.length){

	       			excelLine+=arrayHeaders[j]+"\":\""+arrayRow[j]+"\"}";
	       		}
	       		else{
	       		
					excelLine+=arrayHeaders[j]+"\":\""+arrayRow[j]+"\",\"";
	       		}
	       
       		}

		if (i < numRecords){

			excelLine+=",{\"";
			}
		}
	}//for

        JSONvalue = "["+ excelLine + "]";
        data1 = JSON.parse(JSONvalue);
        data2 = {sheetid:refCode,
        	headers:true, 
              column: {
                  style:{
                      Font:{
                          Bold:"1",
                          Color:"#3C3741",
                      },
                      Alignment:{
                          Horizontal:"Center"
                      },
                      Interior:{
                          Color:"#7CEECE",
                          Pattern:"Solid"
                      }
                  }
              }
        };
        
        lista.push(data1);
        lista2.push(data2); 
   
   
   var opts = lista2;
   
   var res = alasql('SELECT * INTO XLSX("'+refCode+'_detailed_ERRORS.xlsx",?) FROM ?',[opts,lista]);
   
}