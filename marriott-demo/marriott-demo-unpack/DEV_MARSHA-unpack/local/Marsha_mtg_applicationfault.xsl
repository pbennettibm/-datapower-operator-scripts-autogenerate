<?xml version="1.0" encoding="UTF-8" ?> 
<xsl:stylesheet version="1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:dp="http://www.datapower.com/extensions" xmlns:dpconfig="http://www.datapower.com/param/config" extension-element-prefixes="dp" exclude-result-prefixes="dp dpconfig" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:svc="http://marsha.marriott.com/services/Availability/v1" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" indent="yes" /> 
<xsl:template match="/">
<soap:Envelope>
<soap:Body>
<soap:Fault>
  <faultcode>soap:Server</faultcode> 
<faultstring>
  <xsl:copy-of select="dp:variable('var://service/error-message')" /> 
  </faultstring>
<detail>
<svc:ApplicationFault>
<svc:Error>
  <svc:ErrorCode>system.error</svc:ErrorCode> 
<svc:ErrorString>
  <xsl:copy-of select="dp:variable('var://service/error-message')" /> 
  </svc:ErrorString>
<svc:ErrorDetail>
  transaction-id: 
  <xsl:copy-of select="dp:variable('var://service/transaction-id')" /> 
  error-code: 
  <xsl:copy-of select="dp:variable('var://service/error-code')" /> 
  error-subcode: 
  <xsl:value-of select="dp:variable('var://service/error-subcode')" /> 
  </svc:ErrorDetail>
  </svc:Error>
  </svc:ApplicationFault>
  </detail>
  </soap:Fault>
  </soap:Body>
  </soap:Envelope>
  </xsl:template>
<xsl:template match="TESTING">
<soap:Envelope xsi:schemaLocation="http://marsha.marriott.com/services/Availability/v1/ MARSHA_AvailabilityOperations_v1_1.xsd http://schemas.xmlsoap.org/soap/envelope/ envelope.xsd">
<soap:Body>
<soap:Fault>
  <faultcode>soap:Server</faultcode> 
  <faultstring>xsl:copy-of select="dp:variable('var://service/error-message')"</faultstring> 
<detail>
<svc:ApplicationFault>
<svc:Error>
  <svc:ErrorCode>system.error</svc:ErrorCode> 
  <svc:ErrorString>xsl:copy-of select="dp:variable('var://service/error-message')"</svc:ErrorString> 
  <svc:ErrorDetail>transaction-id: xsl:copy-of select="dp:variable('var://service/transaction-id')" error-code: xsl:copy-of select="dp:variable('var://service/error-code')" error-subcode: xsl:value-of select="dp:variable('var://service/error-subcode')"</svc:ErrorDetail> 
  </svc:Error>
  </svc:ApplicationFault>
  </detail>
  </soap:Fault>
  </soap:Body>
  </soap:Envelope>
  </xsl:template>
  </xsl:stylesheet>