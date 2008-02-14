<?xml version="1.0"?>
<!-- 
Text Encoding Initiative Consortium XSLT stylesheet family
$Date: 2006-04-26 19:30:23 +0100 (Wed, 26 Apr 2006) $, $Revision$, $Author: rahtz $

XSL stylesheet to process TEI documents using ODD markup

 
##LICENSE
-->
<!-- $Id: nomorechoice.xsl 1472 2006-04-26 18:30:23Z rahtz $ -->
<xsl:transform version="1.0" xmlns="http://relaxng.org/ns/structure/1.0"
  xmlns:exsl="http://exslt.org/common" xmlns:rng="http://relaxng.org/ns/structure/1.0"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:key match="rng:define[@combine='choice']" name="Choices" use="@name"/>
  <xsl:key match="rng:define" name="Defs" use="@name"/>
  <xsl:template match="rng:define">
    <xsl:choose>
      <xsl:when test="key('Choices',@name)">
        <xsl:comment>Killed <xsl:value-of select="@name"/> here</xsl:comment>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy>
          <xsl:apply-templates select="*|@*|text()|comment()"/>
        </xsl:copy>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="rng:define[@combine='choice']">
    <xsl:if test="generate-id(.)=generate-id(key('Choices',@name)[1])">
      <xsl:variable name="what">
        <xsl:value-of select="@name"/>
      </xsl:variable>
      <xsl:variable name="defs">
        <rng:div>
          <xsl:for-each select="key('Choices',@name)">
            <xsl:apply-templates/>
          </xsl:for-each>
        </rng:div>
      </xsl:variable>
      <xsl:for-each select="exsl:node-set($defs)/rng:div">
        <define name="{$what}">
          <xsl:choose>
            <xsl:when test="count(rng:*)=1 and (rng:empty or rng:notAllowed)">
              <xsl:copy-of select="*"/>
            </xsl:when>
            <xsl:when test="contains($what,'attributes')">
              <xsl:copy-of select="*"/>
            </xsl:when>
            <xsl:otherwise>
              <rng:choice>
                <xsl:for-each select="*">
                  <xsl:if test="not(self::rng:notAllowed)">
                    <xsl:copy-of select="."/>
                  </xsl:if>
                </xsl:for-each>
              </rng:choice>
            </xsl:otherwise>
          </xsl:choose>
        </define>
      </xsl:for-each>
    </xsl:if>
  </xsl:template>
  <xsl:template match="*|@*|text()|comment()">
    <xsl:copy>
      <xsl:apply-templates select="*|@*|text()|comment()"/>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="rng:optional[rng:choice/rng:attribute]">
    <xsl:for-each select="rng:choice/rng:attribute">
      <rng:optional>
        <xsl:copy-of select="."/>
      </rng:optional>
    </xsl:for-each>
  </xsl:template>
  <xsl:template match="rng:data[@type='token']">
    <rng:text/>
  </xsl:template>
</xsl:transform>
