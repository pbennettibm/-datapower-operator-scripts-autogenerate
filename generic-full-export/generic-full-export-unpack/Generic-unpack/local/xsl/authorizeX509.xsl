<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" 
xmlns:dp="http://www.datapower.com/extensions" extension-element-prefixes="dp" exclude-result-prefixes="dp">


	<xsl:template match="/">
 <!--  <xsl:variable name="input" select="dp:variable('var://context/copyOfInput/_roottree')" />  -->
		
		<!-- Pick out the X509 certificate. -->
    <!--  <xsl:variable name="X509" select="string($input/*[local-name()='Envelope']/*[local-name()='Header']/wsse:Security/wsse:BinarySecurityToken[@ValueType='http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-x509-token-profile-1.0#X509v3'])"/> -->

<xsl:variable name="X509" select="string(/container/mapped-credentials/entry/CertificateDetails/Base64)"/>

<xsl:message> ####X509 results:<xsl:copy-of select="$X509"/></xsl:message>

<!-- Use dp:validate-certificate() to examine the cert, including checking it against a "well known" valcred. -->
          <xsl:variable name="certnode">
            <input>
              <subject>
                <xsl:value-of select="concat('cert:',$X509)"/>
              </subject>
            </input>
          </xsl:variable>
                   
          <xsl:variable name="aaa" select="dp:variable('var://context/ActiveMatrixESB/aaa')"/>
          <xsl:variable name="valcred" select="$aaa/aaa/@valcred"/>
          
          <xsl:variable name="validationResult" select="dp:validate-certificate($certnode, $valcred) "/>

<xsl:message> ####Validation results:<xsl:copy-of select="$validationResult"/></xsl:message>

                  
              <xsl:variable name="result">
              	<xsl:choose>
              		<xsl:when test="$validationResult != ''">
              			<xsl:element name="declined"/>
                                <xsl:variable name="ServiceName" select="dp:variable('var://context/ActiveMatrixESB/serviceName')"/>
                                <xsl:variable name="CounterName" select="concat('/monitor-count/', $ServiceName, 'AAAFailuresCnt')"/>
                                <dp:increment-integer name="$CounterName"/>
                                <xsl:message dp:priority="info">########Counter Name: <xsl:value-of select="$CounterName"/> ####### </xsl:message>
              		</xsl:when>
              		<xsl:otherwise>
              			<xsl:element name="approved"/>
              		</xsl:otherwise>
              	</xsl:choose>
              </xsl:variable>
              
              <xsl:message>### authorization decision=<xsl:copy-of select="$result"/></xsl:message>
              
              <!-- Return the original credentials too. -->
              <xsl:copy-of select="$result"/> 
              
	</xsl:template>
</xsl:stylesheet>
