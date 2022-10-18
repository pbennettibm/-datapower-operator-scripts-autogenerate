<?xml version="1.0" encoding="UTF-8"?>
<!-- 

  This stylesheet will check to see if the Request Header is populated and if it is then use that value as the new backend server target.  The header should provide a full url.

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
  
   <!--Provided by APP team and used to redirect request-->
     <xsl:variable name="targetURL" select="dp:http-request-header('targetURL')"/>
     <xsl:message dp:type="{$LogCat}" dp:priority="info">#####targetURL Value for SalesForce backend:<xsl:value-of select="$targetURL"/></xsl:message>
     
     <!--Splits requested URL into pieces making it easier to manage the redirect--> 
     <xsl:variable select="'(\w+):\/\/([^/:]+)(:\d*)?(.*)'" name="urlRegExp"/> 
     <xsl:variable select="regexp:match($targetURL, $urlRegExp)" name="urlPieces"/> 
   <!-- Given a backend url, http://ip:port/uri, the regexp match will return: [1]http://ip:port/uri [2]http [3]ip [4]port [5]/uri -->
    
      
      
    <xsl:choose>
   <xsl:when test="$targetURL != ''" >
     <dp:set-variable name="'var://service/routing-url'" value="$targetURL" />
     <xsl:message dp:type="{$LogCat}" dp:priority="info">#####targetURL Value for SalesForce backend:<xsl:value-of select="$targetURL"/> was used to direct the request.  If url is not correct it came from the client.  Client must update it.</xsl:message>
    </xsl:when>  
  
   <xsl:otherwise>
      <dp:reject>The SalesForce client did not specify a backend server with this call.</dp:reject>
      <xsl:message dp:type="{$LogCat}" dp:priority="info">#####targetURL Value for SalesForce backend:<xsl:value-of select="$targetURL"/> was blank and it can't be blank per App team request to reject if blank.</xsl:message>
   </xsl:otherwise>
  </xsl:choose>  
    
    
    <!--No content is changed only the target url is set-->
    <xsl:copy-of select="."/>
  </xsl:template>

</xsl:stylesheet>