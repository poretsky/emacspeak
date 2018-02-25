<?xml version="1.0"?>
<!--
Author: T. V. Raman <raman@cs.cornell.edu>
Copyright: (C) T. V. Raman, 2001 - 2002,   All Rights Reserved.
License: GPL
View OPML feeds as XHTML
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="1.0">
  <xsl:output encoding="UTF-8" method="xml" indent="yes"/>
  <xsl:template match="/opml">
    <html>
      <xsl:apply-templates/>
    </html>
  </xsl:template>
  <xsl:template match="head">
    <h1>
    <xsl:value-of select="title"/> </h1>
    <xsl:if test="dateModified">
      <h2>Date Modified: <xsl:copy-of
      select="dateModified"/></h2>
    </xsl:if>
  </xsl:template>
  <xsl:template match="body">
    <body>
      
      <ol>
        <xsl:apply-templates select=".//outline"/>
      </ol>
    </body>
  </xsl:template>
  <xsl:template match="outline">

    <xsl:if test="@xmlUrl|@xmlurl|@URL">
      <li><xsl:element name="a">
        <xsl:attribute name="href">
          <xsl:value-of select="@xmlUrl|@xmlurl|@URL"/>
        </xsl:attribute>
        <xsl:value-of select="@title|@text"/>
        <xsl:if test="@type">
(<xsl:value-of select="@type"/>)
        </xsl:if>
      </xsl:element>
      <xsl:value-of select="@description|@subtext"/>
      </li>
    </xsl:if>


  </xsl:template>
  
</xsl:stylesheet>
<!--

Local Variables:
folded-file: t
End:
-->
