
----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_Line_Variable]
/*
-------------------------------------------------------------------------------------------------
Stored Procedure: spLocal_PCMT_Get_Line_Variable

											PCMT Version 5.0.0 (P3 and P4)
-------------------------------------------------------------------------------------------------
Author			: 	Rick Perreault, Solutions et Technologies Industrielles inc.
Date ALTERd	:	13-Nov-2002	
Version			: 	1.0.0
SP Type			:	Function
Called by		:	Excel file
Description		: 	This sp return the line plus the pu_id, pug_id and var_id that have a 
               	given production group and variable. If it is an add variable, it return 
               	only the line that do not have the varaible name we are about to add. 
               	If it is an edit variable, it return only the line that have the 
               	variable name we are about ot edit
						PCMT Version 2.1.0 and 3.0.0
Editor tab spacing: 3
-------------------------------------------------------------------------------------------------
Revision date who what
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2005-10-31
Version		:	1.1.0
Purpose		: 	Compliant with Proficy 3 and 4.
					Added [dbo] template when referencing objects.
					Added registration of SP Version into AppVersions table.
					PCMT Version 5.0.3
-------------------------------------------------------------------------------------------------
Updated By	:	Alexandre Turgeon (System Technologies for Industry Inc)
Date			:	2006-05-17
Version		:	2.0.0
Purpose		: 	Now also uses the unit desc as an input
-------------------------------------------------------------------------------------------------
Updated By  : Jonathan Corriveau (STI)
Date        : 2008-10-31
Version     : 2.1.0
Purpose     : [spLocal_PCMT_Get_Line_Variable]
    Replace : SELECT DISTINCT pl.pl_id, NULL, @vcrPuDesc, NULL, pl.pl_desc ...
  	 By      : SELECT DISTINCT pl.pl_id, NULL, pu.pu_desc, NULL, pl.pl_desc ...
-------------------------------------------------------------------------------------------------
Updated By  : Jonathan Corriveau (STI)
Date        : 2008-10-31
Version     : 2.1.1
Purpose     : [spLocal_PCMT_Get_Line_Variable]
    Replace : SELECT pl.pl_id, pu.pu_id, @vcrPuDesc, null, v.var_id, ...
  	 By      : SELECT pl.pl_id, pu.pu_id, pu.pu_desc, null, v.var_id, ...
-------------------------------------------------------------------------------------------------
Updated By  : Jonathan Corriveau (STI)
Date        : 2008-11-03
Version     : 2.1.2
Purpose     : [spLocal_PCMT_Get_Line_Variable]
    Replace : ... pl.pl_id NOT IN (SELECT DISTINCT pl.pl_id
								  FROM dbo.prod_lines pl
									 LEFT JOIN dbo.prod_units pu ON pu.pl_id = pl.pl_id
									 LEFT JOIN dbo.variables v ON v.pu_id = pu.pu_id
								  WHERE v.var_desc_global = @vcrVarDesc) AND ...
  	 By      : ... pu.pu_id NOT IN (SELECT DISTINCT pu.pu_id
							from dbo.prod_units pu 
									 LEFT JOIN dbo.variables v ON v.pu_id = pu.pu_id
								  WHERE v.var_desc = @vcrVarDesc) AND ...
-------------------------------------------------------------------------------------------------
Updated By  : Alberto Ledesma - Arido Software
Date        : 2010-11-04
Version     : 
Purpose     : The SP was modified to work with the search that is performed 
				when editing variables with the same name and are on different lines.    

*/

@vcrPuDesc			varchar(50),
@vcrPugDesc			varchar(50),
@vcrVarDesc			varchar(50),
@intType			integer,  --1 : Add variable, 2: Edit Variable
@intUserId			INTEGER,
@intLineSpecific	BIT=0

AS

SET NOCOUNT ON

SET @vcrPuDesc 	= LTRIM(RTRIM(@vcrPuDesc))
SET @vcrPuDesc 	= ISNULL(@vcrPuDesc,'-1')

SET @vcrPugDesc 	= LTRIM(RTRIM(@vcrPugDesc))
SET @vcrPugDesc 	= ISNULL(@vcrPugDesc,'-1')

--Getting objects IDs on which user as sufficient rights.
CREATE TABLE #PCMTPLIDs(Item_Id INTEGER)
INSERT #PCMTPLIDs (Item_Id)
EXECUTE spLocal_PCMT_GetObjectIDs 'prod_lines', 'pl_id', @intUserId


IF @intType = 1
	BEGIN
		-- verify if the production group exists on the unit
		SELECT DISTINCT pl.pl_id, NULL, pu.pu_desc, NULL, pl.pl_desc
		FROM dbo.Prod_Lines pl
		   JOIN dbo.Prod_Units pu ON (pu.pl_id = pl.pl_id),
			#PCMTPLIDs pl2
		WHERE
				pu.pu_id NOT IN (SELECT DISTINCT pu.pu_id
								from dbo.prod_units pu 
										 LEFT JOIN dbo.variables v ON v.pu_id = pu.pu_id
									  WHERE v.var_desc = @vcrVarDesc) AND
				pl.pl_id IN (SELECT DISTINCT pl.pl_id
									  FROM dbo.prod_lines pl
										 LEFT JOIN dbo.prod_units pu ON pu.pl_id = pl.pl_id
										 LEFT JOIN dbo.variables v ON v.pu_id = pu.pu_id
									  WHERE @vcrPuDesc = RTRIM(LTRIM(REPLACE(REPLACE(pu.pu_desc, pl.pl_desc, ''), '  ', ' ')))
											  AND ((LEN(pu.pu_desc) > LEN(@vcrPuDesc) AND @intLineSpecific = 1) OR (LEN(pu.pu_desc) = LEN(@vcrPuDesc) AND @intLineSpecific = 0)))
				AND pl.pl_id != 0
			AND pl.pl_id = pl2.Item_Id
		ORDER BY pl.pl_desc
	END
ELSE
	BEGIN
		IF (@vcrPuDesc<>'' AND @vcrPugDesc<>'') 
			BEGIN
				SELECT	pl.pl_id, pu.pu_id, pu.pu_desc, null, v.var_id, 
						bvpl.pl_desc + '\' + bvpu.pu_desc + '\' + bvpug.pug_desc + '\' + v.var_desc_global AS base_var_desc,				  
						v.input_tag, v.output_tag, pl.pl_desc, v.dq_tag
				FROM dbo.Prod_Lines pl
					JOIN dbo.Prod_Units pu ON (pu.pl_id = pl.pl_id)
					JOIN dbo.variables v ON (v.pu_id = pu.pu_id)
					LEFT JOIN dbo.Pu_Groups pug ON (pug.pug_id = v.pug_id)
					LEFT JOIN dbo.pu_groups bvpug ON (bvpug.pug_id = v.pug_id)
					LEFT JOIN dbo.prod_units bvpu ON (bvpu.pu_id = v.pu_id)
					LEFT JOIN dbo.prod_lines bvpl ON (bvpl.pl_id = bvpu.pl_id)     
				WHERE (v.var_desc_global = @vcrVarDesc OR v.var_desc_local = @vcrVarDesc) AND pl.pl_id != 0
					AND (		bvpu.pu_desc_local like '%' +  @vcrPuDesc + '%' 
							OR  bvpu.pu_desc_global like '%' +  @vcrPuDesc + '%'
							OR	bvpug.pug_desc_local like '%' + @vcrPugDesc + '%'
							OR	bvpug.pug_desc_global like '%' + @vcrPugDesc + '%')
				ORDER BY pl.pl_desc
			END
		ELSE
			BEGIN
				IF @vcrPuDesc<>'' 
					BEGIN
						 SELECT pl.pl_id, pu.pu_id, pu.pu_desc, null, v.var_id, 
								bvpl.pl_desc + '\' + bvpu.pu_desc + '\' + bvpug.pug_desc + '\' + v.var_desc_global AS base_var_desc,		
								v.input_tag, v.output_tag, pl.pl_desc, v.dq_tag
						 FROM dbo.Prod_Lines pl
							  JOIN dbo.Prod_Units pu ON (pu.pl_id = pl.pl_id)
							  JOIN dbo.variables v ON (v.pu_id = pu.pu_id)
							  LEFT JOIN dbo.Pu_Groups pug ON (pug.pug_id = v.pug_id)
							  LEFT JOIN dbo.pu_groups bvpug ON (bvpug.pug_id = v.pug_id)
							  LEFT JOIN dbo.prod_units bvpu ON (bvpu.pu_id = v.pu_id)
							  LEFT JOIN dbo.prod_lines bvpl ON (bvpl.pl_id = bvpu.pl_id)     
						 WHERE (v.var_desc_global = @vcrVarDesc OR v.var_desc_local = @vcrVarDesc) AND pl.pl_id != 0
								and (		bvpu.pu_desc_local like '%' + @vcrPuDesc + '%'
										OR	bvpu.pu_desc_global like '%' + @vcrPuDesc + '%')				 
						 ORDER BY pl.pl_desc
					END
				ELSE
					BEGIN
						IF @vcrPugDesc<>''
							BEGIN
								SELECT pl.pl_id, pu.pu_id, pu.pu_desc, null, v.var_id, 
										bvpl.pl_desc + '\' + bvpu.pu_desc + '\' + bvpug.pug_desc + '\' + v.var_desc_global AS base_var_desc,		
										v.input_tag, v.output_tag, pl.pl_desc, v.dq_tag
								FROM dbo.Prod_Lines pl
									JOIN dbo.Prod_Units pu ON (pu.pl_id = pl.pl_id)
									JOIN dbo.variables v ON (v.pu_id = pu.pu_id)
									LEFT JOIN dbo.Pu_Groups pug ON (pug.pug_id = v.pug_id)
									LEFT JOIN dbo.pu_groups bvpug ON (bvpug.pug_id = v.pug_id)
									LEFT JOIN	dbo.prod_units bvpu ON (bvpu.pu_id = v.pu_id)
									LEFT JOIN dbo.prod_lines bvpl ON (bvpl.pl_id = bvpu.pl_id)     
								WHERE (v.var_desc_global = @vcrVarDesc OR v.var_desc_local = @vcrVarDesc) AND pl.pl_id != 0
										and (		bvpug.pug_desc_local like '%' + @vcrPugDesc + '%' 
												OR	bvpug.pug_desc_global like '%' + @vcrPugDesc + '%'
												OR	bvpug.pug_desc like '%' + @vcrPugDesc + '%' )
	 							ORDER BY pl.pl_desc
							END 
						ELSE
							BEGIN
								SELECT pl.pl_id, pu.pu_id, pu.pu_desc, null, v.var_id, 
										bvpl.pl_desc + '\' + bvpu.pu_desc + '\' + bvpug.pug_desc + '\' + v.var_desc_global AS base_var_desc,		
										v.input_tag, v.output_tag, pl.pl_desc, v.dq_tag
								FROM dbo.Prod_Lines pl
									JOIN dbo.Prod_Units pu ON (pu.pl_id = pl.pl_id)
									JOIN dbo.variables v ON (v.pu_id = pu.pu_id)
									LEFT JOIN dbo.Pu_Groups pug ON (pug.pug_id = v.pug_id)
									LEFT JOIN dbo.pu_groups bvpug ON (bvpug.pug_id = v.pug_id)
									LEFT JOIN dbo.prod_units bvpu ON (bvpu.pu_id = v.pu_id)
									LEFT JOIN dbo.prod_lines bvpl ON (bvpl.pl_id = bvpu.pl_id)     
								WHERE (v.var_desc_global = @vcrVarDesc OR v.var_desc_local = @vcrVarDesc) AND pl.pl_id != 0							
								ORDER BY pl.pl_desc
							END
					END		
			END
	END

DROP TABLE #PCMTPLIDs

SET NOCOUNT OFF



