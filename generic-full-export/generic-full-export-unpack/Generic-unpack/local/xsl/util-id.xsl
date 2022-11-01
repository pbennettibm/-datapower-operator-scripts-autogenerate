<?xml version="1.0" encoding="UTF-8"?>
<!-- 

  This stylesheet contains functions to handle the "userid" for the request when it
  was supplied as an X509 certificate in a binary security token, as a userid in a
  username token, or as a basic auth userid.

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
  xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
  extension-element-prefixes="date dp dyn exslt func regexp str" 
  exclude-result-prefixes="date dp dpconfig dpquery dyn exslt func regexp str">

  <xsl:template match="/">
    
    <xsl:element name="result">

      <xsl:element name="isIdX509">
        <xsl:value-of select="local:isIdX509(.)"/>
      </xsl:element>
      
      <xsl:element name="isIdUsernameToken">
        <xsl:value-of select="local:isIdUsernameToken(.)"/>
      </xsl:element>
      
      <xsl:element name="isIdBasicAuth">
        <xsl:value-of select="local:isIdBasicAuth()"/>
      </xsl:element>
      
      <xsl:element name="getIdDN">
        <xsl:value-of select="local:getIdDN(.)"/>
      </xsl:element>
      
      <xsl:element name="getIdUNT">
        <xsl:value-of select="local:getIdUNT(.)"/>
      </xsl:element>
      
      <xsl:element name="getIdBasicAuth">
        <xsl:value-of select="local:getIdBasicAuth()"/>
      </xsl:element>
      
      <xsl:element name="getId">
        <xsl:value-of select="local:getId(.)"/>
      </xsl:element>
      
      <xsl:if test="local:isIdX509(.)">
        <xsl:element name="CN">
          <xsl:value-of select="local:CNfromDN(local:getIdDN(.))"/>
        </xsl:element>
      </xsl:if>
      
    </xsl:element>
    
  </xsl:template>
  
  
  <!-- 
    Determine whether the request contains a binary security token with an X509 certificate.
    Returns boolean true or false (not string 'true' or 'false')
  -->
  <func:function name="local:isIdX509">
    <xsl:param name="request"/>
    <!--
      This xpath tests whether the request contains an X509 certificate in a binary security token.
      
      The first two terms (/*[local-name()='Envelope']/*[local-name()='Header']) are insensitive to
      whether the request is SOAP 1 or SOAP 1.2. 
      
      The wsse:Security term identifies the WS-Security header in the request (if one is present).
      
      The final term, wsse:BinarySecurityToken[@ValueType='http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-x509-token-profile-1.0#X509v3'],
      identifies whether an X509 certificate is present.
    -->
    <func:result select="$request/*[local-name()='Envelope']/*[local-name()='Header']/wsse:Security/wsse:BinarySecurityToken[@ValueType='http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-x509-token-profile-1.0#X509v3'] != ''"/>
  </func:function>
  
  
  
  <!-- 
    Determine whether the request contains a username token.
    Returns boolean true or false (not string 'true' or 'false')
  -->
  <func:function name="local:isIdUsernameToken">
    <xsl:param name="request"/>
    <!--
      This xpath tests whether the request contains a username token.
      
      The first two terms (/*[local-name()='Envelope']/*[local-name()='Header']) are insensitive to
      whether the request is SOAP 1 or SOAP 1.2. 
      
      The wsse:Security term identifies the WS-Security header in the request (if one is present).
      
      The final term, wsse:UsernameToken, identifies whether a UsernameToken is present.
    -->
    <func:result select="$request/*[local-name()='Envelope']/*[local-name()='Header']/wsse:Security/wsse:UsernameToken != ''"/>
  </func:function>
  
  
  
  <!-- 
    Determine whether the request contains a Basic Auth header.
    Returns boolean true or false (not string 'true' or 'false')
  -->
  <func:function name="local:isIdBasicAuth">
    <func:result select="starts-with(dp:request-header('Authorization'), 'Basic ')"/>
  </func:function>
  
  
  
  <!-- 
    Return the DN from the X509 certificate, or an empty string.
  -->
  <func:function name="local:getIdDN">
    <xsl:param name="request"/>
    <func:result>
      
      <!-- Pick out the X509 certificate. -->
      <xsl:variable name="X509" select="string($request/*[local-name()='Envelope']/*[local-name()='Header']/wsse:Security/wsse:BinarySecurityToken[@ValueType='http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-x509-token-profile-1.0#X509v3'])"/>
      
      <xsl:choose>
        <xsl:when test="$X509 != ''">
          
          <!-- Get the "subject" from the cert, which is usually a DN. -->
          <xsl:value-of select="dp:get-cert-subject(concat('cert:', $X509))"/>
          
        </xsl:when>
        <xsl:otherwise>
          
          <!-- No cert, no joy.  Return an empty string. -->
          <xsl:value-of select="''"/>
          
        </xsl:otherwise>
      </xsl:choose>
      
    </func:result>
  </func:function>
  
  
  <!-- 
    Return the user name from a WS-Security UsernameToken, or return an empty string.
  -->
  <func:function name="local:getIdUNT">
    <xsl:param name="request"/>
    <func:result select="string($request/*[local-name()='Envelope']/*[local-name()='Header']/wsse:Security/wsse:UsernameToken/wsse:Username)"/>
  </func:function>
  

  <!-- 
    Return the userid from the Basic Auth HTTP header, or return an empty string.
  -->
  <func:function name="local:getIdBasicAuth">
    <func:result>
      
      <xsl:variable name="hdr" select="dp:request-header('Authorization')"/>
      <xsl:choose>
        <xsl:when test="starts-with($hdr, 'Basic ')">
          
          <!--
            The Authorization header value is "Basic xxxxxx" where xxxxxx is a base-64 encoded string 
            of the form "uid:pwd".  So this line of code peels off the xxxxx part, decodes it, then picks
            off the userid.
          -->
          <xsl:value-of select="substring-before(dp:decode(substring-after($hdr, 'Basic '), 'base-64'), ':')"/>
          
        </xsl:when>
        <xsl:otherwise>
          
          <!-- No Basic Auth header so no joy.  Return an empty string. -->
          <xsl:value-of select="''"/>
          
        </xsl:otherwise>
      </xsl:choose>
      
    </func:result>
  </func:function>
  
  
  
  <!-- 
    Returns the userid or DN provided in a basic auth header, a username token, or an X509 certificate (in that order). 
  -->
  <func:function name="local:getId">
    <xsl:param name="request"/>
    <func:result>
      
      <xsl:choose>
        <xsl:when test="local:isIdBasicAuth()">
          <xsl:value-of select="local:getIdBasicAuth()"/>
        </xsl:when>
        <xsl:when test="local:isIdUsernameToken($request)">
          <xsl:value-of select="local:getIdUNT($request)"/>
        </xsl:when>
        <xsl:when test="local:isIdX509($request)">
          <xsl:value-of select="local:getIdDN($request)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="''"/>
        </xsl:otherwise>
      </xsl:choose>
    </func:result>
  </func:function>
  
  
  <!-- 
    Return the CN contained in a DN, assuming that there IS a CN in the DN.
  -->
  <func:function name="local:CNfromDN">
    <xsl:param name="DN"/>
    <func:result>
      <!--
        It might seem simpler to just search for CN=, but this may be part of the content of a field,
        so we check more carefully, including comma in the search because comma is reserved solely
        for separating DN values.
      -->
      <xsl:variable name="afterCN">
        <xsl:choose>
          <xsl:when test="starts-with($DN, 'CN=')">
            <!-- CN is the first thing in the DN. -->
            <xsl:value-of select="substring-after($DN, 'CN=')"/>
          </xsl:when>
          <xsl:when test="starts-with($DN, ', CN=')">
            <!-- CN is not the first thing in the DN, and there are blanks following the commas -->
            <xsl:value-of select="substring-after($DN, ', CN=')"/>
          </xsl:when>
          <xsl:when test="starts-with($DN, ',CN=')">
            <!-- CN is not the first thing in the DN, and there are no blanks following the commas -->
            <xsl:value-of select="substring-after($DN, ',CN=')"/>
          </xsl:when>
          <xsl:otherwise>
            <!-- No CN in the DN. -->
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      
      <!-- Peel off the CN value, unless it is empty or the CN term is the last one in the DN. -->
      <xsl:choose>
        <xsl:when test="contains($afterCN, ',')">
          <xsl:value-of select="substring-before($afterCN, ',')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$afterCN"/> <!-- either CN wasn't present, or it was the final/only term in the DN. -->
        </xsl:otherwise>
      </xsl:choose>
    </func:result>
  </func:function>
  
  
</xsl:stylesheet>
