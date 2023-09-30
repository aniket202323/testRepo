













-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Put_DataType_Phrase]
/*
-------------------------------------------------------------------------------------------------
											PCMT Version 5.1.1
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2005-11-03
Version		:	1.1.0
Purpose		: 	Compliant with Proficy 3 and 4.
					Added [dbo] template when referencing objects.
					Added registration of SP Version into AppVersions table.
					PCMT Version 5.0.3
-------------------------------------------------------------------------------------------------
Created by	: 	Rick Perreault, Solutions et Technologies Industrielles inc.
On				:	13-Nov-2002	
Version		: 	1.0.0
Purpose		: 	Insert a phrase for a specify data type and order
					PCMT Version 2.1.0 and 3.0.0
-------------------------------------------------------------------------------------------------
*/

@intDataTypeId		integer,
@intPhraseOrder	integer,
@vcrPhrase			varchar(50)

AS

INSERT INTO dbo.Phrase(data_type_ID, Phrase_Order, Phrase_Value) 
VALUES (@intDataTypeId, @intPhraseOrder, @vcrPhrase)

SET NOCOUNT OFF















