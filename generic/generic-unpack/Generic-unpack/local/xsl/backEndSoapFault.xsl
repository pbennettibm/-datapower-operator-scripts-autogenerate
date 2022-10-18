<?xml version="1.0" encoding="UTF-8" ?> 
<!-- 
This is to log messages
  --> 
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:date="http://exslt.org/dates-and-times" xmlns:dp="http://www.datapower.com/extensions" xmlns:dpconfig="http://www.datapower.com/param/config" xmlns:dpquery="http://www.datapower.com/param/query" xmlns:dyn="http://exslt.org/dynamic" xmlns:exslt="http://exslt.org/common" xmlns:func="http://exslt.org/functions" xmlns:local="urn:local:function" xmlns:mgmt="http://www.datapower.com/schemas/management" xmlns:regexp="http://exslt.org/regular-expressions" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope" xmlns:str="http://exslt.org/strings" extension-element-prefixes="date dp dyn exslt func regexp str" xmlns:v1="http://schemas.delta.com/common/shoppoctypes/v1" exclude-result-prefixes="date dp dpconfig dpquery dyn exslt func regexp str">

<xsl:include href="util-id.xsl"/>
<xsl:template match="/">

<xsl:variable name="ServiceName" select="dp:variable('var://context/ActiveMatrixESB/serviceName')"/>
<xsl:variable name="CounterName" select="concat('/monitor-count/', $ServiceName, 'BackEndSoapFaultCt')"/>

<dp:increment-integer name="$CounterName"/>

<xsl:message dp:priority="info">########Counter Name: <xsl:value-of select="$CounterName"/> ####### </xsl:message>


  <xsl:copy-of select="/" /> 

  </xsl:template>
  </xsl:stylesheet>