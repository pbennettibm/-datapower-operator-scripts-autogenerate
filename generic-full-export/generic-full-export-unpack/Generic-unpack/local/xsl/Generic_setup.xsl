<?xml version="1.0" encoding="UTF-8"?>
<!-- 

  This stylesheet examines the request message and sets up the "ActiveMatrixESB" context plus a number
  of "ActiveMatrixESB" context variables that control the processing of the request and response.
  
  The input context is expected to be INPUT and the output context is expected to be "ActiveMatrixESB".
  
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
  xmlns:local="urn:local:function" 
  xmlns:mgmt="http://www.datapower.com/schemas/management" 
  xmlns:regexp="http://exslt.org/regular-expressions" 
  xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" 
  xmlns:soap12="http://www.w3.org/2003/05/soap-envelope" 
  xmlns:str="http://exslt.org/strings" 
  xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
  extension-element-prefixes="date dp dyn exslt func regexp str" 
  exclude-result-prefixes="date dp dpconfig dpquery dyn exslt func regexp str">
  
  
  <xsl:include href="AuthType-Util-mpg.xsl"/>


  <xsl:variable name="controlFilesPrefix" select="'local:///control/'"/>
  <xsl:variable name="debugFilesPrefix" select="'local:///debug/'"/>

  <!--
    Load the service definitions file, which may not exist, or it may exist but relies on
    default values from the defaults.control.xml file.  We copy the guts of the service definition
    file followed by the guts of the defaults.control.xml file.  When the service definitions file
    defines something (e.g. <req-xform1>) then $control will have two copies of that element, one
    from the services definition file and one from the defaults.control.xml file.  The code will
    always use the *first* of these two elements.  When the services definition file doesn't
    contain an element but the defaults.control.xml file does, then that one will be used.
  -->
  <xsl:variable name="controlFilename" select="concat($controlFilesPrefix, translate(substring(dp:variable('var://service/URI'), 2), '/', '_'), '.xml')"/>
  <xsl:variable name="controlFile" select="document($controlFilename)"/>
  <xsl:variable name="control">
    <xsl:element name="control">
      
      <xsl:copy-of select="$controlFile/control/node()"/>
      
      <xsl:variable name="defaults" select="document(concat($controlFilesPrefix,'defaults.control.xml'))"/>

      
      <!-- Define defaults for the backend URI, port, and transport protocol based on the incoming values. -->
      <xsl:variable name="LocalPort" select="substring-after(dp:variable('var://service/local-service-address'), ':')"/>
      <xsl:element name="transportProtocol">
        <xsl:choose>
          <xsl:when test="$LocalPort = normalize-space($defaults/control/httpsPort)">
            <xsl:value-of select="'https://'"/>
          </xsl:when>
          <xsl:when test="$LocalPort = normalize-space($defaults/control/httpPort)">
            <xsl:value-of select="'http://'"/>
          </xsl:when>
        </xsl:choose>
      </xsl:element>
      
      <xsl:element name="backendURI">
        <xsl:value-of select="dp:variable('var://service/URI')"/>
      </xsl:element>
      
      <xsl:element name="backendPort">
        <xsl:value-of select="substring-after(dp:http-request-header('Host'), ':')"/>
      </xsl:element>
      
    <xsl:copy-of select="$defaults/control/node()"/>
      
    </xsl:element>
  </xsl:variable>
  
  <xsl:variable name="debugMe" select="local:ifTrue($control/control/debugMe)"/>
  
  <xsl:variable name="ctx" select="normalize-space($control/control/contextName)"/>
  




  <xsl:template match="/">

    <xsl:variable name="debugFilename" select="concat($debugFilesPrefix, translate(substring(dp:variable('var://service/URI'), 2), '/', '_'), '.xml')"/>
    <xsl:variable name="debugFile" select="document($debugFilename)"/>
    <xsl:variable name="trustedHostsFilename" select="concat($controlFilesPrefix, 'trustedHosts.xml')"/>
    <xsl:variable name="trustedHostsFile" select="document($trustedHostsFilename)"/>
    
    <xsl:variable name="serviceName" select="translate(substring(dp:variable('var://service/URI'), 2), '/', '_')"/>    
    <dp:set-variable name="concat($ctx, 'serviceName')" value="$serviceName"/>

    <xsl:if test="$debugMe">
      <xsl:message>control file (<xsl:value-of select="$controlFilename"/>): <xsl:copy-of select="$controlFile"/></xsl:message>
    </xsl:if>

    <xsl:if test="not($controlFile/control)">
      <dp:set-variable name="concat($ctx, 'serviceName')" value="'unknownService'"/>
    </xsl:if>

    <!-- Set up debug logging if necessary. -->
    <xsl:variable name="debug-xform1">
      <xsl:choose>
        <xsl:when test="$debugFile/debug">
          <xsl:value-of select="$control/debug-xform1[1]"/>
          <dp:set-variable name="concat($ctx, 'debug-var')" value="true()"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="'store:///identity.xsl'"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <dp:set-variable name="concat($ctx, 'debug-xform1')" value="$debug-xform1"/>
    
    <!-- Set up optional schema validation of the request and response. -->
    <xsl:if test="$control/control/validate">

      <!-- Validation is defined, so parse it out. -->
      <xsl:variable name="wsdl" select="normalize-space($control/control/validate[1])"/>
      <xsl:if test="local:isTrue($control/control/validate[1]/@request)">
        <dp:set-variable name="concat($ctx, 'request-validate')" value="$wsdl"/>
      </xsl:if>
      <xsl:if test="local:isTrue($control/control/validate[1]/@response)">
        <dp:set-variable name="concat($ctx, 'response-validate')" value="$wsdl"/>
      </xsl:if>
      <xsl:if test="local:isTrue($control/control/validate[1]/@fault)">
        <dp:set-variable name="concat($ctx, 'fault-validate')" value="$wsdl"/>
      </xsl:if>

    </xsl:if>

    <!-- Set up optional signing of the request and response. -->
    <xsl:if test="$control/control/sign">

      <!-- Signing is defined, so parse it out. -->
      <xsl:if test="local:isTrue($control/control/sign[1]/@request)">
        <dp:set-variable name="concat($ctx, 'request-sign')" value="'yes'"/>
      </xsl:if>
      <xsl:if test="local:isTrue($control/control/sign[1]/@response)">
        <dp:set-variable name="concat($ctx, 'response-sign')" value="'yes'"/>
      </xsl:if>
      
    </xsl:if>
    
    <!-- Set backend URL. -->
    <dp:set-variable name="'var://service/routing-url'" value="concat(normalize-space($control/control/transportProtocol[1]), normalize-space($control/control/backendHost[1]), ':', normalize-space($control/control/backendPort[1]), normalize-space($control/control/backendURI[1]))"/>
        
    <!-- Set up the various transforms, using a default stylesheet when necessary. -->
    <dp:set-variable name="concat($ctx, 'req-xform1')" value="local:whichXsl('req-xform1')"/>
    
    <dp:set-variable name="concat($ctx, 'req-log-xform1')" value="local:whichXsl('req-log-xform1')"/>
    <xsl:message>##### <xsl:value-of select="dp:variable(concat($ctx, 'req-log-xform1'))"/>  </xsl:message> 
    
    <dp:set-variable name="concat($ctx, 'req-log-xform2')" value="local:whichXsl('req-log-xform2')"/>
    <xsl:message>##### <xsl:value-of select="dp:variable(concat($ctx, 'req-log-xform2'))"/>  </xsl:message> 
    
    <dp:set-variable name="concat($ctx, 'resp-log-xform1')" value="local:whichXsl('resp-log-xform1')"/>
    <xsl:message>##### <xsl:value-of select="dp:variable(concat($ctx, 'resp-log-xform1'))"/>  </xsl:message> 
    
    <dp:set-variable name="concat($ctx, 'soap-log-xform1')" value="local:whichXsl('soap-log-xform1')"/>
    <xsl:message>##### <xsl:value-of select="dp:variable(concat($ctx, 'soap-log-xform1'))"/>  </xsl:message> 
    
    <dp:set-variable name="concat($ctx, 'err-log-xform1')" value="local:whichXsl('err-log-xform1')"/>
    <xsl:message>##### <xsl:value-of select="dp:variable(concat($ctx, 'err-log-xform1'))"/>  </xsl:message> 
    
    <dp:set-variable name="concat($ctx, 'fault-log-xform1')" value="local:whichXsl('fault-log-xform1')"/>
    <xsl:message>##### <xsl:value-of select="dp:variable(concat($ctx, 'fault-log-xform1'))"/>  </xsl:message> 
    
    <dp:set-variable name="concat($ctx, 'req-stat-xform1')" value="local:whichXsl('req-stat-xform1')"/>
    
    <dp:set-variable name="concat($ctx, 'fault-stat-xform1')" value="local:whichXsl('fault-stat-xform1')"/>
    
    <dp:set-variable name="concat($ctx, 'soap-stat-xform1')" value="local:whichXsl('soap-stat-xform1')"/>
    
    <dp:set-variable name="concat($ctx, 'resp-stat-xform1')" value="local:whichXsl('resp-stat-xform1')"/>
    
    <dp:set-variable name="concat($ctx, 'err-stat-xform1')" value="local:whichXsl('err-stat-xform1')"/>    
    
    <dp:set-variable name="concat($ctx, 'req-soap-action-xform1')" value="local:whichXsl('req-soap-action-xform1')"/>
    
    <dp:set-variable name="concat($ctx, 'req-after-aaa-xform1')" value="local:whichXsl('req-after-aaa-xform1')"/>
    
    <dp:set-variable name="concat($ctx, 'soap-xform1')" value="local:whichXsl('soap-xform1')"/>
    
    <dp:set-variable name="concat($ctx, 'resp-xform1')" value="local:whichXsl('resp-xform1')"/>

    <dp:set-variable name="concat($ctx, 'fault-xform1')" value="local:whichXsl('fault-xform1')"/>

    <dp:set-variable name="concat($ctx, 'err-xform1')" value="local:whichXsl('err-xform1')"/>
    
    <dp:set-variable name="concat($ctx, 'resp-xform2')" value="local:whichXsl('resp-xform2')"/>


    <!-- Extract the operation. -->
    <xsl:variable name="rawoperation">
      <xsl:choose>
        <xsl:when test="dp:request-header('SOAPAction')">
          <xsl:value-of select="dp:request-header('SOAPAction')"/>
        </xsl:when>
        <xsl:when test="/soap:Envelope/soap:Body">
          <xsl:value-of select="local-name(/soap:Envelope/soap:Body/*[1])"/>
        </xsl:when>
        <xsl:when test="/soap12:Envelope/soap12:Body">
          <xsl:value-of select="local-name(/soap12:Envelope/soap12:Body/*[1])"/>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>
    <xsl:message>#### RawOperation: <xsl:value-of select="$rawoperation"/></xsl:message>
    <xsl:variable name="operation" select="translate($rawoperation, '&quot;', '')"/>
    <dp:set-variable name="concat($ctx, 'operation')" value="$operation"/>
    <xsl:message>#### Operation: <xsl:value-of select="$operation"/></xsl:message>
    
    <!-- Find the most appropriate <aaa> element in the control file, if any. -->
    <xsl:variable name="aaa">
      
      <!-- Find the first <aaa> element for this operation, or for all operations ('*'). -->
      <xsl:choose>
        <xsl:when test="$control/control/aaa/operation[normalize-space(.) = $operation]">
          <xsl:copy-of select="$control/control/aaa[operation[string() = $operation]][1]"/>
          <xsl:message>####Value of the control in when : <xsl:value-of select="$control/control/aaa[operation[string() = $operation]][1]"/> </xsl:message>
        </xsl:when>
        <xsl:otherwise>
          <xsl:copy-of select="$control/control/aaa[operation[string() = '*']][1]"/>
          <xsl:message>####Value of the control in otherwise : <xsl:value-of select="$control/control/aaa[operation[string() = '*']][1]"/> </xsl:message>
        </xsl:otherwise>
      </xsl:choose>
      
    </xsl:variable>

    <!-- Extract the SM_SESSION header, stripping quotes and whitespace. -->
    <xsl:variable name="sm_session" select="normalize-space(translate(dp:request-header('SM_SESSION'), '&quot;',''))"/>
    
    <!-- 
      It isn't clear how the presence of an SM_SESSION header interacts with AU/AZ decisions.
      For the moment, I'm ignoring it, but we need to revisit this and settle it.
    -->
    
    <xsl:variable name="clientIP">
      <xsl:choose>
        <xsl:when test="dp:request-header('X-Forwarded-For') !=''">
          <xsl:value-of select="dp:request-header('X-Forwarded-For')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="dp:client-ip-addr()"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <dp:set-variable name="concat($ctx, 'clientIP')" value="$clientIP"/>        
    <xsl:message>### client IP <xsl:value-of select="$clientIP"/></xsl:message>
    
    <!--
      Decide whether to do Basic-Auth-or-UNT-Authentication or X509-Authentication followed by
      custom-Authohrization, or whether to do nothing.  This is driven by the <aaa> element
      selected in the preceding code.
    -->
    <xsl:variable name="aaa_type">
      <xsl:choose>



        <xsl:when test="$trustedHostsFile/trusted/host[@ip = $clientIP and not(disallowedOperation[normalize-space() = $operation])]">
          
          <!-- 
            This request originates from a "trusted host" so skip AAA regardless of whether credentials 
            are supplied or not, and regardless of whether a <aaa> element specifies certain roles or
            valcred for this operation.
          -->
          <xsl:value-of select="'aaaSkip'"/>
          <xsl:message>#### Partner Call </xsl:message>
          <dp:set-variable name="concat($ctx, 'partner-call')" value="'yes'"/>
          
        </xsl:when>
        <xsl:when test="$trustedHostsFile/trusted/host[@ip = $clientIP and (disallowedOperation[normalize-space() = $operation])]">
          
          <!-- 
            This request originates from a "trusted host" but operation is denied so reject it
          -->
          <xsl:value-of select="'aaaReject'"/>
          
        </xsl:when>
        <xsl:when test="$aaa/aaa/role and $aaa/aaa/@valcred">
          
          <!-- 
            The <aaa> element specifies both roles and a valcred, so the client is free to specify either
            a Basic Auth header, a UsernameToken, or a BinarySecurityToken containing an X509 certificate.
            Decide which is present and use that.
          -->
          <xsl:choose>
            <xsl:when test="(/*[local-name()='Envelope']/*[local-name()='Header']/wsse:Security/wsse:BinarySecurityToken[@ValueType='http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-x509-token-profile-1.0#X509v3']) 
      or (/*[local-name()='Envelope']/*[local-name()='Header']/wsse:Security/*[local-name()='Signature']/*[local-name()='KeyInfo']/wsse:SecurityTokenReference/wsse:KeyIdentifier[@ValueType='http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-x509-token-profile-1.0#X509SubjectKeyIdentifier'])">
              <xsl:value-of select="'aaaX509'"/>
            </xsl:when>
            <xsl:when test="/soap:Envelope/soap:Header/wsse:Security/wsse:UsernameToken">
              <xsl:value-of select="'aaaUserid'"/>
            </xsl:when>
            <xsl:when test="/soap12:Envelope/soap12:Header/wsse:Security/wsse:UsernameToken">
              <xsl:value-of select="'aaaUserid'"/>
            </xsl:when>
            <xsl:when test="dp:request-header('Authorization') != ''">
              <xsl:value-of select="'aaaUserid'"/>
            </xsl:when>
            <xsl:otherwise>
              <!-- The <aaa> element requires either a userid (Basic Auth or UNT) or an X509 cert, but none are present. -->
              <xsl:value-of select="'aaaReject'"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        
        <xsl:when test="$aaa/aaa/role">
          
          <xsl:value-of select="'aaaUserid'"/> <!-- Roles are based on userids -->
          
        </xsl:when>
        <xsl:when test="$aaa/aaa/@valcred">
          
          <xsl:value-of select="'aaaX509'"/> <!-- X509 certs are judged against a valcred -->
          
        </xsl:when>
        <xsl:when test="$aaa/aaa/@open[string() = 'true' or string() = 'TRUE' or string() = 'yes' or string() = 'YES' or string() = 'on' or string() = 'ON']">
          
          <xsl:value-of select="'aaaSkip'"/> <!-- This operation is open to all without AU or AZ. -->
          
        </xsl:when>
        <xsl:otherwise>
          
          <!-- By default, all operations are prohibited. -->
          <!-- <xsl:value-of select="'aaaReject'"/> -->
          
          <!-- By default, all operations are open. -->
          <xsl:value-of select="normalize-space($control/control/defaultAAA)"/>
          
        </xsl:otherwise>
        
      </xsl:choose>
    </xsl:variable>
    
    <!-- Possible values are : aaaSkip, aaaReject, aaaUserid, and aaaX509 -->    
    <dp:set-variable name="concat($ctx, 'aaa_type')" value="$aaa_type"/>
    <dp:set-variable name="concat($ctx, 'aaa')" value="$aaa"/>
    
    <!-- Capture credentials, since these are used in a number of places. -->
    <xsl:variable name="DN" select="local:getIdDN(.)"/>
    <xsl:variable name="CN" select="local:CNfromDN($DN)"/>
    <xsl:variable name="OU" select="local:OUfromDN($DN)"/>
    <xsl:variable name="uid">
      <xsl:choose>
        <xsl:when test="local:isIdBasicAuth()">
          <xsl:value-of select="local:getIdBasicAuth()"/>
        </xsl:when>
        <xsl:when test="local:isIdUsernameToken(.)">
          <xsl:value-of select="local:getIdUNT(.)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="''"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <dp:set-variable name="'var://context/creds/DN'" value="$DN"/>
    <dp:set-variable name="'var://context/creds/CN'" value="$CN"/>
    <dp:set-variable name="'var://context/creds/OU'" value="$OU"/>
    <dp:set-variable name="'var://context/creds/uid'" value="$uid"/>
    
    <!-- If data hiding is indicated, record that information for use by the stylesheet. -->
    <xsl:variable name="dataHiding">
      <xsl:copy-of select="$control/control/dataHiding[1]"/>
    </xsl:variable>
    <dp:set-variable name="concat($ctx, 'dataHiding')" value="$dataHiding"/>
    

    <!-- Generate the control structure for the Condition actions. -->
    <xsl:element name="control">

      <xsl:if test="dp:variable(concat($ctx, 'request-validate'))">
        <xsl:element name="request-validate">
          <xsl:value-of select="dp:variable(concat($ctx, 'request-validate'))"/>
        </xsl:element>
      </xsl:if>

      <xsl:if test="dp:variable(concat($ctx, 'response-validate'))">
        <xsl:element name="response-validate">
          <xsl:value-of select="dp:variable(concat($ctx, 'response-validate'))"/>
        </xsl:element>
      </xsl:if>

      <xsl:if test="dp:variable(concat($ctx, 'request-sign'))">
        <xsl:element name="request-sign">
          <xsl:value-of select="dp:variable(concat($ctx, 'request-sign'))"/>
        </xsl:element>
      </xsl:if>

      <xsl:if test="dp:variable(concat($ctx, 'response-sign'))">
        <xsl:element name="response-sign">
          <xsl:value-of select="dp:variable(concat($ctx, 'response-sign'))"/>
        </xsl:element>
      </xsl:if>
      
      <xsl:if test="dp:variable(concat($ctx, 'fault-validate'))">
        <xsl:element name="fault-validate">
          <xsl:value-of select="dp:variable(concat($ctx, 'fault-validate'))"/>
        </xsl:element>
      </xsl:if>

      <xsl:if test="dp:variable(concat($ctx, 'aaa_type'))">
        <xsl:element name="aaa_type">
          <xsl:value-of select="dp:variable(concat($ctx, 'aaa_type'))"/>
        </xsl:element>
      </xsl:if>

    </xsl:element>

  </xsl:template>
  
  
  <!-- 
    Return true() when the value is yes, true, on, or 1 (case insensitive).
  -->
  <func:function name="local:isTrue">
    <xsl:param name="value"/>
    <xsl:variable name="valueLC" select="translate(normalize-space($value), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')"/>
    <func:result select="$valueLC = 'yes' or $valueLC = 'true' or $valueLC = 'on' or $valueLC = '1'"/>
  </func:function>
  
  
  <!-- 
    Return the filename of a stylesheet based on the control element, or store:///identity.xsl
  -->
  <func:function name="local:whichXsl">
    <xsl:param name="elementName"/> <!-- e.g. 'req-xform1' -->
    <func:result>
      <xsl:choose>
        <xsl:when test="$control/control/*[name() = $elementName]">
          <xsl:value-of select="normalize-space($control/control/*[name() = $elementName][1])"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="'store:///Q.xsl'"/>
        </xsl:otherwise>
      </xsl:choose>
    </func:result>
  </func:function>
  
</xsl:stylesheet>