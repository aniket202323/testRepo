/*
Stored Procedure: 	 spRS_RptParmValsSubType
Author: 	  	  	  	 Matthew Wells (MSI)
Date Created: 	  	 08/27/01
SP Type: 	  	  	 Report Parameter
Tab Spacing: 	  	 4
Description:
=========
Returns the possible values for the subgroup type parameter.
Change Date 	 Who 	 What
=========== 	 ==== 	 =====
*/
CREATE PROCEDURE [dbo].[spRS_RptParmValsSubType]
@LocaleId int =NULL
AS
DECLARE @List TABLE ( 	 Id 	  	 int,
 	  	  	  	  	  	 Value 	 varchar(50))
DECLARE @LangID int
IF @LocaleId=NULL
BEGIN
 	 SELECT @LangId=0
END
ELSE
BEGIN
 	 SELECT @LangId=Language_Id FROM Language_locale_conversion where LocaleId = @LocaleID
END
INSERT @List
VALUES (0, dbo.fnRS_TranslateString_New(@LangId,34847, 'Variable'))
INSERT @List
VALUES (1, dbo.fnRS_TranslateString_New(@LangId,35321,'Time-Series'))
SELECT Id, Value
FROM @List
SET ANSI_NULLS OFF
