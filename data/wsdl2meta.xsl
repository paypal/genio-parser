<?xml version="1.0" encoding="ISO-8859-1"?>

<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<!-- root elements -->
	<xsl:template match="/">
		<wsdl2ruby>
			<properties>
				<xsl:apply-templates select="//*[local-name()='definitions']" />
			</properties>
			<elements>
				<xsl:apply-templates select=".//*[local-name()='element']" />
				<xsl:apply-templates select=".//*[local-name()='simpleType'] " />
			</elements>
			<packages>
				<xsl:apply-templates
					select="//*[local-name()='schema' and namespace-uri()='http://www.w3.org/2001/XMLSchema']" />
			</packages>

			<services>
				<xsl:apply-templates
					select="//*[local-name()='service' and namespace-uri()='http://schemas.xmlsoap.org/wsdl/']" />
			</services>
		</wsdl2ruby>
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
			<classes>
				<xsl:apply-templates
					select=".//*[local-name()='complexType' and not(starts-with(@name, 'ArrayOf_'))]" />
			</classes>
		</package>
	</xsl:template>


	<!-- matching definitions tag -->
	<xsl:template match="*[local-name()='definitions']">
		<xsl:for-each select="namespace::*">
			<namespace name="{name()}">
				<xsl:value-of select='.' />
			</namespace>
		</xsl:for-each>
		<xsl:for-each select="attribute::*">
			<attribute name="{name()}">
				<xsl:value-of select='.' />
			</attribute>
		</xsl:for-each>
		<xsl:for-each select="//*[local-name()='schema']">
			<xsl:choose>
				<xsl:when test="@elementFormDefault">
					<elementFormDefault namespace="{@targetNamespace}"><xsl:value-of select="@elementFormDefault" /></elementFormDefault>
				</xsl:when>
				<xsl:when test="@attributeFormDefault">
					<attributeFormDefault namespace="{@targetNamespace}"><xsl:value-of select="@attributeFormDefault" /></attributeFormDefault>
				</xsl:when>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>

	<!-- matching simpletype tag(enum and simple values) -->
	<xsl:template match="*[local-name()='simpleType']">
		<xsl:if test="local-name(parent::node())!='union'">
			<xsl:choose>
				<!-- for enums -->
				<xsl:when
					test="./*[local-name()='restriction'] and .//*[local-name()='enumeration'] ">
					<enum name="{@name | ../@name}" package="{@type | ancestor::*[local-name()='schema']/@targetNamespace}">
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
				<xsl:when
					test="./*[local-name()='union']">
					<element name="{@name}" package="xs:string" type="string" />
				</xsl:when>
				<xsl:otherwise>
					<xsl:variable name="base"
						select=".//*[local-name()='restriction']/@base" />
					<element name="{@name}" package="{$base}"
						type="{substring-after($base,':')}" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
	</xsl:template>

	<!-- matching element tag -->
	<xsl:template match="*[local-name()='element']">
		<xsl:choose>
			<xsl:when test="@name">
			<element name="{@name | ../@name}" package="{@type | ../@targetNamespace}"
				type="{substring-after(@type,':')}"></element>
			</xsl:when>
		</xsl:choose>
	</xsl:template>

	<!-- matching complextype tag -->
	<xsl:template match="*[local-name()='complexType']">
		<class name="{@name | ../@name}" package="{ancestor::*[local-name()='schema']/@targetNamespace}">
			<!-- for annotation tag -->
			<xsl:if test=".//*[local-name()='annotation'] ">
				<documentation>
					<xsl:value-of select=".//*[local-name()='annotation']" />
				</documentation>
			</xsl:if>
			<!-- for simpleContent tag with extension -->
			<properties>
			<xsl:if
				test="./*[local-name()='simpleContent'] and .//*[local-name()='extension']">
					<xsl:variable name="attrib" select=".//*[local-name()='attribute']" />
					<xsl:choose>
						<xsl:when test="substring-before($attrib/@type,':')='xs'">
							<property name="{$attrib/@name}" type="{substring-after($attrib/@type,':')}"
								min="1" simpletype="1" attrib="1" />
						</xsl:when>
						<xsl:otherwise>
							<property name="{$attrib/@name}" type="{substring-after($attrib/@type,':')}"
								min="1" simpletype="0" package="{substring-before($attrib/@type,':')}"
								attrib="1" />
						</xsl:otherwise>
					</xsl:choose>
					<!-- with base -->
					<xsl:if test="substring-before(.//*[local-name()='extension']/@base, ':')='xs'">
						<xsl:variable name="base" select=".//*[local-name()='extension']/@base" />
						<property name="value" type="{substring-after($base,':')}" min="1" simpletype="1" value="1" />
					</xsl:if>
				
			</xsl:if>
			<!-- tag with extension -->
			<xsl:if test=".//*[local-name()='extension']">
				<xsl:if	test="substring-before(.//*[local-name()='extension']/@base,':')!='xs'">
					<xsl:choose>
						<xsl:when test="contains(.//*[local-name()='extension']/@base, ':')" >
							<extends name="{substring-after(.//*[local-name()='extension']/@base,':')}" 
								package="{substring-before(.//*[local-name()='extension']/@base,':')}" />
						</xsl:when>
						<xsl:otherwise>
							<xsl:variable name="package">
								<xsl:variable name="defaultns" select="ancestor::*[local-name()='schema']/@targetNamespace" />
								<xsl:for-each select="ancestor::*[local-name()='schema']/namespace::*">
									<xsl:choose>
										<xsl:when test="current() = $defaultns">
											<xsl:value-of select="name()" />
										</xsl:when>
									</xsl:choose>
								</xsl:for-each>
							</xsl:variable>
							<extends name="{.//*[local-name()='extension']/@base}" package="{$package}" />
						</xsl:otherwise>
					</xsl:choose>
				</xsl:if>
			</xsl:if>
			<!-- for element tag -->
			<xsl:if test=".//*[local-name()='element']">
					<xsl:for-each select="./*[local-name()='sequence' or local-name()='all' or local-name()='choice']/*[local-name()='element']">
						<xsl:variable name="doc"
							select=".//*[local-name()='documentation']" />
						<xsl:choose>
							<xsl:when test="substring-before(@type,':')='xs'">
								<property name="{@name}" type="{substring-after(@type,':')}"
									min="{@minOccurs}" max="{@maxOccurs}" documentation="{$doc}"
									simpletype="1" />
							</xsl:when>
							<xsl:when test="@type">
								<property name="{@name}" type="{substring-after(@type, ':')}"
									simpletype="0" min="{@minOccurs}" max="{@maxOccurs}"
									package="{substring-before(@type, ':')}" documentation="{$doc}" />
							</xsl:when>
							<xsl:otherwise>
								<xsl:choose>
									<xsl:when test="@ref">
										<xsl:variable name="refname">
											<xsl:choose>
												<xsl:when test="contains(@ref, ':')">
													<xsl:value-of select="substring-after(@ref,':')" />
												</xsl:when>
												<xsl:otherwise>
													<xsl:value-of select="@ref" />
												</xsl:otherwise>
											</xsl:choose>
										</xsl:variable>
										<xsl:variable name="reftype">
											<xsl:for-each select="ancestor::*[local-name()='schema']/*[local-name()='element' and @name=$refname]">
													<xsl:value-of select="@type" />
											</xsl:for-each>
										</xsl:variable>
										<property name="{substring-after(@ref,':')}" type="{substring-after($reftype,':')}" min="{@minOccurs}"
											max="{@maxOccurs}" documentation="{$doc}"
											package="{substring-before(@ref, ':')}" simpletype="0" />
									</xsl:when>
									<xsl:otherwise>
										<property name="{@name}" type="{@name}" simpletype="0" min="{@minOccurs}" max="{@maxOccurs}"
											package="{substring-before(@type, ':')}" documentation="{$doc}" />
									</xsl:otherwise>
								</xsl:choose>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:for-each>
					<xsl:for-each select="./*[local-name()='complexContent']/*[local-name()='extension']/*[local-name()='sequence' or local-name()='all' or local-name()='choice']/*[local-name()='element']">
						<xsl:variable name="doc"
							select=".//*[local-name()='documentation']" />
						<xsl:choose>
							<xsl:when test="substring-before(@type,':')='xs'">
								<property name="{@name}" type="{substring-after(@type,':')}"
									min="{@minOccurs}" max="{@maxOccurs}" documentation="{$doc}"
									simpletype="1" />
							</xsl:when>
							<xsl:when test="@type">
								<property name="{@name}" type="{substring-after(@type, ':')}"
									simpletype="0" min="{@minOccurs}" max="{@maxOccurs}"
									package="{substring-before(@type, ':')}" documentation="{$doc}" />
							</xsl:when>
							<xsl:otherwise>
								<xsl:choose>
									<xsl:when test="@ref">
										<xsl:choose>
											<xsl:when test="@name">
												<property name="{@name}" package="{substring-before(@ref,':')}"
													min="{@minOccurs}" max="{@maxOccurs}" documentation="{$doc}"
													simpletype="0" />
											</xsl:when>
											<xsl:otherwise>
												<property name="{substring-after(@ref,':')}" min="{@minOccurs}"
													max="{@maxOccurs}" documentation="{$doc}"
													package="{substring-before(@ref, ':')}" simpletype="0" />
											</xsl:otherwise>
										</xsl:choose>
									</xsl:when>
									<xsl:otherwise>
										<property name="{@name}" type="{@name}" simpletype="0" min="{@minOccurs}" max="{@maxOccurs}"
											package="{substring-before(@type, ':')}" documentation="{$doc}" />
									</xsl:otherwise>
								</xsl:choose>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:for-each>
			</xsl:if>
			<xsl:for-each select=".//*[local-name()='attribute']">
			<xsl:variable name="attrib" select="." />
					<xsl:choose>
						<xsl:when test="substring-before($attrib/@type,':')='xs'">
							<property name="{$attrib/@name}" type="{substring-after($attrib/@type,':')}"
								min="1" simpletype="1" attrib="1" />
						</xsl:when>
						<xsl:otherwise>
							<property name="{$attrib/@name}" type="{substring-after($attrib/@type,':')}"
								min="1" simpletype="0" package="{substring-before($attrib/@type,':')}"
								attrib="1" />
						</xsl:otherwise>
					</xsl:choose>
			</xsl:for-each>
			
			</properties>
		</class>
	</xsl:template>

	<!-- matching service tag -->
	<xsl:template match="*[local-name()='service']">
		<service name="{@name}">
			<xsl:apply-templates
				select="*[local-name()='port' and namespace-uri()='http://schemas.xmlsoap.org/wsdl/']" />
		</service>
	</xsl:template>

	<!-- matching port tag -->
	<xsl:template match="*[local-name()='port']">
		<xsl:apply-templates
			select="//*[local-name()='binding' and @name=substring-after(current()/@binding,':')]" />
	</xsl:template>


	<!-- matching binding tag -->
	<xsl:template match="*[local-name()='binding'] ">
		<xsl:variable name="binding" select="concat(substring-before(@type, ':'), ':', @name)" />
		<binding name="{@name}" type="{substring-before(@type, ':')}" />
		<xsl:apply-templates
			select="//*[local-name()='portType' and @name=substring-after(current()/@type, ':')]">
			<xsl:with-param name="bindingname" select="//*[local-name()='port' and namespace-uri()='http://schemas.xmlsoap.org/wsdl/' and @binding=$binding]/attribute::name" />
		</xsl:apply-templates>
	</xsl:template>

	<!-- matching portType tag -->
	<xsl:template match="*[local-name()='portType']">
		<xsl:param name="bindingname" />
		<functions>
			<xsl:apply-templates select=".//*[local-name()='operation']">
				<xsl:with-param name="bindingname" select="$bindingname" />
			</xsl:apply-templates>
		</functions>
	</xsl:template>

	<!-- matching operation tag -->
	<xsl:template
		match="*[local-name()='operation' and namespace-uri()='http://schemas.xmlsoap.org/wsdl/']">
		<xsl:param name="bindingname" />
		<xsl:variable name="operationname" select="@name" />
		<function name="{@name}" soapAction="{//*[local-name()='binding' and namespace-uri()='http://schemas.xmlsoap.org/wsdl/']/*[local-name()='operation' and @name=$operationname]/*[local-name()='operation']/@soapAction}">
			<documentation>
				<xsl:value-of select="current()" />
			</documentation>
			
			<portname><xsl:value-of select="$bindingname" /></portname>
			<!-- for requests -->
			<parameters>
				<xsl:apply-templates
					select="//*[local-name()='message' and @name=substring-after(current()/*[local-name()='input']/@message, ':')]" />
				<xsl:apply-templates select="//*[local-name()='binding' and namespace-uri()='http://schemas.xmlsoap.org/wsdl/']/*[local-name()='operation' and namespace-uri()='http://schemas.xmlsoap.org/wsdl/' and @name=$operationname]/*[local-name()='input']/*[local-name()='header']/@message"/>
			</parameters>
			<!-- for responses -->
			<returns>
				<xsl:apply-templates
					select="//*[local-name()='message' and @name=substring-after(current()/*[local-name()='output']/@message, ':')]" />
			</returns>
			<!-- for faults -->
			<throws>
				<xsl:apply-templates
					select="//*[local-name()='message' and @name=substring-after(current()/*[local-name()='fault']/@message, ':')]" />
			</throws>
		</function>
	</xsl:template>

	<xsl:template match="@*[local-name()='message']">
		<xsl:variable name="name" select="substring-after(current(), ':')" />
		<variable name="{$name}" type="{//*[local-name()='element' and @name=$name]/@type}" package="{substring-before(current(), ':')}" part="header"/>
	</xsl:template>

	<!-- matching message tag -->
	<xsl:template match="*[local-name()='message']">
		<xsl:for-each select="*[local-name()='part']">
			<xsl:choose>
				<xsl:when test="substring-before(@type,':')='xsd'">
					<variable name="{@name}" type="{substring-after(@type,':')}"
						package="{substring-before(@type,':')}" part="body" />
				</xsl:when>
				<xsl:when
					test="//*[local-name()='complexType' and @name=substring-after(current()/@type,':')]//*[@ref='soapenc:arrayType']">
					<xsl:variable name="type"
						select="//*[local-name()='complexType' and @name=substring-after(current()/@type,':')]//*[@ref='soapenc:arrayType']/@*[local-name()='arrayType']" />
					<variable name="{@name}" type="{substring-after($type,':')}"
						package="{substring-before(@type,':')}" part="body" />
				</xsl:when>
				<xsl:when test="not(@type) and @element">
					<variable name="{substring-after(@element,':')}" type="{substring-after(@element,':')}"
						package="{substring-before(@element,':')}" part="body" />
				</xsl:when>
				<xsl:otherwise>
					<variable name="{@name}" type="{@type}"
						package="{substring-before(@type,':')}" part="body" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>

</xsl:stylesheet>
