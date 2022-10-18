<?xml version="1.0" encoding="UTF-8"?>
<!-- 

  This stylesheet examines the incoming request's response code and Content-Type 
  and returns either the response itself, or a SOAP Fault.
  
  THIS TECHNIQUE IS RECOMMENDED ONLY FOR MPGWs, NOT WSPs. First, an incoming bit of
  HTML, for example, would fail validation so you wouldn't get to this stylesheet in
  the response rule.  You could disable validation but an HTML input wouldn't necessarily
  even be accepted as XML.  Even if the HTML also happened to be well-formed XML, it
  you've now disabled validation for normal SOAP responses.

  This stylesheet relies on a context variable (var://context/soap/version) to contain
  the namespace for the original SOAP request.  When this context variable is empty (or 
  doesn't exist) then the response is HTML.
  
  When the original request is a GET then you have to rely on some external bit of
  knowledge to set the context variable.
  
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
  xmlns:soap12="http://www.w3.org/2003/05/soap-envelope"
  xmlns:str="http://exslt.org/strings"
  extension-element-prefixes="date dp dyn exslt func regexp str" 
  exclude-result-prefixes="date dp dpconfig dpquery dyn exslt func regexp str">


  <dp:input-mapping href="store:///pkcs7-convert-input.ffd" type="ffd"/>
  
  
  <xsl:variable name="nameCtxvar" select="'var://context/soap/version'"/>
  <xsl:variable name="soapResponseNamespace">
    <xsl:choose>
      <xsl:when test="dp:variable($nameCtxvar) != ''">
        
        <xsl:value-of select="dp:variable($nameCtxvar)"/> <!-- Use the supplied value -->
        
      </xsl:when>
      <xsl:otherwise>
        
        <xsl:value-of select="'http://schemas.xmlsoap.org/soap/envelope/'"/> <!-- default to SOAP 1.1 Fault -->
        <!-- <xsl:value-of select="''"/> <! - - default to XML -->
        
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  

  <xsl:variable name="contentType" select="dp:response-header('Content-Type')"/>
  <xsl:variable name="responseCode" select="dp:response-header('x-dp-response-code')"/>
  <xsl:variable name="backendUrl" select="dp:variable('var://service/routing-url')"/>
  
  
  
  <xsl:template match="/">
    
    <xsl:message dp:priority="warn">### contentType=<xsl:value-of select="$contentType"/>, responseCode=<xsl:value-of select="$responseCode"/>, backendUrl=<xsl:value-of select="$backendUrl"/></xsl:message>
    
    <xsl:variable name="headerNames" select="dp:variable('var://service/header-manifest')"/>
    <xsl:for-each select="$headerNames//header">
      <xsl:message>^^^ <xsl:value-of select="."/> : <xsl:value-of select="dp:response-header(.)"/></xsl:message>
    </xsl:for-each>
    
    <!-- Decide which sort of response we have to work with, based on the Content-Type (xml or non-xml). -->
    <xsl:variable name="responseType">
      <xsl:choose>
        <xsl:when test="contains($contentType, 'xml')">
          
          <!-- 
            Found a content type containing 'xml', e.g. text/xml, application/blotz+xml, etc.
          -->
          <xsl:value-of select="'xml'"/>
          
        </xsl:when>
        <xsl:otherwise>
          
          <!-- Response type is non-xml, so don't touch it later. -->
          <xsl:value-of select="'non-xml'"/>
          
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <!-- Decide which type of response is needed (soap11, soap12, or xml). -->
    <xsl:variable name="responseNeeded">
      <xsl:choose>
        <xsl:when test="$soapResponseNamespace = 'http://schemas.xmlsoap.org/soap/envelope/'">
          
          <xsl:value-of select="'soap11'"/>
          
        </xsl:when>
        <xsl:when test="$soapResponseNamespace = 'http://www.w3.org/2003/05/soap-envelope'">
          
          <xsl:value-of select="'soap12'"/>
          
        </xsl:when>
        <xsl:when test="$soapResponseNamespace != ''">
          
          <xsl:message terminate="yes" dp:priority="error">SOAP namespace (<xsl:value-of select="$soapResponseNamespace"/>) not SOAP 1.1 or 1.2 so it is not currently supported.</xsl:message>
          
        </xsl:when>
        <xsl:otherwise>
          
          <xsl:value-of select="'xml'"/>
          
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:message dp:priority="warn">### responseType=<xsl:value-of select="$responseType"/>, responseNeeded=<xsl:value-of select="$responseNeeded"/></xsl:message>
    
    <!--
      When the response contains XML, we just return it.  It may be a normal response or a SOAP Fault,
      we'll trust that it is the correct thing.  We don't try to change a SOAP 1.1 Fault to a SOAP 1.2
      Fault, or vice versa.  If the response is non-xml then we construct a response, either SOAP 1.1,
      SOAP 1.2, or plain XML, without touching the body of the non-xml payload.
    -->
    <xsl:variable name="result">

      <xsl:choose>
        <xsl:when test="$responseType = 'xml'">
          
          <!-- 
            Return the response payload as-is.  The response hasn't been parsed up to this moment,
            so it is implicitly parsed now.
          -->
          <dp:set-response-header name="'Content-Type'" value="$contentType"/>
          <xsl:copy-of select="dp:parse(dp:decode(dp:binary-encode(/object/message/node()), 'base-64'))"/>
          
        </xsl:when>
        <xsl:otherwise>
          
          <!-- The response is non-xml so create a SOAP or XML response from scratch based on non-payload information. -->
          <xsl:choose>
            <xsl:when test="$responseNeeded = 'soap11'">
              
              <xsl:element name="soap:Envelope" namespace="http://schemas.xmlsoap.org/soap/envelope/">
                <xsl:element name="soap:Body">
                  <xsl:element name="soap:Fault">
                    
                    <xsl:element name="faultcode">
                      <xsl:value-of select="'fake'"/>
                    </xsl:element>
                    
                    <xsl:element name="faultstring">
                      <xsl:value-of select="concat('HTTP response code ', $responseCode, 'and content type ', $contentType, ' from ', $backendUrl)"/>
                    </xsl:element>
                    
                  </xsl:element>
                </xsl:element>
              </xsl:element>
              
            </xsl:when>
            <xsl:when test="$responseNeeded = 'soap12'">
              
              <xsl:element name="soap12:Envelope" namespace="http://schemas.xmlsoap.org/soap/envelope/">
                <xsl:element name="soap12:Body">
                  <xsl:element name="soap12:Fault">
                    
                    <xsl:element name="soap12:Code">
                      <xsl:element name="soap12:Value">
                        <xsl:value-of select="'fake'"/>
                      </xsl:element>
                    </xsl:element>
                    
                    <xsl:element name="soap12:Reason">
                      <xsl:value-of select="concat('HTTP response code ', $responseCode, 'and content type ', $contentType, ' from ', $backendUrl)"/>
                    </xsl:element>
                    
                  </xsl:element>
                </xsl:element>
              </xsl:element>
              
            </xsl:when>
            <xsl:otherwise>
              
              <!-- Generate a sensible plain XML response. -->
              <xsl:choose>
                <xsl:when test="starts-with($responseCode, '2')">
                  
                  <!-- A 2xx response. -->
                  <xsl:element name="okay"/>
                  
                </xsl:when>
                <xsl:otherwise>
                  
                  <!-- Either a 4xx or 5xx response (1xx and 3xx are handled automatically by DP, we don't see them. -->
                  <xsl:element name="html">
                    <xsl:element name="body">
                      <xsl:element name="p">
                        <xsl:value-of select="concat('HTTP response code ', $responseCode, 'and content type ', $contentType, ' from ', $backendUrl)"/>
                      </xsl:element>
                    </xsl:element>
                  </xsl:element>
                  
                </xsl:otherwise>
              </xsl:choose>
              
            </xsl:otherwise>
          </xsl:choose>
          
        </xsl:otherwise>
      </xsl:choose>
      
    </xsl:variable>
    
    <xsl:copy-of select="$result"/>
    
  </xsl:template>

</xsl:stylesheet>
