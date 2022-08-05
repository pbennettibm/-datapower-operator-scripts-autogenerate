<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dp="http://www.datapower.com/extensions" xmlns:dyn="http://exslt.org/dynamic" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:v1="http://ms.marriott.com/schema/types/promotion/PromotionService/v1_0/" xmlns:v1_fault="http://ms.marriott.com/schema/promotion/fault/v1_0/" xmlns:v1_promo="http://ms.marriott.com/schema/types/promotion/Promotion/v1_0/" xmlns:v1_status="http://ms.marriott.com/schema/types/promotion/MemberPromotionStatus/v1_0/" xmlns:v2="http://ms.marriott.com/promotion/service/v2/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="1.0" exclude-result-prefixes="v1 v1_promo v1_status v1_fault xsl soap dp" extension-element-prefixes="dp">
   <xsl:output method="xml" indent="yes" omit-xml-declaration="yes" />
   <xsl:template match="/">
         <xsl:variable name="channel">
	      <xsl:choose>
		   <xsl:when test="contains($host,'sc.marriott.com')">
                             <xsl:value-of select="'saleschannel'"/>
		   </xsl:when>
		   <xsl:otherwise>
                             <xsl:value-of select="'marrnet'"/>
		   </xsl:otherwise>
	      </xsl:choose>
         </xsl:variable>
         <xsl:variable name="apos">
            <xsl:text>'</xsl:text>
         </xsl:variable>
         <xsl:variable name="File" select="document('local:///dpConfig/marshaConfig.xml')" />
	<xsl:variable name="webserviceProxy" select="dp:variable('var://service/processor-name')"/>
	<xsl:variable name="operationName" select="substring-after(dp:variable('var://service/wsm/operation'),'}')"/>
	<xsl:variable name="serviceName" select="substring-after(dp:variable('var://service/wsm/service'),'}')"/>
         <xsl:variable name="proxyfinder" select="concat('$File','//',$webserviceProxy,'/MPGW')" />
         <xsl:variable name="proxyquery" select="dyn:evaluate($proxyfinder)" />
         <xsl:if test="$proxyquery != 'True'">
         <xsl:variable name="endpointquey" select="concat('$File','//',$webserviceProxy,'/',$serviceName,'/',$operationName,'/',$channel)" />
	<xsl:variable name="endpoint" select="dyn:evaluate($endpointquey)" />
         </xsl:if>
        <xsl:choose>
           <xsl:when test="$proxyquery">
             <xsl:variable name="proxyMquey" select="concat('$File','//',$webserviceProxy,'/default/',$channel)" />
             <xsl:variable name="proxyqueryM" select="dyn:evaluate($proxyMquey)" />
             <xsl:variable name="URI" select="dp:variable('var://service/URI')"/>
             <xsl:variable name="routingValue" select="concat($proxyqueryM,$URI)"/>
	   <xsl:message dp:type="MARSHARoutingLog" dp:priority="error">HostName=<xsl:value-of select="dp:request-header('Host')"/>,Operation=<xsl:copy-of select="dp:variable('var://service/wsm/operation')" />,Old_routing_url=<xsl:value-of select="dp:variable('var://service/URL-out')" />,New_routing_url=<xsl:value-of select="$routingValue" /></xsl:message>             
             <dp:set-variable name="'var://service/routing-url'" value="$routingValue" /> 
           </xsl:when>
           <xsl:when test="$endpoint">
	   <xsl:message dp:type="MARSHARoutingLog" dp:priority="error">HostName=<xsl:value-of select="dp:request-header('Host')"/>,Operation=<xsl:copy-of select="dp:variable('var://service/wsm/operation')" />,Old_routing_url=<xsl:value-of select="dp:variable('var://service/URL-out')" />,New_routing_url=<xsl:value-of select="$endpoint" /></xsl:message>
             <dp:set-variable name="'var://service/routing-url'" value="$endpoint" /> 
           </xsl:when>
           <xsl:otherwise>
	     	 <xsl:variable name="defaultendpointquey" select="concat('$File','//',$webserviceProxy,'/default/',$channel)" />
	    	 <xsl:variable name="defaultendpoint" select="dyn:evaluate($defaultendpointquey)" />
	   <xsl:message dp:type="MARSHARoutingLog" dp:priority="error">HostName=<xsl:value-of select="dp:request-header('Host')"/>,Operation=<xsl:copy-of select="dp:variable('var://service/wsm/operation')" />,Old_routing_url=<xsl:value-of select="dp:variable('var://service/URL-out')" />,New_routing_url=<xsl:value-of select="$defaultendpoint" /></xsl:message>
                   <dp:set-variable name="'var://service/routing-url'" value="$defaultendpoint" />		 
      	  </xsl:otherwise>
        </xsl:choose>
   </xsl:template>
</xsl:stylesheet>