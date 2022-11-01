<?xml version="1.0" encoding="UTF-8"?>
<!-- 
  This stylesheet builds a nice SOAP Fault based on the current error.
Always check line 296 or 297 because LogTargets are being modified to accommodate the 175 device limit
Versioning
10/17/2012  *Deployed to SI DMZ, SI CMS, SI Datalex, and Prod Datalex\
11/09/2012  Updated default message if message is not signed It now says Authentication Failure:  Message Body not signed
11/14/2012  Added Stats processing at bottom
12/12/12
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
  xmlns:mgmt="http://www.datapower.com/schemas/management" 
  xmlns:regexp="http://exslt.org/regular-expressions" 
  xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" 
  xmlns:str="http://exslt.org/strings" 
  xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
  extension-element-prefixes="date dp dyn exslt func regexp str" 
  exclude-result-prefixes="dp">
  
  <dp:summary xmlns="">
    <operation>xform</operation>
    <description>Specialized OnError Processing</description>
  </dp:summary>
  
   <xsl:include href="AuthType-Util-new.xsl"/>
    
  <!--
    These parameters are specified as part of the Transform action and are passed in by
    the firmware when this stylesheet is executed.
  -->
<!--User supplied variable section-->
  <dp:param name="dpconfig:OnErrorLogCat" type="'dmString'" xmlns="">
    <display>LoggingCategory</display>
    <description>Name of Log Category for events</description>
    <default>DMZSupportEvents</default>
  </dp:param>
  <xsl:param name="dpconfig:OnErrorLogCat"/>

  <!--<dp:param name="dpconfig:OnErrorDetailLogCat" type="'dmString'" xmlns="">
    <display>LoggingCategory</display>
    <description>Name of Log Category for Requests</description>
    <default>SupportDetailEvents</default>
  </dp:param>
  <xsl:param name="dpconfig:OnErrorDetailLogCat"/>-->

   <dp:param name="dpconfig:valcredX509" type="'dmString'" xmlns="">
    <display>Valcred Object</display>
    <description>Name of valcred object used by AAA action.</description>
    <default/>
  </dp:param>
  <xsl:param name="dpconfig:valcredX509"/>
  
  <dp:param name="dpconfig:ldapHostname" type="'dmString'" xmlns="">
    <display>LDAP Hostname</display>
    <description>LDAP server hostname or IP address</description>
    <default>LDAP-PRD.delta.com</default>
  </dp:param>
  <xsl:param name="dpconfig:ldapHostname" select="'LDAP-PRD.delta.com'"/>
  
  <dp:param name="dpconfig:ldapPort" type="'dmString'" xmlns="">
    <display>LDAP Port</display>
    <description>LDAP server port</description>
    <default>389</default>
  </dp:param>
  <xsl:param name="dpconfig:ldapPort"/>
  
  <dp:param name="dpconfig:ldapId" type="'dmString'" xmlns="">
    <display>LDAP ID</display>
    <description>LDAP server ID for checking whether we can connect</description>
    <default>svcdpw</default>
  </dp:param>
  <xsl:param name="dpconfig:ldapId"/>
  
  <dp:param name="dpconfig:ldapPwd" type="'dmString'" xmlns="">
    <display>LDAP Password</display>
    <description>Password for LDAP server ID for checking whether we can connect</description>
    <default/>
  </dp:param>
  <xsl:param name="dpconfig:ldapPwd"/>
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
   <xsl:variable name="reqBody2">
     <dp:serialize select="dp:variable('var://context/copyOfInput/_roottree')/soap:Envelope/soap:Body" omit-xml-decl="yes"/>
   </xsl:variable>
   <xsl:variable name="reqBody" select="translate($reqBody2, '&#x20;&#x9;&#xD;&#xA;;&#x22;', ' ')"/>
            
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

<!--Defines messages based on ErrorCodes and Subcodes.  Will log appropriate action internally-->
    <xsl:variable name="errorMessage">
      <xsl:choose>
        
        <xsl:when test="$errorCode='0x00230001'">
          <xsl:choose>
            <xsl:when test="$errorDirection='response'">
              <xsl:value-of
                select="concat('Error parsing or validating BACKEND SERVICE response message.','(TID:',$transactionId,')')" />
                <xsl:message dp:priority="info" dp:type="{$dpconfig:OnErrorLogCat}">***Error parsing or validating BACKEND SERVICE response message.Uncertain what would cause this error.<xsl:value-of select="concat('(TID:',$transactionId,')')"/></xsl:message>
		<xsl:message dp:priority="info" dp:type="{$ErrLogCat}"><xsl:value-of 
			select="concat($svcName,',',$operationName,',','Error parsing or validating BACKEND SERVICE response message.,',$cnVal,',',$userID,',',$baVal,',',$soapAct,',',$errCode,',',$errSubCode,',General,Uncertain what would cause this error')" /> 
		</xsl:message>
		<xsl:message dp:priority="info" dp:type="{$ErrReqCat}"><xsl:value-of select="$reqBody" /> </xsl:message>

            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of
                select="concat('Error parsing or validating APPLICATION request message.','(TID:',$transactionId,')')" />
                <xsl:message dp:priority="info" dp:type="{$dpconfig:OnErrorLogCat}">***Error parsing or validating APPLICATION request message.Uncertain what would cause this error.<xsl:value-of select="concat('(TID:',$transactionId,')')"/></xsl:message>
		<xsl:message dp:priority="info" dp:type="{$ErrLogCat}"><xsl:value-of 
			select="concat($svcName,',',$operationName,',','Error parsing or validating APPLICATION request message.,',$cnVal,',',$userID,',',$baVal,',',$soapAct,',',$errCode,',',$errSubCode,',General,Uncertain what would cause this error')" /> 
		</xsl:message>
		<xsl:message dp:priority="info" dp:type="{$ErrReqCat}"><xsl:value-of select="$reqBody" /> </xsl:message>
                
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        
        <xsl:when test="$errorCode='0x00030001'">
          <xsl:choose>
            <xsl:when test="$errorDirection='response'">
              <xsl:value-of select="concat('Error parsing BACKEND SERVICE response message.','(TID:',$transactionId,')')" />
                <xsl:message dp:priority="info" dp:type="{$dpconfig:OnErrorLogCat}">***Error parsing BACKEND SERVICE response message.Uncertain what would cause this error.<xsl:value-of select="concat('(TID:',$transactionId,')')"/></xsl:message>
		<xsl:message dp:priority="info" dp:type="{$ErrLogCat}"><xsl:value-of 
			select="concat($svcName,',',$operationName,',','Error parsing BACKEND SERVICE response message.,',$cnVal,',',$userID,',',$baVal,',',$soapAct,',',$errCode,',',$errSubCode,',General,Uncertain what would cause this error')" /> 
		</xsl:message>
		<xsl:message dp:priority="info" dp:type="{$ErrReqCat}"><xsl:value-of select="$reqBody" /> </xsl:message>

            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="concat('Error parsing APPLICATION request message','(TID:',$transactionId,')')" />
		<xsl:message dp:priority="info" dp:type="{$dpconfig:OnErrorLogCat}">***Error parsing APPLICATION request message.Uncertain what would cause this error.<xsl:value-of select="concat('(TID:',$transactionId,')')"/></xsl:message>
		<xsl:message dp:priority="info" dp:type="{$ErrLogCat}"><xsl:value-of 
			select="concat($svcName,',',$operationName,',','Error parsing APPLICATION request message.,',$cnVal,',',$userID,',',$baVal,',',$soapAct,',',$errCode,',',$errSubCode,',General,Uncertain what would cause this error')" /> 
		</xsl:message>
		<xsl:message dp:priority="info" dp:type="{$ErrReqCat}"><xsl:value-of select="$reqBody" /> </xsl:message>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        
        <xsl:when test="$errorCode='0x00d30003'">
          <xsl:choose>
            <xsl:when test="$errorSubCode='0x00d30003'">
		<xsl:value-of select="concat('Access to this Service Denied by Policy.','(TID:',$transactionId,')')"/>
		<xsl:message dp:priority="info" dp:type="{$dpconfig:OnErrorLogCat}">***Access to this Service Denied by Policy. The operation called was blocked by a reject all action.<xsl:value-of select="concat('(TID:',$transactionId,')')"/></xsl:message>
		<xsl:message dp:priority="info" dp:type="{$ErrLogCat}"><xsl:value-of 
			select="concat($svcName,',',$operationName,',','Access to this Service Denied by Policy.,',$cnVal,',',$userID,',',$baVal,',',$soapAct,',',$errCode,',',$errSubCode,',General,The operation called was blocked by a reject all action')" /> 
		</xsl:message>
		<xsl:message dp:priority="info" dp:type="{$ErrReqCat}"><xsl:value-of select="$reqBody" /> </xsl:message>
            </xsl:when>
            <xsl:when test="$errorSubCode='0x01d30002'">
                <xsl:copy-of select="local:badAuth()"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="concat('Unrecognized failure in SOA. Please contact IT,SOASvsSupport','(TID:',$transactionId,')')" />
              <xsl:message dp:priority="info" dp:type="{$dpconfig:OnErrorLogCat}">***Generic failure in middleware. Uncertain what would cause this error.<xsl:value-of select="concat('(TID:',$transactionId,')')"/></xsl:message>
		<xsl:message dp:priority="info" dp:type="{$ErrLogCat}"><xsl:value-of 
			select="concat($svcName,',',$operationName,',','Unrecognized failure in SOA. Please contact IT,SOASvsSupport.,',$cnVal,',',$userID,',',$baVal,',',$soapAct,',',$errCode,',',$errSubCode,',General,Generic failure in middleware.Uncertain what would cause this error')" /> 
		</xsl:message>
		<xsl:message dp:priority="info" dp:type="{$ErrReqCat}"><xsl:value-of select="$reqBody" /> </xsl:message>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
         
         <xsl:when test="$errorCode='0x01130011'">
          <xsl:value-of select="concat('Failed to process response headers.','(TID:',$transactionId,')')" />
          <xsl:message dp:priority="error" dp:type="{$dpconfig:OnErrorLogCat}">***Failed to process response headers. The failure usually indicates the proxy was set up for non-ssl and the backend server is expecting SSL. Update the proxy on Datapower to resolve issue.<xsl:value-of select="concat('(TID:',$transactionId,')')"/></xsl:message>
	  <xsl:message dp:priority="info" dp:type="{$ErrLogCat}"><xsl:value-of 
		select="concat($svcName,',',$operationName,',','Failed to process response headers.,',$cnVal,',',$userID,',',$baVal,',',$soapAct,',',$errCode,',',$errSubCode,',General,The failure usually indicates the proxy was set up for non-ssl and the backend server is expecting SSL. Update the proxy on Datapower to resolve issue')" /> 
	  </xsl:message>
          <xsl:message dp:priority="info" dp:type="{$ErrReqCat}"><xsl:value-of select="$reqBody" /> </xsl:message>
        </xsl:when>

		<xsl:when test="$errorCode='0x00c3000c'">
          <xsl:value-of select="concat('Proxy is misconfigured.','(TID:',$transactionId,')')" />
          <xsl:message dp:priority="error" dp:type="{$dpconfig:OnErrorLogCat}">***The proxy is not configured properly.  The output of one action does not match the input of the action following it. Modify the communications between the two rule actions to match.<xsl:value-of select="concat('(TID:',$transactionId,')')"/></xsl:message>
	  <xsl:message dp:priority="info" dp:type="{$ErrLogCat}"><xsl:value-of 
		select="concat($svcName,',',$operationName,',','Proxy is misconfigured.,',$cnVal,',',$userID,',',$baVal,',',$soapAct,',',$errCode,',',$errSubCode,',General,The proxy is not configured properly. The output of one action does not match the input of the action following it. Modify the communications between the two rule actions to match')" /> 
	  </xsl:message>
	  <xsl:message dp:priority="info" dp:type="{$ErrReqCat}"><xsl:value-of select="$reqBody" /> </xsl:message>
        </xsl:when>
        
        <xsl:when test="$errorCode='0x00c30008'">
           <xsl:choose>
            <xsl:when test="$errorDirection='response'">
				 <xsl:value-of select="concat('Server message did not include a SOAP Action Header.','(TID:',$transactionId,')')" />
              <xsl:message dp:priority="error" dp:type="{$dpconfig:OnErrorLogCat}">***The server did not respond with valid SOAP.  The server most likely sent a response like HTML that is not allowed with a web service proxy.  The server is expected to send valid SOAP as the response.  Try to send test message directly to server to determine what is being sent to Datapower.<xsl:value-of select="concat('(TID:',$transactionId,')')"/></xsl:message>
              <xsl:message dp:priority="info" dp:type="{$ErrLogCat}"><xsl:value-of 
	      		select="concat($svcName,',',$operationName,',','Server message did not include a SOAP Action Header.,',$cnVal,',',$userID,',',$baVal,',',$soapAct,',',$errCode,',',$errSubCode,',General,The server did not respond with valid SOAP.The server most likely sent a response like HTML that is not allowed with a web service proxy.The server is expected to send valid SOAP as the response.Try to send test message directly to server to determine what is being sent to Datapower.')" /> 
	      </xsl:message>
	      <xsl:message dp:priority="info" dp:type="{$ErrReqCat}"><xsl:value-of select="$reqBody" /> </xsl:message>
            </xsl:when>
            <xsl:otherwise>
             <xsl:value-of select="concat('Client Message did not include a SOAP Action Header.','(TID:',$transactionId,')')" />
                <xsl:message dp:priority="info" dp:type="{$dpconfig:OnErrorLogCat}">***The web service requires a SOAP Action Header.  The client must include a SOAP Action header.<xsl:value-of select="concat('(TID:',$transactionId,')')"/></xsl:message>
		<xsl:message dp:priority="info" dp:type="{$ErrLogCat}"><xsl:value-of 
			select="concat($svcName,',',$operationName,',','Client Message did not include a SOAP Action Header.,',$cnVal,',',$userID,',',$baVal,',',$soapAct,',',$errCode,',',$errSubCode,',General,The web service requires a SOAP Action Header.  The client must include a SOAP Action header')" /> 
		</xsl:message>
		<xsl:message dp:priority="info" dp:type="{$ErrReqCat}"><xsl:value-of select="$reqBody" /> </xsl:message>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
		          
		<xsl:when test="$errorCode='0x01130006' or $errorCode='0x01130007' or $errorCode='0x0113001e' or $errorCode='0x01130009' or $errorCode='0x00c3000f' or $errorCode='0x00030004'">
          <xsl:value-of select="concat('Failed to establish a backside connection.','(TID:',$transactionId,')')" />
          <xsl:message dp:priority="error" dp:type="{$dpconfig:OnErrorLogCat}">***Failed to establish a backside connection. Something has interfered with connectivity to backend server.  Test that backend server can be pinged, or called directly.<xsl:value-of select="concat('(TID:',$transactionId,')')"/></xsl:message>
	<xsl:message dp:priority="info" dp:type="{$ErrLogCat}"><xsl:value-of 
		select="concat($svcName,',',$operationName,',','Failed to establish a backside connection.,',$cnVal,',',$userID,',',$baVal,',',$soapAct,',',$errCode,',',$errSubCode,',General,Something has interfered with connectivity to backend server.Test that backend server can be pinged,or called directly')" /> 
	</xsl:message>
        <xsl:message dp:priority="info" dp:type="{$ErrReqCat}"><xsl:value-of select="$reqBody" /> </xsl:message>  
        </xsl:when>
    
	      
<!--CATCH ALL OTHER ERRORS-->
        <xsl:otherwise>
          <xsl:value-of select="concat($originalMessage,'.(TID:',$transactionId,')')" />
		   <xsl:message dp:priority="error"  dp:type="{$dpconfig:OnErrorLogCat}">***ErrorCode was not a match for current error list.  Investigate  <xsl:value-of select="concat('ErrorCode= ',$errorCode,' With SubCode= ',$errorSubCode ,' ',$originalMessage,'. Service ', dp:variable('var://service/processor-name'), ' - DP transaction id ', dp:variable('var://service/transaction-id'), ' on ', dp:variable('var://service/protocol'), '://', dp:variable('var://service/local-service-address'), ' at ', date:date-time())"/></xsl:message>
              <xsl:message dp:priority="info" dp:type="{$dpconfig:OnErrorLogCat}">***Generic failure in middleware. Uncertain what would cause this error.<xsl:value-of select="concat('(TID:',$transactionId,')')"/></xsl:message>
		<xsl:message dp:priority="info" dp:type="{$ErrLogCat}"><xsl:value-of 
			select="concat($svcName,',',$operationName,',',$originalMessage,',',$cnVal,',',$userID,',',$baVal,',',$soapAct,',',$errCode,',',$errSubCode,',General,Generic failure in middleware.Uncertain what would cause this error')" /> 
		</xsl:message>
		<xsl:message dp:priority="info" dp:type="{$ErrReqCat}"><xsl:value-of select="$reqBody" /> </xsl:message>
        </xsl:otherwise> 
        </xsl:choose>
        </xsl:variable>
 <!--End selection of appropriate error message and logging message-->

<!-- Determine the Authentication Details only if error is related to Authentication(ErrorSubCode=0x01d30002)-->
<func:function name="local:badAuth">
    <xsl:variable name="result">
    <!--<xsl:param name="strategy"/>--> <!-- <error> strategy element --><!--NOT SURE IF THIS IS NEEDED-->
     <xsl:choose>

      <xsl:when test="local:getId($input) = ''">
          <xsl:choose>
		  <!--<xsl:when test="$dpconfig:valcredX509 != '' ">-->
            <!-- No userid of any sort was supplied, so gently correct the caller. -->
            <xsl:when test="$dpconfig:ldapPwd != ''"> 
            <xsl:value-of select="'Authentication Failure:  SOAP Message should have included a username/password combination. No credentials were provided.  Contact IT,SOASvsSupport.'"/>        
            <xsl:message dp:priority="info" dp:type="{$dpconfig:OnErrorLogCat}">***The domain is not configured for a certificate so a username/password should of been provided.  The message had no security information in the message.  The client must authenticate with the appropriate type for this service call.</xsl:message>
	    <xsl:message dp:priority="info" dp:type="{$ErrLogCat}"><xsl:value-of 
		select="concat($svcName,',',$operationName,',','Authentication Failure:SOAP Message should have included a username/password combination.No credentials were provided.Contact IT SOASvsSupport.,',$cnVal,',',$userID,',',$baVal,',',$soapAct,',',$errCode,',',$errSubCode,',General,The domain is not configured for a certificate so a username/password should of been provided.The message had no security information in the message.The client must authenticate with the appropriate type for this service call')" /> 
	    </xsl:message>
	    <xsl:message dp:priority="info" dp:type="{$ErrReqCat}"><xsl:value-of select="$reqBody" /> </xsl:message>
         </xsl:when>
         <xsl:otherwise>
           <!--Defaults to lettting them know to sign the message.  This is most messages.-->
		   <xsl:value-of select="'Authentication Failure:  SOAP body must be signed for signature-based authentication.'"/>        
            <xsl:message dp:priority="info" dp:type="{$dpconfig:OnErrorLogCat}">***The domain is configured to require Digital Certificates but the client did not include one in the message.  The client must authenticate with the appropriate type for this service call.</xsl:message>  
            <xsl:message dp:priority="info" dp:type="{$ErrLogCat}"><xsl:value-of 
            	select="concat($svcName,',',$operationName,',','Authentication Failure: SOAP body must be signed for signature-based authentication.,',$cnVal,',',$userID,',',$baVal,',',$soapAct,',',$errCode,',',$errSubCode,',x509,The domain is configured to require Digital Certificates but the client did not include one in the message.')" /> 
            </xsl:message>
            <xsl:message dp:priority="info" dp:type="{$ErrReqCat}"><xsl:value-of select="$reqBody" /> </xsl:message>
         </xsl:otherwise> 
         </xsl:choose>    
       </xsl:when>
      <xsl:otherwise>

        <!-- A userid of some sort was supplied, so lets check out the possibilities. -->
        
        <xsl:choose>
          <xsl:when test="local:isIdX509($input)">
            <xsl:variable name="dnVal" select="local:getIdDN(.)"/>
   	        <xsl:variable name="cnVal" select="local:CNfromDN($dnVal)"/>
            <!-- We have an X509 certificate, so examine it carefully. -->
            <xsl:variable name="wssec" select="$input/*[local-name()='Envelope']/*[local-name()='Header']/wsse:Security"/>
            <xsl:value-of select="local:examineX509($wssec)"/>
            <xsl:message dp:priority="info" dp:type="{$dpconfig:OnErrorLogCat}">***Certificate details were examined with isIdX509 Function. This is the DN from the certificate: <xsl:value-of select="$dnVal" /></xsl:message>
          </xsl:when>
          <xsl:when test="local:isIdUsernameToken($input)">
            
            <!-- We have a username token, so examine it carefully. -->
            <xsl:variable name="wssec" select="$input/*[local-name()='Envelope']/*[local-name()='Header']/wsse:Security"/>
            <xsl:value-of select="local:examineUsernameToken($wssec)"/>
              <xsl:message dp:priority="info" dp:type="{$dpconfig:OnErrorLogCat}">***Username/Password token were examinded with the examineUsernameToken function.  This is the result from the function: <xsl:value-of select="local:examineUsernameToken($wssec)" /></xsl:message>
          </xsl:when>
          <xsl:when test="local:isIdBasicAuth()">

            <!-- We have a basic auth header, so examine it carefully. -->
            <xsl:value-of select="local:examineBasicAuth()"/>
              <xsl:message dp:priority="info" dp:type="{$dpconfig:OnErrorLogCat}">***Username/Password from the HTTP Basic Auth were examined by the examineBasicAuth function.  This is the result from the function: <xsl:value-of select="local:examineBasicAuth()" /></xsl:message>
          </xsl:when>
          <xsl:otherwise>            
            <xsl:message dp:priority="error" dp:type="{$dpconfig:OnErrorLogCat}">***Someone added a new type of user credential without updating the code in on-error.xsl.</xsl:message>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
</xsl:variable>
  <func:result select="$result"/>
 </func:function>
<!--End the Authentication Details specific section-->


<!--Builds response to client and logs to target-->
<xsl:template match="/">
	            
    <!-- Build the response document -->
    <xsl:variable name="responseDoc">
      <xsl:element name="soap:Envelope">
        <xsl:element name="soap:Body">
          <xsl:element name="soap:Fault">
					<xsl:element name="faultcode">
					<xsl:value-of select="$errorCode"/>
					</xsl:element>
					<xsl:element name="faultstring">
					<xsl:value-of select="$errorMessage"/>
					</xsl:element>
					<xsl:element name="faultfactor">
					<xsl:value-of select="'SOA'"/>
					</xsl:element>
					<xsl:element name="faultdetail">
					<xsl:value-of select="concat('Service ', dp:variable('var://service/processor-name'), ' - DP transaction id ', dp:variable('var://service/transaction-id'), ' on ', $deviceName, ' at ', date:date-time())"/>
					</xsl:element>
          </xsl:element>
        </xsl:element>
      </xsl:element>
    </xsl:variable>
    
    <!-- set the HTTP Response Code and content type -->
    <dp:set-variable name="'var://service/error-protocol-response'" value="'500'"/>
    <dp:set-request-header name="'Content-Type'" value="'text/xml'"/>

    <xsl:copy-of select="$responseDoc"/>

    <!-- Do some logging too. -->
    <!--<xsl:variable name="LogCat" select="$dpconfig:OnErrorDetailLogCat"/>-->
	<!--<xsl:variable name="LogCat" select="concat(dp:variable('var://service/processor-name'), 'IntErrors')"/>-->
	<xsl:variable name="LogCat" select="'DMZErrorsLogCat'"/>
    <xsl:variable name="ServiceName" select="dp:variable('var://service/processor-name')"/>
 
   <xsl:message dp:priority="info" dp:type="{$LogCat}">
     <xsl:value-of select=" concat('[',$ServiceName, '] Request:')"/>
     <xsl:copy-of select="dp:variable('var://context/copyOfInput/_roottree')"/>
    </xsl:message>
   <xsl:message dp:priority="info" dp:type="{$LogCat}">
      <xsl:value-of select=" concat('[',$ServiceName, '] Response:')"/>
      <xsl:copy-of select="$responseDoc"/>
    </xsl:message>


<!-- Stats processing  -->
<xsl:variable name="LogCat2" select="'AMXStats'"/>
  
 <xsl:variable name="errCode" select="dp:variable('var://service/error-code')"/>
 <xsl:variable name="errSubCode" select="dp:variable('var://service/error-subcode')"/>
 <xsl:variable name="errMsg" select="dp:variable('var://service/error-message')"/>
 <xsl:variable name="userID" select = "dp:variable('var://context/WSM/identity/username')"/>
  <xsl:variable name="IPaddr" select = "dp:request-header('X-Forwarded-For')"/>
  
  <xsl:variable name="operationName" select="dp:variable('var://context/ActiveMatrixESB/operation')"/>
  
 <xsl:choose>
       <xsl:when test="dp:variable('var://context/WSM/identity/username') != ''">
            <xsl:message dp:type="{$LogCat2}" dp:priority="info">
            	
            	<xsl:value-of select=" concat($svcName,',',$operationName,',',$userID,',' , $errCode, ',' , $errSubCode, ',' , $errMsg, ',' ,$IPaddr)" />
            </xsl:message>
       </xsl:when>
 
      <xsl:otherwise>
         <xsl:message dp:type="{$LogCat2}" dp:priority="info">
 		<xsl:value-of select=" concat($svcName,',',$operationName,',',',' , $errCode, ',' , $errSubCode, ',' , $errMsg, ',' ,$IPaddr)" />
 		
 	</xsl:message>
      </xsl:otherwise>
      
  </xsl:choose>
 <!-- End Stats section -->

</xsl:template>

</xsl:stylesheet>