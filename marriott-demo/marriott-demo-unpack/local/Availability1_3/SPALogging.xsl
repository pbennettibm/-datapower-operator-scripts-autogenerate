<?xml version="1.0" encoding="UTF-8"?>
<!--
This stylesheet will extract input values from GetAvailablity request and log it to SysLog. Sample information that will be logged are below,

*+www.roomkey.com+en+ATLNO+13.RPT+GOV+2012-08-07+2012-09-10+3+9
US+www.roomkey.com+en+ATLNO+13.RPT+*+2012-08-07+2012-09-10+3+9
*+www.roomkey.com+en+ATLNO+13.RPT+*+2012-08-07+2012-09-10+3+9
*+www.roomkey.com+en+ATLNO+*+GOV+2012-08-07+2012-09-10+3+9
*+www.roomkey.com+en+ATLNO+13.RPT14.RPT+IBMGOV+REGAREGB+2012-08-07+2012-09-10+1+3

If the country code is not available, it will be replaced with *. This key will be inserted as a comment in the request payload.
The logging will controlled by configuration XML called log-config.xml 

The fields are in the order it appears in the payload,
1.Country Code
2.Partner URL
3.Language code
4.Hotel Code
5.Sell Strategy code
6.Cluster Code
7.Rate Plan Code
8.In Date
9.Out Date
10.Number of Rooms
11.Number of Guests
- - - - - - - - - - - - - - -
MODIFICATION LOG:
- - - - - - - - - - - - - - - 
                - - -  Date :     Aug2012   
                - - -  Project:   Reservaton Strategy
                - - -  Author :   Bishenjit Choudhury, MARSHA Development   
-->

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
											xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
											xmlns:n="http://marsha.marriott.com/services/Availability/v1"
											xmlns:dp="http://www.datapower.com/extensions"
											extension-element-prefixes="dp">
	<xsl:template  name="SPALogging" match="/"> 

	  <xsl:variable name="log-config" select="document('local:///Availability1_3/log-config.xml')" />
	  <xsl:variable name="SPALogging" select="$log-config/logconfig/log/@SPAlogging" />
	  
	  <xsl:if test="$SPALogging = 'true'">   
	  		<xsl:for-each select="//soapenv:Body/n:GetAvailability">
			<xsl:variable name="var9_cur" select="."/>
			<xsl:for-each select="n:POS/n:Source">
				<xsl:variable name="var1_ISOCountry" select="@ISOCountry"/>
				<xsl:for-each select="n:RequestorID">
					<xsl:variable name="var11_RequestorID" select="@URL"/>
					<xsl:variable name="var15_RequestorID" select="@ID"/>
					<xsl:for-each select="$var9_cur/n:OperationProfile/n:PrimaryLanguage">
						<xsl:variable name="var8_cur" select="."/>
						<xsl:variable name="var2_Availability" select="$var9_cur/n:Availability"/>
						<xsl:for-each select="$var2_Availability/n:Hotels/n:Hotel">
							<xsl:variable name="var3_HotelCode" select="@HotelCode"/>
							<xsl:for-each select="$var2_Availability/n:RatePlans">
							
								<xsl:variable name="var4_RatePlanType">
									 <xsl:for-each select="n:RatePlan/@RatePlanType">
										 <xsl:value-of select="."/>
									</xsl:for-each>
								</xsl:variable> 
								
								<xsl:variable name="var5_RatePlanCategory">
									 <xsl:for-each select="n:RatePlan/@RatePlanCategory">
										 <xsl:value-of select="."/>
									</xsl:for-each>
								</xsl:variable> 
								
								<xsl:variable name="var20_RatePlanCode">
									 <xsl:for-each select="n:RatePlan/@RatePlanCode">
										 <xsl:value-of select="."/>
									</xsl:for-each>
								</xsl:variable> 

								<xsl:for-each select="$var2_Availability/n:InventoriesList/n:Inventories/n:Inventory/n:InvCounts">
									<xsl:variable name="var6_EffectiveDate" select="n:StatusApplicationControl/@EffectiveDate"/>
									<xsl:variable name="var7_ExpireDate" select="n:StatusApplicationControl/@ExpireDate"/>
									<xsl:variable name="var12_Count" select="n:InvCount/@Count"/>
									<xsl:for-each select="$var2_Availability/n:ResGuest/n:GuestCounts">
										<xsl:choose>
											<xsl:when test="(string(boolean($var1_ISOCountry)) = 'false')">
											<xsl:variable name="key"  select="concat(concat(concat(concat(concat(concat(concat('*','+',string($var11_RequestorID),'+',
																																			string($var15_RequestorID),'+',
																																			($var8_cur)),'+', string($var3_HotelCode)),'+', 
																																			string($var4_RatePlanType)),'+', 
																																			string($var5_RatePlanCategory),'+',
																																			string($var20_RatePlanCode)),'+', 
																																			string($var6_EffectiveDate)),'+', 
																																			string($var7_ExpireDate)),'+',
																																			string($var12_Count),'+', 
																																			string(number(string(n:GuestCount/@Count))))" />
												<xsl:message dp:priority="CachingLogDev">Cache: Key '<xsl:value-of select="$key"/></xsl:message>
												<xsl:comment>
													<xsl:value-of select="$key"/>
												</xsl:comment>
											</xsl:when>
											<xsl:otherwise>
												<xsl:variable name="key"  select="concat(concat(concat(concat(concat(concat(concat(string($var1_ISOCountry), '+',
																																			string($var11_RequestorID),'+',
																																			string($var15_RequestorID),'+',
																																			($var8_cur)),'+', string($var3_HotelCode)),'+', 
																																			string($var4_RatePlanType)),'+', 
																																			string($var5_RatePlanCategory),'+',
																																			string($var20_RatePlanCode)),'+', 
																																			string($var6_EffectiveDate)),'+', 
																																			string($var7_ExpireDate)),'+',
																																			string($var12_Count),'+', 
																																			string(number(string(n:GuestCount/@Count))))" />
												<xsl:message dp:priority="info" dp:type="CachingLogDev">Cache: Key '<xsl:value-of select="$key"/></xsl:message>
												<xsl:comment>
													<xsl:value-of select="$key"/>
												</xsl:comment>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:for-each>
								</xsl:for-each>
							</xsl:for-each>
						</xsl:for-each>
					</xsl:for-each>
				</xsl:for-each>
			</xsl:for-each>
		</xsl:for-each>
		</xsl:if> 
		<xsl:copy-of select="./*"/>
	</xsl:template>
</xsl:stylesheet>
