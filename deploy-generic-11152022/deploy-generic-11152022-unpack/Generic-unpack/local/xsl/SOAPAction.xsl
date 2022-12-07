<?xml version="1.0" encoding="UTF-8" ?> 
<!-- 
This file includes a SOAP Action if none is included or specifically adds SOAP Actions for specified services based on uri
  --> 
<xsl:stylesheet version="1.0" 
xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
xmlns:xsd="http://www.w3.org/2001/XMLSchema" 
xmlns:date="http://exslt.org/dates-and-times" 
xmlns:dp="http://www.datapower.com/extensions" 
xmlns:dpconfig="http://www.datapower.com/param/config" 
xmlns:dpquery="http://www.datapower.com/param/query" 
xmlns:dyn="http://exslt.org/dynamic" 
xmlns:exslt="http://exslt.org/common" 
xmlns:func="http://exslt.org/functions" 
xmlns:filter="urn:filter:library"
xmlns:local="urn:local:function" 
xmlns:mgmt="http://www.datapower.com/schemas/management" 
xmlns:regexp="http://exslt.org/regular-expressions" 
xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" 
xmlns:soap12="http://www.w3.org/2003/05/soap-envelope" 
xmlns:str="http://exslt.org/strings" 
extension-element-prefixes="date dp dyn exslt func regexp str" 
xmlns:v1="http://schemas.delta.com/common/shoppoctypes/v1" 
exclude-result-prefixes="date dp dpconfig dpquery dyn exslt func regexp str">


<xsl:template match="/">
 <xsl:variable name="LogCat" select="concat(dp:variable('var://service/domain-name'), 'Error')"/>
 <xsl:variable name="LogCatDebug" select="concat(dp:variable('var://service/domain-name'), 'Debug')"/>
 <xsl:variable name="ServiceName" select="dp:variable('var://service/processor-name')"/>
 <xsl:variable name="proxyURI" select="dp:variable('var://service/URI')"/>
 <xsl:variable name="dbquote">&quot;</xsl:variable> 
 <xsl:variable name="operationSOAP" select="substring-after(dp:variable('var://service/wsm/operation'),'}')"/>

<!-- 
Added this section to deal with SoapAction missing
  --> 
 <xsl:choose>
    <xsl:when test="dp:http-request-header('SOAPAction') = '' or dp:http-request-header('SOAPAction') = '&quot;&quot;'">
          <xsl:choose>
          <xsl:when test="$proxyURI='/eProxy/resadapter'">
		  <xsl:variable name="operationName" select="concat($dbquote, '/Service/RESAdapter-service.serviceagent/RESAdapterServicePortTypeEndpoint1/',$operationSOAP, $dbquote)"/>
		  <dp:set-http-request-header name="'SOAPAction'" value="$operationName"/>
          <xsl:message dp:type="{$LogCat}" dp:priority="warning">***The SOAP Action was not supplied for RESAdapter. The SOAP Action was added with this value "<xsl:value-of select="$operationName"/>" .</xsl:message>
          </xsl:when>
          <xsl:when test="($proxyURI='/eProxy/vendorservice') or ($proxyURI='/eProxy/vendorservice3') or ($proxyURI='/eProxy/vendorservice2')">
		  <xsl:variable name="operationName" select="concat(substring-before(substring-after(dp:variable('var://service/wsm/operation'),'{'),'}'),substring-after(dp:variable('var://service/wsm/operation'),'}'))"/>
          <dp:set-http-request-header name="'SOAPAction'" value="$operationName"/>
          <xsl:message dp:type="{$LogCat}" dp:priority="warning">***The SOAP Action was not supplied for VendorService. The SOAP Action was added with this value "<xsl:value-of select="$operationName"/>" .</xsl:message>
          </xsl:when>
          <xsl:otherwise> 
          <xsl:variable name="operationName" select="substring-before(dp:variable('var://context/ActiveMatrixESB/operation'),'Request')"/>
		  <dp:set-http-request-header name="'SOAPAction'" value="$operationName"/>   
          <xsl:message dp:type="{$LogCat}" dp:priority="warning">***The SOAP Action was not supplied for <xsl:value-of select="$ServiceName"/>. The SOAP Action was added with this value "<xsl:value-of select="$operationName"/>" .</xsl:message>     
          </xsl:otherwise>  
		</xsl:choose>
	</xsl:when>
  </xsl:choose>
  <xsl:copy-of select="/" />
  </xsl:template>
  </xsl:stylesheet>