
# Script to split lookup tables into separate tables per country

from collections import defaultdict
from lxml import etree
import os

feature_names = [
    "ProductionFacility",
    "ProductionSite",
    "ProductionInstallationPart",
    "ProductionInstallation",
]

for feature_name in feature_names:
    print("###Starting", feature_name)
    filename = '{}.xml'.format(feature_name)

    input_data = etree.parse('lookup-tables/{}'.format(filename))
    feature_nodes = input_data.findall(feature_name)

    output_data = defaultdict(list)

    if not os.path.exists(feature_name):
        os.makedirs(feature_name)

    for node in feature_nodes:
        country_id = node.find('countryId').attrib.values()[0]
        output_data[country_id].append(node)

    for country_id, nodes in output_data.items():
        print("Starting ", country_id)
        out_filename = '{}_{}'.format(country_id, filename)
        output_file = os.path.join(feature_name, out_filename)

        document_node = etree.Element('data')
        root = etree.ElementTree(document_node)

        for node in nodes:
            document_node.append(node)

        root.write(output_file,
                   encoding=None,
                   method="xml",
                   pretty_print=True)
