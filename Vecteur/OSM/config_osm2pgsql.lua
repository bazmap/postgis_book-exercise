-- Fichier de configuration pour l'import des données OSM avec osm2pgsql

-- Variables
------------
-- Projection utilisée
local var_srid = 3857

-- Schéma de destination des données
local var_schema = 'exo_osm'

-- Liste des tags non utiles (principale des tags utilisés pour la numérisations)
-- Le caractère '*' permet de spécifier "n'importe quel(s) charactère(s) (possiblement au pluriel)"
local var_delete_keys = {
	-- "mapper" keys
	'attribution',
	'comment',
	'created_by',
	'fixme',
	'note',
	'note:*',
	'odbl',
	'odbl:note',
	'source',
	'source:*',
	'source_ref',

	-- Corine Land Cover (CLC) (Europe)
	'CLC:*',

	-- Geobase (CA)
	'geobase:*',
	-- CanVec (CA)
	'canvec:*',

	-- osak (DK)
	'osak:*',
	-- kms (DK)
	'kms:*',

	-- ngbe (ES)
	-- See also note:es and source:file above
	'ngbe:*',

	-- Friuli Venezia Giulia (IT)
	'it:fvg:*',

	-- KSJ2 (JA)
	-- See also note:ja and source_ref above
	'KSJ2:*',
	-- Yahoo/ALPS (JA)
	'yh:*',

	-- LINZ (NZ)
	'LINZ2OSM:*',
	'linz2osm:*',
	'LINZ:*',
	'ref:linz:*',

	-- WroclawGIS (PL)
	'WroclawGIS:*',
	-- Naptan (UK)
	'naptan:*',

	-- TIGER (US)
	'tiger:*',
	-- GNIS (US)
	'gnis:*',
	-- National Hydrography Dataset (US)
	'NHD:*',
	'nhd:*',
	-- mvdgis (Montevideo, UY)
	'mvdgis:*',

	-- EUROSHA (Various countries)
	'project:eurosha_2012',

	-- UrbIS (Brussels, BE)
	'ref:UrbIS',

	-- NHN (CA)
	'accuracy:meters',
	'sub_sea:type',
	'waterway:type',
	-- StatsCan (CA)
	'statscan:rbuid',

	-- RUIAN (CZ)
	'ref:ruian:addr',
	'ref:ruian',
	'building:ruian:type',
	-- DIBAVOD (CZ)
	'dibavod:id',
	-- UIR-ADR (CZ)
	'uir_adr:ADRESA_KOD',

	-- GST (DK)
	'gst:feat_id',

	-- Maa-amet (EE)
	'maaamet:ETAK',
	-- FANTOIR (FR)
	'ref:FR:FANTOIR',

	-- 3dshapes (NL)
	'3dshapes:ggmodelk',
	-- AND (NL)
	'AND_nosr_r',

	-- OPPDATERIN (NO)
	'OPPDATERIN',
	-- Various imports (PL)
	'addr:city:simc',
	'addr:street:sym_ul',
	'building:usage:pl',
	'building:use:pl',
	-- TERYT (PL)
	'teryt:simc',

	-- RABA (SK)
	'raba:id',
	-- DCGIS (Washington DC, US)
	'dcgis:gis_id',
	-- Building Identification Number (New York, US)
	'nycdoitt:bin',
	-- Chicago Building Import (US)
	'chicago:building_id',
	-- Louisville, Kentucky/Building Outlines Import (US)
	'lojic:bgnum',
	-- MassGIS (Massachusetts, US)
	'massgis:way_id',
	-- Los Angeles County building ID (US)
	'lacounty:*',
	-- Address import from Bundesamt für Eich- und Vermessungswesen (AT)
	'at_bev:addr_date',

	-- "import" keys
	'import',
	'import_uuid',
	'OBJTYPE',
	'SK53_bulk:load',
	'mml:class'
}



-- Fonctions
------------

-- Fonction de nettoyage des tags
-- La fonction make_clean_tags_func() créé une nouvelle fonction à partir d'une liste de tag, qui permet de supprimer ces tags d'un objet.
-- Cette nouvelle fonction renvoie "vrai" si tous les tags ont été retirés.
local clean_tags = osm2pgsql.make_clean_tags_func(var_delete_keys)


-- Fonction permettant de déterminer si l'objet est une surface
function has_area_tags(tags)
	if tags.area == 'yes' then
		return true
	end
	if tags.area == 'no' then
		return false
	end

	-- Si le tag "area" n'existe pas, on retourne la valeur du premier tag possédant une valeur
	return tags.aeroway
		or tags.amenity
		or tags.building
		or tags.harbour
		or tags.historic
		or tags.landuse
		or tags.leisure
		or tags.man_made
		or tags.military
		or tags.natural
		or tags.office
		or tags.place
		or tags.power
		or tags.public_transport
		or tags.shop
		or tags.sport
		or tags.tourism
		or tags.water
		or tags.waterway
		or tags.wetland
		or tags['abandoned:aeroway']
		or tags['abandoned:amenity']
		or tags['abandoned:building']
		or tags['abandoned:landuse']
		or tags['abandoned:power']
		or tags['area:highway']
		or tags['building:part']
end





-- Définition des tables de destintation
----------------------------------------

-- Variable de type tableau qui contiendra la définition des tables à créer en base
local var_tables = {}

-- Table des ponctuels
var_tables.ponctuel = osm2pgsql.define_table({
	-- Schéma contenant la table
	schema = var_schema,
	-- Nom de la table
	name = 'ponctuel',
	-- Gestion de la colonne d'identifiant osm
	ids = { type = 'node', id_column = 'osm_id' },
	-- Liste des colonnes à créer
	columns = {
		-- Colonne d'identifiant (de type sérial donc gérée automatiquement)
		{ column = 'id', sql_type = 'serial', create_only = true },
		-- Colonne contenant les tags
		{ column = 'tags', type = 'hstore' },
		-- Colonnes supplémentaires (qui reprendront la valeur de certains tages)
		{ column = 'amenity', type = 'text' },
		{ column = 'historic', type = 'text'},
		{ column = 'highway', type = 'text' },
		{ column = 'name', type = 'text' },
		{ column = 'natural', type = 'text' },
		{ column = 'place', type = 'text' },
		{ column = 'power', type = 'text' },
		{ column = 'shop', type = 'text' },
		{ column = 'tourism', type = 'text' },
		-- Colonne géométrique
		{ column = 'geom', type = 'point', projection = var_srid },
	}
})

-- Table des lignes
var_tables.ligne = osm2pgsql.define_table({
	-- Schéma contenant la table
	schema = var_schema,
	-- Nom de la table
	name = 'ligne',
	-- Gestion de la colonne d'identifiant osm
	ids = { type = 'way', id_column = 'osm_id' },
	-- Liste des colonnes à créer
	columns = {
		-- Colonne d'identifiants (de type sérial donc gérée automatiquement)
		{ column = 'id', sql_type = 'serial', create_only = true },
		-- Colonne contenant les tags
		{ column = 'tags', type = 'hstore' },
		-- Colonnes supplémentaires (qui reprendront la valeur de certains tages)
		{ column = 'access', type = 'text' },
		{ column = 'admin_level', type = 'text' },
		{ column = 'barrier', type = 'text' },
		{ column = 'boundary', type = 'text' },
		{ column = 'highway', type = 'text' },
		{ column = 'intermittent', type = 'text' },
		{ column = 'name', type = 'text' },
		{ column = 'power', type = 'text' },
		{ column = 'tracktype', type = 'text' },
		{ column = 'waterway', type = 'text' },
		-- Colonne géométrique
		{ column = 'geom', type = 'linestring', projection = var_srid },
	}
})

-- Table des surfaces
var_tables.surface = osm2pgsql.define_table({
	-- Schéma contenant la table
	schema = var_schema,
	-- Nom de la table
	name = 'surface',
	-- Gestion de la colonne d'identifiant osm
	ids = { type = 'area', id_column = 'osm_id' },
	-- Liste des colonnes à créer
	columns = {
		-- Colonne d'identifiants (de type sérial donc gérée automatiquement)
		{ column = 'id', sql_type = 'serial', create_only = true },
		-- Colonne contenant les tags
		{ column = 'tags', type = 'hstore' },
		-- Colonnes supplémentaires (qui reprendront la valeur de certains tages)
		{ column = 'amenity', type = 'text' },
		{ column = 'building', type = 'text' },
		{ column = 'landuse', type = 'text' },
		{ column = 'leaf_type', type = 'text' },
		{ column = 'leisure', type = 'text' },
		{ column = 'name', type = 'text' },
		{ column = 'natural', type = 'text' },
		-- Colonne géométrique
		{ column = 'geom', type = 'multipolygon', projection = var_srid },
	}
})

-- Table des itineraires
var_tables.itineraire = osm2pgsql.define_table({
	-- Schéma contenant la table
	schema = var_schema,
	-- Nom de la table
	name = 'itineraire',
	-- Gestion de la colonne d'identifiant osm
	ids = { type = 'relation', id_column = 'osm_id' },
	-- Liste des colonnes à créer
	columns = {
		-- Colonne d'identifiants (de type sérial donc gérée automatiquement)
		{ column = 'id', sql_type = 'serial', create_only = true },
		-- Colonne contenant les tags
		{ column = 'tags', type = 'hstore' },
		-- Colonnes supplémentaires (qui reprendront la valeur de certains tages)
		{ column = 'from', type = 'text' },
		{ column = 'name', type = 'text' },
		{ column = 'network', type = 'text' },
		{ column = 'route', type = 'text' },
		{ column = 'to', type = 'text' },
		{ column = 'via', type = 'text' },
		-- Colonne géométrique
		{ column = 'geom', type = 'multilinestring', projection = var_srid },
	}
})

-- Table des frontières
var_tables.limite = osm2pgsql.define_table({
	-- Schéma contenant la table
	schema = var_schema,
	-- Nom de la table
	name = 'limite',
	-- Gestion de la colonne d'identifiant osm
	ids = { type = 'relation', id_column = 'osm_id' },
	-- Liste des colonnes à créer
	columns = {
		-- Colonne d'identifiants (de type sérial donc gérée automatiquement)
		{ column = 'id', sql_type = 'serial', create_only = true },
		-- Colonne contenant les tags
		{ column = 'tags', type = 'hstore' },
		-- Colonnes supplémentaires (qui reprendront la valeur de certains tages)
		{ column = 'boundary', type = 'text' },
		{ column = 'name', type = 'text' },
		-- Colonne géométrique
		{ column = 'geom', type = 'multilinestring', projection = var_srid },
	}
})





-- Fonction de traitement des objets
------------------------------------

-- Traitement des noeuds
function osm2pgsql.process_node(object)
	-- Si le nettoyage des tags ne laisse aucun tag : on ne renvoie rien : on ne conserve pas l'objet
	if clean_tags(object.tags) then
		return
	end

	-- Ajout d'un objet à la table des ponctuels
	-- Définition de la valeur des colonnes qui ont été ajoutées :
	--		La colonne id est de type serial donc pas besoin de définir la valeur
	-- 		Récupération de la valeurs d'un tag :
	--			object.tags.mon_tag = valeur du tag indiqué (le tag reste présent dans l'objet object.tags)
	--			object:grab_tag('mon_tag') = valeur du tag indiqué (le tag est supprimé de l'objet object.tags, pratique pour éviter d'avoir deux fois la donnée)
	--		Conversion de la géométrie de l'objet en POINT
	var_tables.ponctuel:insert({
		amenity = object:grab_tag('amenity'),
		historic = object:grab_tag('historic'),
		highway = object:grab_tag('highway'),
		name = object:grab_tag('name'),
		natural = object:grab_tag('natural'),
		place = object:grab_tag('place'),
		power = object:grab_tag('power'),
		shop = object:grab_tag('shop'),
		tourism = object:grab_tag('tourism'),

		tags = object.tags,

		geom = object:as_point()
	})
end



-- Traitement des chemins
function osm2pgsql.process_way(object)
	-- Si le nettoyage des tags ne laisse aucun tag : on ne conserve pas l'objet
	if clean_tags(object.tags) then
		return
	end

	-- Si l'objet est fermé et qu'il est considéré comme une surface
	if object.is_closed and has_area_tags(object.tags) then

		-- Ajout d'un objet à la table des surface
		-- Définition de la valeur des colonnes qui ont été ajoutées :
		--		La colonne id est de type serial donc pas besoin de définir la valeur
		-- 		Récupération de la valeurs d'un tag :
		--			object.tags.mon_tag = valeur du tag indiqué (le tag reste présent dans l'objet object.tags)
		--			object:grab_tag('mon_tag') = valeur du tag indiqué (le tag est supprimé de l'objet object.tags, pratique pour éviter d'avoir deux fois la donnée)
		--		Conversion de la géométrie de l'objet en POLYGON
		var_tables.surface:insert({
			amenity = object:grab_tag('amenity'),
			building = object:grab_tag('building'),
			landuse = object:grab_tag('landuse'),
			leaf_type = object:grab_tag('leaf_type'),
			leisure = object:grab_tag('leisure'),
			name = object:grab_tag('name'),
			natural = object:grab_tag('natural'),

			tags = object.tags,

			geom = object:as_multipolygon()
		})
	else

		-- Ajout d'un objet à la table des lignes
		-- Définition de la valeur des colonnes qui ont été ajoutées :
		--		La colonne id est de type serial donc pas besoin de définir la valeur
		-- 		Récupération de la valeurs d'un tag :
		--			object.tags.mon_tag = valeur du tag indiqué (le tag reste présent dans l'objet object.tags)
		--			object:grab_tag('mon_tag') = valeur du tag indiqué (le tag est supprimé de l'objet object.tags, pratique pour éviter d'avoir deux fois la donnée)
		--		Conversion de la géométrie de l'objet en linestring
		var_tables.ligne:insert({
			access = object:grab_tag('access'),
			admin_level = object:grab_tag('admin_level'),
			barrier = object:grab_tag('barrier'),
			boundary = object:grab_tag('boundary'),
			highway = object:grab_tag('highway'),
			intermittent = object:grab_tag('intermittent'),
			name = object:grab_tag('name'),
			power = object:grab_tag('power'),
			tracktype = object:grab_tag('tracktype'),
			waterway = object:grab_tag('waterway'),

			tags = object.tags,

			geom = object:as_linestring()
		})
	end
end



-- Traitement des relations
function osm2pgsql.process_relation(object)
	-- Si le nettoyage des tags ne laisse aucun tag : on ne conserve pas l'objet
	if clean_tags(object.tags) then
		return
	end

	-- Récupération du tag "type"
	local type = object.tags.type

	-- Les relations de type "route" sont envoyées dans la table des itineraires
	if type == 'route' then
		-- On créé une ligne à partir de la relation

		-- Ajout d'un objet à la table des lignes
		-- Définition de la valeur des colonnes qui ont été ajoutées :
		--		La colonne id est de type serial donc pas besoin de définir la valeur
		-- 		Récupération de la valeurs d'un tag :
		--			object.tags.mon_tag = valeur du tag indiqué (le tag reste présent dans l'objet object.tags)
		--			object:grab_tag('mon_tag') = valeur du tag indiqué (le tag est supprimé de l'objet object.tags, pratique pour éviter d'avoir deux fois la donnée)
		--		Conversion de la géométrie de l'objet en MULTILINESTRING
		var_tables.itineraire:insert({
			from = object:grab_tag('from'),
			name = object:grab_tag('name'),
			network = object:grab_tag('network'),
			route = object:grab_tag('route'),
			to = object:grab_tag('to'),
			via = object:grab_tag('via'),

			tags = object.tags,

			geom = object:as_multilinestring()
		})
		return
	end

	-- Les relations de type "frontière" ou "multipolygon" mais avec le tags "boundary" sont envoyées dans la table des limites
	if type == 'boundary' or (type == 'multipolygon' and object.tags.boundary) then
		-- On créé une ligne à partir de la relation

		-- Ajout d'un objet à la table des lignes
		-- Définition de la valeur des colonnes qui ont été ajoutées :
		--		La colonne id est de type serial donc pas besoin de définir la valeur
		-- 		Récupération de la valeurs d'un tag :
		--			object.tags.mon_tag = valeur du tag indiqué (le tag reste présent dans l'objet object.tags)
		--			object:grab_tag('mon_tag') = valeur du tag indiqué (le tag est supprimé de l'objet object.tags, pratique pour éviter d'avoir deux fois la donnée)
		--		Conversion de la géométrie de l'objet en MULTILINESTRING
		var_tables.limite:insert({
			boundary = object:grab_tag('boundary'),
			name = object:grab_tag('name'),

			tags = object.tags,

			geom = object:as_multilinestring()
		})

		-- On créé également un polygone à partir de la relation (les limites seront donc à la fois dans la table limite ET dans la table des surfaces)

		-- Ajout d'un objet à la table des surfaces
		-- Définition de la valeur des colonnes qui ont été ajoutées :
		--		La colonne id est de type serial donc pas besoin de définir la valeur
		-- 		Récupération de la valeurs d'un tag :
		--			object.tags.mon_tag = valeur du tag indiqué (le tag reste présent dans l'objet object.tags)
		--			object:grab_tag('mon_tag') = valeur du tag indiqué (le tag est supprimé de l'objet object.tags, pratique pour éviter d'avoir deux fois la donnée)
		--		Conversion de la géométrie de l'objet en MULTIPOLYGON
		var_tables.surface:insert({
			amenity = object:grab_tag('amenity'),
			building = object:grab_tag('building'),
			landuse = object:grab_tag('landuse'),
			leaf_type = object:grab_tag('leaf_type'),
			leisure = object:grab_tag('leisure'),
			name = object:grab_tag('name'),
			natural = object:grab_tag('natural'),

			tags = object.tags,

			geom = object:as_multipolygon()
		})
		return
	end

	-- Les relations de type "multipolygon" sont envoyées dans la table des surfaces
	if object.tags.type == 'multipolygon' then
		-- On créé un polygone à partir de la relation

		-- Ajout d'un objet à la table des surfaces
		-- Définition de la valeur des colonnes qui ont été ajoutées :
		--		La colonne id est de type serial donc pas besoin de définir la valeur
		-- 		Récupération de la valeurs d'un tag :
		--			object.tags.mon_tag = valeur du tag indiqué (le tag reste présent dans l'objet object.tags)
		--			object:grab_tag('mon_tag') = valeur du tag indiqué (le tag est supprimé de l'objet object.tags, pratique pour éviter d'avoir deux fois la donnée)
		--		Conversion de la géométrie de l'objet en MULTIPOLYGON
		var_tables.surface:insert({
			amenity = object:grab_tag('amenity'),
			building = object:grab_tag('building'),
			landuse = object:grab_tag('landuse'),
			leaf_type = object:grab_tag('leaf_type'),
			leisure = object:grab_tag('leisure'),
			natural = object:grab_tag('natural'),

			tags = object.tags,

			geom = object:as_multipolygon()
		})
	end
end