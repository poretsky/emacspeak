<?xml version="1.0"?>
<!--
Author: T. V. Raman <raman@cs.cornell.edu>
Copyright: (C) T. V. Raman, 2001 - 2002,   All Rights Reserved.
License: GPL
View an Atom feed as clean HTML
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:atom="http://purl.org/atom/ns#"
                xmlns:w3a="http://www.w3.org/2005/Atom"
                xmlns:xhtml="http://www.w3.org/1999/xhtml"
                xmlns:gr="http://www.google.com/schemas/reader/atom/"
                version="1.0">
  <xsl:output encoding="iso8859-15" method="html" indent="yes"/>
  
  <xsl:template match="atom:feed|w3a:feed">
    <html>
      <head>
        <title>
          <xsl:apply-templates select="atom:title|w3a:title"/>
          
        </title>
      </head>
      <body>
        <h1><xsl:value-of select="atom:title|w3a:title"
        disable-output-escaping="yes"/>
        <xsl:apply-templates
            select="atom:link[@rel='self']|w3a:link[@rel='self']"/>
        <xsl:apply-templates
            select="atom:link[@rel='service.post']|w3a:link[@rel='service.post']"/>
        </h1>
        <h2>Table Of Contents</h2>
        <ol>
          <xsl:apply-templates select="atom:entry|w3a:entry" mode="toc"/>
        </ol>
        <xsl:apply-templates select="atom:entry|w3a:entry"/>
        <h2>
          <xsl:apply-templates select="atom:link[@rel='alternate']|w3a:link[@rel='alternate']"/>
        </h2>
        <p>
          <xsl:apply-templates select="atom:tagline|w3a:tagline"/>
          <xsl:apply-templates select="atom:author|w3a:author"/>
        </p>
      </body>
    </html>
  </xsl:template>
  
  <xsl:template match="atom:entry|w3a:entry">
    <h2>
      <a>
        <xsl:attribute name="name">
          <xsl:value-of select="generate-id(.)"/> 
        </xsl:attribute>
        <xsl:attribute name="id"> <xsl:value-of select="generate-id(.)"/>
        </xsl:attribute>
        <xsl:apply-templates select="atom:title|w3a:title"/>
      </a>
      <xsl:apply-templates
          select="atom:link[@rel='service.edit']|w3a:link[@rel='service.edit']"/>
    </h2>
    <xsl:apply-templates select="atom:summary|atom:content|w3a:content|w3a:summary"/>
    <p>
      <xsl:apply-templates
      select="atom:link[@rel='alternate']|w3a:link[@rel='alternate']"/>
      <em><xsl:value-of  select="atom:author/atom:name"
      disable-output-escaping="yes"/>
        <xsl:text> at </xsl:text>
      <xsl:value-of select="atom:issued|w3a:issued"/></em>
    </p>
  </xsl:template>
  <xsl:template match="atom:entry|w3a:entry" mode="toc">
    <li>
      <a>
        <xsl:attribute name="href">
          #<xsl:value-of select="generate-id(.)"/> 
        </xsl:attribute>
        <xsl:value-of select="atom:title|w3a:title"
                      disable-output-escaping="yes"/>
      </a>
    </li>
  </xsl:template>
  <xsl:template
      match="atom:content|atom:summary|w3a:content|w3a:summary">
    <xsl:choose>
      <xsl:when test="@type='application/xhtml+xml'">
    <xsl:copy-of select="node()"/>
      </xsl:when>
<xsl:when test="@type='html' or @type='text/html'">
<xsl:value-of disable-output-escaping="yes"
    select="node()"/>
</xsl:when>
<!-- for legacy atom 0.3-->
<xsl:when test="@mode='escaped'">
<xsl:value-of disable-output-escaping="yes"
    select="node()"/>
</xsl:when>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="xhtml:div">
    <xsl:copy/>
  </xsl:template>
  <xsl:template match="atom:link|w3a:link">
    <a>
      <xsl:attribute name="href">
        <xsl:value-of
            select="@href"/>
      </xsl:attribute>
      <xsl:choose>
        <xsl:when test="@rel='service.edit'">[Edit]</xsl:when>
        <xsl:when test="@rel='service.post'">[Post]</xsl:when>
        <xsl:otherwise>
          Bookmark:
        </xsl:otherwise>
      </xsl:choose>
    </a>
  </xsl:template>
  
  
  
</xsl:stylesheet>
