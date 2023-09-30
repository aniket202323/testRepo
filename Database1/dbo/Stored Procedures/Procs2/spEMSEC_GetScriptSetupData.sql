CREATE Procedure dbo.spEMSEC_GetScriptSetupData
@ModelNumber int
AS
DECLARE @ModelId Int
SELECT @ModelId = ED_Model_Id From ed_Models where Model_Num = @ModelNumber
SELECT Ed_Script_ID,Script_Desc,Field_Desc,TabNumber,VB_Script,Result_Desc  
 	 FROM ed_Script es 
 	 JOIN ed_Fields ef on  es.ED_Field_Id = ef.ED_Field_Id 
WHERE  es.ED_Model_Id = @ModelId
Order by Ed_Script_ID Desc
