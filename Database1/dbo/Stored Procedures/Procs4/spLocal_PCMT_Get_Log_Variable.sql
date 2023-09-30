













-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_Log_Variable]
  
/*
-------------------------------------------------------------------------------------------------
											PCMT Version 5.1.1
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2005-10-31
Version		:	1.1.0
Purpose		: 	Compliant with Proficy 3 and 4.
					Added [dbo] template when referencing objects.
					Added registration of SP Version into AppVersions table.
					Replaced #Users temp table by @Users table variable
					Replaced #Variables temp table by @Variables table variable
					PCMT Version 5.0.3
-------------------------------------------------------------------------------------------------
Created By	:	Rick Perreailt, Solutions et Technologies Industrielles Inc.
On				:	19-Dec-02	
Version		:	1.0.0
Purpose		:	This SP gets variables logs from Local_PG_PCMT_log_variables
					PCMT Version 2.1.0 and 3.0.0
-------------------------------------------------------------------------------------------------
*/


@dtmStartTime	datetime = NULL,
@dtmEndTime		datetime = NULL,
@intUserId		integer = NULL,
@intVarId		integer = NULL

AS
SET NOCOUNT ON

DECLARE @Users TABLE
(
[user_id]	INTEGER
)

DECLARE @Variables TABLE
(
Var_Id	INTEGER
)

--If user is not specified, then look for all users
IF @intUserId IS NULL
  INSERT @Users ([user_id])
  SELECT DISTINCT [user_id]
  FROM dbo.Local_PG_PCMT_Log_Variables
ELSE
  INSERT @Users ([user_id]) VALUES(@intUserId)

--If variable is not specified, then look for all variables
IF @intVarId IS NULL
  INSERT @Variables (Var_Id)
  SELECT DISTINCT var_id
  FROM dbo.Local_PG_PCMT_Log_Variables
ELSE
  INSERT @Variables (Var_Id) VALUES(@intVarId)


SELECT	CONVERT(VARCHAR,lv.[timestamp],120) AS [Entry On], 
	u.username AS [User], 
	Type, 
	pl.pl_desc AS Line,
	pu.pu_desc AS Unit,
        lv.var_id AS [Variable Id],
	lv.var_desc AS [Variable Name],
	lv.pug_desc AS [Production Group],
        et.et_desc AS [Event Type],
	ds.ds_desc AS [Data Source],
	lv.eng_units AS [Eng. Units],
        st.st_desc AS [Sampling Type],
        v.var_desc AS [Base Variable],
	dt.data_type_desc AS [Data Type],
	lv.var_precision AS [Precision],
 	[Test Frequency] = CASE lv.event_type
			     WHEN 1 THEN lv.sampling_interval
			     ELSE NULL
 			   END,
 	[Sampling Interval] = CASE lv.event_type
				WHEN 0 THEN lv.sampling_interval
				ELSE NULL
 			      END,
 	[Sampling Offset] = CASE lv.event_type
			      WHEN 0 THEN lv.sampling_offset
			      ELSE NULL
 			    END,
	[Repeating Value] = CASE lv.repeating
			      WHEN 1 THEN 'TRUE'
			      WHEN 0 THEN 'FALSE'
			    END,
	lv.repeat_backtime AS [Repeating Max Win.],
	pp.prop_desc + '\' + s.spec_desc AS [Property\Specification],
	sa.sa_desc AS [Spec. Activation],
        lv.extended_info AS [Extended Info],
        c.calculation_desc AS Calculation,
	lv.Input_Tag AS [Input Tag],
	lv.Output_Tag AS [Output Tag],
        lv.External_Link AS [External Link],
	t.at_desc AS [Alarm Template],
        ald.sheet_desc AS [Alarm Display],
        aud.sheet_desc AS [Autolog Display],
	autolog_display_order AS [Autolog Display Order]
FROM	dbo.Local_PG_PCMT_Log_Variables lv
	LEFT JOIN dbo.Users u		ON (u.[user_id] = lv.[user_id])
	LEFT JOIN dbo.Prod_Units pu 	ON (pu.pu_id = lv.pu_id)
	LEFT JOIN dbo.Prod_Lines pl 	ON (pl.pl_id = pu.pl_id)
	LEFT JOIN dbo.Data_Source ds 	ON (ds.ds_id = lv.ds_id)
	LEFT JOIN dbo.Event_Types et	ON (et.et_id = lv.event_type)
	LEFT JOIN dbo.Data_Type dt		ON (dt.data_type_id = lv.data_type_id)
	LEFT JOIN dbo.Variables v		ON (v.var_id = lv.base_var_id)
	LEFT JOIN dbo.Specifications s	ON (s.spec_id = lv.spec_id)
	LEFT JOIN dbo.Product_Properties pp ON (pp.prop_id = s.prop_id)
	LEFT JOIN dbo.Spec_Activations sa	ON (sa.sa_id = lv.sa_id)
   LEFT JOIN dbo.Calculations c	ON (c.calculation_id = lv.calculation_id)
	LEFT JOIN dbo.Alarm_Templates t	ON (t.at_id = lv.alarm_template_id)
	LEFT JOIN dbo.Sheets ald		ON (ald.sheet_id = lv.alarm_display_id)
	LEFT JOIN dbo.Sheets aud		ON (aud.sheet_id = lv.autolog_display_id)
   LEFT JOIN dbo.Sampling_Type st	ON (st.st_id = lv.sampling_type)
WHERE lv.[timestamp] >= ISNULL(@dtmStartTime,'01-Jan-1900') AND
      lv.[timestamp] < ISNULL(@dtmEndTime,GETDATE()) AND
      lv.[user_id] IN (SELECT [user_id] FROM @Users) AND
      lv.var_id IN (SELECT var_id FROM @Variables) 
ORDER BY lv.[timestamp]

SET NOCOUNT OFF















