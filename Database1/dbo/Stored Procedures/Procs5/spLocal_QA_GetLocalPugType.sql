
-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_QA_GetLocalPugType]
/*
-------------------------------------------------------------------------------------------------
Updated By	:	Ketki Pophali (Capgemini)
Date			:	2019-05-23
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
Created by 	Marc Charest, Solutions et Technologies Industrielles Inc.
On 		18-Jun-2004	
Version 	1.0.0
Purpose		This SP returns local translation for given PUG description.
-----------------------------------------------------------------------------------------------------------------------
Testing statement:	declare @vcrLocalType varchar(50)
			exec spLocal_QA_GetLocalPugType
				'PAD|PAD@PAD|TAMPON@PAD|WHATEVER@PACKAGE|PACKAGE@CASE|CASE',
				'PAD1@TAMPON1@WHATEVER1@PACKAGE1@CASE1',
				'QA Package Attributes',
				 @vcrLocalType output
			select @vcrLocalType
-----------------------------------------------------------------------------------------------------------------------
*/

@vcrGlobal		varchar(500),
@vcrLocal		varchar(500),
@vcrPUGType		varchar(50),
@vcrType			varchar(50) output

AS
SET NOCOUNT ON

CREATE TABLE #GlobalGroups
(
Group_ID			int,
GroupDesc		varchar(50),
SubgroupDesc	varchar(50)
)

CREATE TABLE #LocalGroups
(
Group_ID			int,
SubgroupDesc	varchar(50)
)

INSERT INTO #GlobalGroups
EXEC spCmn_ReportCollectionParsing					
		@vcrGlobal,	
		'|',					
		'@',						
		'VarChar(500)',
		'VarChar(500)' 

INSERT INTO #LocalGroups
EXEC spCmn_ReportCollectionParsing					
		@vcrLocal,	
		'',					
		'@',						
		'VarChar(500)'

SELECT @vcrType = L.SubgroupDesc 
FROM #GlobalGroups G, #LocalGroups L 
WHERE (@vcrPUGType like '%' + G.SubgroupDesc + '%') and (G.Group_ID = L.Group_ID)

DROP TABLE #GlobalGroups
DROP TABLE #LocalGroups

SET NOCOUNT OFF


