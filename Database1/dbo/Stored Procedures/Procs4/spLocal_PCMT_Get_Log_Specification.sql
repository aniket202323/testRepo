













-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_Log_Specification]
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
					Replaced #Users temp table with @Users table variable
					PCMT Version 5.0.3
-------------------------------------------------------------------------------------------------
Created By	:	Rick Perreault, Solutions et Technologies Industrielles Inc.
On				:	19-Dec-02	
Version		:	1.0.0
Purpose		:	This SP gets specifications logs from Local_PG_PCMT_log_specifications
					PCMT Version 2.1.0 and 3.0.0
-------------------------------------------------------------------------------------------------
*/

@dtmStartTime	datetime=NULL,
@dtmEndTime		datetime=NULL,
@intUserId		integer=NULL

AS
SET NOCOUNT ON

DECLARE @Users TABLE
(
[user_id]		INTEGER
)

--If user is not specified, then look for all users
IF @intUserId IS NULL
  INSERT @Users ([user_id])
  SELECT DISTINCT [user_id]
  FROM dbo.Local_PG_PCMT_Log_Specifications
ELSE
  INSERT @Users ([user_id]) VALUES(@intUserId)


SELECT	CONVERT(varchar,ls.[timestamp],120) AS [Entry On], 
	u.username AS [User], 
	Type, 
        pp.prop_desc AS Property,
        ls.Spec_Id AS [Specification Id],
        ls.Spec_Desc AS [Specification],
        dt.data_type_desc AS [Data Type],
        ls.spec_precision AS [Precision],
        ls.extended_info AS [Extended Info]
FROM	dbo.Local_PG_PCMT_Log_Specifications ls
        LEFT JOIN dbo.Users u		ON (u.[user_id] = ls.[user_id])
        LEFT JOIN dbo.Specifications s	ON (s.spec_id = ls.spec_id)
		  LEFT JOIN dbo.Product_Properties pp ON (pp.prop_id = s.prop_id)
        LEFT JOIN dbo.Data_Type dt		ON (dt.data_type_id = ls.data_type_id)
WHERE ls.[timestamp] >= ISNULL(@dtmStartTime,'01-Jan-1900') AND
      ls.[timestamp] < ISNULL(@dtmEndTime,GETDATE()) AND
      ls.[user_id] IN (SELECT [user_id] FROM @Users)
ORDER BY ls.[timestamp]

SET NOCOUNT OFF















