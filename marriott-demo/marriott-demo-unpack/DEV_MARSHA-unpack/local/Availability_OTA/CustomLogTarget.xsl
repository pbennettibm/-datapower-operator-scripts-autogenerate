<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dp="http://www.datapower.com/extensions" xmlns:exslt="http://exslt.org/common" xmlns:json="http://www.ibm.com/xmlns/prod/2009/jsonx" extension-element-prefixes="exslt dp" exclude-result-prefixes="json exslt dp" version="1.0">
   <xsl:template match="/">
      <xsl:variable name="ServiceName" select="dp:variable('var://service/processor-name')" />
      <xsl:variable name="OperationName" select="dp:variable('var://service/wspolicy/operation/configname')" />
      <xsl:variable name="Uri" select="dp:variable('var://service/URL-in')" />
      <source>
         <xsl:message dp:type="customOTALog" dp:priority="error">
            <xsl:copy-of select="dp:variable('var://service/transaction-rule-type')" /> | <xsl:copy-of select="concat($Uri)" /> | OTA = <xsl:copy-of select="string(/*['Envelope']/*['Body']/*['OTA_HotelAvailRQ']/*['POS']/*['Source']/*['RequestorID']/@URL)" /> | <xsl:copy-of select="dp:variable('var://service/error-code')" /> | <xsl:copy-of select="dp:variable('var://service/time-elapsed')" />
         </xsl:message>
      </source>
   </xsl:template>
</xsl:stylesheet>