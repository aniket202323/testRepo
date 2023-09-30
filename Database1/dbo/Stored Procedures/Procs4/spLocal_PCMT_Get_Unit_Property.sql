
-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_Unit_Property]
/*
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2006-01-05
Version		:	2.1.0
Purpose		: 	Compliant with Proficy 3 and 4.
					Added [dbo] template when referencing objects.
					Added registration of SP Version into AppVersions table.
					Replaced #UnitProperty and #UnitPropertyMult temp tables by
					@UnitProperty and @UnitPropertyMult TABLE variables.
					Deleted property_cursor cursor no longer required. (Use Identity column).
					QSMT Version 10.0.0
-------------------------------------------------------------------------------------------------
Modified by	: 	Marc Charest, Solutions et Technologies Industrielles inc.
On				:	06-Jan-2004
Version		: 	2.0.1
Purpose		:	The prod line description is no more added to the property name 
					within [Property] field into #UnitProperty table.
-------------------------------------------------------------------------------------------------
Modified by	: 	Clement Morin, Solutions et Technologies Industrielles inc.
On				:	07-Jul-2003
Version		: 	2.0.0
Purpose		:	Make the single line or multi line edit possible
-------------------------------------------------------------------------------------------------
Created by	: 	Rick Perreault, Solutions et Technologies Industrielles inc.
On				:	24-Feb-2003
Version		: 	1.0.0
Purpose		: 	Return the list of properties for a given unit name
-------------------------------------------------------------------------------------------------
TEST CODE :
exec spLocal_PCMT_Get_Unit_Property 'RTT','DIMR005[REC]DIMR007[REC]',NULL,2
-------------------------------------------------------------------------------------------------
*/
@intUserId		INTEGER,
@vcrUnit		varchar(50),
@vcrLineList	varchar(4096),
@intProdId		INT = NULL,
@intSingleLine	INT = NULL

AS

SET NOCOUNT ON

Declare
@intEndPos		INT,				--2.0.0		--ending position within @vcrLineList
@intBegPos		INT,				--2.0.0		--starting position within @vcrLineList
@vcrLineDesc	varchar(100),  --2.0.0		--Found description within @vcrLineList
@vcrLineIN		varchar(4096),	--3.0.0
@intQtee			INT,				--3.0.0
@vcrProperty	varchar(100),	--3.0.0
@intposition 	INT,				--3.0.0
@RowNum			INT,
@NbrRows			INT,
@PL_Desc			varchar(50)

DECLARE @UnitProperty TABLE
(
PKey					INT IDENTITY(1,1),
[Prop. Id]			INT,
[Property]			varchar(100),
[Char. Id]			integer,
[Characteristic]	varchar(100),
[PU_Id]				INT
)

DECLARE @UnitPropertyMult TABLE
(
[Property]			varchar(100),
[Characteristic]	varchar(100)
)

DECLARE @LinesList TABLE
(
PL_Desc	varchar(50)
)

--Security Utilization
CREATE TABLE #PCMTPPIDs(Item_Id INTEGER)
INSERT #PCMTPPIDs (Item_Id)
EXECUTE spLocal_PCMT_GetObjectIDs 'product_properties', 'prop_id', @intUserId

IF @intProdId IS NULL
	BEGIN
		IF @intSingleLine = 1
			BEGIN
				-- select all the properties for a new products for a single unit
				INSERT INTO @UnitProperty([Prop. Id],[Property],PU_ID)
					SELECT DISTINCT	pp.prop_id, pp.prop_desc,pu.PU_ID
					FROM					dbo.Product_Properties pp,
											dbo.Prod_Units pu, #PCMTPPIDs pp2
					WHERE					pu.pu_desc = @vcrUnit
											AND pp.prop_id = pp2.item_id
					--AND					pp.prop_desc <> 'RE_Product Information'
			END
		ELSE
			BEGIN
				-- select all the properties for multiple lines new product
				INSERT INTO @UnitProperty([Prop. Id],[Property],PU_ID)
					SELECT DISTINCT	pp.prop_id, pp.prop_desc,pu.PU_ID
					FROM					dbo.Product_Properties pp,
											dbo.Prod_Units pu, #PCMTPPIDs pp2
					WHERE					pu.pu_desc LIKE '% ' + @vcrUnit
											AND pp.prop_id = pp2.item_id

					--AND					pp.prop_desc <> 'RE_Product Information'
			END
			
	/* 2.0.0
	  insert into #UnitProperty ([Prop. Id],[Property],[Char. Id],[Characteristic],PU_ID)
	  SELECT DISTINCT [Prop. Id] = pp.prop_id, [Property] = pp.prop_desc, [Char. Id] = 0, [Characteristic] = '',pu.PU_ID
	  FROM Prod_Units pu
	       left join PU_Characteristics puc on (pu.pu_id = puc.pu_id)
	       join Product_Properties pp on (pp.prop_id = puc.prop_id)
	  WHERE pu.pu_desc like '%' + @vcrUnit and pp.prop_desc <> 'RE_Product Information'
	  ORDER BY pp.prop_desc
	*/
	
	END
ELSE
	BEGIN
		IF @intSingleLine = 1
			BEGIN
				-- return all the properties with caracteristics selected for a single unit
				INSERT INTO @UnitProperty([Prop. Id],[Property],PU_ID)
				--2.0.1			SELECT DISTINCT pp.prop_id, pp.prop_desc + ' ' + PL.PL_Desc as prop,pu.PU_ID
					SELECT DISTINCT	pp.prop_id, pp.prop_desc AS prop,pu.PU_ID
					FROM					dbo.Product_Properties pp, #PCMTPPIDs pp2,
											dbo.Prod_Units pu
					JOIN					dbo.Prod_Lines PL ON (PL.PL_Id = PU.PL_Id) 
					WHERE					pu.pu_desc = @vcrUnit
											AND pp.prop_id = pp2.item_id
					--AND					pp.prop_desc <> 'RE_Product Information'
		
				UPDATE	@UnitProperty SET [Char. Id] = C.Char_Id,[Characteristic] = C.Char_Desc
				FROM		dbo.PU_Characteristics puc
				JOIN		dbo.Characteristics C ON (c.Char_Id = PUC.Char_Id)
				JOIN		@UnitProperty up ON UP.[Prop. Id] = puc.Prop_Id
				WHERE		PUC.Prod_Id = @intProdId
				AND		up.pu_id = puc.PU_Id
			END
		ELSE
			BEGIN
				-- return all the properties with caracteristics selected for a Multiple unit
				INSERT INTO @UnitProperty([Prop. Id],[Property],PU_ID)
					SELECT DISTINCT	pp.prop_id, pp.prop_desc AS prop,pu.PU_ID
					FROM					dbo.Product_Properties pp,
											dbo.Prod_Units pu, #PCMTPPIDs pp2
					WHERE					pu.pu_desc LIKE '% ' + @vcrUnit
											AND pp.prop_id = pp2.item_id
					--AND					pp.prop_desc <> 'RE_Product Information'
	

				UPDATE	@UnitProperty 
				SET		[Char. Id] =	CASE WHEN CHARINDEX(PL_Desc,C.Char_Desc)-1 < 1
													THEN -1
													ELSE -2
												END,
												[Characteristic]= LEFT(C.Char_Desc, CASE WHEN CHARINDEX(PL_Desc,C.Char_Desc)-1 < 1 
																									THEN	LEN(C.Char_Desc)
																									ELSE	CHARINDEX(PL_Desc,C.Char_Desc)-2 
																								END) 
				FROM		dbo.PU_Characteristics puc
				JOIN		dbo.Characteristics C ON (c.Char_Id = PUC.Char_Id)
				JOIN		@UnitProperty up ON UP.[Prop. Id] = puc.Prop_Id
				JOIN		dbo.Prod_Units PU ON up.PU_Id = PU.PU_id 
				JOIN		dbo.Prod_Lines PL ON PL.PL_Id = PU.PL_ID
				WHERE		PUC.Prod_Id = @intProdId
				AND		up.pu_id = puc.PU_Id
				AND		up.[Prop. Id] = PUC.Prop_Id

			END

	/* 2.0.0
		insert into #UnitProperty ([Prop. Id],[Property],[Char. Id],[Characteristic],PU_ID)
		SELECT DISTINCT [Prop. Id] = pp.prop_id, [Property] = pp.prop_desc, [Char. Id] =c.char_id, [Characteristic] = c.char_desc,pu.PU_ID
		FROM Prod_Units pu
			left join PU_Characteristics puc on (puc.pu_id = pu.pu_id and puc.prod_id = @intProdId)
			join Product_Properties pp on (pp.prop_id = puc.prop_id)
			join Characteristics c on (c.char_id = puc.char_id) 
		WHERE pu.pu_desc like '%' + @vcrUnit and pp.prop_desc <> 'RE_Product Information'
		ORDER BY pp.prop_desc 
	*/
	
	END

-- Delete the data from line not selected in configuration 2.0.0
SET @intBegPos = 1
SET  @vcrLineIN = ' '

WHILE @intBegPos <= LEN(@vcrLineList)
	BEGIN
		SET @intEndPos = CHARINDEX('[REC]', @vcrLineList, @intBegPos)
		SET @vcrLineDesc = SUBSTRING(@vcrLineList, @intBegPos, @intEndPos - @intBegPos)
		SET @vcrLineIN = @vcrLineIN + @vcrLineDesc + ''','''
		SET @intBegPos = @intEndPos + 5
	END
	
SET @vcrLineIN = SUBSTRING(@vcrLineIN,2,LEN(@vcrLineIN) -4 )

-- Added v2.1.0 to eliminate scripting (because scripting is not possible with TABLE variable)
SET @intBegPos = 1
WHILE @intBegPos <= LEN(@vcrLineList)
	BEGIN
		SET @intEndPos = CHARINDEX('[REC]', @vcrLineList, @intBegPos)
		SET @PL_Desc = SUBSTRING(@vcrLineList, @intBegPos, @intEndPos - @intBegPos)
		  
		INSERT @LinesList (PL_Desc) VALUES(@PL_Desc)		
		
		SET @intBegPos = @intEndPos + 5 
	END

DELETE	@UnitProperty
FROM		@UnitProperty up
JOIN		dbo.Prod_Units pu ON (up.PU_Id = pu.pu_id)
JOIN		dbo.Prod_Lines PL ON (pl.Pl_Id=pu.pl_Id)
WHERE		PL_Desc NOT IN (SELECT PL_Desc FROM @LinesList)

UPDATE @UnitProperty SET [Char. Id] = 0 WHERE [Char. Id] IS NULL
UPDATE @UnitProperty SET [Characteristic] = ' ' WHERE [Characteristic] IS NULL

-- Delete characteristics that not have the right format
-- to be configured on the multi line edit
IF @intSingleLine = 2
	BEGIN
		INSERT INTO @UnitPropertyMult ([Property],[Characteristic])
			SELECT DISTINCT	[Property],[Characteristic]
			FROM					@UnitProperty 

		-- Initialize loop variables
		SET @NbrRows = (SELECT COUNT(PKey) FROM @UnitProperty)
		SET @RowNUm = 1
		
		WHILE @RowNUm <= @NbrRows
			BEGIN
				SET @vcrProperty = (SELECT [Property] FROM @UnitProperty WHERE PKey = @RowNum)
				
				SET @intQtee = (SELECT COUNT([Property]) FROM @UnitPropertyMult WHERE [Property] = @vcrProperty)
				
				IF @intQtee > 1
					BEGIN
						UPDATE	@UnitProperty
						SET		[Char. Id] = 0 ,
									[Characteristic] = ''
						WHERE		[Property] = @vcrProperty
						--and  [Char. Id] <> (select max([Char. Id]) from #UnitProperty where [Property] = @vcrProperty)
					END
			   
				SET @RowNum = @RowNum + 1
			END
	END


-- Return the information 
IF @intSingleLine = 2 BEGIN
	SELECT DISTINCT	[Prop. Id],[Property],[Char. Id], '', [Characteristic]
	FROM					@UnitProperty
	WHERE
		(
		[Property] NOT IN (SELECT A.[Property] FROM
									(
									SELECT [Property], COUNT(DISTINCT [Char. Id]) AS [Char. Id]
									FROM					@UnitProperty
									GROUP BY 			[Property] HAVING COUNT(DISTINCT [Char. Id]) > 1) A)
		AND [Char. Id] < 0
		)
		OR [Char. Id] = 0
	ORDER BY				[Property] END
ELSE BEGIN
	SELECT DISTINCT	[Prop. Id],[Property],[Char. Id], '', [Characteristic]
	FROM					@UnitProperty
	ORDER BY				[Property]
END

DROP TABLE #PCMTPPIDs
	 
SET NOCOUNT OFF



















