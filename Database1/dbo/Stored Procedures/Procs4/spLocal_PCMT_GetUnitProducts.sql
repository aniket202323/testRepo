




CREATE PROCEDURE [dbo].[spLocal_PCMT_GetUnitProducts]
/*
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2006-01-04
Version		:	1.1.0
Purpose		: 	Compliant with Proficy 3 and 4.
					Added [dbo] template when referencing objects.
					Added registration of SP Version into AppVersions table.
					QSMT Version 10.0.0
-------------------------------------------------------------------------------------------------
Created by	: 	Marc Charest, Solutions et Technologies Industrielles inc.
On				:	10-May-2004
Version		: 	1.0.0
Purpose		:	Returns product descriptions  	
-------------------------------------------------------------------------------------------------
TEST CODE :
exec spLocal_QSMT_GetUnitProducts '10,36'
-------------------------------------------------------------------------------------------------
*/

@vcrUnitIDs	varchar(500)

AS
SET NOCOUNT ON

Declare
@vcrSQLQuery	NVARCHAR(1000)

SET @vcrSQLQuery = 'SELECT DISTINCT p.prod_id, p.prod_desc FROM dbo.pu_products pup, dbo.products p WHERE pup.pu_id IN ('
SET @vcrSQLQuery = @vcrSQLQuery + @vcrUnitIDs
SET @vcrSQLQuery = @vcrSQLQuery + ') AND pup.prod_id = p.prod_id ORDER BY p.prod_desc'

EXEC sp_executesql @vcrSQLQuery

SET NOCOUNT OFF




