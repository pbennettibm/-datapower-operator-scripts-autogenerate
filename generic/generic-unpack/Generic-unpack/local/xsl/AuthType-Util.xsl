<?xml version="1.0" encoding="UTF-8"?>
<!-- 

  This stylesheet contains functions to handle the "userid" for the request when it
  was supplied as an X509 certificate in a binary security token, as a userid in a
  username token, or as a basic auth userid.
11/09/2012  Updated the error for username/password does not validate;Request was to modify to a "Failed Authorization Error:"
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
  exclude-result-prefixes="date dp dpconfig dpquery dyn exslt func regexp str">

  <xsl:template match="/">
    
    <xsl:element name="result">
		<!--This set of functions only return a True or False-->
      <xsl:element name="isIdX509">
        <xsl:value-of select="local:isIdX509(.)"/>
      </xsl:element>
      
      <xsl:element name="isIdUsernameToken">
        <xsl:value-of select="local:isIdUsernameToken(.)"/>
      </xsl:element>
      
      <xsl:element name="isIdBasicAuth">
        <xsl:value-of select="local:isIdBasicAuth()"/>
      </xsl:element>
      <!--End set of functions only return a True or False-->

      <xsl:element name="getIdDN">
        <xsl:value-of select="local:getIdDN(.)"/>
      </xsl:element>
      

	  <!--These functions get more details about the Identification used in Authentication-->
      <xsl:element name="getIdUNT">
        <xsl:value-of select="local:getIdUNT(.)"/>
      </xsl:element>
      
      <xsl:element name="getIdBasicAuth">
        <xsl:value-of select="local:getIdBasicAuth()"/>
      </xsl:element>
      
      <xsl:element name="getId">
        <xsl:value-of select="local:getId(.)"/>
      </xsl:element>
      <!--Details added for OnError.  The next four functions were added specifically for OnError.xsl
		These functions will return error messages. -->
	  <xsl:element name="examineX509">
        <xsl:value-of select="local:examineX509(.)"/>
      </xsl:element>
	
	  <xsl:element name="examineUsernameToken">
        <xsl:value-of select="local:examineUsernameToken(.)"/>
      </xsl:element>

	  <xsl:element name="examineBasicAuth">
        <xsl:value-of select="local:examineBasicAuth()"/>
      </xsl:element>
	  
	  <!--LDPAP connection parameters must be passed to this function for it to work.-->
      <xsl:element name="canLDAPbeReached">
        <xsl:value-of select="local:canLDAPbeReached(.)"/>
      </xsl:element>
      
       <!--Runs only if the authentication was a certificate.  This will pull the CN value only from the certificate information-->
	<xsl:if test="local:isIdX509(.)">
        <xsl:element name="CN">
          <xsl:value-of select="local:CNfromDN(local:getIdDN(.))"/>
        </xsl:element>
      </xsl:if>
      
    </xsl:element>
    
  </xsl:template>
  
  
  <!-- 
    Determine whether the request contains a binary security token with an X509 certificate.
    Returns boolean true or false (not string 'true' or 'false')
  -->
  <func:function name="local:isIdX509">
    <xsl:param name="request"/>
    <!--
      This xpath tests whether the request contains an X509 certificate in a binary security token.
      
      The first two terms (/*[local-name()='Envelope']/*[local-name()='Header']) are insensitive to
      whether the request is SOAP 1 or SOAP 1.2. 
      
      The wsse:Security term identifies the WS-Security header in the request (if one is present).
      
      The final term, wsse:BinarySecurityToken[@ValueType='http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-x509-token-profile-1.0#X509v3'],
      identifies whether an X509 certificate is present.
    -->
    <func:result select="$request/*[local-name()='Envelope']/*[local-name()='Header']/wsse:Security/wsse:BinarySecurityToken[@ValueType='http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-x509-token-profile-1.0#X509v3'] != ''"/>
  </func:function>
  
  
  
  <!-- 
    Determine whether the request contains a username token.
    Returns boolean true or false (not string 'true' or 'false')
  -->
  <func:function name="local:isIdUsernameToken">
    <xsl:param name="request"/>
    <!--
      This xpath tests whether the request contains a username token.
      
      The first two terms (/*[local-name()='Envelope']/*[local-name()='Header']) are insensitive to
      whether the request is SOAP 1 or SOAP 1.2. 
      
      The wsse:Security term identifies the WS-Security header in the request (if one is present).
      
      The final term, wsse:UsernameToken, identifies whether a UsernameToken is present.
    -->
    <func:result select="$request/*[local-name()='Envelope']/*[local-name()='Header']/wsse:Security/wsse:UsernameToken != ''"/>
  </func:function>
  
  
  
  <!-- 
    Determine whether the request contains a Basic Auth header.
    Returns boolean true or false (not string 'true' or 'false')
  -->
  <func:function name="local:isIdBasicAuth">
    <func:result select="starts-with(dp:request-header('Authorization'), 'Basic ')"/>
  </func:function>
  
  
  
  <!-- 
    Return the DN from the X509 certificate, or an empty string.
  -->
  <func:function name="local:getIdDN">
    <xsl:param name="request"/>
    <func:result>
      
      <!-- Pick out the X509 certificate. -->
      <xsl:variable name="X509" select="string($request/*[local-name()='Envelope']/*[local-name()='Header']/wsse:Security/wsse:BinarySecurityToken[@ValueType='http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-x509-token-profile-1.0#X509v3'])"/>
      
      <xsl:choose>
        <xsl:when test="$X509 != ''">
          
          <!-- Get the "subject" from the cert, which is usually a DN. -->
          <xsl:value-of select="dp:get-cert-subject(concat('cert:', $X509))"/>
          
        </xsl:when>
        <xsl:otherwise>
          
          <!-- No cert, no joy.  Return an empty string. -->
          <xsl:value-of select="''"/>
          
        </xsl:otherwise>
      </xsl:choose>
      
    </func:result>
  </func:function>
  
  
  <!-- 
    Return the user name from a WS-Security UsernameToken, or return an empty string.
  -->
  <func:function name="local:getIdUNT">
    <xsl:param name="request"/>
    <func:result select="string($request/*[local-name()='Envelope']/*[local-name()='Header']/wsse:Security/wsse:UsernameToken/wsse:Username)"/>
  </func:function>
  

  <!-- 
    Return the userid from the Basic Auth HTTP header, or return an empty string.
  -->
  <func:function name="local:getIdBasicAuth">
    <func:result>
      
      <xsl:variable name="hdr" select="dp:request-header('Authorization')"/>
      <xsl:choose>
        <xsl:when test="starts-with($hdr, 'Basic ')">
          
          <!--
            The Authorization header value is "Basic xxxxxx" where xxxxxx is a base-64 encoded string 
            of the form "uid:pwd".  So this line of code peels off the xxxxx part, decodes it, then picks
            off the userid.
          -->
          <xsl:value-of select="substring-before(dp:decode(substring-after($hdr, 'Basic '), 'base-64'), ':')"/>
          
        </xsl:when>
        <xsl:otherwise>
          
          <!-- No Basic Auth header so no joy.  Return an empty string. -->
          <xsl:value-of select="''"/>
          
        </xsl:otherwise>
      </xsl:choose>
      
    </func:result>
  </func:function>
  
  
  
  <!-- 
    Returns the userid or DN provided in a basic auth header, a username token, or an X509 certificate (in that order). 
  -->
  <func:function name="local:getId">
    <xsl:param name="request"/>
    <func:result>
      
      <xsl:choose>
        <xsl:when test="local:isIdBasicAuth()">
          <xsl:value-of select="local:getIdBasicAuth()"/>
        </xsl:when>
        <xsl:when test="local:isIdUsernameToken($request)">
          <xsl:value-of select="local:getIdUNT($request)"/>
        </xsl:when>
        <xsl:when test="local:isIdX509($request)">
          <xsl:value-of select="local:getIdDN($request)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="''"/>
        </xsl:otherwise>
      </xsl:choose>
    </func:result>
  </func:function>
  
  
  <!-- 
    Return the CN contained in a DN, assuming that there IS a CN in the DN.
  -->
  <func:function name="local:CNfromDN">
    <xsl:param name="DN"/>
    <func:result>
      <!--
        It might seem simpler to just search for CN=, but this may be part of the content of a field,
        so we check more carefully, including comma in the search because comma is reserved solely
        for separating DN values.
      -->
      <xsl:variable name="afterCN">
        <xsl:choose>
          <xsl:when test="starts-with($DN, 'CN=')">
            <!-- CN is the first thing in the DN. -->
            <xsl:value-of select="substring-after($DN, 'CN=')"/>
          </xsl:when>
          <xsl:when test="starts-with($DN, ', CN=')">
            <!-- CN is not the first thing in the DN, and there are blanks following the commas -->
            <xsl:value-of select="substring-after($DN, ', CN=')"/>
          </xsl:when>
          <xsl:when test="starts-with($DN, ',CN=')">
            <!-- CN is not the first thing in the DN, and there are no blanks following the commas -->
            <xsl:value-of select="substring-after($DN, ',CN=')"/>
          </xsl:when>
          <xsl:otherwise>
            <!-- No CN in the DN. -->
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      
      <!-- Peel off the CN value, unless it is empty or the CN term is the last one in the DN. -->
      <xsl:choose>
        <xsl:when test="contains($afterCN, ',')">
          <xsl:value-of select="substring-before($afterCN, ',')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$afterCN"/> <!-- either CN wasn't present, or it was the final/only term in the DN. -->
        </xsl:otherwise>
      </xsl:choose>
    </func:result>
  </func:function>
  <!-- NEW FUNCTIONS **********************************************************************************************************-->
  <!-- 
    Examine the supplied <wsse:Security> element which is guaranteed to contain a <wsse:BinarySecurityToken> 
    element containing an X509 certificate. Return a string indicating what the problem might be.
  -->
  <func:function name="local:examineX509">
    <xsl:param name="wssec"/>
    <func:result>
      <!--MAKE SURE VALIDATION CREDENTIAL IS POPULATED AND ACCURATE FOR THIS SECTION TO WORK-->
      <xsl:choose>
        <xsl:when test="not($wssec/dsig:Signature)">
          
          <!-- The <wsse:Security> element doesn't contain a signature! -->
          <xsl:value-of select="concat('The ', name($wssec), ' element lacks a signature!  An XML digital signature required.')"/>
          <xsl:message dp:priority="info" dp:type="{$dpconfig:OnErrorLogCat}" >***No signature was included in the WS-Security section of the message.</xsl:message>
        </xsl:when>
        <xsl:otherwise>
          
          <!-- 
            A digital signature is present, but whether it is signed correctly is difficult to verify.
            Examine the certificate instead, which is much easier. ;)
          -->
         
          <!-- Extract the raw base-64 encoded certificate (it is the text content of the <wsse:BinarySecurityToken>). -->
          <xsl:variable name="cert" select="string($wssec/wsse:BinarySecurityToken[@ValueType='http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-x509-token-profile-1.0#X509v3'])"/>
          
          <!-- Use dp:validate-certificate() to examine the cert, including checking it against a "well known" valcred. -->
          <xsl:variable name="certnode">
            <input>
              <subject>
                <xsl:value-of select="concat('cert:',$cert)"/>
              </subject>
            </input>
          </xsl:variable>
          <xsl:variable name="validationResult" select="dp:validate-certificate($certnode, $dpconfig:valcredX509) "/>
          
          <!-- Return dp:validate-certificate()'s complaint. -->
          <xsl:value-of select="'Authentication Failure: '"/>
          <xsl:choose>
            <xsl:when test="$validationResult = '*ASN.1 parse of certificate failed*'">
              
              <xsl:value-of select="'Your x509 digital certficate is invalid. It has been corrupted or otherwise compromised.'"/>
              <xsl:message dp:priority="info" dp:type="{$dpconfig:OnErrorLogCat}" >***Certificate failed validation because it was not in the correct format from the client or may have been truncated by another system.</xsl:message>
            </xsl:when>
            
			<xsl:when test="$validationResult = 'certificate not trusted'">
               <xsl:value-of select="'One of the signatures on the request document, although valid, was signed by an unknown or untrusted party. The signature cannot be trusted.'"/>
		      <xsl:message dp:priority="info"  dp:type="{$dpconfig:OnErrorLogCat}">***Certificate is not included in Valcred.  Add certificate to Valcred to resolve error.</xsl:message>
            </xsl:when>
            
			<xsl:when test="$validationResult = 'certificate has expired'">
               <xsl:value-of select="'Your x509 certficate has expired.'"/>
		      <xsl:message dp:priority="info" dp:type="{$dpconfig:OnErrorLogCat}" >***Certificate has expired. Add new certificate to Valcred in Datapower to allow access.</xsl:message>
            </xsl:when>
            
			<xsl:when test="$validationResult != ''">
              
              <xsl:value-of select="$validationResult"/>
              <xsl:message dp:priority="error" dp:type="{$dpconfig:OnErrorLogCat}" >***Certificate validation did not fail with a known message.  Add this message to the utility functions to increase details.<xsl:value-of select="$validationResult"/></xsl:message>
            </xsl:when>
            <xsl:otherwise>

              <!-- The certificate itself is fine so the only remaining possibility is an incorrect signature. -->
              <xsl:value-of select="'The digitial signature in the message is invalid.  Either the message was changed after it was signed or tampered with in transit.'"/>
            <xsl:message dp:priority="info" dp:type="{$dpconfig:OnErrorLogCat}" >***Certificate signature was tampered with because the certificate portion was validated successfully.</xsl:message>
            </xsl:otherwise>
          </xsl:choose>
          
        </xsl:otherwise>
      </xsl:choose>
      
    </func:result>
  </func:function>
  
  
  
  <!-- 
    Examine the supplied <wsse:Security> element which is guaranteed to contain a <wsse:UsernameToken> element. 
  -->
  <func:function name="local:examineUsernameToken">
    <xsl:param name="wssec"/>
    <func:result>
       
      <xsl:choose>
        <xsl:when test="$wssec/wsse:UsernameToken/wsse:Username != '' and $wssec/wsse:UsernameToken/wsse:Password != ''">
			<xsl:variable name="LDAPReachability">
			<xsl:value-of select="local:canLDAPbeReached()"/>
			</xsl:variable>
          <!-- We can infer that the problem is a bad uid/password combination. -->
			<!--	<xsl:choose>
				<xsl:when test="$LDAPReachability != ''">-->
				<xsl:value-of select="$LDAPReachability"/>
				<!--</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="concat('The userid/password is invalid.',$LDAPReachability)" />
					<xsl:message dp:priority="info" dp:type="{$dpconfig:OnErrorLogCat}">***The Username/Password in the WS-Security Header was found and LDAP was contacted. The client is most likely not sending a correct combination.  <xsl:value-of select="$LDAPReachability" /></xsl:message>
				</xsl:otherwise>-->
                </xsl:when>
     
        



        <xsl:when test="$wssec/wsse:UsernameToken/wsse:Username != '' and $wssec/wsse:UsernameToken/wsse:Password = ''">
          
          <xsl:value-of select="concat('The message did not inlcude a password to go with the userid: ', $wssec/wsse:UsernameToken/wsse:Username)"/>
          <xsl:message dp:priority="info" dp:type="{$dpconfig:OnErrorLogCat}">***The Password was either not provided or it was not found in the correct location.  This client should correct the message.  This indicates the username was present but specifically no password was available.</xsl:message>
        </xsl:when>
        <xsl:otherwise>
          
          <xsl:value-of select="'The WS-Security Username Token was incomplete and/or malformed causing either a userid or password not to be found.'"/>
            <xsl:message dp:priority="info" dp:type="{$dpconfig:OnErrorLogCat}">***Username/Password was either not provided or it was not found in the correct location.  This client should correct the message.</xsl:message>
        </xsl:otherwise>
      </xsl:choose>
      
    </func:result>
  </func:function>
  
  
  
  <!-- 
    Examine the current Basic Auth header (which is guaranteed to exist) and see if you can explain an
    AU/AZ failure.
  -->
  <func:function name="local:examineBasicAuth">
    <func:result>

      <xsl:variable name="authHeader" select="dp:request-header('Authorization')"/>
      <xsl:variable name="uidpwd" select="dp:decode(substring-after($authHeader, 'Basic '), 'base-64')"/>
      <xsl:variable name="uid" select="substring-before($uidpwd, ':')"/>
      <xsl:variable name="pwd" select="substring-after($uidpwd, ':')"/>
      
      <xsl:choose>
        <xsl:when test="$uid != '' and $pwd != ''">
			<xsl:variable name="LDAPReachability">
			<xsl:value-of select="local:canLDAPbeReached()"/>
			</xsl:variable>
          <!-- We can infer that the problem is a bad uid/password combination. -->
				<xsl:choose>
				<xsl:when test="$LDAPReachability != ''">
				<xsl:value-of select="concat('Error in Authentication.  The LDAP server can not be reached currently for more details. ',$LDAPReachability,'. ')"/>
				<xsl:message dp:priority="error" dp:type="{$dpconfig:OnErrorLogCat}">***The Username/Password in the BASIC Authentication was found but LDAP could not be reached for further details.  Additional details could not be verified.  This may be a misconfiguration on Datapower with the error processing, or the LDAP could be unreachable. <xsl:value-of select="$LDAPReachability" /></xsl:message>
				</xsl:when>
				<xsl:otherwise>
					<!--<xsl:value-of select="local:canLDAPbeReached(concat('The userid/password combination ', $uid, '/****** does not work.'))"/>-->
					<xsl:value-of select="concat('The userid/password combination ', $uid, '/****** does not work.')" />
					<xsl:message dp:priority="info" dp:type="{$dpconfig:OnErrorLogCat}">***The Username/Password in the BASIC Authentication was found and LDAP was contacted. The client is most likely not sending a correct combination.  <xsl:value-of select="$LDAPReachability" /></xsl:message>
				</xsl:otherwise>
                </xsl:choose>
        </xsl:when>

        <xsl:when test="$uid != '' and $pwd = ''">
          <xsl:value-of select="concat('Missing password for userid: ', $uid)"/>
          	<xsl:message dp:priority="info" dp:type="{$dpconfig:OnErrorLogCat}">***Username/Password BASIC Authentication did not include a password value.  Client should correct the message.</xsl:message>
        </xsl:when>
        <xsl:otherwise>
          
          <xsl:value-of select="'The Basic Auth header is missing a userid or password.'"/>
           <xsl:message dp:priority="info" dp:type="{$dpconfig:OnErrorLogCat}">***Username/Password BASIC Authentication was either not provided or it was not found in the correct location.  Client should correct the message.</xsl:message>
        </xsl:otherwise>
      </xsl:choose>
      
    </func:result>
  </func:function>
  
  
  <!-- 
    Attempt to simply reach LDAP.  If it can be reached then the userid/password is bad, otherwise
    AAA failed to authorize the userid/password because LDAP was unreachable.  Returns an error
    message that reflects one possibility or the other.
  -->
  <func:function name="local:canLDAPbeReached">
    <xsl:param name="defaultMsg"/>
    <func:result>
           
      <xsl:choose>
		<!--<xsl:when test="$dpconfig:ldapHostname != ''">-->
         <!--<xsl:when test="dp:variable('var://context/WSM/identity/credentials') = ''">  -->
             <xsl:when test="dp:variable('var://context/WSM/identity/authenticated-user') = ''">
          <!-- LDAP is configured, so see if it can be reached. The user never authenticated.So explain why -->
          <xsl:variable name="testldap" select="dp:ldap-search($dpconfig:ldapHostname,$dpconfig:ldapPort,$dpconfig:ldapId,$dpconfig:ldapPwd, 'DC=delta, DC=rl, DC=delta, DC=com', 'dn', '(&amp;(objectClass=user)(dalLoginList=svcdpw))', 'sub', '', '', 'v3')"/>
      			<xsl:choose>
			    <xsl:when test="$testldap/LDAP-search-error/error">
			    	 <xsl:value-of select="'Cannot connect to LDAP at this time for additional information on the Authentication error.'"/>
                     <xsl:message dp:priority="error" dp:type="{$dpconfig:OnErrorLogCat}">***An LDAP connection was attempted to determine more details.  Additional details could not be verified because LDAP could not be reached.  This may be a misconfiguration on Datapower with the error processing, or the LDAP connection.</xsl:message>
				</xsl:when>
				<!--The LDAP connection was successful so the user must not have given the right information.-->
				<xsl:otherwise>
					 <xsl:value-of select="'Authentication Failure:  Invalid UserID or Password'" />
                     <xsl:message dp:priority="error" dp:type="{$dpconfig:OnErrorLogCat}">***The message provided credentials that could not be Authenticated.  The LDAP server responded properly.  Most likely the user is not providing the right combination.</xsl:message>
				</xsl:otherwise>
                </xsl:choose>
          </xsl:when>
		  <xsl:otherwise>
		  <!--This is an authorization failure because the authentication-user value is not blank.  They only explanation is an authorization failure.  -->
		  <xsl:value-of select="'Authorization Failure:  This account does not have the proper access.'" />
          <xsl:message dp:priority="error" dp:type="{$dpconfig:OnErrorLogCat}">***The message provided credentials that could not be Authorized.  The LDAP server responded properly.  Most likely the account provided is not in the required group.</xsl:message>
		  </xsl:otherwise>
		</xsl:choose>
     
        
      
    </func:result>
  </func:function>
</xsl:stylesheet>
