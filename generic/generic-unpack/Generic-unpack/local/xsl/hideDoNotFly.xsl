<?xml version="1.0" encoding="UTF-8"?>
<!-- 

  This stylesheet ...

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
  extension-element-prefixes="date dp dyn exslt func regexp str" 
  exclude-result-prefixes="date dp dpconfig dpquery dyn exslt func regexp str">

  <xsl:template match="/">
    
    <!-- Copy SOAP Faults straight thru. -->
    <xsl:choose>
      <xsl:when test="/*[local-name() = 'Envelope']/*[local-name() = 'Body']/*[local-name() = 'Fault']">
        
        <xsl:copy-of select="."/>
        
      </xsl:when>
      <xsl:otherwise>
        
        <!-- See whether this requester is permitted to see the Do Not Fly information. -->
        <xsl:choose>
          <xsl:when test="local:isPermitted()">
            
            <!-- Permitted, so just copy the message through. -->
            <xsl:copy-of select="."/>
            
          </xsl:when>
          <xsl:otherwise>
            
            <!-- Copy the message, hiding the important bits. -->
            <xsl:apply-templates select="." mode="hideStuff"/>
            
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="/" mode="hideStuff">
    <xsl:copy>
      <xsl:apply-templates select="node()" mode="hideStuff"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="*" mode="hideStuff">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" mode="hideStuff"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="@DoNotBoardPsngrInd | @PsngrSecurityPfmdInd | @PsngrSecurityRqdInd" mode="hideStuff">
    <xsl:attribute name="{name()}">
      <xsl:value-of select="'***'"/>
    </xsl:attribute>
  </xsl:template>
  
  <xsl:template match="@* | text() | comment() | processing-instruction()" mode="hideStuff">
    <xsl:copy-of select="."/>
  </xsl:template>
  
  
  <!-- 
    
  -->
  <func:function name="local:isPermitted">
    
    <xsl:variable name="dataHiding" select="dp:variable('var://context/ActiveMatrixESB/dataHiding')"/>
    
    <xsl:choose>
      <xsl:when test="dp:variable('var://context/creds/uid') != ''">
        
        <!-- Decide based on the userid, which implies LDAP roles. -->
        <xsl:variable name="ldapResults" select="dp:variable('var://context/ldap/search-results')"/>
        <xsl:choose>
          <xsl:when test="local:anyRolesInCommon($ldapResults, $dataHiding)">
            <xsl:message>### local:isPermitted : true : ldapResults=<xsl:copy-of select="$ldapResults"/>, dataHiding=<xsl:copy-of select="$dataHiding"/></xsl:message>
            <func:result select="true()"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:message>### local:isPermitted : false : ldapResults=<xsl:copy-of select="$ldapResults"/>, dataHiding=<xsl:copy-of select="$dataHiding"/></xsl:message>
            <func:result select="false()"/>
          </xsl:otherwise>
        </xsl:choose>
        
      </xsl:when>
      <xsl:otherwise>

        <!-- Decide based on the OU in the X509 cert. -->
        <xsl:variable name="OU" select="dp:variable('var://context/creds/OU')"/>
        <xsl:choose>
          <xsl:when test="$dataHiding/dataHiding/OU[string() = $OU]">
            <xsl:message>### local:isPermitted : true : OU=<xsl:value-of select="$OU"/>, dataHiding=<xsl:copy-of select="$dataHiding"/></xsl:message>
            <func:result select="true()"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:message>### local:isPermitted : false : OU=<xsl:value-of select="$OU"/>, dataHiding=<xsl:copy-of select="$dataHiding"/></xsl:message>
            <func:result select="false()"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
    
    <func:result>
      
    </func:result>
  </func:function>
  
  <!-- 
    Test whether there are any roles common to both the ldap search results and the
    data hiding structure.  Here are examples of both:
    <LDAP-search-results>
      <result>
        <DN>CN=svcdpw,OU=svcacct,DC=delta,DC=rl,DC=delta,DC=com</DN>
        <attribute-value name="memberOf">CN=SVC_Accounts,OU=Campus,OU=Delta,OU=Groups,DC=delta,DC=rl,DC=delta,DC=com</attribute-value>
        <attribute-value name="memberOf">CN=DenyLocalLogon,OU=DT,OU=Groups,DC=delta,DC=rl,DC=delta,DC=com</attribute-value>
      </result>
    </LDAP-search-results>
    and
    <dataHiding>
      <role>Security</role>
      <role>...</role>
    </dataHiding>
    
    Look for each <role> in the <dataHiding> as an OU=role in the memberOf DN.
  -->
  <func:function name="local:anyRolesInCommon">
    <xsl:param name="ldapResults"/>
    <xsl:param name="dataHiding"/>
    <xsl:variable name="dots">
      
      <xsl:for-each select="$dataHiding/dataHiding/role">

        <xsl:variable name="ouRole" select="concat(., ',')"/>
        <xsl:for-each select="$ldapResults/LDAP-search-results/result/attribute-value[@name = 'memberOf']">
        
          <xsl:variable name="dn" select="concat(., ',')"/>
          <xsl:if test="contains($dn, $ouRole)">
            <xsl:value-of select="."/>  <!-- Record a dot to indicate that a role was found in common between the two set of information. -->
          </xsl:if>
          
        </xsl:for-each>
        
      </xsl:for-each>
      
    </xsl:variable>
    <xsl:message>### local:anyRolesInCommon : <xsl:value-of select="$dots != ''"/> : ldap=<xsl:copy-of select="$ldapResults"/>, dataHiding=<xsl:copy-of select="$dataHiding"/></xsl:message>
    <func:result select="$dots != ''"/>
  </func:function>
  
</xsl:stylesheet>