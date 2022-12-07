<?xml version="1.0" encoding="utf-8"?>   
<xsl:stylesheet version="1.0" 
xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dp="http://www.datapower.com/extensions" xmlns:date="http://exslt.org/dates-and-times" extension-element-prefixes="dp date" exclude-result-prefixes="dp date"> <!-- | | This stylesheet reports on all cert objects in the domain | | Change history: | 2009/06/02 swl initial version | | --> <xsl:template match=
"/"> 
<xsl:variable name="stats" select="dp:variable('var://service/system/status/ObjectStatus')" />   <!-- Reduce the statistics to just the certificate object status nodes --> 
<xsl:variable name="cert-stats"> 
<xsl:copy-of select="$stats//ObjectStatus[./Class/text() = 'CryptoCertificate']" /> 
</xsl:variable>   <!-- If certs are in the returned results, 

continue --> 
<xsl:if test="count($cert-stats) != 0"> 
<xsl:element name="certificates"> <xsl:attribute name="appliance"><xsl:value-of select="dp:variable('var://service/system/ident')/identification/device-name" />
</xsl:attribute> <xsl:attribute name="domain"><xsl:value-of select="dp:variable('var://service/domain-name')" />
</xsl:attribute> <!-- For each node found, get desired nodes from status and cert stats --> 
<xsl:for-each select="$cert-stats/ObjectStatus"> <xsl:variable name="name" select="./Name/text()" /> <xsl:variable name="status" select="./OpState/text()" /> 
<xsl:variable name="errorcode" select="./ErrorCode/text()" /> <xsl:variable name="certDetails" select="dp:get-cert-details(concat('name:',$name))" /> 
<xsl:variable name="certExpire" select="$certDetails/CertificateDetails/NotAfter" /> <xsl:variable name="currentDate" select="date:date-time()" /> 
<xsl:variable name="toExpire" select="date:difference($currentDate, $certExpire)" /> 

<xsl:variable name="datePrefix">
<xsl:choose>
  <xsl:when test="substring($toExpire,1,1) = '-'">
     <xsl:value-of select=" '-'"/>
  </xsl:when>
  <xsl:otherwise>
    <xsl:value-of select=" ''"/>
  </xsl:otherwise>
</xsl:choose>  	 
</xsl:variable> 	 

<xsl:variable name="toExpireDays" select="concat($datePrefix, substring-after(substring-before($toExpire, 'D'), 'P'))" /> 

<!-- output node with the current status/cert info --> 
<xsl:element name="certificate"> <xsl:attribute name="name"><xsl:value-of select="$name" /></xsl:attribute> <xsl:element name="Status"><xsl:value-of select="$status" /></xsl:element> 
<xsl:element name="ErrorCode"><xsl:value-of select="$errorcode" /></xsl:element> <xsl:element name="NotBefore"><xsl:value-of select="$certDetails/CertificateDetails/NotBefore" />
</xsl:element> <xsl:element name="NotAfter"><xsl:value-of select="$certExpire" /></xsl:element> <xsl:element name="ExpiresInDays">
<xsl:value-of select="$toExpireDays" /></xsl:element> <xsl:element name="Expires">


<xsl:value-of select="$toExpire" /></xsl:element> <xsl:element name="Subject"><xsl:value-of select="$certDetails/CertificateDetails/Subject" />
</xsl:element> <xsl:element name="Issuer"><xsl:value-of select="$certDetails/CertificateDetails/Issuer" />
</xsl:element> </xsl:element> </xsl:for-each> </xsl:element> </xsl:if> </xsl:template>   
</xsl:stylesheet>