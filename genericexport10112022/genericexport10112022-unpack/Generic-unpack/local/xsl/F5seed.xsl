<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:dp="http://www.datapower.com/extensions" 
	extension-element-prefixes="dp" 
	exclude-result-prefixes="dp">

	<xsl:template match="/">	
	    <xsl:copy-of select="document('local:///control/F5seed.xml')"/>
	</xsl:template>	
</xsl:stylesheet>