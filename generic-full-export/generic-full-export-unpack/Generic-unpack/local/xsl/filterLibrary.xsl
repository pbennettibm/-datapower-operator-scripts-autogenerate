<?xml version="1.0" encoding="UTF-8"?>
<!-- 

  This stylesheet implements a filter library, functions that can "filter" a nodeset by removing elements or
  attributes, or rewriting elements or attributes.
  
  Each of these functions relies on its own set of templates that implement the copy idiom.
  
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
  xmlns:filter="urn:filter:library"
  xmlns:func="http://exslt.org/functions"
  xmlns:local="urn:local:function"
  xmlns:mgmt="http://www.datapower.com/schemas/management"
  xmlns:regexp="http://exslt.org/regular-expressions"
  xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
  xmlns:str="http://exslt.org/strings"
  xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
  extension-element-prefixes="date dp dyn exslt func regexp str" 
  exclude-result-prefixes="date dp dpconfig dpquery dyn exslt func regexp str">

  <!-- 
    Rewrite the SpecialServiceRequest/@Remarks field for FQTV and OAID cases.  Kelvin needed this.
  -->
  <func:function name="filter:rewriteRemarks">
    <xsl:param name="nodeset"/>
    <func:result>
      <xsl:apply-templates select="$nodeset" mode="filter:rewriteRemarks"/>
    </func:result>
  </func:function>
  
  <xsl:template match="/" mode="filter:rewriteRemarks">
    <xsl:copy>
      <xsl:apply-templates select="node()" mode="filter:rewriteRemarks"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="*" mode="filter:rewriteRemarks">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" mode="filter:rewriteRemarks"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="@Remarks[name(..) = 'SpecialServiceRequest' and ../@RequestCode='FQTV']" mode="filter:rewriteRemarks">
    <!-- 
      Given Remarks="/AF1425528881.2-BAGOURD/CHRISTIANMR", the regular expression will match:
      ([^\.]+) matches all the characters (at least one chr is required) preceding a period (e.g. /AF1425528881)
      \.. matches a period followed by any single character (e.g. .2)
      (.+) matches the rest of the characters ('+' implies that there must be at least one character)
      In the output expression:
      $1 is the string matched by ([^\.]+)
      .* are literal characters
      $2 is the string matched by (.+)
    -->
    <xsl:attribute name="Remarks">
      <xsl:value-of select="regexp:replace(., '([^\.]+)\..(.+)', '', '$1.*$2')"/>
    </xsl:attribute>
  </xsl:template>
  
  <xsl:template match="@Remarks[name(..) = 'SpecialServiceRequest' and ../@RequestCode='OAID']" mode="filter:rewriteRemarks">
    <!--
      Given Remarks="/AF1425528881 **AF PLATINUM**", the regular expression will match:
      (.+?) matches all characters up to the first '**' literal
      \*\* matches a two asterisks
      (.+) matches up to the next two asterisks
      \*\* matches two asterisks
      The output expression copies the first part (matching (.+?)) and simply drops the part
      between the pairs of asterisks.  Actually, if there were anything following the second pair
      of asterisks, that would be dropped too.
    -->
    <xsl:attribute name="Remarks">
      <xsl:value-of select="regexp:replace(., '(.+?)\*\*(.+)\*\*', '', '$1****')"/>
    </xsl:attribute>
  </xsl:template>
  
  <xsl:template match="@* | text() | comment() | processing-instruction()" mode="filter:rewriteRemarks">
    <xsl:copy-of select="."/>
  </xsl:template>
  
  
  
  
  <!-- 
    Remove any WS-Security header.
  -->
  <func:function name="filter:expungeWSSec">
    <xsl:param name="nodeset"/>
    <func:result>
      <xsl:apply-templates select="$nodeset" mode="filter:expungeWSSec"/>
    </func:result>
  </func:function>
  
  <xsl:template match="/" mode="filter:expungeWSSec">
    <xsl:copy>
      <xsl:apply-templates select="node()" mode="filter:expungeWSSec"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="wsse:Security" mode="filter:expungeWSSec">
    <xsl:comment> Removed a WS-Security header. </xsl:comment>
  </xsl:template>
  
  <xsl:template match="*" mode="filter:expungeWSSec">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" mode="filter:expungeWSSec"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="@* | text() | comment() | processing-instruction()" mode="filter:expungeWSSec">
    <xsl:copy-of select="."/>
  </xsl:template>
  
  
  
  <!-- 
    Find all attributes that contain credit card numbers or security codes and obscure them with asterisks.
  -->
  <func:function name="filter:obscureCreditCardInfo">
    <xsl:param name="nodeset"/>
    <func:result>
      <xsl:apply-templates select="$nodeset" mode="filter:obscureCreditCardInfo"/>
    </func:result>
  </func:function>
  
  <xsl:template match="/" mode="filter:obscureCreditCardInfo">
    <xsl:copy>
      <xsl:apply-templates select="node()" mode="filter:obscureCreditCardInfo"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="*" mode="filter:obscureCreditCardInfo">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" mode="filter:obscureCreditCardInfo"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="@CardIdentificationNumber | @CreditCardNumber" mode="filter:obscureCreditCardInfo">
    <xsl:attribute name="{name()}">
      <xsl:value-of select="filter:replaceAllWithAsterisks(.)"/>
    </xsl:attribute>
  </xsl:template>
  
  <xsl:template match="@* | text() | comment() | processing-instruction()" mode="filter:obscureCreditCardInfo">
    <xsl:copy-of select="."/>
  </xsl:template>
  
  
   <!-- 
    Return a string of asterisks that is the same length as the supplied value.  (Up to 30 characters)
  -->
  <func:function name="filter:replaceAllWithAsterisks">
    <xsl:param name="value"/>
    <func:result>
      <xsl:value-of select="substring('******************************', 1, string-length($value))"/>
    </func:result>
  </func:function>
  </xsl:stylesheet>