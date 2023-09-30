CREATE PROCEDURE dbo.spServer_CmnGetArrayInfo
@Array_Id int,
@Num_Elements int OUTPUT,
@Element_Size int OUTPUT
 AS
Select @Num_Elements = Num_Elements,
       @Element_Size = Element_Size
  From Array_Data
  Where Array_Id = @Array_Id
