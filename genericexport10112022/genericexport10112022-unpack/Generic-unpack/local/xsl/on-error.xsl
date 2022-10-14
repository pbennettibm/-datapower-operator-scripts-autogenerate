<?xml version="1.0" encoding="UTF-8"?>
<!-- 
  This stylesheet builds a nice SOAP Fault based on the current error.
Always check line 296 or 297 because LogTargets are being modified to accommodate the 175 device limit
Versioning
10/17/2012  *Deployed to SI DMZ, SI CMS, SI Datalex, and Prod Datalex\
11/09/2012  Updated default message if message is not signed It now says Authentication Failure:  Message Body not signed
11/14/2012  Added Stats processing at bottom
12/12/12
02/14/2013    Upated for use in the MPGW
02/28/2013  Removed errors for errCode and errSubCode references
04/30/2013  consolidated error codes, support messages,implemented request filter  
05/09/2016  updated so all Faults return the TID, code returns custom DP:reject errors, and updated SOAP fault to meet standard
-->
<xsl:stylesheet version="1.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:xsd="http://www.w3.org/2001/XMLSchema" 
  xmlns:date="http://exslt.org/dates-and-times" 
  xmlns:dp="http://www.datapower.com/extensions" 
  xmlns:dpconfig="http://www.datapower.com/param/config" 
  xmlns:dpquery="http://www.datapower.com/param/query"
  xmlns:dsig="http://www.w3.org/2000/09/xmldsig#"
  xmlns:dyn="http://exslt.org/dynamic" 
  xmlns:exslt="http://exslt.org/common" 
  xmlns:func="http://exslt.org/functions" 
  xmlns:local="urn:local:function" 
  xmlns:filter="urn:filter:library"
  xmlns:mgmt="http://www.datapower.com/schemas/management" 
  xmlns:regexp="http://exslt.org/regular-expressions" 
  xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" 
  xmlns:str="http://exslt.org/strings" 
  xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
  extension-element-prefixes="date dp dyn exslt func regexp str" 
  exclude-result-prefixes="dp">
  
      <!--Included utility files-->
      <xsl:include href="filterLibrary.xsl"/>
	  <xsl:include href="AuthType-Util-mpg.xsl"/>

  <!--
    These parameters are specified as part of the Transform action and are passed in by
    the firmware when this stylesheet is executed.
  -->
<xsl:variable name="SupportLogCategory" select="'ActiveMatrixSupportEvents'"/>
<!--User supplied variable section-->

  <!--This value is used to determine the simplest problem with AAA when an ID can not be determined-->
  <!--values are: aaaX509, aaaUserid, aaaSkip and aaaReject-->
  <xsl:variable name="aaa_type" select="dp:variable('var://context/ActiveMatrixESB/aaa_type')"/>
  <xsl:variable name="Auth_Type" >
		<xsl:choose>
		    <xsl:when test="$aaa_type='aaaUserid'">
			  <xsl:value-of select="'LDAP'"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="'x509'"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
  
 <!--Ends the user supplied variables section-->
 
   <xsl:variable name="ErrLogCat" select="'AMXErrCat'"/>
   <xsl:variable name="ErrReqCat" select="'AMXErrReq'"/>
   <xsl:variable name="dnVal" select="local:getIdDN(.)"/>
   <xsl:variable name="cnVal" select="local:CNfromDN($dnVal)"/>
   <xsl:variable name="baVal" select="local:getIdBasicAuth()"/>
<!--   <xsl:variable name="operationName" select="substring-after(dp:variable('var://service/wsm/operation'),'}')"/>-->
   <xsl:variable name="operationName" select="dp:variable('var://context/ActiveMatrixESB/operation')"/>
   <xsl:variable name="svcName" select = "dp:variable('var://context/ActiveMatrixESB/serviceName')"/>
   <xsl:variable name="userID" select = "dp:variable('var://context/WSM/identity/username')"/>
   <xsl:variable name="soapAct" select = "dp:http-request-header('SOAPAction')"/>
   <xsl:variable name="customError" select = "dp:variable('var://service/error-message')"/>  <!--Custom Reject Messages-->
            
    <!-- Get the necessary system variables -->
  <xsl:variable name="transactionId" select="dp:variable('var://service/transaction-id')"/>
  <xsl:variable name="errorCode" select="dp:variable('var://service/error-code')"/>
  <xsl:variable name="errorSubCode" select="dp:variable('var://service/error-subcode')"/>
  <xsl:variable name="originalMessage" select="dp:variable('var://service/error-message')"/>
  <xsl:variable name="errorDirection">
    <xsl:choose>
      <xsl:when test="dp:responding()=true()">
        <xsl:value-of select="'response'"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="'request'"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  
  <xsl:variable name="dpfaultCode">
     <xsl:choose>
          <xsl:when test="$errorDirection='response'">
          <xsl:value-of select="'soap:server'"/>
          </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="'soap:client'"/>
        </xsl:otherwise>
      </xsl:choose>
  </xsl:variable>
  
<xsl:variable name="input" select="/"/> <!-- The input to this stylesheet -->

<!-- device/system identity - get device name, if it is not set then use device serial number -->
  <xsl:variable name="sysIdent" select="dp:variable('var://service/system/ident')" /> 
  <xsl:variable name="deviceName" 
    select="$sysIdent/*[local-name()='identification']/*[local-name()='device-name']/text()" />  
  <xsl:variable name="serialNum" 
    select="$sysIdent/*[local-name()='identification']/*[local-name()='serial-number']/text()" />
  <xsl:variable name="deviceIdent">
    <xsl:choose>
      <xsl:when test="string-length(normalize-space($deviceName)) > 0 and $deviceName != '(unknown)'">
        <xsl:value-of select="$deviceName" />      
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$serialNum" />
      </xsl:otherwise>
    </xsl:choose> 
  </xsl:variable>
<!--Ends the system variable section-->  


<xsl:template match="/">
<!--Defines messages based on ErrorCodes and Subcodes. -->
      <xsl:choose>
         <xsl:when test="$errorCode='0x00230001'">
          <xsl:choose>
            <xsl:when test="$errorDirection='response'">
                <xsl:variable name="errorMessage" select="concat('Error parsing or validating BACKEND SERVICE response message.(TID:',$transactionId,')')"/>
				<dp:set-variable name="'var://context/errorInfo/errorMessage'" value="$errorMessage" />
                <xsl:variable name="supportMessage" select="concat('***Error parsing or validating BACKEND SERVICE response message.Uncertain what would cause this error.(TID:',$transactionId,')')"/>
				<dp:set-variable name="'var://context/errorInfo/supportMessage'" value="$supportMessage" />
			</xsl:when>
            <xsl:otherwise>
              <xsl:variable name="errorMessage" select="concat('Error parsing or validating APPLICATION(client)request message.(TID:',$transactionId,')')"/>
			  <dp:set-variable name="'var://context/errorInfo/errorMessage'" value="$errorMessage" />
              <xsl:variable name="supportMessage" select="concat('***Error parsing or validating APPLICATION request message.Uncertain what would cause this error.(TID:',$transactionId,')')"/>
              <dp:set-variable name="'var://context/errorInfo/supportMessage'" value="$supportMessage" />  
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="$errorCode='0x00030001'">
          <xsl:choose>
            <xsl:when test="$errorDirection='response'">
                <xsl:variable name="errorMessage" select="concat('Error parsing BACKEND SERVICE response message.(TID:',$transactionId,')')"/>
				<dp:set-variable name="'var://context/errorInfo/errorMessage'" value="$errorMessage" />
                <xsl:variable name="supportMessage" select="concat('***Error parsing BACKEND SERVICE response message.Uncertain what would cause this error.(TID:',$transactionId,')')"/>
                <dp:set-variable name="'var://context/errorInfo/supportMessage'" value="$supportMessage" /> 
	    </xsl:when>
            <xsl:otherwise>
				  <xsl:variable name="errorMessage" select="concat('Error parsing APPLICATION(client) request message.(TID:',$transactionId,')')" />
				  <dp:set-variable name="'var://context/errorInfo/errorMessage'" value="$errorMessage" />
                 <xsl:variable name="supportMessage" select="concat('***Error parsing APPLICATION request message.Uncertain what would cause this error.(TID:',$transactionId,')')"/>
				 <dp:set-variable name="'var://context/errorInfo/supportMessage'" value="$supportMessage" />
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="$errorCode='0x00d30003'">
          <xsl:choose>
            <xsl:when test="$errorSubCode='0x00d30003'">
                        <xsl:variable name="rejectError" select="dp:variable('var://service/error-message')"/>
			<xsl:variable name="errorMessage" select="concat($rejectError,':(TID:',$transactionId,')')" />
			<dp:set-variable name="'var://context/errorInfo/errorMessage'" value="$errorMessage" />
			<xsl:variable name="supportMessage" select="concat('***Access to this Service Denied by Policy. The operation called was blocked by a reject all action.(TID:',$transactionId,')')"/>
			<dp:set-variable name="'var://context/errorInfo/supportMessage'" value="$supportMessage" />	
            </xsl:when>
         <xsl:when test="$errorSubCode='0x01d30002'">
                <xsl:variable name="errorMessage">
				<!--Calls functions and then functions write out error code and support log variables-->
				<xsl:copy-of select="local:badAuth()"/>
				</xsl:variable>
			</xsl:when>
            <xsl:otherwise>
              <xsl:variable name="errorMessage" select="concat('Unrecognized failure in SOA. Please contact IT SOASvsSupport.(TID:',$transactionId,')')"  />
			  <dp:set-variable name="'var://context/errorInfo/errorMessage'" value="$errorMessage" />
			  <xsl:variable name="supportMessage" select="concat('***Generic failure in middleware. Uncertain what would cause this error.(TID:',$transactionId,')')"/>	
			  <dp:set-variable name="'var://context/errorInfo/supportMessage'" value="$supportMessage" />		
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
         <xsl:when test="$errorCode='0x01130011'">
          <xsl:variable name="errorMessage" select="concat('Failed to process response headers from backend server.(TID:',$transactionId,')')"  />
		  <dp:set-variable name="'var://context/errorInfo/errorMessage'" value="$errorMessage" />
          <xsl:variable name="supportMessage" select="concat('***Failed to process response headers from backend server. The failure usually indicates the proxy was set up for non-ssl and the backend server is expecting SSL. Update the proxy on Datapower to resolve issue.(TID:',$transactionId,')')"/>
 	      <dp:set-variable name="'var://context/errorInfo/supportMessage'" value="$supportMessage" />	
        </xsl:when>
	<xsl:when test="$errorCode='0x00c3000c'">
          <xsl:variable name="errorMessage" select="concat('Proxy is misconfigured.(TID:',$transactionId,')')"/>
			<dp:set-variable name="'var://context/errorInfo/errorMessage'" value="$errorMessage" />
		    <xsl:variable name="supportMessage" select="concat('***The proxy is not configured properly.  The output of one action does not match the input of the action following it. Modify the communications between the two rule actions to match.(TID:',$transactionId,')')"/>
 			<dp:set-variable name="'var://context/errorInfo/supportMessage'" value="$supportMessage" />		
        </xsl:when>
     <xsl:when test="$errorCode='0x00c30008'">
           <xsl:choose>
            <xsl:when test="$errorDirection='response'">
	      <xsl:variable name="errorMessage" select="concat('Remote server message was not valid XML. Verify SOAP response is being sent by backend server.(TID:',$transactionId,')')"/>
			<dp:set-variable name="'var://context/errorInfo/errorMessage'" value="$errorMessage" />
              <xsl:variable name="supportMessage" select="concat('***The end point server did not respond with valid SOAP. Server may be unavailable.Watch for connectivity failure error to follow or precede this error. Try to send test message directly to server to determine what is being sent to Datapower.(TID:',$transactionId,')')"/>
 	        <dp:set-variable name="'var://context/errorInfo/supportMessage'" value="$supportMessage" />
            </xsl:when>
           <xsl:otherwise>
             <xsl:variable name="errorMessage" select="concat('Client Message did not include a SOAP Action Header.(TID:',$transactionId,')')"/>
			  <dp:set-variable name="'var://context/errorInfo/errorMessage'" value="$errorMessage" />
              <xsl:variable name="supportMessage" select="concat('***The web service requires a SOAP Action Header.  The client must include a SOAP Action header.(TID:',$transactionId,')')"/>
 			  <dp:set-variable name="'var://context/errorInfo/supportMessage'" value="$supportMessage" />
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
	<xsl:when test="$errorCode='0x01130006' or $errorCode='0x01130007' or $errorCode='0x0113001e' or $errorCode='0x01130009' or $errorCode='0x00c3000f' or $errorCode='0x00030004'">
          <xsl:variable name="errorMessage" select="concat('Failed to establish a backside connection.(TID:',$transactionId,')')"/>
			<dp:set-variable name="'var://context/errorInfo/errorMessage'" value="$errorMessage" />
            <xsl:variable name="supportMessage" select="concat('***Failed to establish a backside connection. Something has interfered with connectivity to backend server.  Test that backend server can be pinged or called directly.(TID:',$transactionId,')')"/>
 		    <dp:set-variable name="'var://context/errorInfo/supportMessage'" value="$supportMessage" />
        </xsl:when>
<!--CATCH ALL OTHER ERRORS-->
        <xsl:otherwise>
          <xsl:variable name="errorMessage" select="$originalMessage" />
			<dp:set-variable name="'var://context/errorInfo/errorMessage'" value="$errorMessage" />
		   	<xsl:variable name="supportMessage" select="concat('***ErrorCode was not a match for current error list.ErrorCode= ',$errorCode,' With SubCode= ',$errorSubCode ,' ',$originalMessage,'. Service ', dp:variable('var://service/processor-name'),'- DP transaction id ',dp:variable('var://service/transaction-id'), ' on ', dp:variable('var://service/protocol'), '://', dp:variable('var://service/local-service-address'), ' at ', date:date-time(),'.','(TID:',$transactionId,')')"/> 
			<dp:set-variable name="'var://context/errorInfo/supportMessage'" value="$supportMessage" />
        </xsl:otherwise> 
    </xsl:choose>

<!--####Error Code and messages are set now send response to other system#####-->        
<xsl:call-template name="SOAPErrorResponse">
	 <xsl:with-param name ="erMessage" select="dp:variable('var://context/errorInfo/errorMessage')"> </xsl:with-param>
</xsl:call-template>

<!--####Now record the problems in the Datapower logs#####-->  
<xsl:call-template name="Logging" >
				 <xsl:with-param name ="erMessage" select="dp:variable('var://context/errorInfo/errorMessage')"> </xsl:with-param>
				 <xsl:with-param name ="supMessage" select="dp:variable('var://context/errorInfo/supportMessage')"> </xsl:with-param> 
</xsl:call-template>
</xsl:template>

<!-- Determine the Authentication Details only if error is related to Authentication(ErrorSubCode=0x01d30002)-->
<func:function name="local:badAuth">
<xsl:variable name="result">     
<xsl:choose>
      <xsl:when test="local:getId($input) = ''">
        <xsl:choose>
		   <!--values are: aaaX509, aaaUserid, aaaSkip and aaaReject-->
              <!-- No userid of any sort was supplied, so gently correct the caller. -->
            <xsl:when test="$aaa_type='aaaUserid'">
            <xsl:variable name="errorMessage" select="concat('Authentication Failure:  SOAP Message should have included a username/password combination. No credentials were provided. Check client configuration to ensure a username/password is being sent(TID:',$transactionId,')')"/>        
            <dp:set-variable name="'var://context/errorInfo/errorMessage'" value="$errorMessage" />
			<xsl:variable name="supportMessage" select="concat('***The control file is configured for a username/password.  The message had no security information in the message.  The client must authenticate with the appropriate type for this service call.(TID:',$transactionId,')')"/>
	        <dp:set-variable name="'var://context/errorInfo/supportMessage'" value="$supportMessage" />
	        </xsl:when>
         <xsl:when test="$aaa_type='aaaX509'">
		
        <xsl:variable name="errorMessage" select="concat('Authentication Failure:  SOAP body must be signed for signature-based authentication. No credentials were provided.  Check client configuration to ensure a signature is being sent.(TID:',$transactionId,')')"/>
		 <dp:set-variable name="'var://context/errorInfo/errorMessage'" value="$errorMessage" />
		 <xsl:variable name="supportMessage" select="concat('***The control file is configured for a X509 certificate.  The message had no security information in the message.  The client must authenticate with the appropriate type for this service call.(TID:',$transactionId,')')"/>
		 <dp:set-variable name="'var://context/errorInfo/supportMessage'" value="$supportMessage" />
		 </xsl:when>
         <xsl:when test="$aaa_type='aaaReject'" >
			  <xsl:variable name="errorMessage" select="concat('Authentication Reject:  The service is configured to reject traffic.(TID:',$transactionId,')')"/> 
			  <dp:set-variable name="'var://context/errorInfo/errorMessage'" value="$errorMessage" />
	          <xsl:variable name="supportMessage" select="concat('***The control file is configured to Reject everyone for this operation in the service.(TID:',$transactionId,')')"/>
			  <dp:set-variable name="'var://context/errorInfo/supportMessage'" value="$supportMessage" />
		 </xsl:when>
         <xsl:otherwise>
                   <xsl:variable name="errorMessage" select="concat('Authentication Skip:  The service is configured to skip AAA processing.(TID:',$transactionId,')')"/> 
					<dp:set-variable name="'var://context/errorInfo/errorMessage'" value="$errorMessage" />
                   <xsl:variable name="supportMessage" select="concat('***The control file is configured to SKIP AAA for this operation in the service.  No AAA error should occur.(TID:',$transactionId,')')"/>
				   <dp:set-variable name="'var://context/errorInfo/supportMessage'" value="$supportMessage" />
			</xsl:otherwise> 
         </xsl:choose>    
       </xsl:when>
      <xsl:otherwise>
        <!-- A userid of some sort was supplied, so lets check out the possibilities. -->
        <xsl:choose>
          <xsl:when test="local:isIdX509($input)">
			<!--<xsl:variable name="dnVal" select="local:getIdDN(.)"/>-->
			<xsl:variable name="certInfo" select="local:getId($input)"/>
   	        <!--<xsl:message dp:priority="critical" dp:type="'ActiveMatrixSupportEvents'">$$$$Value of ID<xsl:value-of select="$certInfo"/></xsl:message>--> 
			 <xsl:choose>
			    <xsl:when test="$certInfo='OTHER_X509_Value'">
					<xsl:variable name="errorMessage" select="concat('Authentication Error: WS-Security Header encountered an error.(TID:',$transactionId,')')"/> 
					<dp:set-variable name="'var://context/errorInfo/errorMessage'" value="$errorMessage" />         
					<xsl:variable name="supportMessage" select="concat('***The message used WS-Security with a X509 but On-error does not support it.  Check AAA.log for more details.(TID:',$transactionId,')')"/>.
					<dp:set-variable name="'var://context/errorInfo/supportMessage'" value="$supportMessage" />
				</xsl:when>
			<xsl:otherwise>
			<!--REMOVED BY KEVIN.  It looks like these values are already set at the top of the page.-->
			<!--<xsl:variable name="cnVal" select="local:CNfromDN($dnVal)"/>-->
            <!-- We have an X509 certificate, so examine it carefully. -->
            <xsl:variable name="wssec" select="$input/*[local-name()='Envelope']/*[local-name()='Header']/wsse:Security"/>
            <xsl:value-of select="local:examineX509($wssec)"/>
				</xsl:otherwise>
			</xsl:choose>
		  </xsl:when>
          <xsl:when test="local:isIdUsernameToken($input)">
            <!-- We have a username token, so examine it carefully. -->
            <xsl:variable name="wssec" select="$input/*[local-name()='Envelope']/*[local-name()='Header']/wsse:Security"/>
            <xsl:value-of select="local:examineUsernameToken($wssec)"/>
		  </xsl:when>
          <xsl:when test="local:isIdBasicAuth()">
            <!-- We have a basic auth header, so examine it carefully. -->
            <xsl:value-of select="local:examineBasicAuth()"/>
          </xsl:when>
          <xsl:otherwise>   
			<xsl:variable name="errorMessage" select="concat('Authentication Not Supported: The authentication type provided is not supported.(TID:',$transactionId,')')"/> 
			<dp:set-variable name="'var://context/errorInfo/errorMessage'" value="$errorMessage" />         
            <xsl:variable name="supportMessage" select="concat('***Someone added a new type of user credential without updating the code in on-error.xsl.(TID:',$transactionId,')')"/>.
			<dp:set-variable name="'var://context/errorInfo/supportMessage'" value="$supportMessage" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
</xsl:variable>
  <func:result select="$result"/>
 </func:function>

<xsl:template name="SOAPErrorResponse">    
	 <xsl:param name ="erMessage"/>      
    <!-- Build the response document -->
    <xsl:variable name="responseDoc">
      <xsl:element name="soap:Envelope">
        <xsl:element name="soap:Body">
          <xsl:element name="soap:Fault">
					<xsl:element name="faultcode">
					<xsl:value-of select="$dpfaultCode"/>
					</xsl:element>
					<xsl:element name="faultstring">
					<xsl:value-of select="$erMessage"/>
					</xsl:element>
					<xsl:element name="faultactor">
					<xsl:value-of select="'SOA'"/>
					</xsl:element>
					<xsl:element name="detail">
					<xsl:element name="description">
					<xsl:value-of select="concat('Service ', dp:variable('var://service/processor-name'), ' - DP transaction id ', dp:variable('var://service/transaction-id'), ' on ', $deviceName, ' at ', date:date-time())"/>
					</xsl:element>
					</xsl:element>
          </xsl:element>
        </xsl:element>
      </xsl:element>
    </xsl:variable>
    
    <!-- set the HTTP Response Code and content type -->
    <dp:set-variable name="'var://service/error-protocol-response'" value="'500'"/>
    <dp:set-request-header name="'Content-Type'" value="'text/xml'"/>

    <xsl:copy-of select="$responseDoc"/>
 </xsl:template>

<!--############  Logging Section All Logs will be written in this section  ################################################-->

<xsl:template name="Logging"> 
<xsl:param name="erMessage" />
<xsl:param name ="supMessage" /> 
<!--Print Error loggging ONCE to Plain Text file -->
      <xsl:message dp:priority="info" dp:type="{$ErrLogCat}">
	  		  <xsl:value-of select="concat($svcName,',',$operationName,',',$erMessage,',',$cnVal,',',$userID,',',$baVal,',',$soapAct,',',$errorCode,',',$errorSubCode,',',$Auth_Type,',',$supMessage)"/>
     </xsl:message>
  
  
		<xsl:message dp:priority="info" dp:type="{$ErrReqCat}">
           <!-- <xsl:value-of select=" concat('[',$ServiceName,'] [',$operationName, '] Request:')"/>-->
            <xsl:copy-of select="filter:expungeWSSec(filter:obscureCreditCardInfo(dp:variable('var://context/copyOfInput/_roottree')/soap:Envelope/soap:Body))"/>
        </xsl:message>
 <!--End selection of appropriate error message and logging message-->

<!-- Stats processing  -->
<!-- <xsl:variable name="LogCat2" select="'AMXStats'"/> -->
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

 <xsl:variable name="errMsg" select="dp:variable('var://service/error-message')"/>
 <xsl:variable name="userID" select = "dp:variable('var://context/WSM/identity/username')"/>
  <xsl:variable name="forwardIP" select = "dp:request-header('X-Forwarded-For')"/>
  <xsl:variable name="IPaddr" >		
	<xsl:choose>
		    <xsl:when test="$forwardIP=''">
			  <xsl:value-of select="dp:http-request-header('X-Client-IP')"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$forwardIP"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
		
  <xsl:variable name="operationName" select="dp:variable('var://context/ActiveMatrixESB/operation')"/>
  <xsl:variable name="AppID" select="$input/*[local-name()='Envelope']/*[local-name()='Body']/*/*[local-name()='RequestInfo']/@ApplicationId"/>
  <xsl:variable name="AppChNm" select="$input/*[local-name()='Envelope']/*[local-name()='Body']/*/*[local-name()='RequestInfo']/@AppChannelName"/>
  <xsl:variable name="ResponseComplete" select="dp:variable('var://service/time-response-complete')" /> 
   <xsl:variable name="ElapsedTime" select="dp:variable('var://service/time-elapsed')" /> 

 <xsl:choose>
       <xsl:when test="dp:variable('var://context/WSM/identity/username') != ''">
            <xsl:message dp:type="{$LogCat2}" dp:priority="info">
            	<xsl:value-of select=" concat($svcName,',',$operationName,',',$userID,',' ,$errorCode, ',' , $errorSubCode, ',' , $errMsg,',',$AppID,',',$AppChNm,',',$IPaddr)" />
            </xsl:message>
           <xsl:message dp:type="{$LogCat3}" dp:priority="info">
              <xsl:value-of select="concat('ServiceName=',$svcName)" />, <xsl:value-of select="concat('OperationName=',$operationName)" />, <xsl:value-of select="concat('UserID=', $userID)" />, <xsl:value-of select="concat('ErrorCode=', $errorCode)" />, <xsl:value-of select="concat('ErrorSubCode=',$errorSubCode)" />, <xsl:value-of select="concat('ErrorMsg=',$errMsg)" />, <xsl:value-of select="concat('IPAddr=',$IPaddr)" />, <xsl:value-of select="concat('ResponseComplete=',$ResponseComplete)" />, <xsl:value-of select="concat('ElapsedTime=',$ElapsedTime)" /> 
           </xsl:message>
       </xsl:when>
 
      <xsl:otherwise>
         <xsl:message dp:type="{$LogCat2}" dp:priority="info">
 		<xsl:value-of select=" concat($svcName,',',$operationName,',',',' , $errorCode, ',' , $errorSubCode, ',' , $errMsg,',',$AppID,',',$AppChNm,',',$IPaddr)" />	
 	</xsl:message>
        <xsl:message dp:type="{$LogCat3}" dp:priority="info">
              <xsl:value-of select="concat('ServiceName=',$svcName)" />, <xsl:value-of select="concat('OperationName=',$operationName)" />, <xsl:value-of select="concat('ErrorCode=', $errorCode)" />, <xsl:value-of select="concat('ErrorSubCode=',$errorSubCode)" />, <xsl:value-of select="concat('ErrorMsg=',$errMsg)" />, <xsl:value-of select="concat('IPAddr=',$IPaddr)" />, <xsl:value-of select="concat('ResponseComplete=',$ResponseComplete)" />, <xsl:value-of select="concat('ElapsedTime=',$ElapsedTime)" /> 
    	</xsl:message>
      </xsl:otherwise>
      
  </xsl:choose>
 <!-- End Stats section -->
   
</xsl:template>



</xsl:stylesheet>