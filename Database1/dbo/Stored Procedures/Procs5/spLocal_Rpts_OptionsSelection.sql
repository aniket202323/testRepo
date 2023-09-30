     /*  
Name: spLocal_STLS_sel_Options1  
Purpose: Select Sort-By Options.  
Date: 12/17/2001  
*/  
CREATE PROCEDURE spLocal_Rpts_OptionsSelection  
 @OptionDataType VARCHAR(50)  
AS  
SELECT DISTINCT Phrase.Phrase_Value, Phrase.Data_Type_Id, Phrase.Phrase_Id, Phrase.Phrase_Order  
FROM Phrase  
Join Data_Type ON Phrase.Data_Type_Id = Data_Type.Data_Type_Id  
WHERE Data_Type.Data_Type_Desc = @OptionDataType  
ORDER BY Phrase.Phrase_Value  
