Create Procedure dbo.spFF_GetDataTypeDesc 
@DataType_Id int,
@DataType_Desc nvarchar(50) OUTPUT
AS
Select @DataType_Desc = Null
Select @DataType_Desc = Data_Type_Desc From Data_Type Where Data_Type_Id = @DataType_Id
Return(100)
