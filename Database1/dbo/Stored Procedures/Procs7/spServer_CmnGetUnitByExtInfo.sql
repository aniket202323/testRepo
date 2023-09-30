CREATE PROCEDURE dbo.spServer_CmnGetUnitByExtInfo
@Extended_Info nVarChar(255),
@PU_Id int output,
@MasterUnit int output
 AS
Select @PU_Id = NULL
Select @PU_Id = PU_Id,
       @MasterUnit = Master_Unit
  From Prod_Units_Base 
  Where Extended_Info Like '%' + @Extended_Info + '%'
If (@PU_Id Is NULL)
  Begin
    Select @MasterUnit = 0
    Select @PU_Id = 0
  End
Else
  If (@MasterUnit Is NULL)
    Select @MasterUnit = @PU_Id
