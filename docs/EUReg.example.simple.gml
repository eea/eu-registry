<?xml version="1.0" ?>
<gml:FeatureCollection xmlns:net="http://inspire.ec.europa.eu/schemas/net/4.0"
    xmlns:sc="http://www.interactive-instruments.de/ShapeChange/AppInfo"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:gco="http://www.isotc211.org/2005/gco"
    xmlns:hfp="http://www.w3.org/2001/XMLSchema-hasFacetAndProperty"
    xmlns:gml="http://www.opengis.net/gml/3.2" xmlns:ad="http://inspire.ec.europa.eu/schemas/ad/4.0"
    xmlns:base2="http://inspire.ec.europa.eu/schemas/base2/2.0"
    xmlns:pf="http://inspire.ec.europa.eu/schemas/pf/4.0"
    xmlns:act-core="http://inspire.ec.europa.eu/schemas/act-core/4.0"
    xmlns:base="http://inspire.ec.europa.eu/schemas/base/3.3"
    xmlns:gmd="http://www.isotc211.org/2005/gmd" xmlns:EUReg="http://dd.eionet.europa.eu/euregistryonindustrialsites"
    xmlns:gsr="http://www.isotc211.org/2005/gsr" xmlns:gts="http://www.isotc211.org/2005/gts"
    xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:gss="http://www.isotc211.org/2005/gss"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    gml:id="_c748ac9d-9b0d-44ed-9723-b2a58c21fc6f"
    xsi:schemaLocation="http://dd.eionet.europa.eu/euregistryonindustrialsites http://dd.eionet.europa.eu/schemas/euregistryonindustrialsites/EUReg.xsd">
    
    <gml:featureMember>        
        <EUReg:ReportData gml:id="ES.RD.2017">
            <EUReg:reportingYear>2017</EUReg:reportingYear>
            <EUReg:countryId
                xlink:href="http://dd.eionet.europa.eu/vocabulary/euregistryonindustrialsites/CountryCodeValue/ES"/>
        </EUReg:ReportData>
    </gml:featureMember>
    
    <gml:featureMember>
        <EUReg:ProductionSite gml:id="_123456789.SITE">
            <pf:inspireId>
                <base:Identifier>
                    <base:localId>123456789.SITE</base:localId>
                    <base:namespace>ES.CAED</base:namespace>
                </base:Identifier>
            </pf:inspireId>
            <pf:name>SITE EXAMPLE 1</pf:name>
            <pf:status xsi:nil="true"/>
            <EUReg:reportData xlink:href="#ES.RD.2017"/>
            <EUReg:location>
                <gml:Point gml:id="PS_point1" srsName="urn:ogc:def:crs:EPSG::4258" srsDimension="2">
                    <gml:pos>41.991925 2.104334</gml:pos>
                </gml:Point>
            </EUReg:location>
            <EUReg:confidentiality>
                <EUReg:Confidentiality>
                    <EUReg:confidential>false</EUReg:confidential>
                </EUReg:Confidentiality>
            </EUReg:confidentiality>
        </EUReg:ProductionSite>
    </gml:featureMember>
    
    <gml:featureMember>
        <EUReg:ProductionFacility gml:id="_000000002.FACILITY">
            <act-core:inspireId>
                <base:Identifier>
                    <base:localId>000000002.FACILITY</base:localId>
                    <base:namespace>ES.CAED</base:namespace>
                </base:Identifier>
            </act-core:inspireId>
            <act-core:name>FIRST EXAMPLE FACILITY</act-core:name>
            <act-core:geometry>
                <gml:Point gml:id="PF_point1" srsName="urn:ogc:def:crs:EPSG::4258" srsDimension="2">
                    <gml:pos>41.991932 2.104331</gml:pos>
                </gml:Point>
            </act-core:geometry>
            <act-core:function>
                <act-core:Function>
                    <act-core:activity
                        xlink:href="http://dd.eionet.europa.eu/vocabulary/euregistryonindustrialsites/NACEValue/35.11"/>
                </act-core:Function>
            </act-core:function>
            <act-core:validFrom xsi:nil="true"/>
            <act-core:beginLifespanVersion xsi:nil="true"/>
            <pf:riverBasinDistrict>http://dd.eionet.europa.eu/vocabularyconcept/euregistryonindustrialsites/RiverBasinDistrictValue/ES030</pf:riverBasinDistrict>
            <pf:status>
                <pf:StatusType>
                    <pf:statusType
                        xlink:href="http://dd.eionet.europa.eu/vocabulary/euregistryonindustrialsites/ConditionOfFacilityValue/functional"/>
                    <pf:validFrom xsi:nil="true"/>
                </pf:StatusType>
            </pf:status>
            <pf:hostingSite xlink:href="#_123456789.SITE"/>
            <pf:groupedInstallation xlink:href="#_010101011.INSTALLATION"/>
            <pf:groupedInstallation xlink:href="#_010101012.INSTALLATION"/>
            <EUReg:nameOfOwner>OWNER LIMITED</EUReg:nameOfOwner>
            <EUReg:numberOfInstallations>2</EUReg:numberOfInstallations>
            <EUReg:remarks>This is a simple example of how a facility would be reported to the EU Registry on Industrial Sites</EUReg:remarks>
            <EUReg:ownerURL>http://www.fakeurl.fake</EUReg:ownerURL>           
            <EUReg:EPRTRAnnexIActivity>
                <EUReg:EPRTRAnnexIActivityType>
                    <EUReg:EPRTRAnnexIApplicable>true</EUReg:EPRTRAnnexIApplicable>
                    <EUReg:mainActivity
                        xlink:href="http://dd.eionet.europa.eu/vocabulary/euregistryonindustrialsites/EPRTRAnnexIActivityValue/1(c)"/>
                </EUReg:EPRTRAnnexIActivityType>
            </EUReg:EPRTRAnnexIActivity>
            <EUReg:dateOfStartOfOperation>1982-01-01</EUReg:dateOfStartOfOperation>
            <EUReg:confidentiality>
                    <EUReg:Confidentiality>
                        <EUReg:confidential>true</EUReg:confidential>
                        <EUReg:description xlink:href="http://dd.eionet.europa.eu/vocabulary/euregistryonindustrialsites/ReasoningValue/Article4(2)(a)"/>
                    </EUReg:Confidentiality>               
            </EUReg:confidentiality>
            <EUReg:competentAuthorityEPRTR>
                <EUReg:CompetentAuthority>
                    <EUReg:organisationName>MINISTRY FOR PRTR</EUReg:organisationName>
                    <EUReg:individualName>Mr John Wayne</EUReg:individualName>
                    <EUReg:electronicMailAddress>john.wayne@fake.com</EUReg:electronicMailAddress>
                    <EUReg:address>
                        <EUReg:AddressDetails>
                            <EUReg:streetName>Ministry Street</EUReg:streetName>
                            <EUReg:buildingNumber>20</EUReg:buildingNumber>
                            <EUReg:city>MADRID</EUReg:city>
                            <EUReg:postalCode>28001</EUReg:postalCode>
                            <EUReg:countryCode xlink:href="http://dd.eionet.europa.eu/vocabulary/euregistryonindustrialsites/CountryCodeValue/ES"/>
                        </EUReg:AddressDetails>
                    </EUReg:address>
                    <EUReg:telephoneNo>+34 91 000 000</EUReg:telephoneNo>
                    <EUReg:faxNo>34 91 000 001</EUReg:faxNo>
                </EUReg:CompetentAuthority>
            </EUReg:competentAuthorityEPRTR>
            <EUReg:address>
                <EUReg:AddressDetails>
                    <EUReg:streetName>Administrative Street</EUReg:streetName>
                    <EUReg:buildingNumber>20</EUReg:buildingNumber>
                    <EUReg:city>BARCELONA</EUReg:city>
                    <EUReg:postalCode>8029</EUReg:postalCode>
                    <EUReg:countryCode xlink:href="http://dd.eionet.europa.eu/vocabulary/euregistryonindustrialsites/CountryCodeValue/ES"/>
                </EUReg:AddressDetails>
            </EUReg:address>
        </EUReg:ProductionFacility>
    </gml:featureMember>
   
    <gml:featureMember>
        <EUReg:ProductionInstallation gml:id="_010101011.INSTALLATION">
            <pf:inspireId>
                <base:Identifier>
                    <base:localId>010101011.INSTALLATION</base:localId>
                    <base:namespace>ES.CAED</base:namespace>
                </base:Identifier>
            </pf:inspireId>           
            <pf:pointGeometry>               
                <gml:Point gml:id="PI_point1" srsName="urn:ogc:def:crs:EPSG::4258" srsDimension="2">
                    <gml:pos>41.991931 2.104330</gml:pos>
                </gml:Point>         
            </pf:pointGeometry>
                                   
            <pf:name>FIRST INSTALLATION. S.A.</pf:name>
            <pf:status>
                <pf:StatusType>
                    <pf:statusType
                        xlink:href="http://dd.eionet.europa.eu/vocabulary/euregistryonindustrialsites/ConditionOfFacilityValue/functional"/>
                    <pf:validFrom xsi:nil="true"/>
                </pf:StatusType>
            </pf:status>
            <pf:type xsi:nil="true"/>
            <pf:groupedInstallationPart xlink:href="#_987654321.PART"/>
            
            <EUReg:etsId>ETS.5463.fake</EUReg:etsId>
            <EUReg:espirsId>Seveso1235.ES.fake</EUReg:espirsId>
            <EUReg:IEDAnnexIActivity>
                <EUReg:IEDAnnexIActivityType>
                    <EUReg:IEDAnnexIApplicable>true</EUReg:IEDAnnexIApplicable>
                    <EUReg:mainActivity
                        xlink:href="http://dd.eionet.europa.eu/vocabulary/euregistryonindustrialsites/IEDAnnexIActivityValue/1.1"/>
                </EUReg:IEDAnnexIActivityType>
            </EUReg:IEDAnnexIActivity>
            <EUReg:permit>
                <EUReg:PermitDetails>
                    <EUReg:permitGranted>true</EUReg:permitGranted>
                    <EUReg:permitReconsidered>false</EUReg:permitReconsidered>
                    <EUReg:permitUpdated>false</EUReg:permitUpdated>
                    <EUReg:dateOfGranting>1956-01-01</EUReg:dateOfGranting>
                </EUReg:PermitDetails>
            </EUReg:permit>
            <EUReg:otherRelevantChapters xlink:href="http://dd.eionet.europa.eu/vocabularyconcept/euregistryonindustrialsites/RelevantChapterValue/ChapterIII"/>
            <EUReg:inspections>2</EUReg:inspections>
            <EUReg:dateOfStartOfOperation>1956-01-01</EUReg:dateOfStartOfOperation>
            <EUReg:confidentiality>
                <EUReg:Confidentiality>
                    <EUReg:confidential>false</EUReg:confidential>
                </EUReg:Confidentiality>
            </EUReg:confidentiality>
            <EUReg:competentAuthorityInspections>
                <EUReg:CompetentAuthority>
                    <EUReg:organisationName>MINISTRY FOR IPPC – Compliance Department</EUReg:organisationName>
                    <EUReg:individualName>MRS KEANE WALTER</EUReg:individualName>
                    <EUReg:electronicMailAddress>keane.walter@fake.com</EUReg:electronicMailAddress>
                    <EUReg:address>
                        <EUReg:AddressDetails>
                            <EUReg:streetName>Ministry Street</EUReg:streetName>
                            <EUReg:buildingNumber>10</EUReg:buildingNumber>
                            <EUReg:city>MADRID</EUReg:city>
                            <EUReg:postalCode>28001</EUReg:postalCode>
                            <EUReg:countryCode xlink:href="http://dd.eionet.europa.eu/vocabulary/euregistryonindustrialsites/CountryCodeValue/ES"/>
                        </EUReg:AddressDetails>
                    </EUReg:address>
                    <EUReg:telephoneNo>+34 91 002 000</EUReg:telephoneNo>
                    <EUReg:faxNo>+ 34 91 002 001</EUReg:faxNo>
                </EUReg:CompetentAuthority>
            </EUReg:competentAuthorityInspections>
            <EUReg:competentAuthorityPermits>
                <EUReg:CompetentAuthority>
                    <EUReg:organisationName>MINISTRY FOR IPPC</EUReg:organisationName>
                    <EUReg:individualName>MR TOM RICHARDSON</EUReg:individualName>
                    <EUReg:electronicMailAddress>tom.richardson@fake.com</EUReg:electronicMailAddress>
                    <EUReg:address>
                        <EUReg:AddressDetails>
                            <EUReg:streetName>Ministry Street</EUReg:streetName>
                            <EUReg:buildingNumber>10</EUReg:buildingNumber>
                            <EUReg:city>MADRID</EUReg:city>
                            <EUReg:postalCode>28001</EUReg:postalCode>
                            <EUReg:countryCode xlink:href="http://dd.eionet.europa.eu/vocabulary/euregistryonindustrialsites/CountryCodeValue/ES"/>
                        </EUReg:AddressDetails>
                    </EUReg:address>
                    <EUReg:telephoneNo>+34 91 001 000</EUReg:telephoneNo>
                    <EUReg:faxNo>+ 34 91 001 001</EUReg:faxNo>
                </EUReg:CompetentAuthority>
            </EUReg:competentAuthorityPermits>
            <EUReg:batArticle15-4>false</EUReg:batArticle15-4>
            <EUReg:baselineReportArticle22>true</EUReg:baselineReportArticle22>
        </EUReg:ProductionInstallation>
    </gml:featureMember>
    
    
    
    <gml:featureMember>
        <EUReg:ProductionInstallation gml:id="_010101012.INSTALLATION">
            <pf:inspireId>
                <base:Identifier>
                    <base:localId>010101012.INSTALLATION</base:localId>
                    <base:namespace>ES.CAED</base:namespace>
                </base:Identifier>
            </pf:inspireId>
            
            <pf:pointGeometry>               
                <gml:Point gml:id="PI_point2" srsName="urn:ogc:def:crs:EPSG::4258" srsDimension="2">
                    <gml:pos>41.991929 2.104327</gml:pos>
                </gml:Point>         
            </pf:pointGeometry>  
            
            <pf:name>SECOND INSTALLATION. S.A.</pf:name>
            <pf:status>
                <pf:StatusType>
                    <pf:statusType
                        xlink:href="http://dd.eionet.europa.eu/vocabulary/euregistryonindustrialsites/ConditionOfFacilityValue/disused"/>
                    <pf:validFrom xsi:nil="true"/>
                </pf:StatusType>
            </pf:status>           
            <pf:type xsi:nil="true"/>
            <pf:groupedInstallationPart xlink:href="#_987654322.PART"/>
            <EUReg:etsId>ETS.54622.fake</EUReg:etsId>
            <EUReg:espirsId>Seveso1235.ES.fake</EUReg:espirsId>
            <EUReg:IEDAnnexIActivity>
                <EUReg:IEDAnnexIActivityType>
                    <EUReg:IEDAnnexIApplicable>true</EUReg:IEDAnnexIApplicable>
                    <EUReg:mainActivity
                        xlink:href="http://dd.eionet.europa.eu/vocabulary/euregistryonindustrialsites/IEDAnnexIActivityValue/1.1"/>
                </EUReg:IEDAnnexIActivityType>
            </EUReg:IEDAnnexIActivity>
            <EUReg:permit>
                <EUReg:PermitDetails>
                    <EUReg:permitGranted>true</EUReg:permitGranted>
                    <EUReg:permitReconsidered>false</EUReg:permitReconsidered>
                    <EUReg:permitUpdated>false</EUReg:permitUpdated>
                    <EUReg:dateOfGranting>1982-01-01</EUReg:dateOfGranting>
                </EUReg:PermitDetails>
            </EUReg:permit>
            <EUReg:otherRelevantChapters xlink:href="http://dd.eionet.europa.eu/vocabulary/euregistryonindustrialsites/RelevantChapterValue/ChapterIII"/>
            <EUReg:inspections>0</EUReg:inspections>
            <EUReg:dateOfStartOfOperation>1982-01-01</EUReg:dateOfStartOfOperation>
            <EUReg:confidentiality>
                <EUReg:Confidentiality>
                    <EUReg:confidential>true</EUReg:confidential>
                    <EUReg:description xlink:href="http://dd.eionet.europa.eu/vocabulary/euregistryonindustrialsites/ReasoningValue/Article4(2)(e)"/>
                </EUReg:Confidentiality>               
            </EUReg:confidentiality>
            <EUReg:competentAuthorityInspections>
                <EUReg:CompetentAuthority>
                    <EUReg:organisationName>MINISTRY FOR IPPC – Compliance Department</EUReg:organisationName>
                    <EUReg:individualName>MRS KEANE WALTER</EUReg:individualName>
                    <EUReg:electronicMailAddress>keane.walter@fake.com</EUReg:electronicMailAddress>
                    <EUReg:address>
                        <EUReg:AddressDetails>
                            <EUReg:streetName>Ministry Street</EUReg:streetName>
                            <EUReg:buildingNumber>10</EUReg:buildingNumber>
                            <EUReg:city>MADRID</EUReg:city>
                            <EUReg:postalCode>28001</EUReg:postalCode>
                            <EUReg:countryCode xlink:href="http://dd.eionet.europa.eu/vocabulary/euregistryonindustrialsites/CountryCodeValue/ES"/>
                        </EUReg:AddressDetails>
                    </EUReg:address>
                    <EUReg:telephoneNo>+34 91 002 000</EUReg:telephoneNo>
                    <EUReg:faxNo>+ 34 91 002 001</EUReg:faxNo>
                </EUReg:CompetentAuthority>
            </EUReg:competentAuthorityInspections>
            <EUReg:competentAuthorityPermits>
                <EUReg:CompetentAuthority>
                    <EUReg:organisationName>MINISTRY FOR IPPC</EUReg:organisationName>
                    <EUReg:individualName>MR TOM RICHARDSON</EUReg:individualName>
                    <EUReg:electronicMailAddress>tom.richardson@fake.com</EUReg:electronicMailAddress>
                    <EUReg:address>
                        <EUReg:AddressDetails>
                            <EUReg:streetName>Ministry Street</EUReg:streetName>
                            <EUReg:buildingNumber>10</EUReg:buildingNumber>
                            <EUReg:city>MADRID</EUReg:city>
                            <EUReg:postalCode>28001</EUReg:postalCode>
                            <EUReg:countryCode xlink:href="http://dd.eionet.europa.eu/vocabulary/euregistryonindustrialsites/CountryCodeValue/ES"/>
                        </EUReg:AddressDetails>
                    </EUReg:address>
                    <EUReg:telephoneNo>+34 91 001 000</EUReg:telephoneNo>
                    <EUReg:faxNo>+ 34 91 001 001</EUReg:faxNo>
                </EUReg:CompetentAuthority>
            </EUReg:competentAuthorityPermits>
            <EUReg:batArticle15-4>true</EUReg:batArticle15-4>
            <EUReg:baselineReportArticle22>true</EUReg:baselineReportArticle22>
        </EUReg:ProductionInstallation>
    </gml:featureMember>
   
    <gml:featureMember>
        <EUReg:ProductionInstallationPart gml:id="_987654321.PART">
            <pf:inspireId>
                <base:Identifier>
                    <base:localId>987654321.PART</base:localId>
                    <base:namespace>ES.CAED</base:namespace>
                </base:Identifier>
            </pf:inspireId>
            
            <pf:pointGeometry>
                <gml:Point gml:id="PIP_point1" srsName="urn:ogc:def:crs:EPSG::4258" srsDimension="2">
                    <gml:pos>41.991929 2.104327</gml:pos>
                </gml:Point>
            </pf:pointGeometry>
            
            <pf:name>FIRST INSTALLATION S.A. – Plant 1</pf:name>
            <pf:status>
                <pf:StatusType>
                    <pf:statusType xlink:href="http://dd.eionet.europa.eu/vocabulary/euregistryonindustrialsites/ConditionOfFacilityValue/functional"/>
                    <pf:validFrom xsi:nil="true"/>
                </pf:StatusType>
            </pf:status>
            <pf:type xsi:nil="true"/>
            <pf:technique xsi:nil="true"/>
            <EUReg:MWth>125</EUReg:MWth>
            <EUReg:specificConditions/>
            <EUReg:nominalCapacity>
                <EUReg:CapacitySIWI/>
            </EUReg:nominalCapacity>
            <EUReg:derogations/>
            <EUReg:dateOfStartOfOperation>1956-01-01</EUReg:dateOfStartOfOperation>
            <EUReg:confidentiality>
                <EUReg:Confidentiality>
                    <EUReg:confidential>false</EUReg:confidential>
                </EUReg:Confidentiality>
            </EUReg:confidentiality>
            <EUReg:plantType xlink:href="http://dd.eionet.europa.eu/vocabulary/euregistryonindustrialsites/PlantTypeValue/LCP"/>
        </EUReg:ProductionInstallationPart>
    </gml:featureMember>
    
    <gml:featureMember>
        <EUReg:ProductionInstallationPart gml:id="_987654322.PART">
            <pf:inspireId>
                <base:Identifier>
                    <base:localId>987654322.PART</base:localId>
                    <base:namespace>ES.CAED</base:namespace>
                </base:Identifier>
            </pf:inspireId>
            <pf:pointGeometry>
                <gml:Point gml:id="PIP_point2" srsName="urn:ogc:def:crs:EPSG::4258" srsDimension="2">
                    <gml:pos>41.991931 2.104330</gml:pos>
                </gml:Point>
            </pf:pointGeometry> 
            <pf:name>SECOND INSTALLATION S.A. – Plant 2</pf:name>
            <pf:status>
                <pf:StatusType>
                    <pf:statusType xlink:href="http://dd.eionet.europa.eu/vocabulary/euregistryonindustrialsites/ConditionOfFacilityValue/disused"/>
                    <pf:validFrom xsi:nil="true"/>
                </pf:StatusType>
            </pf:status>
            <pf:type xsi:nil="true"/>
            <pf:technique xsi:nil="true"/>
            <EUReg:MWth>55</EUReg:MWth>
            <EUReg:specificConditions/>
            <EUReg:nominalCapacity>
                <EUReg:CapacitySIWI/>
            </EUReg:nominalCapacity>
            <EUReg:derogations xlink:href="http://dd.eionet.europa.eu/vocabularyconcept/euregistryonindustrialsites/DerogationValue/Article33/view?facet=HTML+Representation"/>
            <EUReg:dateOfStartOfOperation>1982-01-01</EUReg:dateOfStartOfOperation>
            <EUReg:confidentiality>
                <EUReg:Confidentiality>
                    <EUReg:confidential>false</EUReg:confidential>
                </EUReg:Confidentiality>
            </EUReg:confidentiality>
            <EUReg:plantType xlink:href="http://dd.eionet.europa.eu/vocabulary/euregistryonindustrialsites/PlantTypeValue/LCP"/>
        </EUReg:ProductionInstallationPart>
    </gml:featureMember>
    
    
</gml:FeatureCollection>
