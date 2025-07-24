<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.1" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="tei">

    <!-- Sortie du résultat en texte brut (GeoJSON) -->
    <xsl:output method="text" encoding="UTF-8"/>
    
    <!-- Chargement du fichier d'autorité des lieux -->
    <xsl:variable name="places-doc" select="document('places-map.xml')"/>

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
        <!-- Récupérer tous les placeName avec @corresp -->
        <xsl:variable name="all-places" select=".//tei:placeName[@corresp]"/>
        <!-- Récupérer l'ID du premier placeName -->
        <xsl:variable name="first-place-id" select="substring-after($all-places[1]/@corresp, '#')"/>
        <!-- Chercher si un des autres placeName pointe vers un lieu dont une addrLine corresp=#ID_DU_PREMIER_PLACE_NAME -->
        <xsl:variable name="places-ref-to-first">
            <xsl:for-each select="$all-places[position() &gt; 1]">
                <xsl:variable name="this-id" select="substring-after(@corresp, '#')"/>
                <xsl:variable name="lieu" select="$places-doc//tei:place[@xml:id = $this-id]"/>
                <xsl:if test="$lieu//tei:addrLine[@corresp = concat('#', $first-place-id)]">
                    <xsl:text>1</xsl:text>
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>
        <xsl:choose>
            <!-- Cas où il existe au moins un autre lieu qui référence le premier -->
            <xsl:when test="string-length($places-ref-to-first) &gt; 0">
                <!-- On crée un feature pour tous les placeName sauf le premier -->
                <xsl:apply-templates select="$all-places[position() &gt; 1]"/>
            </xsl:when>
            <xsl:otherwise>
                <!-- On crée un feature pour tous les placeName (y compris le premier) -->
                <xsl:apply-templates select="$all-places"/>
            </xsl:otherwise>
        </xsl:choose>
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

            <!-- Ajouter une virgule entre les features sauf pour le premier (pour éviter la dernière virgule) -->
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
            <!-- Longitude -->
            <xsl:value-of select="$long"/>
            <xsl:text>, </xsl:text>
            <!-- Latitude -->
            <xsl:value-of select="$lat"/>
            <xsl:text>]
        },
        "properties": {
        "date": "</xsl:text>
            <!-- Extraction de la date (plusieurs formats possibles selon l'attribut de la balise date) -->
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
            <!-- Nom du lieu dans le fichier d'autorité -->
            <xsl:value-of select="normalize-space($place//tei:placeName)"/>
            <xsl:text>",
            <!-- Type du lieu (ne sera pas affiché mais permettra de différencier les types de lieux par couleur) -->
        "place-type": "</xsl:text>
            <xsl:value-of select="$place/@type"/>
            <xsl:text>",
        <!-- Identifiant xml:id de l'événement parent -->
        "event-id": "</xsl:text>
            <xsl:value-of select="ancestor::tei:event/@xml:id"/>
            <xsl:text>",
        "event": "</xsl:text>
            <!-- Texte de l'événement (guillemets supprimés pour éviter les erreurs de parsing) -->
            <xsl:value-of select="normalize-space(translate(ancestor::tei:event//tei:p, '&quot;', ''))"/>
            <xsl:text>"
        }
        }</xsl:text>
        </xsl:if>
    </xsl:template>

</xsl:stylesheet> 