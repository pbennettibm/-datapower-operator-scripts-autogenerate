<?xml version="1.0" encoding="UTF-8"?>
<!-- 

  This stylesheet will perform a verification of the value provided for the dynamic end point url to ensure 
  it is going to the correct location and not being used incorrectly to access other servcies.
  
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
  xmlns:local="urn:local:function"
  xmlns:mgmt="http://www.datapower.com/schemas/management"
  xmlns:regexp="http://exslt.org/regular-expressions"
  xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
  xmlns:str="http://exslt.org/strings"
  extension-element-prefixes="date dp dyn exslt func regexp str" 
  exclude-result-prefixes="date dp dpconfig dpquery dyn exslt func regexp str">
 

  <xsl:template match="/">
        <xsl:variable name="HostValue" select="dp:http-request-header('Host')"/>
        <xsl:variable name="ClientIP" select="dp:http-request-header('X-Forwarded-For')"/>
  	<xsl:variable name="targetURL" select="dp:http-request-header('targetURL')"/>
   <!--Splits requested URL into pieces making it easier to verify each piece if necessary--> 
       <xsl:variable select="'(\w+):\/\/([^/:]+)(:\d*)?(.*)'" name="urlRegExp"/> 
       <xsl:variable select="regexp:match($targetURL, $urlRegExp)" name="urlPieces"/> 
   <!-- Given a backend url, http://ip:port/uri, the regexp match will return: [1]http://ip:port/uri [2]http [3]ip [4]port [5]/uri -->
   	<xsl:variable select="$urlPieces[3]" name="domain"/>
   	<xsl:message dp:priority="error">The targeted domain is : <xsl:value-of select="$urlPieces[3]"/></xsl:message>
   	
   	
   	<xsl:variable name="backendDomain">
   	  <xsl:choose>
   		<xsl:when test="contains($domain,'salesforce.com')">
               		<xsl:message dp:priority="error"> The request was verified to be going to the allowed domain.</xsl:message>
          	</xsl:when> 
          	<xsl:otherwise>
             		<dp:reject>The client did not specify a valid backend domain with this call.</dp:reject>
             		<xsl:message dp:priority="error"> The request did not match an allowed backend domain. Check the targetURL value and notify client.</xsl:message>
          	</xsl:otherwise>
         </xsl:choose>
     	</xsl:variable>
     
     
      <!--Security Based on IP address-->	
     	 <xsl:variable name="IPCheck">
     	  <xsl:choose>
     		<xsl:when test="($HostValue='soaws-test.delta.com:4040')">
     		 <xsl:message> The request matched to an allowed IP address for ST.</xsl:message>
                <xsl:value-of select="'allow ST'"/>
             </xsl:when>
             <xsl:when test="($HostValue='soaws-si.delta.com:4010') and ($ClientIP='139.72.118.194' or $ClientIP='10.12.165.178' or $ClientIP='10.67.57.112' or $ClientIP='147.118.33.224' or $ClientIP='147.118.33.226' or $ClientIP='147.118.35.221' or $ClientIP='147.118.35.222')">
     		 <xsl:message> The request matched to an allowed IP address for SI and DEV.</xsl:message>
                <xsl:value-of select="'allow DEV'"/>
             </xsl:when>
     	    <xsl:when test="($HostValue='soaws.delta.com:4010') and ($ClientIP='10.68.89.119' or $ClientIP='10.68.89.120' or $ClientIP='10.68.91.171' or $ClientIP='10.68.91.172' or $ClientIP='10.12.165.178')">
	         <xsl:message> The request matched to an allowed IP address for SI and DEV</xsl:message>
                <xsl:value-of select="'allow PROD'"/>
             </xsl:when>
              <xsl:otherwise>
               <dp:reject>The client did not match an allowed IP address.</dp:reject>
               <xsl:message dp:priority="error"> The request did not match a configured allowed IP address for an associated environment.</xsl:message>
             </xsl:otherwise>
             </xsl:choose>
	  </xsl:variable>
     
     
     
    <!--No content is changed only the target url is set-->
    <xsl:copy-of select="."/>
   </xsl:template>
  
</xsl:stylesheet>