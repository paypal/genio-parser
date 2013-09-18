<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
	xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:wadl="http://wadl.dev.java.net/2009/02" exclude-result-prefixes="wadl xs">
	<xsl:template match="wadl:application">
		<packages>
			<xsl:apply-templates
				select="//*[local-name()='schema' and namespace-uri()='http://www.w3.org/2001/XMLSchema']" />
		</packages>
		<xsl:apply-templates select="wadl:resources" />
	</xsl:template>

	<xsl:template match="*[local-name()='element']">
		<element name="{@name | ../@name}" type="@type" package="../@targetNamespace"></element>
	</xsl:template>

	<xsl:template match="wadl:resources">
    <resources base="{@base}">
			<xsl:apply-templates select="//wadl:resource" />
		</resources>
	</xsl:template>

	<xsl:template match="wadl:resource">
		<xsl:variable name="path">
			<xsl:for-each select="ancestor-or-self::wadl:resource">
				<xsl:value-of select="@path" />
			</xsl:for-each>
		</xsl:variable>

		<resource path="{$path}">
			<xsl:copy-of select="wadl:doc" />
			<!-- TODO: Inherit matrix and template params from parent resources -->
			<xsl:copy-of select="wadl:param" />
			<xsl:copy-of select="wadl:method" />
		</resource>
	</xsl:template>

	<!-- matching schema tag -->
	<xsl:template match="//*[local-name()='schema']">
		<!-- for namespaces -->
		<package tns="{@targetNamespace}">
			<namespaces>
				<xsl:for-each select="namespace::*">
					<namespace name="{name()}">
						<xsl:value-of select='.' />
					</namespace>
				</xsl:for-each>
			</namespaces>
			<!-- for classes(requests and responses) -->
			<elements>
				<xsl:apply-templates select="./*[local-name()='element']" />
			</elements>
			<classes>
				<xsl:apply-templates
					select=".//*[local-name()='complexType' and not(starts-with(@name, 'ArrayOf_'))]" />
			</classes>
		</package>
	</xsl:template>
	<!-- matching simpletype tag(enum and simple values) -->
	<xsl:template match="*[local-name()='simpleType']">
		<xsl:choose>
			<!-- for enums -->
			<xsl:when
				test=".//*[local-name()='restriction'] and .//*[local-name()='enumeration'] ">
				<enum name="{@name}" package="{@type | ../@targetNamespace}">
					<documentation>
						<xsl:value-of select=".//*[local-name()='documentation']" />
					</documentation>
					<xsl:for-each select=".//*[local-name()='enumeration']">
						<value>
							<xsl:value-of select='@value' />
						</value>
					</xsl:for-each>
				</enum>
			</xsl:when>
			<!-- for simple values -->
			<xsl:otherwise>
				<xsl:variable name="base"
					select=".//*[local-name()='restriction']/@base" />
				<element name="{@name}" package="{$base}"
					type="{substring-after($base,':')}" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- matching element tag -->
	<xsl:template match="*[local-name()='element']">
		<element name="{@name | ../@name}" type="{@type}" package="{../@targetNamespace}"/>
	</xsl:template>

	<!-- matching complextype tag -->
	<xsl:template match="*[local-name()='complexType']">
		<class name="{@name | ../@name}" package="{@type | ../@targetNamespace}">
			<!-- for annotation tag -->
			<xsl:if test=".//*[local-name()='annotation'] ">
				<documentation>
					<xsl:value-of select="./*[local-name()='annotation']" />
				</documentation>
			</xsl:if>
			<!-- for simpleContent tag with extension -->
			<xsl:if
				test="./*[local-name()='simpleContent'] and .//*[local-name()='extension']">
				<properties>

					<xsl:variable name="attrib" select=".//*[local-name()='attribute']" />
					<xsl:choose>
						<xsl:when test="substring-before($attrib/@type,':')='xs'">
							<property name="{$attrib/@name}" type="{substring-after($attrib/@type,':')}"
								min="1" simpletype="1" attrib="1" />
						</xsl:when>
						<xsl:otherwise>
							<property name="{$attrib/@name}" type="{$attrib/@type}"
								min="1" simpletype="0" package="{substring-before($attrib/@type,':')}"
								attrib="1" />
						</xsl:otherwise>
					</xsl:choose>
					<!-- with base -->
					<xsl:variable name="base"
						select=".//*[local-name()='extension']/@base" />
					<property name="value" type="{substring-after($base,':')}"
						min="1" simpletype="1" value="1" />
				</properties>
			</xsl:if>
			<!-- tag with extension -->
			<xsl:if test=".//*[local-name()='extension']">
				<xsl:if
					test="substring-before(.//*[local-name()='extension']/@base,':')!='xs'">
					<extends
						name="{substring-after(.//*[local-name()='extension']/@base,':')}"
						package="{substring-before(.//*[local-name()='extension']/@base,':')}" />

				</xsl:if>
			</xsl:if>
			<!-- for element tag -->
			<xsl:if test=".//*[local-name()='element']">
				<properties>
					<xsl:for-each select=".//*[local-name()='element']">
						<xsl:variable name="doc"
							select=".//*[local-name()='documentation']" />
						<xsl:choose>
							<xsl:when test="substring-before(@type,':')='xs'">
								<property name="{@name}" type="{substring-after(@type,':')}"
									min="{@minOccurs}" max="{@maxOccurs}" documentation="{$doc}"
									simpletype="1" />
							</xsl:when>
							<xsl:when
								test="//*[local-name()='complexType' and @name=substring-after(current()/@type,':')] //*[@ref='soapenc:arrayType']">
								<xsl:variable name="type"
									select="//*[local-name()='complexType' and @name=substring-after(current()/@type,':')] //*[@ref='soapenc:arrayType']/@*[local-name()='wsdl:arrayType']" />
								<property name="{@name}" type="{$type}"
									package="{substring-before($type,':')}" min="{@minOccurs}" max="{@maxOccurs}"
									documentation="{$doc}" simpletype="0" />
							</xsl:when>
							<!-- tag contains ref not type -->
							<xsl:when test="not(@type) and @ref">
								<xsl:choose>
									<xsl:when test="@name">
										<property name="{@name}" package="{substring-before(@ref,':')}"
											min="{@minOccurs}" max="{@maxOccurs}" documentation="{$doc}"
											simpletype="0" />
									</xsl:when>
									<xsl:otherwise>
										<property name="{substring-after(@ref, ':')}" min="{@minOccurs}"
											max="{@maxOccurs}" documentation="{$doc}"
											package="{substring-before(@ref,':')}" simpletype="0" ref="{@ref}"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:when>
							<xsl:otherwise>
								<property name="{@name}" type="{substring-after(@type, ':')}"
									simpletype="0" min="{@minOccurs}" max="{@maxOccurs}"
									package="{substring-before(@type,':')}" documentation="{$doc}" />
							</xsl:otherwise>
						</xsl:choose>
					</xsl:for-each>
				</properties>
			</xsl:if>
		</class>
	</xsl:template>
</xsl:stylesheet>
