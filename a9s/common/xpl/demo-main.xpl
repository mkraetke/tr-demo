<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:cx="http://xmlcalabash.com/ns/extensions" xmlns:tr="http://transpect.io" version="1.0"
  name="demo" type="tr:demo">

  <p:documentation>Eine kleine Transpect-Demo</p:documentation>

  <p:input port="source">
    <p:documentation> Hier wird das Parameter-Dokument erwartet.</p:documentation>
    <p:document href="../params.xml"/>
  </p:input>

  <p:output port="result">
    <p:documentation>Primärer Ausgabe-Port</p:documentation>
  </p:output>

  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
  
  <p:identity/>

</p:declare-step>
