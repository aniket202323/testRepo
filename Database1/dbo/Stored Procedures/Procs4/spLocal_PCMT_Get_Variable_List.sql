







-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE  PROCEDURE [dbo].[spLocal_PCMT_Get_Variable_List]
/*
-------------------------------------------------------------------------------------------------
Stored Procedure: spLocal_PCMT_Get_Variable_List

											PCMT Version 5.0.0 (P3 AND P4)
-------------------------------------------------------------------------------------------------
Author			: 	Rick Perreault, Solutions et Technologies Industrielles inc.
Date created	:	13-Nov-2002	
Version			: 	1.0.0
SP Type			:	Function
Called by		:	Excel file
Description		: 	This sp return the list of variables IN a given production group.
               	Can also be depending of sheet type ID.
               	1: Autolog Time Based
               	2: Autolog Event Based
               	11: Alarm View
						PCMT Version 2.1.0 AND 3.0.0
editor tab spacing: 3
-------------------------------------------------------------------------------------------------
Revision date who what
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2005-11-01
Version		:	1.1.0
Purpose		: 	Compliant with Proficy 3 AND 4.
					Added [dbo] template when referencing objects.
					Added registration of SP Version into AppVersions table.
					PCMT Version 5.0.3
-------------------------------------------------------------------------------------------------
Updated By	:	Alexandre Turgeon (System Technologies for Industry Inc)
Date			:	2006-05-19
Version		:	2.0.0
Purpose		: 	Also retreives user-defined variables and can filter them by event subtype
-------------------------------------------------------------------------------------------------
Updated By	:	Vincent Rouleau (System Technologies for Industry Inc)
Date			:	2007-09-26
Version		:	2.0.1
Purpose		: 	For time-based sheet, retrieve time-based variables
-------------------------------------------------------------------------------------------------
Updated By	:	Vincent Rouleau (System Technologies for Industry Inc)
Date			:	2007-10-29
Version		:	2.0.2
Purpose		: 	Ensure that Var_Desc_Global doesn't need to be present
-------------------------------------------------------------------------------------------------
Updated By	:	Vincent Rouleau (System Technologies for Industry Inc)
Date			:	2008-1-23
Version		:	2.0.3
Purpose		: 	removed contraint on data source, its not needed
-------------------------------------------------------------------------------------------------
Updated By	:	Tim Rogers (P&G)
Date			:	2008-3-05
Version		:	1.3 (new number based on serena version manager)
Purpose		: 	removed contraint on data source, its not needed for all areas
-------------------------------------------------------------------------------------------------
Updated By	:	Stephane Turner (System Technologies for Industry Inc)
Date			:	2008-05-16
Purpose		: 	Update global desc of variables when global desc is null
-------------------------------------------------------------------------------------------------
Updated By	:	Marc Charest (System Technologies for Industry Inc)
Date			:	2009-01-30
Purpose		: 	Added the following clause to shoe or not show the children variables
					depending on the selected operation:
					-- AND ((v.pvar_id IS NULL AND @intUnObs NOT IN (5,6,7)) OR (@intUnObs IN (5,6,7))) --
-------------------------------------------------------------------------------------------------
Updated By	:	Marc Charest (System Technologies for Industry Inc)
Date			:	2009-06-15 (PCMT 1.27)
Purpose		: 	New parameter (@bitGlobal) added to the SP. SP now really matter about Local/Global
					user selection.
					This is addresses ticket #25162026.
-------------------------------------------------------------------------------------------------
*/
--spLocal_PCMT_Get_Variable_List null,null,202,'',0, 0, 2
@intPlId				integer,
@intPuId				integer,
@intPugId			integer,
@vcrMask				varchar(50),
@intSheetType		integer,
@intSheetSubtype	integer = 0,
@intUnObs			INTEGER = 0,
@bitGlobal			bit = 1

AS
SET NOCOUNT ON

DECLARE @vars TABLE(var_id INT, var_desc_global VARCHAR(50), pl_desc VARCHAR(50), pu_desc VARCHAR(50), pug_desc VARCHAR(50))

IF @intSheetType NOT IN (1, 2, 11) 
BEGIN
	IF @intSheetType != 25
	BEGIN
		INSERT INTO @vars(var_id, var_desc_global, pl_desc, pu_desc, pug_desc)
		SELECT DISTINCT 
			v.var_id, 
			CASE 	WHEN @bitGlobal = 1 
				  	THEN REPLACE(REPLACE(COALESCE(v.var_desc_global, v.var_desc_local), 'z_obs_', ''), ':' + CAST(v.var_id AS VARCHAR(25)), '') 
				  	ELSE REPLACE(REPLACE(v.var_desc_local, 'z_obs_', ''), ':' + CAST(v.var_id AS VARCHAR(25)), '') 
					END AS [var_desc],
			pl.pl_desc, pu.pu_desc, pug.pug_desc
		FROM dbo.Variables v
		   JOIN dbo.Data_Source ds ON (ds.ds_id = v.ds_id)
		   JOIN dbo.Event_Types et ON (et.et_id = v.event_type)
		   JOIN dbo.Prod_Units pu ON (pu.pu_id = v.pu_id)
		   JOIN dbo.Prod_Lines pl ON (pl.pl_id = pu.pl_id)
		   JOIN dbo.PU_Groups pug ON (pug.pug_id = v.pug_id),
			dbo.Local_PG_PCMT_Edit_Queries eq --ON ((v.var_id = eq.var_id AND @intUnObs = 4) OR (@intUnObs <> 4))
		WHERE (pu.pl_id = @intPlId OR v.pu_id = @intPuId OR v.pug_id = @intPugId OR
		    ISNULL(@intPlId,0) + ISNULL(@intPuId,0) + ISNULL(@intPugId,0) = 0) AND 
		    ((COALESCE(v.var_desc_global, v.var_desc_local) NOT LIKE 'z_obs%' AND @intUnObs <> 4) OR (COALESCE(v.var_desc_global, v.var_desc_local) LIKE 'z_obs%' AND @intUnObs = 4)) AND
		    --ds.ds_desc IN ('Autolog','Base Unit','Base Variable','Historian','Undefined','CalculationMgr') AND
		    et.et_desc IN ('Time','Production Event', 'User-Defined Event') AND
		    COALESCE(v.var_desc_global, v.var_desc_local) LIKE '%' + @vcrMask + '%'
			 AND ((v.pvar_id IS NULL AND @intUnObs NOT IN (5,6,7)) OR (@intUnObs IN (5,6,7)))	--to get children
			 AND ((v.var_id = eq.var_id AND @intUnObs = 4) OR (@intUnObs <> 4))
	END
	ELSE
	BEGIN
		IF @intSheetSubtype != 0
		BEGIN
			INSERT INTO @vars(var_id, var_desc_global, pl_desc, pu_desc, pug_desc)
			SELECT DISTINCT 
				v.var_id, 
				CASE WHEN @bitGlobal = 1 THEN COALESCE(v.var_desc_global, v.var_desc_local) ELSE v.var_desc_local END AS [var_desc], 
				pl.pl_desc, pu.pu_desc, pug.pug_desc
			FROM dbo.Variables v
			   JOIN dbo.Data_Source ds ON (ds.ds_id = v.ds_id)
			   JOIN dbo.Event_Types et ON (et.et_id = v.event_type)
			   JOIN dbo.Prod_Units pu ON (pu.pu_id = v.pu_id)
			   JOIN dbo.Prod_Lines pl ON (pl.pl_id = pu.pl_id)
			   JOIN dbo.PU_Groups pug ON (pug.pug_id = v.pug_id)
			WHERE (pu.pl_id = @intPlId OR v.pu_id = @intPuId OR v.pug_id = @intPugId OR
			     ISNULL(@intPlId,0) + ISNULL(@intPuId,0) + ISNULL(@intPugId,0) = 0) AND 
			    COALESCE(v.var_desc_global, v.var_desc_local) NOT LIKE 'z_obs%' AND
			    --ds.ds_desc IN ('Autolog','Base Unit','Base Variable','Historian','Undefined','CalculationMgr') AND
			    et.et_desc IN ('User-Defined Event') AND
				 v.event_subtype_id = @intSheetSubtype AND 
			    COALESCE(v.var_desc_global, v.var_desc_local) LIKE '%' + @vcrMask + '%'
	   		 AND ((v.pvar_id IS NULL AND @intUnObs NOT IN (5,6,7)) OR (@intUnObs IN (5,6,7)))	--to get children
		END
		ELSE
		BEGIN
			INSERT INTO @vars(var_id, var_desc_global, pl_desc, pu_desc, pug_desc)
			SELECT DISTINCT 
				v.var_id, 
				CASE WHEN @bitGlobal = 1 THEN COALESCE(v.var_desc_global, v.var_desc_local) ELSE v.var_desc_local END AS [var_desc],  
				pl.pl_desc, pu.pu_desc, pug.pug_desc
			FROM dbo.Variables v
			   JOIN dbo.Data_Source ds ON (ds.ds_id = v.ds_id)
			   JOIN dbo.Event_Types et ON (et.et_id = v.event_type)
			   JOIN dbo.Prod_Units pu ON (pu.pu_id = v.pu_id)
			   JOIN dbo.Prod_Lines pl ON (pl.pl_id = pu.pl_id)
			   JOIN dbo.PU_Groups pug ON (pug.pug_id = v.pug_id)
			WHERE (pu.pl_id = @intPlId OR v.pu_id = @intPuId OR v.pug_id = @intPugId OR
			     ISNULL(@intPlId,0) + ISNULL(@intPuId,0) + ISNULL(@intPugId,0) = 0) AND 
			    COALESCE(v.var_desc_global, v.var_desc_local) NOT LIKE 'z_obs%' AND
			    --ds.ds_desc IN ('Autolog','Base Unit','Base Variable','Historian','Undefined','CalculationMgr') AND
			    et.et_desc IN ('User-Defined Event') AND
			    COALESCE(v.var_desc_global, v.var_desc_local) LIKE '%' + @vcrMask + '%'
	   		 AND ((v.pvar_id IS NULL AND @intUnObs NOT IN (5,6,7)) OR (@intUnObs IN (5,6,7)))	--to get children
		END
	END
END
ELSE 
BEGIN
	IF @intSheetType = 11
	BEGIN
		INSERT INTO @vars(var_id, var_desc_global, pl_desc, pu_desc, pug_desc)
		SELECT DISTINCT 
			v.var_id, 
			CASE WHEN @bitGlobal = 1 THEN COALESCE(v.var_desc_global, v.var_desc_local) ELSE v.var_desc_local END AS [var_desc],
			pl.pl_desc, pu.pu_desc, pug.pug_desc
		FROM dbo.Variables v
		     JOIN dbo.Alarm_Template_Var_Data atd ON (atd.var_id = v.var_id)
		     JOIN dbo.Data_Source ds ON (ds.ds_id = v.ds_id)
		     JOIN dbo.Event_Types et ON (et.et_id = v.event_type)
		     JOIN dbo.Prod_Units pu ON (pu.pu_id = v.pu_id)
		     JOIN dbo.Prod_Lines pl ON (pl.pl_id = pu.pl_id)
		     JOIN dbo.PU_Groups pug ON (pug.pug_id = v.pug_id)
		WHERE (pu.pl_id = @intPlId OR v.pu_id = @intPuId OR v.pug_id = @intPugId OR
		       ISNULL(@intPlId,0) + ISNULL(@intPuId,0) + ISNULL(@intPugId,0) = 0) AND 
		      COALESCE(v.var_desc_global, v.var_desc_local) NOT LIKE 'z_obs%' AND
		     --ds.ds_desc IN ('Autolog','Base Unit','Base Variable','Historian','Undefined','CalculationMgr') AND
		      et.et_desc IN ('Time','Production Event', 'User-Defined Event') AND
		      COALESCE(v.var_desc_global, v.var_desc_local) LIKE '%' + @vcrMask + '%'
   			AND ((v.pvar_id IS NULL AND @intUnObs NOT IN (5,6,7)) OR (@intUnObs IN (5,6,7)))	--to get children
	END
	ELSE    
	BEGIN
		INSERT INTO @vars(var_id, var_desc_global, pl_desc, pu_desc, pug_desc)
		SELECT 
			v.var_id, 
			CASE WHEN @bitGlobal = 1 THEN COALESCE(v.var_desc_global, v.var_desc_local) ELSE v.var_desc_local END AS [var_desc],	
			pl.pl_desc, pu.pu_desc, pug.pug_desc
		FROM dbo.Variables v
		     JOIN dbo.Data_Source ds ON (ds.ds_id = v.ds_id)
		     JOIN dbo.Event_Types et ON (et.et_id = v.event_type)
		     JOIN dbo.Prod_Units pu ON (pu.pu_id = v.pu_id)
		     JOIN dbo.Prod_Lines pl ON (pl.pl_id = pu.pl_id)
		     JOIN dbo.PU_Groups pug ON (pug.pug_id = v.pug_id)
		WHERE (pu.pl_id = @intPlId OR v.pu_id = @intPuId OR v.pug_id = @intPugId OR
		       ISNULL(@intPlId,0) + ISNULL(@intPuId,0) + ISNULL(@intPugId,0) = 0) AND 
		      COALESCE(v.var_desc_global, v.var_desc_local) NOT LIKE 'z_obs%' AND
		      --ds.ds_desc IN ('Autolog','Base Unit','Base Variable','Historian','Undefined','CalculationMgr') AND
		      et.et_desc = CASE 
		                     WHEN @intSheetType = 1 THEN 'Time'
		                     ELSE 'Production Event'
		                   END AND
		      COALESCE(v.var_desc_global, v.var_desc_local) LIKE '%' + @vcrMask + '%'
				AND ((v.pvar_id IS NULL AND @intUnObs NOT IN (5,6,7)) OR (@intUnObs IN (5,6,7)))	--to get children
	END
END

UPDATE dbo.variables 
	SET var_desc_global = var_desc_local
	WHERE var_desc_global IS NULL AND var_id IN(SELECT var_id FROM @vars)

SELECT var_id, var_desc_global, pl_desc, pu_desc, pug_desc
	FROM @vars
	ORDER BY var_desc_global



SET NOCOUNT OFF
