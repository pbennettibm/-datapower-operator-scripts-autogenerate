<?xml version="1.0" encoding="UTF-8" ?> 
<!-- 
This file is a request logging file with filter library included as optional. The default is to remove the WS-Security so that the request can be logged safely.
Must this filterLibrary.xsl for functionality.
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

<xsl:include href="filterLibrary.xsl"/>
<xsl:template match="/">
<!-- <xsl:variable name="LogCat" select="concat(dp:variable('var://service/domain-name'), 'Trans')"/> -->
<xsl:variable name="LogCatDebug" select="concat(dp:variable('var://service/domain-name'), 'Debug')"/>
<xsl:variable name="DebugVar" select="dp:variable('var://context/ActiveMatrixESB/debug-var')"/>
<xsl:variable name="ServiceName" select="dp:variable('var://context/ActiveMatrixESB/serviceName')"/>
 <xsl:variable name="proxyURI" select="dp:variable('var://service/URI')"/>
 <xsl:variable name="dbquote">&quot;</xsl:variable> 
 <xsl:variable name="operationSOAP" select="substring-after(dp:variable('var://service/wsm/operation'),'}')"/>
 <xsl:variable name="operationName" select="dp:variable('var://context/ActiveMatrixESB/operation')"/>

    <xsl:variable name="LogCat">
    <xsl:choose>
	<!--<xsl:when test="($ServiceName='pnrcommon_4') or ($ServiceName='pnrcommon_5') or ($ServiceName='pnrcommon_6') "> -->
	<xsl:when test="contains($ServiceName,'pnrcommon')">
	    <xsl:value-of select="'PnrCommon'"/>
	</xsl:when>
	<xsl:when test="contains($ServiceName,'shop')">
	    <xsl:value-of select="'Shop'"/>
	</xsl:when>
	<xsl:when test="contains($ServiceName,'hostcontext')">
	    <xsl:value-of select="'Hostcontext'"/>
	</xsl:when>
	<xsl:when test="contains($ServiceName,'loyalty')">
	    <xsl:value-of select="'Loyalty'"/>
	</xsl:when>
	<xsl:when test="contains($ServiceName,'seat')">
	    <xsl:value-of select="'Seat'"/>
	</xsl:when>
	<xsl:when test="contains($ServiceName,'flight')">
	    <xsl:value-of select="'Flight'"/>
	</xsl:when>					
	<xsl:otherwise>
	    <xsl:value-of select="concat(dp:variable('var://service/domain-name'), 'Trans')"/>
	</xsl:otherwise>
    </xsl:choose>
    </xsl:variable>

 <xsl:message dp:type="{$LogCat}" dp:priority="info">
    <xsl:value-of select=" concat('[',$ServiceName,'] [',$operationName, '] SOAPResponse:')" />
    <!--<xsl:copy-of select="filter:expungeWSSec(.)"/>-->
       <xsl:copy-of select="filter:expungeWSSec(filter:obscureCreditCardInfo((.)))"/>
 </xsl:message>

    <xsl:if test="$DebugVar">
       <xsl:message dp:type="{$LogCatDebug}" dp:priority="info">
          <xsl:value-of select=" concat('[',$ServiceName,'] [',$operationName, '] SOAPResponse:')" />
          <!--<xsl:copy-of select="filter:expungeWSSec(.)"/>-->
       <xsl:copy-of select="filter:expungeWSSec(filter:obscureCreditCardInfo((.)))"/>
       </xsl:message>
    </xsl:if>
    
    
<!--NOT NEEDED OR USED BECAUSE OUTPUT IS NOT CREATED<xsl:copy-of select="/" />--> 

  </xsl:template>
  </xsl:stylesheet>