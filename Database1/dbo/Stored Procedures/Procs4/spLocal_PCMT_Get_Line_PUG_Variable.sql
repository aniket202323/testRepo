
----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_Line_PUG_Variable]
/*
-------------------------------------------------------------------------------------------------
											PCMT Version 2.0 (PPA 6)
-------------------------------------------------------------------------------------------------
Updated By  : Juan Pablo Galanzini - Arido Software
Date        : 2015-01-19
Version     : 2.1
Description	: 	This sp return all variables by the Line, Production Group and Variable description
Editor tab spacing: 4
-------------------------------------------------------------------------------------------------
*/
--declare
@vcrPLDesc			NVARCHAR(50),
@vcrPugDesc			NVARCHAR(50),
@vcrVarDesc			NVARCHAR(50)

AS
--SELECT @vcrPLDesc	= 'DIEU131'--, @vcrPugDesc = 'RTT EA1 Auto'
-- Test: EXEC [dbo].[spLocal_PCMT_Get_Line_PUG_Variable] 'DIEU131', 'RTT EA1 Auto High Risk', '111'

SET NOCOUNT ON

SET @vcrPLDesc 	= LTRIM(RTRIM(@vcrPLDesc))
SET @vcrPugDesc = LTRIM(RTRIM(@vcrPugDesc))
SET @vcrVarDesc = LTRIM(RTRIM(@vcrVarDesc))

IF (@vcrPLDesc<>'' AND @vcrPugDesc<>'') 
	BEGIN
		SELECT	pl.pl_id, pl.pl_desc, v.pu_id, pu.pu_desc, 
			pug.pug_id, pug.PUG_Desc, v.var_id, v.Var_Desc_Local, v.Var_Desc_Global
		FROM dbo.Prod_Lines pl
			JOIN dbo.Prod_Units pu ON (pu.pl_id = pl.pl_id)
			JOIN dbo.variables v ON (v.pu_id = pu.pu_id)
			JOIN dbo.Pu_Groups pug ON (pug.pug_id = v.pug_id)
		WHERE pl.pl_id != 0
			AND Var_Desc_Local NOT LIKE 'z_obs_%'
			AND (Var_Desc_Local LIKE '%' + @vcrVarDesc + '%' 
				OR @vcrVarDesc LIKE '')
			AND (PL.PL_Desc_Local LIKE '%' +  @vcrPLDesc + '%' 
				OR  PL.PL_Desc_Global LIKE '%' +  @vcrPLDesc + '%'
				OR  PL.PL_Desc LIKE '%' +  @vcrPLDesc + '%')
			AND (pug.pug_desc_local LIKE '%' + @vcrPugDesc + '%'
				OR	pug.pug_desc_global LIKE '%' + @vcrPugDesc + '%'
				OR	pug.pug_desc LIKE '%' + @vcrPugDesc + '%')
			ORDER BY pl.pl_desc, pu.pu_desc, pug.PUG_Desc, v.Var_Desc_Local
	END
ELSE
	BEGIN
		IF @vcrPLDesc<>'' 
			BEGIN
				SELECT	pl.pl_id, pl.pl_desc, v.pu_id, pu.pu_desc, 
					pug.pug_id, pug.PUG_Desc, v.var_id, v.Var_Desc_Local, v.Var_Desc_Global
				 FROM dbo.Prod_Lines pl
					  JOIN dbo.Prod_Units pu ON (pu.pl_id = pl.pl_id)
					  JOIN dbo.variables v ON (v.pu_id = pu.pu_id)
					  JOIN dbo.Pu_Groups pug ON (pug.pug_id = v.pug_id)
				 WHERE pl.pl_id != 0
					AND Var_Desc_Local NOT LIKE 'z_obs_%'
					AND (Var_Desc_Local LIKE '%' + @vcrVarDesc + '%' 
						OR @vcrVarDesc LIKE '')
					AND (PL.PL_Desc_Local LIKE '%' +  @vcrPLDesc + '%' 
						OR  PL.PL_Desc_Global LIKE '%' +  @vcrPLDesc + '%'
						OR  PL.PL_Desc LIKE '%' +  @vcrPLDesc + '%')
				ORDER BY pl.pl_desc, pu.pu_desc, pug.PUG_Desc, v.Var_Desc_Local
			END
		ELSE
			BEGIN
				IF @vcrPugDesc<>''
					BEGIN
						SELECT	pl.pl_id, pl.pl_desc, v.pu_id, pu.pu_desc, 
							pug.pug_id, pug.PUG_Desc, v.var_id, v.Var_Desc_Local, v.Var_Desc_Global
						FROM dbo.Prod_Lines pl
							JOIN dbo.Prod_Units pu ON (pu.pl_id = pl.pl_id)
							JOIN dbo.variables v ON (v.pu_id = pu.pu_id)
							JOIN dbo.Pu_Groups pug ON (pug.pug_id = v.pug_id)
						WHERE pl.pl_id != 0
							AND Var_Desc_Local NOT LIKE 'z_obs_%'
							AND (Var_Desc_Local LIKE '%' + @vcrVarDesc + '%' 
								OR @vcrVarDesc LIKE '')
							AND (pug.pug_desc_local LIKE '%' + @vcrPugDesc + '%'
								OR	pug.pug_desc_global LIKE '%' + @vcrPugDesc + '%'
								OR	pug.pug_desc LIKE '%' + @vcrPugDesc + '%')
						ORDER BY pl.pl_desc, pu.pu_desc, pug.PUG_Desc, v.Var_Desc_Local
					END 
				ELSE
					BEGIN
						SELECT	pl.pl_id, pl.pl_desc, v.pu_id, pu.pu_desc, 
							pug.pug_id, pug.PUG_Desc, v.var_id, v.Var_Desc_Local, v.Var_Desc_Global
						FROM dbo.Prod_Lines pl
							JOIN dbo.Prod_Units pu ON (pu.pl_id = pl.pl_id)
							JOIN dbo.variables v ON (v.pu_id = pu.pu_id)
							JOIN dbo.Pu_Groups pug ON (pug.pug_id = v.pug_id)
						WHERE pl.pl_id != 0	
							AND Var_Desc_Local NOT LIKE 'z_obs_%'
							AND (Var_Desc_Local LIKE '%' + @vcrVarDesc + '%' 
								OR @vcrVarDesc LIKE '')
						ORDER BY pl.pl_desc, pu.pu_desc, pug.PUG_Desc, v.Var_Desc_Local
					END
			END		
	END


SET NOCOUNT OFF
