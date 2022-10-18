<?xml version="1.0" encoding="UTF-8"?>
    <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
        xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" 
        xmlns:dp="http://www.datapower.com/extensions" extension-element-prefixes="dp" exclude-result-prefixes="dp">
        
        <xsl:variable name="DN" select="dp:variable('var://context/creds/DN')"/>
        <xsl:variable name="OU" select="dp:variable('var://context/creds/OU')"/>
        <xsl:variable name="CN" select="dp:variable('var://context/creds/CN')"/>
        <xsl:variable name="UID" select="dp:variable('var://context/creds/uid')"/>
        <xsl:variable name="aaa" select="dp:variable('var://context/ActiveMatrixESB/aaa')"/>
        <xsl:variable name="AuthStatus" select="string(/container/mapped-credentials/@au-success)"/>
        <xsl:variable name="X509" select="string(/container/mapped-credentials/entry/CertificateDetails/Base64)"/>
        <xsl:variable name="valcred" select="$aaa/aaa/@valcred"/>
        
        <xsl:template match="/">
          
            <!--Check if Authentication Worked-->
            
            
            <xsl:message> ####X509 results:<xsl:copy-of select="$X509"/></xsl:message>
            
            <!-- Use dp:validate-certificate() to examine the cert, including checking it against a "well known" valcred. -->
            <xsl:variable name="certnode">
                <input>
                    <subject>
                        <xsl:value-of select="concat('cert:',$X509)"/>
                    </subject>
                </input>
            </xsl:variable>
            
            
            
            <xsl:variable name="validationResult" select="dp:validate-certificate($certnode, $valcred) "/>
            
            <!--Debug Messages-->
            <xsl:message> ####Validation results:<xsl:copy-of select="$validationResult"/></xsl:message>
            <xsl:message> ####CERT OU INFO FOR USE:<xsl:value-of select="concat('*OU=',$OU)" /> </xsl:message>
            <xsl:message> ####CERT CN INFO FOR USE:<xsl:value-of select="concat('*CN=',$CN)" /> </xsl:message>
            <xsl:message> ####CERT DN INFO FOR USE:<xsl:value-of select="concat('*DN=',$DN)" /> </xsl:message>
	    <xsl:message> #### AAA :<xsl:value-of select="concat('*AAA=',$aaa)" /> </xsl:message>
	    <xsl:message> #### AAA  2:<xsl:copy-of select="concat('*AAA=',$aaa)" /> </xsl:message>
         
        <!--Second Authorization Check-->
         <!--Check to see if Control File has any cert_az values-->
         <xsl:variable name="ControlValEnabled">
            <xsl:choose> 
                <xsl:when test="$aaa/aaa/cert_az">            
            <xsl:message>### CERT_AZ ENABLED </xsl:message>
                  <xsl:value-of select="'ON'"/>
                </xsl:when>
            <xsl:otherwise>
                   <xsl:value-of select="'OFF'"/>
                <xsl:message>### CERT_AZ DISABLED </xsl:message>
            </xsl:otherwise>  
            </xsl:choose>
        </xsl:variable>

         <xsl:variable name="MatchedControlVal">
            <xsl:choose> 
                <xsl:when test="$aaa/aaa[cert_az = $OU]">            
            <xsl:message>### MATCHING ROLE '<xsl:value-of select="$OU"/>' </xsl:message>
                  <xsl:value-of select="'Matched'"/>
               </xsl:when>
            <xsl:otherwise>
                 <xsl:value-of select="'No Match'"/>
                <xsl:message>### NO MATCHING ROLE to '<xsl:value-of select="$OU"/>' </xsl:message>
                
            </xsl:otherwise>  
            </xsl:choose>
        </xsl:variable>
        <xsl:message> ####MatchedControlValidation to:<xsl:value-of select="$MatchedControlVal" /> </xsl:message>
        <xsl:message> ####CONTROLVAL Value:<xsl:value-of select="$ControlValEnabled" /> </xsl:message>
        <xsl:variable name="valdnResultLegnth"> <xsl:value-of select="string-length($validationResult)"/> </xsl:variable>
        <xsl:message> ####Validation Result Length: <xsl:value-of select="$valdnResultLegnth" /> </xsl:message>
        <!--End Second Authorization Check-->
       
      
		<xsl:variable name="result">
                <xsl:choose>
                    <!--Failure Conditions-->
                    <xsl:when test="$AuthStatus != 'true' ">
                        <xsl:element name="declined"/>
                        <xsl:variable name="ServiceName" select="dp:variable('var://context/ActiveMatrixESB/serviceName')"/>
                        <xsl:variable name="CounterName" select="concat('/monitor-count/', $ServiceName, 'AAAFailuresCnt')"/>
                        <dp:increment-integer name="$CounterName"/>
                        <xsl:message dp:priority="info">########Counter Name: <xsl:value-of select="$CounterName"/> ####### </xsl:message>
                        <xsl:message> #### Authentication Failed Dont Try Authorization </xsl:message>
                        <xsl:message dp:type="aaa" dp:priority="warning">***FailedAuth, <xsl:value-of select="$OU"/>,<xsl:value-of select="$valcred"/></xsl:message>
                    </xsl:when>
                    <xsl:when test="$valdnResultLegnth &gt; 1 and $ControlValEnabled = 'OFF' ">
                        <xsl:element name="declined"/>
                        <xsl:variable name="ServiceName" select="dp:variable('var://context/ActiveMatrixESB/serviceName')"/>
                        <xsl:variable name="CounterName" select="concat('/monitor-count/', $ServiceName, 'AAAFailuresCnt')"/>
                        <dp:increment-integer name="$CounterName"/>
                        <xsl:message dp:priority="info">########Counter Name: <xsl:value-of select="$CounterName"/> ####### </xsl:message>
                        <xsl:message> #### NO MATCH TO VALCRED CONTROL FILE DISABLED </xsl:message>
                        <xsl:message dp:type="aaa" dp:priority="warning">***Denied by Valcred Only, <xsl:value-of select="$OU"/>,<xsl:value-of select="$valcred"/></xsl:message>
                    </xsl:when>
                     <xsl:when test="$valdnResultLegnth &gt; 1 and $ControlValEnabled = 'ON' and $MatchedControlVal = 'No Match'">
                        <xsl:element name="declined"/>
                        <xsl:variable name="ServiceName" select="dp:variable('var://context/ActiveMatrixESB/serviceName')"/>
                        <xsl:variable name="CounterName" select="concat('/monitor-count/', $ServiceName, 'AAAFailuresCnt')"/>
                        <dp:increment-integer name="$CounterName"/>
                        <xsl:message dp:priority="info">########Counter Name: <xsl:value-of select="$CounterName"/> ####### </xsl:message>
                        <xsl:message> #### NO MATCH TO VALCRED AND NO MATCH TO CONTROL FILE INFO </xsl:message>
                        <xsl:message dp:type="aaa" dp:priority="warning">***Denied By Both, <xsl:value-of select="$OU"/>,<xsl:value-of select="$valcred"/></xsl:message>
                    </xsl:when>

                    <!--Success Conditions-->
                     <xsl:when test="$valdnResultLegnth &lt; 1 and $ControlValEnabled = 'OFF'">
                        <xsl:element name="approved"/>
                         <xsl:message> ####Matched Valcred NO ControlFile Enabled </xsl:message>
                         <xsl:message dp:type="aaa" dp:priority="warning">***Access By Valcred, <xsl:value-of select="$OU"/>,<xsl:value-of select="$valcred"/></xsl:message>
                    </xsl:when>
                    <xsl:when test="$valdnResultLegnth &lt; 1 and $ControlValEnabled = 'ON' and $MatchedControlVal = 'Matched'">
                        <xsl:element name="approved"/>
                         <xsl:message> ####Matched Both Valcred and ControlFile </xsl:message>
                         <xsl:message dp:type="aaa" dp:priority="warning">***Access By Both, <xsl:value-of select="$OU"/>,<xsl:value-of select="$valcred"/></xsl:message>
                    </xsl:when>
                    <xsl:when test="$valdnResultLegnth &gt; 1 and $ControlValEnabled = 'ON' and $MatchedControlVal = 'Matched'">
                        <xsl:element name="approved"/>
                        <xsl:message> ####Matched Only ControlFile </xsl:message>
                        <xsl:message dp:type="aaa" dp:priority="warning">***Access By Control, <xsl:value-of select="$OU"/>,<xsl:value-of select="$valcred"/></xsl:message>
                    </xsl:when>
                    <xsl:otherwise><!--Any cert that is approved by the ValCred or Approved by Matching the Control File should be approved-->
                           <!--Only one match is necessary-->
                        <xsl:element name="approved"/>
                         <xsl:message> ####NOT SURE HOW YOU GOT HERE BUT WE WILL LET YOU IN ANYWAYS</xsl:message>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            
            <xsl:message>### authorization decision=<xsl:copy-of select="$result"/></xsl:message>
            
            <!-- Return the original credentials too. -->
            <xsl:copy-of select="$result"/> 
            
        </xsl:template>
    </xsl:stylesheet>
   