<?xml version="1.0" encoding="UTF-8" ?> 
<!-- 
This creates the statistics across all services.  Util-Id must be included for the required functions.
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
xmlns:filter="urn:filter:library"
xmlns:local="urn:local:function" 
xmlns:mgmt="http://www.datapower.com/schemas/management" 
xmlns:regexp="http://exslt.org/regular-expressions" 
xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" 
xmlns:soap12="http://www.w3.org/2003/05/soap-envelope" 
xmlns:str="http://exslt.org/strings" 
extension-element-prefixes="date dp dyn exslt func regexp str" 
xmlns:v1="http://schemas.delta.com/common/shoppoctypes/v1" 
exclude-result-prefixes="date dp dpconfig dpquery dyn exslt func regexp str">

<xsl:include href="util-id.xsl"/>

<xsl:template match="/">

<xsl:variable name="LogCat" select="'KCTransactionsLogCat'"/>
 <xsl:variable name="ServiceName" select="dp:variable('var://service/processor-name')"/>
 <xsl:variable name="proxyURI" select="dp:variable('var://service/URI')"/>
 <xsl:variable name="dbquote">&quot;</xsl:variable> 
 <xsl:variable name="operationSOAP" select="substring-after(dp:variable('var://service/wsm/operation'),'}')"/>


<!-- Stats Processing -->  

<!-- <xsl:variable name="LogCat2" select="'AMXStats'"/> -->
 <xsl:variable name="dnVal" select="local:getIdDN(.)"/>
 <xsl:variable name="cnVal" select="local:CNfromDN($dnVal)"/>
 <xsl:variable name="baVal" select="local:getIdBasicAuth()"/>

 <!--<xsl:variable name="operationName" select="substring-after(dp:variable('var://service/wsm/operation'),'}')"/>-->
<!--<xsl:variable name="userID" select = "dp:variable('var://context/WSM/identity/username')"/>-->
 <xsl:variable name="operationName" select="dp:variable('var://context/ActiveMatrixESB/operation')"/>
 <xsl:variable name="userID" select = "local:getId(.)"/>
 <xsl:variable name="svcName" select = "dp:variable('var://context/ActiveMatrixESB/serviceName')"/>
 <xsl:variable name="TransID" select="dp:variable('var://service/transaction-id')"/>

 <xsl:variable name="IPaddr" select = "dp:request-header('X-Forwarded-For')"/>

<xsl:variable name="input" select="/"/>
 <xsl:variable name="LogCat2" >
  	<xsl:choose>
 	    <xsl:when test="$svcName='loyaltymiles'">
 		  <xsl:value-of select="'AMXTarget'"/>
 	    </xsl:when>
 	    <xsl:when test="$svcName='hostcontext_v2'">
 		  <xsl:value-of select="'AMXHiVol'"/>
 	    </xsl:when>
 	    <xsl:when test="$svcName='pnrcommon_v5'">
 		  <xsl:value-of select="'AMXHiVol'"/>
 	    </xsl:when>
 	    <xsl:when test="$svcName='flight_v3'">
 		  <xsl:value-of select="'AMXHiVol'"/>
 	    </xsl:when>
 	    <xsl:when test="$svcName='equipment'">
 		  <xsl:value-of select="'AMXHiVol'"/>
 	    </xsl:when>
 	    <xsl:when test="$svcName='acsgenericrequest'">
	     	  <xsl:value-of select="'AMXGeneric'"/>
 		  
 	    </xsl:when>
 	    <xsl:when test="$svcName='resgenericrequest_v2'">
	           <xsl:value-of select="'AMXGeneric'"/>
 	    </xsl:when>
	    <xsl:when test="$svcName='oss'">
	     	  <xsl:value-of select="'AMXGeneric'"/>
 	    </xsl:when>  	    
 	    <xsl:otherwise>
 	     	<xsl:value-of select="'AMXStats'"/>
 	    </xsl:otherwise>  
       </xsl:choose>
 </xsl:variable>

<xsl:variable name="LogCat3" >
 	<xsl:choose>
	    <xsl:when test="$svcName='hostcontext_v2'">
		  <xsl:value-of select="'AMXHiVolGL2'"/>
	    </xsl:when>
	    <xsl:when test="$svcName='pnrcommon_v5'">
		  <xsl:value-of select="'AMXHiVolGL2'"/>
	    </xsl:when>
	    <xsl:when test="$svcName='flight_v3'">
		  <xsl:value-of select="'AMXHiVolGL2'"/>
	    </xsl:when>
	    <xsl:otherwise>
	     	<xsl:value-of select="'AMXStatsGL2'"/>
	    </xsl:otherwise>
	</xsl:choose>
  </xsl:variable>

 <xsl:variable name="DmdCde" select="$input/*[local-name()='Envelope']/*[local-name()='Body']/*[local-name()='AnyDemandCodeRequest']/*[local-name()='DemandCode']"/>

<xsl:variable name="OSSCde" select="$input/*[local-name()='Envelope']/*[local-name()='Body']/*[local-name()='OssGenericRequest']/@DemandCode"/>

 <xsl:variable name="AppID" select="$input/*[local-name()='Envelope']/*[local-name()='Body']/*/*[local-name()='RequestInfo']/@ApplicationId"/>
 <xsl:variable name="AppChNm" select="$input/*[local-name()='Envelope']/*[local-name()='Body']/*/*[local-name()='RequestInfo']/@AppChannelName"/>
 <xsl:variable name="SOATransID" select="$input/*[local-name()='Envelope']/*[local-name()='Body']/*/*[local-name()='RequestInfo']/@TransactionId"/>

  <xsl:choose>
     <xsl:when test="local:isIdX509($input)">
       	<xsl:message dp:type="{$LogCat2}" dp:priority="info">
	  		<xsl:value-of select=" concat($svcName,',',$operationName,',',$cnVal,',',',',',','x509,',$AppID,',',$AppChNm,',',$IPaddr,',',$DmdCde,',',$OSSCde)" />	  
   <!--<xsl:value-of select=" concat($svcName,',',$operationName,',',$cnVal,',',',',',','x509,',$AppID,',',$AppChNm,',',$IPaddr)" />-->	  	
	<!--<xsl:value-of select=" concat($operationName,',',$cnVal,',',',',',','x509,',$IPaddr)" />-->
       </xsl:message>
       <xsl:message dp:type="{$LogCat3}" dp:priority="info">
 	    <xsl:value-of select="concat('ServiceName=',$svcName)" />, <xsl:value-of select="concat('OperationName=',$operationName)" />, <xsl:value-of select="concat('CN=', $cnVal)" />, SecType=x509, <xsl:value-of select="concat('AppID=',$AppID)" />, <xsl:value-of select="concat('AppChName=',$AppChNm)" />, <xsl:value-of select="concat('IPAddr=',$IPaddr)" />, <xsl:value-of select="concat('DmdCode=',$DmdCde)" />, <xsl:value-of select="concat('OSSCode=',$OSSCde)" />, <xsl:value-of select="concat('SOATransID=',$SOATransID)" />
    	</xsl:message>
<!--	<xsl:variable name="response">
		<dp:url-open target="tibems://ems-lab2-7232-dv.delta.com:7232?UserName=dpwuser;Password=iGmDiuw3;RequestQueue=DAL.SOA.DATAPOWER.Q.LOGDATA" response="ignore" data-type="xml">
			<AMXStatsReq_SI-76>
			<xsl:value-of select="concat('ServiceName=',$svcName)" />, <xsl:value-of select="concat('OperationName=',$operationName)" />,<xsl:value-of select="concat('TransID=',$TransID)" />, <xsl:value-of select="concat('CN=', $cnVal)" />, SecType=x509, <xsl:value-of select="concat('AppID=',$AppID)" />, <xsl:value-of select="concat('AppChName=',$AppChNm)" />, <xsl:value-of select="concat('IPAddr=',$IPaddr)" />, <xsl:value-of select="concat('DmdCode=',$DmdCde)" />, <xsl:value-of select="concat('OSSCode=',$OSSCde)" />, <xsl:value-of select="concat('SOATransID=',$SOATransID)" />
			</AMXStatsReq_SI-76>
		</dp:url-open>
	</xsl:variable>
-->
     </xsl:when>

     <xsl:when test="local:isIdUsernameToken($input)">
     	<xsl:message dp:type="{$LogCat2}" dp:priority="info">
     		<xsl:value-of select=" concat($svcName,',',$operationName,',',$userID,',',',',',','LDAP,',$AppID,',',$AppChNm,',',$IPaddr)" />         	</xsl:message>
	<xsl:message dp:type="{$LogCat3}" dp:priority="info">
 	    <xsl:value-of select="concat('ServiceName=',$svcName)" />, <xsl:value-of select="concat('OperationName=',$operationName)" />, <xsl:value-of select="concat('UserID=', $userID)" />, SecType=LDAP, <xsl:value-of select="concat('AppID=',$AppID)" />, <xsl:value-of select="concat('AppChName=',$AppChNm)" />, <xsl:value-of select="concat('IPAddr=',$IPaddr)" />, <xsl:value-of select="concat('DmdCode=',$DmdCde)" />, <xsl:value-of select="concat('OSSCode=',$OSSCde)" />, <xsl:value-of select="concat('SOATransID=',$SOATransID)" />
 	 </xsl:message>
<!--	<xsl:variable name="response">
		<dp:url-open target="tibems://ems-lab2-7232-dv.delta.com:7232?UserName=dpwuser;Password=iGmDiuw3;RequestQueue=DAL.SOA.DATAPOWER.Q.LOGDATA" response="ignore" data-type="xml">
                        <AMXStatsReq_SI-76>
			<xsl:value-of select="concat('ServiceName=',$svcName)" />, <xsl:value-of select="concat('OperationName=',$operationName)" />,<xsl:value-of select="concat('TransID=',$TransID)" />, <xsl:value-of select="concat('UserID=', $userID)" />, SecType=LDAP, <xsl:value-of select="concat('AppID=',$AppID)" />, <xsl:value-of select="concat('AppChName=',$AppChNm)" />, <xsl:value-of select="concat('IPAddr=',$IPaddr)" />, <xsl:value-of select="concat('DmdCode=',$DmdCde)" />, <xsl:value-of select="concat('OSSCode=',$OSSCde)" />, <xsl:value-of select="concat('SOATransID=',$SOATransID)" />
                        </AMXStatsReq_SI-76>
		</dp:url-open>
	</xsl:variable> 
-->	 
      </xsl:when>
      <xsl:when test="local:isIdBasicAuth()">
         <xsl:message dp:type="{$LogCat2}" dp:priority="info">
     		<xsl:value-of select=" concat($svcName,',',$operationName,',',$baVal,',',',',',','BasicAuth,',$AppID,',',$AppChNm,',',$IPaddr)" />         	</xsl:message>
         <xsl:message dp:type="{$LogCat3}" dp:priority="info">
 	    <xsl:value-of select="concat('ServiceName=',$svcName)" />, <xsl:value-of select="concat('OperationName=',$operationName)" />, <xsl:value-of select="concat('BasicAuthID=', $baVal)" />, SecType=BasicAuth, <xsl:value-of select="concat('AppID=',$AppID)" />, <xsl:value-of select="concat('AppChName=',$AppChNm)" />, <xsl:value-of select="concat('IPAddr=',$IPaddr)" />, <xsl:value-of select="concat('DmdCode=',$DmdCde)" />, <xsl:value-of select="concat('OSSCode=',$OSSCde)" />, <xsl:value-of select="concat('SOATransID=',$SOATransID)" /> 
 	 </xsl:message>
<!--     	<xsl:variable name="response">
		<dp:url-open target="tibems://ems-lab2-7232-dv.delta.com:7232?UserName=dpwuser;Password=iGmDiuw3;RequestQueue=DAL.SOA.DATAPOWER.Q.LOGDATA" response="ignore" data-type="xml">
                     <AMXStatsReq_SI-76>
			<xsl:value-of select="concat('ServiceName=',$svcName)" />, <xsl:value-of select="concat('OperationName=',$operationName)" />,<xsl:value-of select="concat('TransID=',$TransID)" />, <xsl:value-of select="concat('BasicAuthID=', $baVal)" />, SecType=BasicAuth, <xsl:value-of select="concat('AppID=',$AppID)" />, <xsl:value-of select="concat('AppChName=',$AppChNm)" />, <xsl:value-of select="concat('IPAddr=',$IPaddr)" />, <xsl:value-of select="concat('DmdCode=',$DmdCde)" />, <xsl:value-of select="concat('OSSCode=',$OSSCde)" />, <xsl:value-of select="concat('SOATransID=',$SOATransID)" /> 
                     </AMXStatsReq_SI-76>
		</dp:url-open>
	</xsl:variable>
--> 	 
     </xsl:when>
     <xsl:otherwise>
          <xsl:message dp:type="{$LogCat2}" dp:priority="info">
     		<xsl:value-of select=" concat($svcName,',',$operationName,',','none',',',',',',','NotSigned,',$AppID,',',$AppChNm,',',$IPaddr,',',$DmdCde,',',$OSSCde)" />         	
         </xsl:message>
	<xsl:message dp:type="{$LogCat3}" dp:priority="info">
 	    <xsl:value-of select="concat('ServiceName=',$svcName)" />, <xsl:value-of select="concat('OperationName=',$operationName)" />, SecType=NotSigned, <xsl:value-of select="concat('AppID=',$AppID)" />, <xsl:value-of select="concat('AppChName=',$AppChNm)" />, <xsl:value-of select="concat('IPAddr=',$IPaddr)" />, <xsl:value-of select="concat('DmdCode=',$DmdCde)" />, <xsl:value-of select="concat('OSSCode=',$OSSCde)" />, <xsl:value-of select="concat('SOATransID=',$SOATransID)" /> 
 	 </xsl:message>
<!--        <xsl:variable name="response">
		<dp:url-open target="tibems://ems-lab2-7232-dv.delta.com:7232?UserName=dpwuser;Password=iGmDiuw3;RequestQueue=DAL.SOA.DATAPOWER.Q.LOGDATA" response="ignore" data-type="xml">
                     <AMXStatsReq_SI-76>
			<xsl:value-of select="concat('ServiceName=',$svcName)" />, <xsl:value-of select="concat('OperationName=',$operationName)" />,<xsl:value-of select="concat('TransID=',$TransID)" />, SecType=NotSigned, <xsl:value-of select="concat('AppID=',$AppID)" />, <xsl:value-of select="concat('AppChName=',$AppChNm)" />, <xsl:value-of select="concat('IPAddr=',$IPaddr)" />, <xsl:value-of select="concat('DmdCode=',$DmdCde)" />, <xsl:value-of select="concat('OSSCode=',$OSSCde)" />, <xsl:value-of select="concat('SOATransID=',$SOATransID)" />
                     </AMXStatsReq_SI-76> 
		</dp:url-open>
	</xsl:variable> 
-->	 
     </xsl:otherwise>

  </xsl:choose>
  
  <!-- End Stats Processing -->
 
 <!--NOT NEEDED OR USED <xsl:copy-of select="/" />--> 

  </xsl:template>
  </xsl:stylesheet>