CREATE PROCEDURE dbo.spCC_LookupDisplay
  @Sheet_Desc nvarchar(50),
  @Form_Type nvarchar(50) OUTPUT,
  @Form_Type_Id Integer OUTPUT
 AS 
Declare @FormType nvarchar(50)
Declare @FormTypeId Integer
Select @FormType = ""
Select @FormTypeId = 0
If @Sheet_Desc > "" 
BEGIN
  Select @FormType = st.Sheet_Type_Desc, @FormTypeId = st.Sheet_Type_Id
    From Sheets s
    Join Sheet_Type st on st.Sheet_Type_Id = s.Sheet_Type
    Where s.Sheet_Desc = @Sheet_Desc
END
SELECT @Form_Type = @FormType, @Form_Type_Id = @FormTypeId
IF @@ERROR > 0 RETURN (0)
RETURN(1)
