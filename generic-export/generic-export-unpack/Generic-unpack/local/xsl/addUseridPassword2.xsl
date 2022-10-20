<?xml version="1.0" encoding="UTF-8"?>
<!-- 

  This stylesheet sets a canned userid/password in a Basic Auth header for the current request.

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


  <xsl:variable name="uid" select="'delta'"/>
  <xsl:variable name="pwd" select="'pass1word'"/>

  
  
  
  <xsl:template match="/">
    
    <dp:set-request-header name="'Authorization'" value="concat('Basic ', dp:encode(concat($uid, ':', $pwd), 'base-64'))"/>
    <dp:set-variable name="'var://service/routing-url'" value="'https://loyaltyservices.pt1.cxloyaltyservices.com/LoyaltyExternalGateway/CreateIncentive/1.0'"/>
<!--value="'https://loyaltyservices.devel.cxloyaltyservices.com/LoyaltyExternalGateway/CreateIncentive/1.0'"/> -->
    <xsl:copy-of select="."/>
    
  </xsl:template>

</xsl:stylesheet>