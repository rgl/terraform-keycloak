#!/bin/python3
from urllib.parse import urlparse, parse_qs
from base64 import b64decode
import xml.etree.ElementTree as ET
import zlib

# NB you should replace this value with your own.
url = 'https://login.microsoftonline.com/00000000-0000-0000-0000-000000000000/saml2?SAMLRequest=TODO'

u = urlparse(url)

qs = parse_qs(u.query)

data_base64 = qs['SAMLRequest'][0]

data_deflated = b64decode(data_base64)

if data_deflated[0] != ord('<'):
    data = zlib.decompress(data_deflated, -15)
else:
    data = data_deflated

data_xml = data.decode('utf-8')

print('XML:\n')
print(data_xml)

print('\nFormatted XML:\n')
data_element = ET.fromstring(data_xml)
ET.indent(data_element)
print(ET.tostring(data_element, encoding='unicode'))
print('\nWARNING: The previous formatted XML is not exactly like the original (e.g. XML prefixes might be different), but it should be semantically equivalent.')
