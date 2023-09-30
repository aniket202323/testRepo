













-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_Translation]
/*
-------------------------------------------------------------------------------------------------
											PCMT Version 5.1.1
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2005-11-01
Version		:	1.1.0
Purpose		: 	Compliant with Proficy 3 and 4.
					Added [dbo] template when referencing objects.
					Added registration of SP Version into AppVersions table.
					PCMT Version 5.0.3
-------------------------------------------------------------------------------------------------
Created By	:	Clement Morin, Solutions et Technologies Industrielles Inc.
On				: 	December 2002	
Version		:	1.0.0
Puprose		:	1) Returns all the languages
					2) Returns all the Items
					3) Returns all translation to fill the translation table  
					PCMT Version 2.1.0 and 3.0.0
-------------------------------------------------------------------------------------------------
*/

@selection	INT,
@langue		Varchar(50) = NULL

AS
SET NOCOUNT ON

IF @Selection = 1
	SELECT [Language] FROM dbo.Local_PG_PCMT_Languages ORDER BY Language
ELSE IF @Selection = 2
	SELECT [Item] FROM dbo.Local_PG_PCMT_Items ORDER BY Item
ELSE IF @Selection = 3
	BEGIN
		SELECT
			lpi.item, lpt.translation
		FROM
			dbo.Local_PG_PCMT_Items lpi
		LEFT JOIN
			dbo.Local_PG_PCMT_Translations lpt
		ON
			(lpt.item_id = lpi.item_id) AND (lpt.lang_id =
																		(SELECT
																			lang_id
																		FROM
																			dbo.Local_PG_PCMT_Languages
																		WHERE
																			language = @langue)
			)
		ORDER BY
			lpi.item
	END
	
SET NOCOUNT OFF















