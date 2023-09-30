
-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_QA_Sample_Required]
/*
-------------------------------------------------------------------------------------------------
Updated By	:	Ketki Pophali (Capgemini)
Date			:	2019-05-24
Version		:	1.2.0
Purpose		: 	FO-03488: App version entry in stored procedures using Appversions table
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2005-11-21
Version		:	1.1.0
Purpose		: 	Compliant with Proficy 3 and 4.
					Added [dbo] template when referencing objects.
					Added registration of SP Version into AppVersions table.
-------------------------------------------------------------------------------------------------
Created by Ugo Lapierre, Solutions et Technologies Industrielles inc.
On 14-nov-01							Version 1.0.0
Purpose : 		Change VB script for Stored Procedure
-------------------------------------------------------------------------------------------------
TEST CODE :
Declare @Out varchar(30)
EXEC spLocal_QA_Sample_Required @Out OUTPUT, '> 35000'
SELECT @Out
-------------------------------------------------------------------------------------------------
*/

@outputvalue	varchar(30) OUTPUT,
@a					varchar(30)

AS
SET NOCOUNT ON

Declare
@Result			float

SELECT @Result =
	CASE @a
		WHEN '501 - 1200' THEN 80
		WHEN '1201 - 3200' THEN 125
		WHEN '3201 - 10000' THEN 200
		WHEN '10001 - 35000' THEN 315
		WHEN '> 35000' THEN 420
	END
	
SET @outputvalue = convert(varchar(30),@result)

SET NOCOUNT OFF


