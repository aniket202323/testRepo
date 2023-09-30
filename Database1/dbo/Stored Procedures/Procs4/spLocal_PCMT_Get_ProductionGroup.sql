












-------------------------------------------------------------------------------------------------
	
	----------------------------------------[Creation Of SP]-----------------------------------------
	CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_ProductionGroup]
	/*
	-------------------------------------------------------------------------------------------------
												PCMT Version 5.1.1
	-------------------------------------------------------------------------------------------------
	Updated By	:	Vincent Rouleau (System Technologies for Industry Inc)
	Date			:	2007-09-04
	Version		:	2.1.0
	Purpose		: 	Fix a bug.  Unit id was compared to group id
	-------------------------------------------------------------------------------------------------
	Updated By	:	Alexandre Turgeon (System Technologies for Industry Inc)
	Date			:	2006-05-17
	Version		:	2.0.0
	Purpose		: 	Now retreives production groups from a specific production unit
	-------------------------------------------------------------------------------------------------
	Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
	Date			:	2005-11-01
	Version		:	1.1.0
	Purpose		: 	Compliant with Proficy 3 and 4.
						Added [dbo] template when referencing objects.
						Added registration of SP Version into AppVersions table.
						PCMT Version 5.0.3
	-------------------------------------------------------------------------------------------------
	Created by	: 	Rick Perreault, Solutions et Technologies Industrielles inc.
	On				:	13-Nov-2002	
	Version		: 	1.0.0
	Purpose		: 	This sp return the production group for PCMT.
						PCMT Version 2.1.0 and 3.0.0
	-------------------------------------------------------------------------------------------------
	*/	
	@PUDesc				varchar(50),
	@txtUserId			INTEGER

	AS

	SET NOCOUNT ON

	DECLARE
	@intUserId			INTEGER

	SET @intUserId		= @txtUserId

	--Getting objects IDs on which user as sufficient rights.
	CREATE TABLE #PCMTPUIDs(Item_Id INTEGER)
	INSERT #PCMTPUIDs (Item_Id)
	EXECUTE spLocal_PCMT_GetObjectIDs 'pu_groups', 'pug_id', @intUserId
	
	--Get the translate item value
	SELECT DISTINCT pug_desc
	FROM dbo.PU_Groups pug
		JOIN dbo.Prod_Units pu ON (pug.pu_id = pu.pu_id)
		JOIN dbo.prod_lines pl ON (pu.pl_id = pl.pl_id),
		#PCMTPUIDs pu2
	WHERE 
			--pu_desc = RTRIM(LTRIM(REPLACE(REPLACE(pu_desc, pl.pl_desc, ''), '  ', ' ')))
			pu_desc LIKE '%' + @PUDesc + '%'
			AND pug.pug_id = pu2.item_id

	
	SET NOCOUNT OFF
	
	
	
	
	
	














