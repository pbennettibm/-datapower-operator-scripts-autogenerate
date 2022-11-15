<?xml version="1.0" encoding="UTF-8"?>
<!-- 
This is to log messages
  -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:date="http://exslt.org/dates-and-times" xmlns:dp="http://www.datapower.com/extensions" xmlns:dpconfig="http://www.datapower.com/param/config" xmlns:dpquery="http://www.datapower.com/param/query" xmlns:dyn="http://exslt.org/dynamic" xmlns:exslt="http://exslt.org/common" xmlns:func="http://exslt.org/functions" xmlns:local="urn:local:function" xmlns:mgmt="http://www.datapower.com/schemas/management" xmlns:regexp="http://exslt.org/regular-expressions" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope" xmlns:str="http://exslt.org/strings" extension-element-prefixes="date dp dyn exslt func regexp str" xmlns:v1="http://schemas.delta.com/common/shoppoctypes/v1" exclude-result-prefixes="date dp dpconfig dpquery dyn exslt func regexp str" xmlns:svg="http://www.w3.org/2000/svg">
	
	<xsl:include href="AuthType-Util-mpg.xsl"/>
	
	<!-- Capture credentials, since these are used in a number of places. -->
   <xsl:variable name="DN" select="dp:variable('var://context/creds/DN')"/>
    <xsl:variable name="OU" select="dp:variable('var://context/creds/OU')"/>
    <xsl:variable name="CN" select="dp:variable('var://context/creds/CN')"/>
    <xsl:variable name="Uid" select="dp:variable('var://context/creds/uid')"/>

    
    <!--<xsl:variable name="DN" select="local:getIdDN(.)"/>
    <xsl:variable name="CN" select="local:CNfromDN($DN)"/>
    <xsl:variable name="OU" select="local:OUfromDN($DN)"/>
    <xsl:variable name="baVal" select="local:getIdBasicAuth()"/>
    <xsl:variable name="userID" select = "local:getId(.)"/> -->
    
    
	<xsl:variable name="controlFilesPrefix" select="'local:///control/'"/>
	<xsl:variable name="mapFileName" select="concat($controlFilesPrefix, 'access.xml')"/>
	<xsl:variable name="mapFile" select="document($mapFileName)"/>
	<xsl:variable name="input" select="/"/>
	
	<xsl:variable name="AppID" select="$input/*[local-name()='Envelope']/*[local-name()='Body']/*/*[local-name()='RequestInfo']/@ApplicationId"/>
	
	<!-- this template is applied by default to all nodes and attributes -->
	<xsl:template match="@*|node()">
		<!-- just copy all my attributes and child nodes, except if there's a better template for some of them -->
		<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:variable name="newAppID">
		<xsl:message>#####DN is zprt <xsl:value-of select="$DN"/>
		</xsl:message>
		<xsl:message>#####OU is zprt <xsl:value-of select="$OU"/>
		</xsl:message>
		<xsl:message>#####Uid is zprt <xsl:value-of select="$Uid"/>
		</xsl:message>
		<xsl:message>#####CN is zprt <xsl:value-of select="$CN"/>
		</xsl:message>
		<xsl:choose>
			<xsl:when test="$mapFile/access/vendor[@OU= $OU]">
				<xsl:message>#### The AppID was changed to: <xsl:value-of select="$mapFile/access/vendor/@intApplicationId"/>
				</xsl:message>
				<xsl:value-of select="$mapFile/access/vendor/@intApplicationId"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:message>#### The OU was not found </xsl:message>
				<xsl:value-of select="$input/*[local-name()='Envelope']/*[local-name()='Body']/*/*[local-name()='RequestInfo']/@ApplicationId"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	
	<!-- this template is applied to an existing fill attribute -->
	<xsl:template match="/*[local-name()='Envelope']/*[local-name()='Body']/*/*[local-name()='RequestInfo']/@ApplicationId">
		<!-- produce a fill attribute with content "red" -->
		<xsl:attribute name="ApplicationId"><xsl:value-of select="$newAppID"/></xsl:attribute>
	</xsl:template>
	
	<xsl:template match="/*[local-name()='Envelope']/*[local-name()='Body']/*/*[local-name()='RequestInfo']">
		<xsl:copy>
			<xsl:attribute name="newatt">static string</xsl:attribute>
			<xsl:apply-templates select="node()|@*"/>
		</xsl:copy>
	</xsl:template>

</xsl:stylesheet>