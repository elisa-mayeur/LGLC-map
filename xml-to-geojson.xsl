<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.1" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="tei">

    <!-- Sortie du résultat en texte brut (GeoJSON) -->
    <xsl:output method="text" encoding="UTF-8"/>
    
    <!-- Chargement du fichier d'autorité des lieux -->
    <xsl:variable name="places-doc" select="document('local-places.xml')"/>

    <!-- Template principal : racine du document -->
    <xsl:template match="/">
        <!-- Début du GeoJSON -->
        <xsl:text>{
        "type": "FeatureCollection",
        "features": [
        </xsl:text>
        <!-- Appliquer le template sur chaque événement -->
        <xsl:apply-templates select="//tei:event"/>
        <!-- Fin du GeoJSON -->
        <xsl:text>
        ]
        }</xsl:text>
    </xsl:template>

    <!-- Template pour chaque événement -->
    <xsl:template match="tei:event">
        <!--
            Si un seul placeName dans l'événement :
            on crée un feature pour ce lieu
        -->
        <xsl:apply-templates select=".//tei:placeName[@corresp][last()=1]"/>
        <!--
            Si plusieurs placeName dans l'événement :
            on crée un feature pour chaque lieu sauf le premier
        -->
        <xsl:apply-templates select=".//tei:placeName[@corresp][position() &gt; 1 and last() &gt; 1]"/>
    </xsl:template>

    <!-- Template pour chaque placeName sélectionné -->
    <xsl:template match="tei:placeName">
        <!-- Récupérer l'identifiant du lieu -->
        <xsl:variable name="place-id" select="substring-after(@corresp, '#')"/>
        <!-- Chercher l'élément place correspondant dans le fichier d'autorité -->
        <xsl:variable name="place" select="$places-doc//tei:place[@xml:id = $place-id]"/>
        <!-- Vérifier que le lieu a des coordonnées valides -->
        <xsl:if test="$place//tei:geo and normalize-space($place//tei:geo) != '' and normalize-space($place//tei:geo) != '?'">
            <!-- Extraire latitude et longitude sans supprimer le signe moins -->
            <xsl:variable name="geo-text" select="normalize-space($place//tei:geo)"/>
            <xsl:variable name="lat" select="substring-before($geo-text, ' ')"/>
            <xsl:variable name="long" select="normalize-space(substring-after($geo-text, ' '))"/>
            <!-- Ajouter une virgule entre les features sauf pour le premier -->
            <xsl:if test="position() > 1 or preceding::tei:placeName[@corresp]">
                <xsl:text>,</xsl:text>
            </xsl:if>
            <!-- Générer le bloc GeoJSON pour ce lieu -->
            <xsl:text>
        {
        "type": "Feature",
        "geometry": {
        "type": "Point",
        "coordinates": [</xsl:text>
            <!-- Longitude (négatif pour l'ouest ou positif pour l'est) -->
            <xsl:value-of select="$long"/>
            <xsl:text>, </xsl:text>
            <!-- Latitude -->
            <xsl:value-of select="$lat"/>
            <xsl:text>]
        },
        "properties": {
        "date": "</xsl:text>
            <!-- Extraction de la date (plusieurs formats possibles) -->
            <xsl:choose>
                <xsl:when test="ancestor::tei:event//tei:date[1]/@when">
                    <xsl:value-of select="ancestor::tei:event//tei:date[1]/@when"/>
                </xsl:when>
                <xsl:when test="ancestor::tei:event//tei:date[1]/@from and ancestor::tei:event//tei:date[1]/@to">
                    <xsl:value-of select="concat(ancestor::tei:event//tei:date[1]/@from, '/', ancestor::tei:event//tei:date[1]/@to)"/>
                </xsl:when>
                <xsl:when test="ancestor::tei:event//tei:date[1]/@notBefore and ancestor::tei:event//tei:date[1]/@notAfter">
                    <xsl:value-of select="concat(ancestor::tei:event//tei:date[1]/@notBefore, '/', ancestor::tei:event//tei:date[1]/@notAfter)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="normalize-space(ancestor::tei:event//tei:date[1])"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>",
        "place": "</xsl:text>
            <!-- Nom du lieu officiel depuis le fichier d'autorité -->
            <xsl:value-of select="normalize-space($place//tei:placeName)"/>
            <xsl:text>",
        "place-type": "</xsl:text>
            <xsl:value-of select="$place/@type"/>
            <xsl:text>",
        <!-- event-id : identifiant xml:id de l'événement parent -->
        "event-id": "</xsl:text>
            <xsl:value-of select="ancestor::tei:event/@xml:id"/>
            <xsl:text>",
        "event": "</xsl:text>
            <!-- Texte de l'événement (guillemets supprimés) -->
            <xsl:value-of select="normalize-space(translate(ancestor::tei:event//tei:p, '&quot;', ''))"/>
            <xsl:text>"
        }
        }</xsl:text>
        </xsl:if>
    </xsl:template>

</xsl:stylesheet> 