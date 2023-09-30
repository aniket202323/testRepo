CREATE PROCEDURE dbo.spServer_CmnPrepareArray
@Array_Id int OUTPUT
 AS
Insert Into Array_Data(Data,Num_Elements) Values(NULL,0)
Select @Array_Id = Scope_identity()
If (@Array_Id Is NULL)
  Select @Array_Id = 0
