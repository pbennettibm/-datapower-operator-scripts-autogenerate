<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:dp="http://www.datapower.com/extensions" xmlns:dpconfig="http://www.datapower.com/param/config" extension-element-prefixes="dp" exclude-result-prefixes="dp dpconfig" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:svc="http://marsha.marriott.com/services/Availability/v1" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output method="xml" indent="yes"/>
	<xsl:template match="/">
		<soap:Envelope>
			<soap:Body>
				<soap:Fault>
					<faultcode>soap:Server</faultcode>
					<faultstring>
						<xsl:copy-of select="dp:variable('var://service/error-message')"/>
					</faultstring>
					<detail>
						<svc:ApplicationFault>
							<svc:Errors>
								<svc:Error>
									<xsl:attribute name="RecordID">
										  <xsl:copy-of select="dp:variable('var://service/transaction-id')"/> 
									</xsl:attribute>
									<xsl:attribute name="ShortText"> system.error-code: <xsl:copy-of select="dp:variable('var://service/error-code')"/> sub-code: <xsl:value-of select="dp:variable('var://service/error-subcode')"/> </xsl:attribute>
									<xsl:copy-of select="dp:variable('var://service/error-message')"/>
								</svc:Error>
							</svc:Errors>
						</svc:ApplicationFault>
					</detail>
				</soap:Fault>
			</soap:Body>
		</soap:Envelope>
                 <xsl:message dp:type="customOTALog" dp:priority="error">
                      errorcode=<xsl:copy-of select="dp:variable('var://service/error-code')" />,errormessage=<xsl:value-of select="dp:variable('var://service/error-message')" />
                 </xsl:message>
	</xsl:template>
</xsl:stylesheet>
