<?xml version="1.0"?>
<!--
Author: T. V. Raman <raman@cs.cornell.edu>
Copyright: (C) T. V. Raman, 2001 - 2002,   All Rights Reserved.
License: GPL
Extract content that has a specified class attribute.
Param class specifies the class to extract.

-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:output method="html" indent="yes" encoding="iso8859-1"/>
  <xsl:param name="class"/>
  <xsl:param name="base"/>
  <xsl:include href="identity.xsl"/>
<!-- { html body  -->
<!--add base uri if available. -->
  <xsl:template match="/html/head">
    <head>
      <xsl:element name="base">
        <xsl:attribute name="href">
          <xsl:value-of select="$base"/>
        </xsl:attribute>
      </xsl:element>
      <xsl:apply-templates/>
    </head>
  </xsl:template>
<!-- nuke these -->
  <xsl:template match="//script|//meta"/>
  <xsl:template match="/html/body">
    <xsl:element name="body">
      <xsl:apply-templates select="@*"/>
      <xsl:for-each select="//*[@class=$class]">
<!--
        <p>
          <xsl:value-of select="name(.)"/>
        </p>
-->
        <xsl:apply-templates/>
        <br/>
      </xsl:for-each>
      <h2>About This Document</h2>
      <p> Found <xsl:value-of select="count(//*[@class=$class])"/>
        nodes with <code>class</code> 
<em><xsl:value-of select="$class"/></em> in
<xsl:element name="a"><xsl:attribute name="href"><xsl:value-of select="$base"/></xsl:attribute>
source document</xsl:element>
    </p>
    </xsl:element>
  </xsl:template>
<!-- } -->
</xsl:stylesheet>
<!--
Local Variables:
mode: xae
sgml-indent-step: 2
sgml-indent-data: t
sgml-set-face: nil
sgml-insert-missing-element-comment: nil
folded-file: t
End:
-->
