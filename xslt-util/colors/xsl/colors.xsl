<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs= "http://www.w3.org/2001/XMLSchema"
  xmlns:css= "http://www.w3.org/1996/css"
  xmlns:tr="http://transpect.io"
  version="2.0">

  <xsl:import href="http://transpect.io/xslt-util/hex/xsl/hex.xsl"/>
  <xsl:import href="colors.mappings.xsl"/>

  <xsl:variable name="three-digits-hex-color-regex" as="xs:string"
    select="'^#[0-9a-fA-F]{3}$'"/>
  <xsl:variable name="six-digits-hex-color-regex" as="xs:string"
    select="'^#[0-9a-fA-F]{6}$'"/>
  <xsl:variable name="rgb-color-regex" as="xs:string"
    select="'^rgb\s*\(\s*\d+\s*,\s*\d+\s*,\s*\d+\s*\)$'"/>
  <!-- ... -->
  <xsl:variable name="device-cmyk-color-regex" as="xs:string"
    select="'^device-cmyk\s*\(\s*(0|0?\.\d+|1(\.0*)?)\s*,\s*(0|0?\.\d+|1(\.0*)?)\s*,\s*(0|0?\.\d+|1(\.0*)?)\s*,\s*(0|0?\.\d+|1(\.0*)?)\s*\)$'"/>

  <!-- Input: '#00CAFF'. Output: 0, 202, 255 -->
  <xsl:function name="tr:hex-rgb-color-to-ints" as="xs:double*">
    <xsl:param name="in" as="xs:string"/>
    <xsl:variable name="six-hex-digits" as="xs:string"
      select="replace(
                tr:hex-rgb-to-six-digits-hex-rgb($in), 
                '^#', 
                ''
              )" />
    <xsl:if test="not(matches($six-hex-digits, '^[a-f0-9]{6}$', 'i'))">
      <xsl:message>Unexpected six-hex string: <xsl:value-of select="$six-hex-digits"/></xsl:message>
    </xsl:if>
      <xsl:sequence select="for $i in (0 to 2) 
                          return tr:hex-to-dec(
                            substring($six-hex-digits, 2 * $i + 1, 2)
                          )" />
  </xsl:function>

  <xsl:function name="tr:rgb-string-to-dec-triple" as="xs:integer+">
    <xsl:param name="string"     as="xs:string"/>
    <xsl:sequence select="for $s in (substring($string, 2, 2), substring($string, 4, 2), substring($string, 6, 2))
                          return tr:hex-to-dec($s)"/>
  </xsl:function>

  <!-- Input: '#ac9'. Output: #AACC99-->
  <xsl:function name="tr:hex-rgb-to-six-digits-hex-rgb" as="xs:string">
    <xsl:param name="in" as="xs:string" />
    <xsl:variable name="stripped-pound" as="xs:string"
      select="replace($in, '#', '')" />
    <xsl:choose>
      <xsl:when test="matches($in, $six-digits-hex-color-regex)">
        <xsl:sequence select="upper-case($in)" />
      </xsl:when>
      <xsl:when test="matches($in, $three-digits-hex-color-regex)">
        <xsl:sequence select="concat(
                                '#',
                                codepoints-to-string(
                                  for $i 
                                  in string-to-codepoints(
                                       upper-case($stripped-pound)
                                     )
                                  return ($i, $i)
                                )
                              )" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:message>colors/colors.xsl: unexpected hex value <xsl:value-of select="$in" />
        </xsl:message>
        <xsl:sequence select="''" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="tr:int-rgb-colors-to-hex" as="xs:string">
    <xsl:param name="in" as="xs:double+"/>
    <xsl:if test="some $i in $in satisfies (not($i castable as xs:integer))">
      <xsl:message>tr:int-rgb-colors-to-hex: cannot cast one or more of '<xsl:value-of select="$in"/>' to integer</xsl:message>
    </xsl:if>
    <xsl:if test="not(count($in) eq 3)">
      <xsl:message>tr:int-rgb-colors-to-hex: expecting exactly 3 values</xsl:message>
    </xsl:if>
    <xsl:sequence select="string-join(
                            (
                              '#',
                              for $i in ($in) 
                              return tr:pad(tr:dec-to-hex(xs:integer(round($i))), 2)
                            ),
                            ''
                          )" />
  </xsl:function>
  

  <!-- aimed at cmyk colors in the 0.0 .. 1.0 value space -->
  <xsl:function name="tr:tint-hex-color" as="xs:string">
    <xsl:param name="color" as="xs:string" />
    <xsl:param name="factor" as="xs:double" />
    <xsl:if test="not(matches($color, '^#?[a-f0-9]{6}$', 'i'))">
      <xsl:message>Unexpected six-hex string: <xsl:value-of select="$color"/></xsl:message>
    </xsl:if>
    <xsl:sequence select="tr:int-rgb-colors-to-hex(
                            for $c in tr:hex-rgb-color-to-ints($color)
                            return (255 - $c) * (1.0 - $factor)
                          )" />
  </xsl:function>
  
  <xsl:function name="tr:tint-hex-color-filled" as="xs:string">
    <xsl:param name="color" as="xs:string" />
    <xsl:param name="factor" as="xs:double" />
    <xsl:param name="fill" as="xs:string" />
        
    <xsl:variable name="combined-colors" as="xs:double *">
      <xsl:for-each select="tr:hex-rgb-color-to-ints($color)">
        <xsl:variable name="position" select="position()"/>
        <xsl:value-of select="(tr:hex-rgb-color-to-ints($fill)[position() = $position] - .) * (1.0 - $factor)"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:sequence select="tr:int-rgb-colors-to-hex(for $c in $combined-colors return $c)" />
  </xsl:function>

  <xsl:function name="tr:device-cmyk-to-rgb-int-triple" as="xs:double*">
    <xsl:param name="input" as="xs:string"/>
    <xsl:analyze-string select="$input"
      regex="{$device-cmyk-color-regex}">
      <xsl:matching-substring>
        <xsl:sequence select="255 * (1 - number(regex-group(1))) * (1 - number(regex-group(7)))"/>
        <xsl:sequence select="255 * (1 - number(regex-group(3))) * (1 - number(regex-group(7)))"/>
        <xsl:sequence select="255 * (1 - number(regex-group(5))) * (1 - number(regex-group(7)))"/>
      </xsl:matching-substring>
      <xsl:non-matching-substring>
        <xsl:message>colors.xsl: Cannot parse <xsl:value-of select="$input"/>. Returning black.</xsl:message>
        <xsl:sequence select="0"/>
        <xsl:sequence select="0"/>
        <xsl:sequence select="0"/>
      </xsl:non-matching-substring>
    </xsl:analyze-string>
  </xsl:function>

  <xsl:function name="tr:rgb-int-triple-to-rgb" as="xs:string">
    <xsl:param name="input" as="xs:double+"/>
    <xsl:sequence select="concat(
                            'rgb(', 
                            string-join(
                              for $i in $input return xs:string(xs:integer(($i))), 
                              ', '), 
                            ')'
                          )"/>
  </xsl:function>

  <!-- recreate css:color attribute with another color type -->
  <xsl:function name="tr:convert-css-color-attr" as="xs:string">
    <xsl:param name="css-color-attr" as="attribute()"/>
    <xsl:param name="target" as="xs:string"/>
    <xsl:attribute name="{name($css-color-attr)}" 
      select="tr:convert-css-color(xs:string($css-color-attr), $target)"/>
  </xsl:function>

  <!-- frontend color conversion function
       1st param: color value
       2nd param: target color type (i.e. 'hex', 'rgba') -->
  <xsl:function name="tr:convert-css-color" as="xs:string">
    <xsl:param name="css-color" as="xs:string"/>
    <xsl:param name="type-out" as="xs:string"/>
    <xsl:variable name="tokenized" select="tr:tokenize-css-color-value($css-color)" as="xs:string+" />
    <xsl:variable name="type-in" select="$tokenized[1]" as="xs:string" />
    <xsl:choose>
      <xsl:when test="$type-in eq 'device-cmyk'">
        <xsl:choose>
          <xsl:when test="$type-out eq 'rgb'">
            <xsl:sequence select="tr:rgb-int-triple-to-rgb(
                                    tr:device-cmyk-to-rgb-int-triple($css-color)
                                  )"/>
          </xsl:when>
          <xsl:when test="$type-out eq 'hex'">
            <xsl:variable name="rgb" select="tr:rgb-int-triple-to-rgb(tr:device-cmyk-to-rgb-int-triple($css-color))"/>
            <xsl:sequence select="tr:convert-css-color($rgb, 'hex')"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:message select="'colors/colors.xsl, tr:convert-css-color: unimplemented conversion from input device-cmyk to type-out', $type-out, 'Input color value:', $css-color"/>
            <xsl:value-of select="$css-color"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="$type-in eq 'hex'">
        <xsl:choose>
          <xsl:when test="$type-out eq 'hex'">
            <xsl:sequence select="tr:hex-rgb-to-six-digits-hex-rgb(
                                    concat('#', $tokenized[2])
                                  )"/>
          </xsl:when>
          <xsl:when test="$type-out eq 'rgb'">
            <xsl:sequence select="concat(
                                    'rgb(',
                                    string-join(
                                      for $double in tr:hex-rgb-color-to-ints(
                                        tr:hex-rgb-to-six-digits-hex-rgb(
                                          concat('#', $tokenized[2])
                                        )
                                      ) return xs:string($double),
                                      ','
                                    ),
                                    ')'
                                  )"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:message select="'colors/colors.xsl, tr:convert-css-color: unimplemented conversion from input hex to type-out', $type-out, 'Input color value:', $css-color"/>
            <xsl:value-of select="$css-color"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="$type-in eq 'rgb'">
        <xsl:choose>
          <xsl:when test="$type-out eq 'hex'">
            <xsl:if test="some $i in $tokenized[position() gt 1] satisfies (not($i castable as xs:integer))">
              <xsl:message>tr:int-rgb-colors-to-hex: cannot cast one or more of '<xsl:value-of select="$tokenized"/>' to integer</xsl:message>
            </xsl:if>            
            <xsl:sequence select="tr:int-rgb-colors-to-hex(
                                    for $i in $tokenized[position() gt 1]
                                    return xs:double($i)
                                  )"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:message select="'colors/colors.xsl, tr:convert-css-color: unimplemented conversion from rgb to', $type-out"/>
            <xsl:value-of select="$css-color"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="$type-in = $known-keywords">
        <xsl:sequence select="tr:color-keyword-to-hex-rgb($type-in)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message select="'colors/colors.xsl, tr:convert-css-color: unimplemented color type conversion:', $type-in, 'to', $type-out"/>
        <xsl:value-of select="$css-color"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- examples  in: #DD05AC          out: ('hex', 'DD05AC')
                 in: rgb (45, 70, 2)  out: ('rgb', '45', '50', '2') -->
  <xsl:function name="tr:tokenize-css-color-value" as="xs:string+">
    <xsl:param name="css-color" as="xs:string"/>
    <xsl:sequence select="tokenize(
                            replace( 
                              replace( 
                                replace(
                                  $css-color,
                                  '^#',
                                  'hex,'),
                                '\s|\)', 
                                ''),
                              '\(',
                              ','),
                            ','
                          )"/>
  </xsl:function>

</xsl:stylesheet>
