<xsl:stylesheet version="1.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
xmlns:dp="http://www.datapower.com/extensions"
xmlns:typ="http://schemas.delta.com/payment/globalcollectdp/types"
exclude-result-prefixes="soap" 
extension-element-prefixes="dp">



<xsl:template match="/">


 <!-- Set backend URL. -->
 <dp:set-variable name="'var://service/routing-url'" value="'https://webservicesa-si.delta.com:32022/loyaltymember'"/>



<xsl:copy-of select="/" /> 

 </xsl:template>
 </xsl:stylesheet>
