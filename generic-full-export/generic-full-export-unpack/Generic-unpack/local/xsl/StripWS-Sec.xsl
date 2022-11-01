<xsl:stylesheet version="1.0" 
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" 
xmlns:dp="http://www.datapower.com/extensions"
xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd" 
xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
exclude-result-prefixes="soap" 
extension-element-prefixes="dp">

<!--  Copy all other elements  -->
  <xsl:template match="@*|node()">
     <xsl:copy>
        <xsl:apply-templates select="@*|node()" />
     </xsl:copy>
  </xsl:template>

<!--  Remove WS-Security Nodeset  -->
  <xsl:template match="wsse:Security">
  </xsl:template>
  
</xsl:stylesheet> 
